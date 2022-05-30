// Copyright (c) 2021 Proton AG
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

import Crypto
import XCTest
@testable import ProtonMail
import ProtonCore_DataModel
import PromiseKit

class MessageSendingRequestBuilderTests: XCTestCase {

    var sut: MessageSendingRequestBuilder!

    let testBody = "body".data(using: .utf8)!
    let testSession = "session".data(using: .utf8)!
    let algo = "aes256"

    override func tearDown() {
        super.tearDown()
        sut = nil
    }

    func testCalculateSendType_internal() {
        sut = MessageSendingRequestBuilder(expirationOffset: nil)
        XCTAssertEqual(sut.calculateSendType(recipientType: 1,
                                             isEO: false,
                                             hasPGPKey: false,
                                             hasPGPEncryption: false,
                                             isMIME: false),
                       .intl)

        XCTAssertEqual(sut.calculateSendType(recipientType: 1,
                                             isEO: false,
                                             hasPGPKey: true,
                                             hasPGPEncryption: true,
                                             isMIME: false),
                       .intl)

        XCTAssertEqual(sut.calculateSendType(recipientType: 1,
                                             isEO: true,
                                             hasPGPKey: false,
                                             hasPGPEncryption: false,
                                             isMIME: false),
                       .intl)
    }

    func testCalculateSendType_eo() {
        sut = MessageSendingRequestBuilder(expirationOffset: nil)
        XCTAssertEqual(sut.calculateSendType(recipientType: 2,
                                             isEO: true,
                                             hasPGPKey: false,
                                             hasPGPEncryption: false,
                                             isMIME: false),
                       .eo)

        XCTAssertEqual(sut.calculateSendType(recipientType: 2,
                                             isEO: true,
                                             hasPGPKey: true,
                                             hasPGPEncryption: true,
                                             isMIME: false),
                       .eo)

    }

    func testCalculateSendType_withExpirationOffsetSet_eo() {
        sut = MessageSendingRequestBuilder(expirationOffset: 100)
        XCTAssertEqual(sut.calculateSendType(recipientType: 2,
                                             isEO: true,
                                             hasPGPKey: true,
                                             hasPGPEncryption: true,
                                             isMIME: true),
                       .eo)
    }

    func testCalculateSendType_pgpMIME() {
        sut = MessageSendingRequestBuilder(expirationOffset: nil)
        XCTAssertEqual(sut.calculateSendType(recipientType: 2,
                                             isEO: false,
                                             hasPGPKey: true,
                                             hasPGPEncryption: true,
                                             isMIME: true),
                       .pgpmime)
    }

    func testCalculateSendType_clearMIME() {
        sut = MessageSendingRequestBuilder(expirationOffset: nil)
        XCTAssertEqual(sut.calculateSendType(recipientType: 2,
                                             isEO: false,
                                             hasPGPKey: false,
                                             hasPGPEncryption: false,
                                             isMIME: true),
                       .cmime)
    }

    func testCalculateSendType_pgpInline() {
        sut = MessageSendingRequestBuilder(expirationOffset: nil)
        XCTAssertEqual(sut.calculateSendType(recipientType: 2,
                                             isEO: false,
                                             hasPGPKey: true,
                                             hasPGPEncryption: true,
                                             isMIME: false),
                       .inlnpgp)
    }

    func testCalculateSendType_clearInline() {
        sut = MessageSendingRequestBuilder(expirationOffset: nil)
        XCTAssertEqual(sut.calculateSendType(recipientType: 2,
                                             isEO: false,
                                             hasPGPKey: false,
                                             hasPGPEncryption: false,
                                             isMIME: false),
                       .cinln)
    }

    func testInit() {
        sut = MessageSendingRequestBuilder(expirationOffset: Int32(100))
        XCTAssertEqual(sut.expirationOffset, Int32(100))

        sut = MessageSendingRequestBuilder(expirationOffset: nil)
        XCTAssertEqual(sut.expirationOffset, Int32(0))
    }

    func testUpdateBodyData_bodySessionAndBodyAlgorithm() {
        sut = MessageSendingRequestBuilder(expirationOffset: nil)
        let testData = "Body".data(using: .utf8)!
        let testSession = "Key".data(using: .utf8)!
        let testAlgo = "algo"
        sut.update(bodyData: testData,
                   bodySession: testSession,
                   algo: testAlgo)
        XCTAssertEqual(sut.bodyDataPacket, testData)
        XCTAssertEqual(sut.bodySessionKey, testSession)
        XCTAssertEqual(sut.bodySessionAlgo, testAlgo)
    }

