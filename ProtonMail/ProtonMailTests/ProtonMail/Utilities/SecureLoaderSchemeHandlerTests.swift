// Copyright (c) 2024 Proton Technologies AG
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

import ProtonCoreTestingToolkitUnitTestsDoh
import ProtonCoreTestingToolkitUnitTestsServices
import ProtonCoreUIFoundations
import XCTest

@testable import ProtonMail

final class SecureLoaderSchemeHandlerTests: XCTestCase {
    private var sut: SecureLoaderSchemeHandler!
    private var apiService: APIServiceMock!
    private var testContainer: TestContainer!
    private var userKeys: UserKeys!

    private let pasteboard = UIPasteboard.withUniqueName()

    override func setUpWithError() throws {
        try super.setUpWithError()

        apiService = APIServiceMock()
        apiService.dohInterfaceStub.fixture = DohMock()
        testContainer = .init()

        let user = try UserManager.prepareUser(apiMock: apiService, globalContainer: testContainer)
        let imageProxy = ImageProxy(dependencies: .init(apiService: apiService, imageCache: nil))

        userKeys = user.toUserKeys()
        sut = .init(userKeys: userKeys, imageProxy: imageProxy)
    }

    override func tearDown() {
        sut = nil
        apiService = nil
        testContainer = nil
        userKeys = nil

        super.tearDown()
    }

    func testCopyingEmbeddedImage() async throws {
        let embeddedImage: UIImage = IconProvider.inbox
        let attachmentData = try XCTUnwrap(embeddedImage.pngData())
        let attachmentID = "foo"
        let path = FileManager.default.attachmentDirectory.appendingPathComponent(attachmentID)

        let encryptedAttachment = try attachmentData.encryptAttachmentNonOptional(
            fileName: path.absoluteString,
            pubKey: userKeys.addressesPrivateKeys[0].publicKey
        )

        let dataPacket = try XCTUnwrap(encryptedAttachment.dataPacket)
        let keyPacket = try XCTUnwrap(encryptedAttachment.keyPacket)

        try dataPacket.write(to: path)

        let attachmentEntity: AttachmentEntity = try await testContainer.contextProvider.writeAsync { context in
            let attachment = Attachment(context: context)
            attachment.attachmentID = attachmentID
            attachment.keyPacket = keyPacket.base64EncodedString()
            return AttachmentEntity(attachment)
        }

        sut.contents = .init(
            body: "",
            remoteContentMode: .allowedThroughProxy,
            messageDisplayMode: .expanded,
            webImages: .init(embeddedImages: [attachmentEntity])
        )

        pasteboard.url = URL(string: "proton-pm-cache://\(attachmentID)")

        try await verifyImageExistsInPasteboard(expectedData: attachmentData)
    }

    func testCopyingRemoteImage() async throws {
        let remoteImage: UIImage = IconProvider.inbox
        let imageData = try XCTUnwrap(remoteImage.pngData())

        apiService.downloadStub.bodyIs { _, _, fileURL, _, _, _, _, _, _, completion in
            do {
                try FileManager.default.createDirectory(
                    at: fileURL.deletingLastPathComponent(),
                    withIntermediateDirectories: true
                )

                try imageData.write(to: fileURL)
                let response = HTTPURLResponse(statusCode: 200)
                completion(response, nil, nil)
            } catch {
                XCTFail("\(error)")
            }
        }

        pasteboard.url = URL(string: "proton-https://example.png")

        try await verifyImageExistsInPasteboard(expectedData: imageData)
    }

    private func verifyImageExistsInPasteboard(expectedData: Data) async throws {
        let maxAttempts = 10
        var attempts = 0

        while pasteboard.image == nil, attempts <= maxAttempts {
            attempts += 1
            try await Task.sleep(for: .milliseconds(50))
        }

        XCTAssertEqual(pasteboard.image?.pngData()?.count, expectedData.count)
    }
}
