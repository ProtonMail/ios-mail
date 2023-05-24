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
import ProtonCore_Crypto
import ProtonCore_DataModel
import ProtonCore_TestingToolkit
import XCTest

@testable import ProtonMail

final class ComposeViewModelTests_Forwarding: XCTestCase {
    private var mockCoreDataService: MockCoreDataContextProvider!
    private var user: UserManager!

    private var testContext: NSManagedObjectContext {
        mockCoreDataService.viewContext
    }

    override func setUpWithError() throws {
        try super.setUpWithError()

        mockCoreDataService = .init()
        user = UserManager(api: APIServiceMock(), role: .member)

        let keyPair = try MailCrypto.generateRandomKeyPair()
        let key = Key(keyID: "1", privateKey: keyPair.privateKey)
        key.signature = "signature is needed to make this a V2 key"
        let address = Address(
            addressID: "",
            domainID: nil,
            email: "",
            send: .active,
            receive: .active,
            status: .enabled,
            type: .externalAddress,
            order: 1,
            displayName: "",
            signature: "a",
            hasKeys: 1,
            keys: [key]
        )
        user.userInfo.userAddresses = [address]
        user.authCredential.mailboxpassword = keyPair.passphrase
    }

    override func tearDownWithError() throws {
        mockCoreDataService = nil
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

        let sut = makeSUT(message: message)

        XCTAssertEqual(sut.getAttachments().map(\.id), [attachmentID])
    }

    func testGivenMIMEMessageWithAttachments_whenForwarding_thenPreservesAttachments() throws {
        let body = MessageDecrypterTestData.decryptedHTMLMimeBody()
        let message = try prepareEncryptedMessage(body: body, mimeType: .multipartMixed)

        try testContext.save()

        let attachmentsAreProcessed = expectation(description: "attachments are processed")

        let sut = makeSUT(message: message)

        // TODO: remove this delay, either by making SUT init synchronous or by removing async operations from it
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            attachmentsAreProcessed.fulfill()
        }

        wait(for: [attachmentsAreProcessed], timeout: 0.2)

        XCTAssertEqual(sut.getAttachments().map(\.id), ["0", "0"])
    }

    private func makeSUT(message: Message) -> ComposeViewModel {
        let contactProvider = MockContactProvider(coreDataContextProvider: mockCoreDataService)

        let copyMessage = CopyMessage(
            dependencies: .init(
                contextProvider: mockCoreDataService,
                messageDecrypter: user.messageService.messageDecrypter
            ),
            userDataSource: user
        )

        let dependencies = ComposeViewModel.Dependencies.init(
            coreDataContextProvider: mockCoreDataService,
            coreKeyMaker: MockKeyMakerProtocol(),
            fetchAndVerifyContacts: .init(),
            internetStatusProvider: .init(),
            fetchAttachment: .init(),
            contactProvider: contactProvider,
            helperDependencies: .init(
                messageDataService: user.messageService,
                cacheService: user.cacheService,
                contextProvider: mockCoreDataService,
                copyMessage: copyMessage
            ), fetchMobileSignatureUseCase: FetchMobileSignature(dependencies: .init(coreKeyMaker: MockKeyMakerProtocol(), cache: MockMobileSignatureCacheProtocol()))
        )

        return ComposeViewModel(
            msg: message,
            action: .forward,
            msgService: user.messageService,
            user: user,
            dependencies: dependencies
        )
    }

    private func prepareEncryptedMessage(body: String, mimeType: Message.MimeType) throws -> Message {
        let encryptedBody = try Encryptor.encrypt(
            publicKey: user.addressKeys.toArmoredPrivateKeys[0],
            cleartext: body
        ).value

        let message = Message(context: testContext)
        message.messageID = "foo"
        message.body = encryptedBody
        message.mimeType = mimeType.rawValue
        return message
    }
}