    func testSetPasswordAndHint() {
        sut = MessageSendingRequestBuilder(expirationOffset: nil)
        let testPassword = "pwd"
        let testHint = "hint"
        sut.set(password: testPassword, hint: testHint)
        XCTAssertEqual(sut.password, testPassword)
        XCTAssertEqual(sut.hint, testHint)
    }

    func testSetClearBody() {
        sut = MessageSendingRequestBuilder(expirationOffset: nil)
        let testClearBody = "body"
        sut.set(clearBody: testClearBody)
        XCTAssertEqual(sut.clearBody, testClearBody)
    }

    func testAddAddress() {
        sut = MessageSendingRequestBuilder(expirationOffset: nil)
        XCTAssertTrue(sut.preAddresses.isEmpty)
        let testAddress = PreAddress(email: "test@test.test",
                                     pubKey: nil,
                                     pgpKey: nil,
                                     recipintType: 1,
                                     isEO: false,
                                     mime: false,
                                     sign: false,
                                     pgpencrypt: false,
                                     plainText: true)
        sut.add(address: testAddress)
        XCTAssertEqual(sut.preAddresses.count, 1)
        XCTAssertEqual(sut.preAddresses[0], testAddress)
    }

    func testAddAttachment() {
        sut = MessageSendingRequestBuilder(expirationOffset: nil)
        XCTAssertTrue(sut.preAttachments.isEmpty)
        let testAttachment = Attachment()
        let testPreAttachment = PreAttachment(id: "id",
                                              session: "key".data(using: .utf8)!,
                                              algo: "algo",
                                              att: testAttachment)
        sut.add(attachment: testPreAttachment)
        XCTAssertEqual(sut.preAttachments.count, 1)
        XCTAssertEqual(sut.preAttachments[0].attachmentId, "id")
    }

    func testContains() {
        sut = MessageSendingRequestBuilder(expirationOffset: nil)
        XCTAssertTrue(sut.preAddresses.isEmpty)
        XCTAssertFalse(sut.contains(type: .pgpmime))

        let pgpMIMEAddress = PreAddress(email: "test@test.com",
                                        pubKey: "key",
                                        pgpKey: "key".data(using: .utf8),
                                        recipintType: 2,
                                        isEO: false,
                                        mime: true,
                                        sign: true,
                                        pgpencrypt: true,
                                        plainText: false)
        sut.add(address: pgpMIMEAddress)
        XCTAssertTrue(sut.contains(type: .pgpmime))
    }

    func testHasMIME() {
        sut = MessageSendingRequestBuilder(expirationOffset: nil)
        XCTAssertTrue(sut.preAddresses.isEmpty)
        XCTAssertFalse(sut.hasMime)

        let pgpMIMEAddress = PreAddress(email: "test@test.com",
                                        pubKey: "key",
                                        pgpKey: "key".data(using: .utf8),
                                        recipintType: 2,
                                        isEO: false,
                                        mime: true,
                                        sign: true,
                                        pgpencrypt: true,
                                        plainText: false)
        sut.add(address: pgpMIMEAddress)
        XCTAssertTrue(sut.hasMime)
    }

    func testHasPlainText() {
        sut = MessageSendingRequestBuilder(expirationOffset: nil)
        XCTAssertTrue(sut.preAddresses.isEmpty)
        XCTAssertFalse(sut.hasPlainText)

        let plainTextAddress = PreAddress(email: "test@test.com",
                                          pubKey: nil,
                                          pgpKey: nil,
                                          recipintType: 2,
                                          isEO: false,
                                          mime: false,
                                          sign: false,
                                          pgpencrypt: false,
                                          plainText: true)
        sut.add(address: plainTextAddress)
        XCTAssertTrue(sut.hasPlainText)
    }

    func testEncodedBody() {
        sut = MessageSendingRequestBuilder(expirationOffset: nil)
        let testBody = "Body".data(using: .utf8)!
        let testSessionKey = "Key".data(using: .utf8)!
        let testEncodedSession = testSessionKey.base64EncodedString(options: .init(rawValue: 0))

        sut.update(bodyData: testBody,
                   bodySession: testSessionKey,
                   algo: "algo")

        XCTAssertEqual(sut.bodyDataPacket, testBody)
        XCTAssertEqual(sut.bodySessionKey, testSessionKey)
        XCTAssertEqual(sut.encodedSessionKey, testEncodedSession)
    }

