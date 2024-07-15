// Copyright (c) 2022 Proton AG
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

import ProtonCoreCrypto
import ProtonCoreDataModel
import ProtonCoreTestingToolkitUnitTestsServices
import XCTest

@testable import ProtonMail

final class MessageDecrypterTests: XCTestCase {
    private var mockUserData: UserManager!
    private var decrypter: MessageDecrypter!

    override func setUpWithError() throws {
        self.mockUserData = UserManager(api: APIServiceMock(), role: .member)
        self.decrypter = MessageDecrypter(userDataSource: mockUserData)

        try CryptoKeyHelper.populateAddressesAndKeys(on: mockUserData)
    }

    override func tearDownWithError() throws {
        self.mockUserData = nil
        self.decrypter = nil
    }

    func verify(mimeAttachments: [MimeAttachment]) throws {
        XCTAssertEqual(mimeAttachments.count, 2)
        let imageAttachment = try XCTUnwrap(mimeAttachments.first(where: { $0.fileName == "image.png" }))

        let manager = FileManager.default
        XCTAssert(imageAttachment.isInline)
        XCTAssertEqual(imageAttachment.mimeType, "image/png")
        XCTAssertEqual(manager.fileExists(atPath: imageAttachment.localUrl?.path ?? ""),
                       true)
        let wordAttachment = try XCTUnwrap(mimeAttachments.first(where: { $0.fileName == "file-sample_100kB.doc" }))
        XCTAssertFalse(wordAttachment.isInline)
        XCTAssertEqual(wordAttachment.mimeType, "application/msword")
        XCTAssertEqual(manager.fileExists(atPath: wordAttachment.localUrl?.path ?? ""),
                       true)
        try? manager.removeItem(atPath: imageAttachment.localUrl?.path ?? "")
        try? manager.removeItem(atPath: wordAttachment.localUrl?.path ?? "")
    }

    func testDecrypt_multipartMixed_textHTML() throws {
        let body = MessageDecrypterTestData.decryptedHTMLMimeBody()
        let message = try self.prepareEncryptedMessage(body: body, mimeType: .multipartMixed)

        let (processedBody, attachments) = try self.decrypter.decrypt(message: message)
        XCTAssert(processedBody.contains(check: MessageDecrypterTestData.imageAttachmentHTMLElement()))

        let mimeAttachments = try XCTUnwrap(attachments)
        try self.verify(mimeAttachments: mimeAttachments)
    }

    func testDecrypt_multipartMixed_textPlain() throws {
        let body = MessageDecrypterTestData.decryptedPlainTextMimeBody()
        let message = try self.prepareEncryptedMessage(body: body, mimeType: .multipartMixed)

        let (processedBody, attachments) = try self.decrypter.decrypt(message: message)
        XCTAssertNotEqual(body, processedBody)
        XCTAssertEqual(processedBody, MessageDecrypterTestData.processedMIMEPlainTextBody())

        let mimeAttachments = try XCTUnwrap(attachments)
        try self.verify(mimeAttachments: mimeAttachments)
    }

    func testDecrypt_textPlain() throws {
        let body = "A & B ' <>"
        let message = try prepareEncryptedMessage(body: body, mimeType: .textPlain)

        let (processedBody, attachments) = try self.decrypter.decrypt(message: message)

        XCTAssertEqual(processedBody, "A &amp; B &#039; &lt;&gt;")
        XCTAssertNil(attachments)
    }

    func testDecrypt_textHTML() throws {
        let body = "<html><head></head><body> A & B ' <>"
        let message = try prepareEncryptedMessage(body: body, mimeType: .textHTML)

        let (processedBody, attachments) = try self.decrypter.decrypt(message: message)

        XCTAssertEqual(processedBody, body)
        XCTAssertNil(attachments)
    }

    func testDecrypter_emptyString_doesntCrash() throws {
        let body = ""
        let message = try prepareEncryptedMessage(body: body, mimeType: .textPlain)

        let (processedBody, _) = try decrypter.decrypt(message: message)

        XCTAssertEqual(processedBody, body)
    }

    func testCachingImprovesPerformanceWhenPerformingMultipleDecryptions() throws {
        let clock = ContinuousClock()
        let rounds = 50

        let scenarios: [(OpenPGPTestsDefine, Message.MimeType, Double)] = [
            (.message_plaintext, .textHTML, 7),
            (.mime_testMessage_without_mime_sig, .multipartMixed, 1),
        ]

        for (file, mimeType, expectedSpeedup) in scenarios {
            let body = try XCTUnwrap(file.rawValue)
            let message = try prepareEncryptedMessage(body: body, mimeType: mimeType)

            // Warmup, this is to ensure the results are not affected by Go runtime initialization, internal Go caching
            // beside our own, etc
            _ = try decrypter.decrypt(message: message)

            decrypter.setCaching(enabled: false)

            let timeWithoutCaching = try clock.measure {
                for _ in 0..<rounds {
                    _ = try self.decrypter.decrypt(message: message)
                }
            }

            decrypter.setCaching(enabled: true)

            let timeWithCaching = try clock.measure {
                for _ in 0..<rounds {
                    _ = try decrypter.decrypt(message: message)
                }
            }

            let speedup = timeWithoutCaching / timeWithCaching
            XCTAssertGreaterThan(speedup, expectedSpeedup)
        }
    }

    private func prepareEncryptedMessage(body: String, mimeType: Message.MimeType) throws -> MessageEntity {
        let encryptedBody = try body.encrypt(
            withKey: mockUserData.userInfo.addressKeys[0],
            userKeys: mockUserData.userInfo.userPrivateKeys,
            mailboxPassphrase: mockUserData.mailboxPassword
        )

        return MessageEntity.make(mimeType: mimeType.rawValue, body: encryptedBody)
    }
}
