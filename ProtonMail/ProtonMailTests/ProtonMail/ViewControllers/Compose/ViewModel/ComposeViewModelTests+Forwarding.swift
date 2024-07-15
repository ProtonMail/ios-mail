// Copyright (c) 2023 Proton Technologies AG
//
// This file is part of Proton Mail.
//
// Proton Mail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Mail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Mail. If not, see https://www.gnu.org/licenses/.

import CoreData
import ProtonCoreCrypto
import ProtonCoreDataModel
import ProtonCoreTestingToolkitUnitTestsServices
import XCTest

@testable import ProtonMail

final class ComposeViewModelTests_Forwarding: XCTestCase {
    private var sut: ComposeViewModel!
    private var testContainer: TestContainer!
    private var user: UserManager!

    private var testContext: NSManagedObjectContext {
        testContainer.contextProvider.mainContext
    }

    override func setUpWithError() throws {
        try super.setUpWithError()

        testContainer = .init()
        user = try UserManager.prepareUser(apiMock: APIServiceMock(), globalContainer: testContainer)
        let composerViewFactory = user.container.composerViewFactory
        sut = ComposeViewModel(
            remoteContentPolicy: .allowedThroughProxy,
            embeddedContentPolicy: .allowed,
            dependencies: composerViewFactory.composeViewModelDependencies
        )
    }

    override func tearDownWithError() throws {
        sut = nil
        testContainer = nil
        user = nil

        try super.tearDownWithError()
    }

    func testGivenPlainMessageWithAttachments_whenForwarding_thenPreservesAttachments() throws {
        let message = try prepareEncryptedMessage(body: "foo", mimeType: .textPlain)

        let attachment = Attachment(context: testContext)
        let attachmentID = AttachmentID(UUID().uuidString)
        attachment.attachmentID = attachmentID.rawValue
        attachment.message = message

        try testContext.save()

        try sut.initialize(message: .init(message), action: .forward)

        XCTAssertEqual(self.sut.getAttachments().map(\.id), [attachmentID])
    }

    func testGivenMIMEMessageWithAttachments_whenForwarding_thenPreservesAttachments() throws {
        let body = MessageDecrypterTestData.decryptedHTMLMimeBody()
        let message = try prepareEncryptedMessage(body: body, mimeType: .multipartMixed)

        try testContext.save()

        try sut.initialize(message: .init(message), action: .forward)

        wait(self.sut.getAttachments().count == 2)
        XCTAssertEqual(sut.getAttachments().map(\.id), ["0", "0"])
    }

    private func prepareEncryptedMessage(body: String, mimeType: Message.MimeType) throws -> Message {
        let encryptedBody = try Encryptor.encrypt(
            publicKey: user.userInfo.addressKeys.toArmoredPrivateKeys[0],
            cleartext: body
        ).value

        let message = Message(context: testContext)
        message.messageID = "foo"
        message.body = encryptedBody
        message.mimeType = mimeType.rawValue
        return message
    }
}