    func testGeneratePlainTextBody() {
        sut = MessageSendingRequestBuilder(expirationOffset: nil)
        let testClearBody = "<html><head></head><body> <div><br></div><div><br></div> <div id=\"protonmail_mobile_signature_block\"><div>Sent from ProtonMail for iOS</div></div></body></html>"
        sut.set(clearBody: testClearBody)
        XCTAssertEqual(sut.generatePlainTextBody(), "\r\n\r\nSent from ProtonMail for iOS\r\n")
    }

    func testGenerateBoundaryString() {
        sut = MessageSendingRequestBuilder(expirationOffset: nil)
        var result = ""
        for _ in 0..<10 {
            let temp = sut.generateMessageBoundaryString()
            XCTAssertFalse(temp.isEmpty)
            XCTAssertNotEqual(result, temp)
            result = temp
        }
    }

    func testBuildFirstPartOfBody() {
        sut = MessageSendingRequestBuilder(expirationOffset: nil)
        let boundaryMsg = "---BoundaryMsg---"
        let messageBody = "test"
        let expected = "Content-Type: multipart/related; boundary=\"---BoundaryMsg---\"\r\n\r\n-----BoundaryMsg---\r\nContent-Type: text/html; charset=utf-8\r\nContent-Transfer-Encoding: quoted-printable\r\nContent-Language: en-US\r\n\r\ntest\r\n\r\n\r\n\r\n"
        XCTAssertEqual(sut.buildFirstPartOfBody(boundaryMsg: boundaryMsg, messageBody: messageBody), expected)
    }

    func testBuildAttachmentBody() {
        sut = MessageSendingRequestBuilder(expirationOffset: nil)
        let boundaryMsg = "---BoundaryMsg---"
        let attContent = "test att".data(using: .utf8)!.base64EncodedString()
        let attName = "test"
        let contentID = "1234"
        let mimeType = "text"
        let expected = "-----BoundaryMsg---\r\nContent-Type: text; name=\"test\"\r\nContent-Transfer-Encoding: base64\r\nContent-Disposition: attachment; filename=\"test\"\r\nContent-ID: <1234>\r\n\r\ndGVzdCBhdHQ=\r\n"

        let result = sut.buildAttachmentBody(boundaryMsg: boundaryMsg,
                                             base64AttachmentContent: attContent,
                                             attachmentName: attName,
                                             contentID: contentID,
                                             attachmentMIMEType: mimeType)
        XCTAssertEqual(result, expected)
    }

    func testPreparePackages() throws {
        sut = MessageSendingRequestBuilder(expirationOffset: nil)
        let key = Key(keyID: "1",
                      privateKey: OpenPGPDefines.privateKey)
        let encrypted = try "test".encrypt(withKey: key, userKeys: [], mailbox_pwd: OpenPGPDefines.passphrase)

        let (keyPacket, dataPacket) = try sut.preparePackages(encrypted: encrypted)

        let splitMsg = CryptoNewPGPSplitMessageFromArmored(encrypted, nil)
        XCTAssertEqual(keyPacket, splitMsg?.keyPacket)
        XCTAssertEqual(dataPacket, splitMsg?.dataPacket)
    }

    func testClearBodyPackage() throws {
        sut = MessageSendingRequestBuilder(expirationOffset: nil)
        XCTAssertNil(sut.clearBodyPackage)
        let plainTextAddress = PreAddress(email: "test@test.com",
                                          pubKey: nil,
                                          pgpKey: nil,
                                          recipintType: 2,
                                          isEO: false,
                                          mime: false,
                                          sign: false,
                                          pgpencrypt: false,
                                          plainText: true)
        sut.add(address: plainTextAddress)
        XCTAssertNil(sut.clearBodyPackage)

        setupTestBody()

        XCTAssertNotNil(sut.clearBodyPackage)
        let result = try XCTUnwrap(sut.clearBodyPackage)
        XCTAssertEqual(result.algo, algo)
        XCTAssertEqual(result.key, testSession.base64EncodedString())
    }

    func testGeneratePackageBuilder_noAddress_emptyBuilder() throws {
        sut = MessageSendingRequestBuilder(expirationOffset: nil)
        XCTAssertTrue(try sut.generatePackageBuilder().isEmpty)
    }

    func testGeneratePackageBuilder_internalAddress() throws {
        sut = MessageSendingRequestBuilder(expirationOffset: nil)

        let internalAddress = PreAddress(email: "test@test.test",
                                         pubKey: nil,
                                         pgpKey: nil,
                                         recipintType: 1,
                                         isEO: false,
                                         mime: false,
                                         sign: false,
                                         pgpencrypt: false,
                                         plainText: false)
        sut.add(address: internalAddress)
        setupTestBody()

        let result = try sut.generatePackageBuilder()
        XCTAssertFalse(result.isEmpty)
        XCTAssertEqual(result.count, 1)
        let builder = try XCTUnwrap(result[0] as? InternalAddressBuilder)
        XCTAssertEqual(builder.preAddress, internalAddress)
        XCTAssertEqual(builder.sendType, .intl)
        XCTAssertEqual(builder.session, sut.bodySessionKey)
        XCTAssertEqual(builder.algo, sut.bodySessionAlgo)
    }

    func testGeneratePackageBuilder_addressWithPlainText_withoutCallingBuild_throwError() throws {
        sut = MessageSendingRequestBuilder(expirationOffset: nil)

        let internalAddress = PreAddress(email: "test@test.test",
                                         pubKey: nil,
                                         pgpKey: nil,
                                         recipintType: 1,
                                         isEO: false,
                                         mime: false,
                                         sign: false,
                                         pgpencrypt: false,
                                         plainText: true)
        sut.add(address: internalAddress)
        setupTestBody()

        XCTAssertThrowsError(try sut.generatePackageBuilder())
    }

    func testGeneratePackageBuilder_addressWithPlainText() throws {
        sut = MessageSendingRequestBuilder(expirationOffset: nil)

        let internalAddress = PreAddress(email: "test@test.test",
                                         pubKey: nil,
                                         pgpKey: nil,
                                         recipintType: 1,
                                         isEO: false,
                                         mime: false,
                                         sign: false,
                                         pgpencrypt: false,
                                         plainText: true)
        sut.add(address: internalAddress)
        setupTestBody()

        let testPassphrase = OpenPGPDefines.passphrase
        let testKey = Key(keyID: "1",
                          privateKey: OpenPGPDefines.privateKey)

        let expectation1 = expectation(description: "closure called")
        sut.buildPlainText(senderKey: testKey,
                           passphrase: testPassphrase,
                           userKeys: [],
                           keys: [],
                           newSchema: false).done { _ in
            XCTAssertNotNil(self.sut.plainTextSessionAlgo)
            XCTAssertNotNil(self.sut.plainTextSessionKey)
            XCTAssertNotNil(self.sut.plainTextDataPackage)

            let result = try self.sut.generatePackageBuilder()

            XCTAssertFalse(result.isEmpty)
            XCTAssertEqual(result.count, 1)
            let builder = try XCTUnwrap(result[0] as? InternalAddressBuilder)
            XCTAssertEqual(builder.preAddress, internalAddress)
            XCTAssertEqual(builder.sendType, .intl)
            XCTAssertEqual(builder.session, self.sut.plainTextSessionKey)
            XCTAssertEqual(builder.algo, self.sut.plainTextSessionAlgo)

            expectation1.fulfill()
        }.catch { _ in
            XCTFail("Should not throw error")
        }
        waitForExpectations(timeout: 2, handler: nil)
    }

    func testGeneratePackageBuilder_EOAddress() throws {
        let testEoOffset: Int32 = 100
        let testEOPassword = "EO PWD"
        sut = MessageSendingRequestBuilder(expirationOffset: testEoOffset)
        sut.set(password: testEOPassword, hint: nil)

        let address = PreAddress(email: "test@test.test",
                                 pubKey: nil,
                                 pgpKey: nil,
                                 recipintType: 2,
                                 isEO: true,
                                 mime: false,
                                 sign: false,
                                 pgpencrypt: false,
                                 plainText: false)
        sut.add(address: address)
        setupTestBody()

        let result = try sut.generatePackageBuilder()
        XCTAssertFalse(result.isEmpty)
        XCTAssertEqual(result.count, 1)
        let builder = try XCTUnwrap(result[0] as? EOAddressBuilder)
        XCTAssertEqual(builder.preAddress, address)
        XCTAssertEqual(builder.sendType, .eo)
        XCTAssertEqual(builder.session, sut.bodySessionKey)
        XCTAssertEqual(builder.algo, sut.bodySessionAlgo)
        XCTAssertEqual(builder.password, testEOPassword)
        XCTAssertNil(builder.hit)
    }

    func testGeneratePackageBuilder_ClearAddress() throws {
        sut = MessageSendingRequestBuilder(expirationOffset: nil)

        let address = PreAddress(email: "test@test.test",
                                 pubKey: nil,
                                 pgpKey: nil,
                                 recipintType: 2,
                                 isEO: false,
                                 mime: false,
                                 sign: false,
                                 pgpencrypt: false,
                                 plainText: false)
        sut.add(address: address)
        setupTestBody()

        let result = try sut.generatePackageBuilder()
        XCTAssertFalse(result.isEmpty)
        XCTAssertEqual(result.count, 1)
        let builder = try XCTUnwrap(result[0] as? ClearAddressBuilder)
        XCTAssertEqual(builder.preAddress, address)
        XCTAssertEqual(builder.sendType, .cinln)
    }

    func testGeneratePackageBuilder_inlinePGPAddress() throws {
        sut = MessageSendingRequestBuilder(expirationOffset: nil)

        let address = PreAddress(email: "test@test.test",
                                 pubKey: nil,
                                 pgpKey: "key".data(using: .utf8)!,
                                 recipintType: 2,
                                 isEO: false,
                                 mime: false,
                                 sign: false,
                                 pgpencrypt: true,
                                 plainText: false)
        sut.add(address: address)
        setupTestBody()

        let result = try sut.generatePackageBuilder()
        XCTAssertFalse(result.isEmpty)
        XCTAssertEqual(result.count, 1)
        let builder = try XCTUnwrap(result[0] as? PGPAddressBuilder)
        XCTAssertEqual(builder.preAddress, address)
        XCTAssertEqual(builder.sendType, .inlnpgp)
        XCTAssertEqual(builder.session, sut.bodySessionKey)
        XCTAssertEqual(builder.algo, sut.bodySessionAlgo)
    }

    func testGeneratePackageBuilder_PGPMIMEaddress() throws {
        sut = MessageSendingRequestBuilder(expirationOffset: nil)

        let address = PreAddress(email: "test@test.test",
                                 pubKey: nil,
                                 pgpKey: "key".data(using: .utf8)!,
                                 recipintType: 2,
                                 isEO: false,
                                 mime: true,
                                 sign: true,
                                 pgpencrypt: true,
                                 plainText: false)
        sut.add(address: address)
        setupTestBody()

        let testPassphrase = OpenPGPDefines.passphrase
        let testKey = Key(keyID: "1",
                          privateKey: OpenPGPDefines.privateKey)

        let expectation1 = expectation(description: "closure called")

        sut.buildMime(senderKey: testKey,
                      passphrase: testPassphrase,
                      userKeys: [],
                      keys: [],
                      newSchema: false).done { _ in
            XCTAssertNotNil(self.sut.mimeDataPackage)
            XCTAssertNotNil(self.sut.mimeSessionAlgo)
            XCTAssertNotNil(self.sut.mimeSessionKey)

            let result = try self.sut.generatePackageBuilder()

            XCTAssertFalse(result.isEmpty)
            XCTAssertEqual(result.count, 1)
            let builder = try XCTUnwrap(result[0] as? PGPMimeAddressBuilder)
            XCTAssertEqual(builder.preAddress, address)
            XCTAssertEqual(builder.sendType, .pgpmime)
            XCTAssertEqual(builder.session, self.sut.mimeSessionKey)
            XCTAssertEqual(builder.algo, self.sut.mimeSessionAlgo)

            expectation1.fulfill()
        }.catch { _ in
            XCTFail("Should not throw error")
        }
        waitForExpectations(timeout: 2, handler: nil)
    }

    func testGeneratePackageBuilder_claerMIMEaddress() throws {
        sut = MessageSendingRequestBuilder(expirationOffset: nil)

        let address = PreAddress(email: "test@test.test",
                                 pubKey: nil,
                                 pgpKey: nil,
                                 recipintType: 2,
                                 isEO: false,
                                 mime: true,
                                 sign: false,
                                 pgpencrypt: false,
                                 plainText: false)
        sut.add(address: address)
        setupTestBody()

        let testPassphrase = OpenPGPDefines.passphrase
        let testKey = Key(keyID: "1",
                          privateKey: OpenPGPDefines.privateKey)

        let expectation1 = expectation(description: "closure called")

        sut.buildMime(senderKey: testKey,
                      passphrase: testPassphrase,
                      userKeys: [],
                      keys: [],
                      newSchema: false).done { _ in
            let result = try self.sut.generatePackageBuilder()

            XCTAssertFalse(result.isEmpty)
            XCTAssertEqual(result.count, 1)
            let builder = try XCTUnwrap(result[0] as? ClearMimeAddressBuilder)
            XCTAssertEqual(builder.preAddress, address)
            XCTAssertEqual(builder.sendType, .cmime)

            expectation1.fulfill()
        }.catch { _ in
            XCTFail("Should not throw error")
        }
        waitForExpectations(timeout: 2, handler: nil)
    }

    private func setupTestBody() {
        sut.update(bodyData: testBody,
                   bodySession: testSession,
                   algo: algo)
    }
}
