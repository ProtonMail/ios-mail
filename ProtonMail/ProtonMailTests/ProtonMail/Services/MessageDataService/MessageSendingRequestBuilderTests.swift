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

import CoreData
import Crypto
import XCTest
@testable import ProtonMail
import ProtonCore_Crypto
import ProtonCore_DataModel
import PromiseKit

class MessageSendingRequestBuilderTests: XCTestCase {

    var sut: MessageSendingRequestBuilder!
    private var coreDataContextProvider: MockCoreDataContextProvider!

    let testBody = "body".data(using: .utf8)!
    let testSession = "session".data(using: .utf8)!
    let algo: Algorithm = .AES256
    var testPublicKey: CryptoKey!
    let testEmail = "test@proton.me"

    override func setUpWithError() throws {
        try super.setUpWithError()
        sut = MessageSendingRequestBuilder(expirationOffset: nil)
        testPublicKey = try XCTUnwrap(CryptoKey(fromArmored: OpenPGPDefines.publicKey))
    }


    private var context: NSManagedObjectContext {
        coreDataContextProvider.rootSavingContext
    }

    override func setUp() {
        super.setUp()

        coreDataContextProvider = MockCoreDataContextProvider()
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
        coreDataContextProvider = nil
    }

    func testInit() {
        sut = MessageSendingRequestBuilder(expirationOffset: Int32(100))
        XCTAssertEqual(sut.expirationOffset, Int32(100))

        sut = MessageSendingRequestBuilder(expirationOffset: nil)
        XCTAssertEqual(sut.expirationOffset, Int32(0))
    }

    func testUpdateBodyData_bodySessionAndBodyAlgorithm() {
        let testData = "Body".data(using: .utf8)!
        let testSession = "Key".data(using: .utf8)!
        let testAlgo = Algorithm.TripleDES
        sut.update(bodyData: testData,
                   bodySession: testSession,
                   algo: testAlgo)
        XCTAssertEqual(sut.bodyDataPacket, testData)
        XCTAssertEqual(sut.bodySessionKey, testSession)
        XCTAssertEqual(sut.bodySessionAlgo, testAlgo)
    }

    func testSetPasswordAndHint() {
        let testPassword = Passphrase(value: "pwd")
        let testHint = "hint"
        sut.set(password: testPassword, hint: testHint)
        XCTAssertEqual(sut.password, testPassword)
        XCTAssertEqual(sut.hint, testHint)
    }

    func testSetClearBody() {
        let testClearBody = "body"
        sut.set(clearBody: testClearBody)
        XCTAssertEqual(sut.clearBody, testClearBody)
    }

    func testAddSendPreferences() {
        XCTAssertTrue(sut.addressSendPreferences.isEmpty)
        let testPreference = SendPreferences(encrypt: Bool.random(),
                                             sign: Bool.random(),
                                             pgpScheme: .proton,
                                             mimeType: .mime,
                                             publicKeys: nil,
                                             isPublicKeyPinned: Bool.random(),
                                             hasApiKeys: Bool.random(),
                                             hasPinnedKeys: Bool.random(),
                                             error: nil)

        sut.add(email: testEmail, sendPreferences: testPreference)

        XCTAssertEqual(sut.addressSendPreferences.count, 1)
        XCTAssertEqual(sut.addressSendPreferences[testEmail], testPreference)
    }

    func testAddAttachment() {
        XCTAssertTrue(sut.preAttachments.isEmpty)
        let testAttachment = Attachment()
        let testPreAttachment = PreAttachment(id: "id",
                                              session: "key".data(using: .utf8)!,
                                              algo: .AES256,
                                              att: testAttachment)
        sut.add(attachment: testPreAttachment)
        XCTAssertEqual(sut.preAttachments.count, 1)
        XCTAssertEqual(sut.preAttachments[0].attachmentId, "id")
    }

    func testContains() throws {
        sut = MessageSendingRequestBuilder(expirationOffset: nil)
        XCTAssertTrue(sut.addressSendPreferences.isEmpty)
        XCTAssertFalse(sut.contains(type: .pgpMIME))
        let testPreferences = SendPreferences(encrypt: true,
                                              sign: true,
                                              pgpScheme: .pgpMIME,
                                              mimeType: .mime,
                                              publicKeys: testPublicKey,
                                              isPublicKeyPinned: true,
                                              hasApiKeys: false,
                                              hasPinnedKeys: true,
                                              error: nil)

        sut.add(email: testEmail, sendPreferences: testPreferences)
        XCTAssertTrue(sut.contains(type: .pgpMIME))
    }

    func testHasMIME() {
        XCTAssertTrue(sut.addressSendPreferences.isEmpty)
        XCTAssertFalse(sut.hasMime)
        let pgpMIMEPreferences = SendPreferences(encrypt: true,
                                                 sign: true,
                                                 pgpScheme: .pgpMIME,
                                                 mimeType: .mime,
                                                 publicKeys: testPublicKey,
                                                 isPublicKeyPinned: false,
                                                 hasApiKeys: false,
                                                 hasPinnedKeys: false,
                                                 error: nil)
        sut.add(email: testEmail, sendPreferences: pgpMIMEPreferences)

        XCTAssertTrue(sut.hasMime)
    }

    func testHasPlainText() {
        XCTAssertTrue(sut.addressSendPreferences.isEmpty)
        XCTAssertFalse(sut.hasPlainText)
        let plainTextPreferences = SendPreferences(encrypt: false,
                                                   sign: false,
                                                   pgpScheme: .cleartextInline,
                                                   mimeType: .plainText,
                                                   publicKeys: nil,
                                                   isPublicKeyPinned: false,
                                                   hasApiKeys: false,
                                                   hasPinnedKeys: false,
                                                   error: nil)
        sut.add(email: testEmail, sendPreferences: plainTextPreferences)

        XCTAssertTrue(sut.hasPlainText)
    }

    func testEncodedBody() {
        let testBody = "Body".data(using: .utf8)!
        let testSessionKey = "Key".data(using: .utf8)!
        let testEncodedSession = testSessionKey.base64EncodedString(options: .init(rawValue: 0))

        sut.update(bodyData: testBody,
                   bodySession: testSessionKey,
                   algo: .AES256)

        XCTAssertEqual(sut.bodyDataPacket, testBody)
        XCTAssertEqual(sut.bodySessionKey, testSessionKey)
        XCTAssertEqual(sut.encodedSessionKey, testEncodedSession)
    }

    func testGeneratePlainTextBody() {
        let testClearBody = "<html><head></head><body> <div><br></div><div><br></div> <div id=\"protonmail_mobile_signature_block\"><div>Sent from ProtonMail for iOS</div></div></body></html>"
        sut.set(clearBody: testClearBody)
        XCTAssertEqual(sut.generatePlainTextBody(), "\r\n\r\nSent from ProtonMail for iOS\r\n")
    }

    func testGenerateBoundaryString() {
        var result = ""
        for _ in 0..<10 {
            let temp = sut.generateMessageBoundaryString()
            XCTAssertFalse(temp.isEmpty)
            XCTAssertNotEqual(result, temp)
            result = temp
        }
    }

    func testBuildFirstPartOfBody() {
        let boundaryMsg = "---BoundaryMsg---"
        let messageBody = "test"
        let expected = "Content-Type: multipart/related; boundary=\"---BoundaryMsg---\"\r\n\r\n-----BoundaryMsg---\r\nContent-Type: text/html; charset=utf-8\r\nContent-Transfer-Encoding: quoted-printable\r\nContent-Language: en-US\r\n\r\ntest\r\n\r\n\r\n\r\n"
        XCTAssertEqual(sut.buildFirstPartOfBody(boundaryMsg: boundaryMsg, messageBody: messageBody), expected)
    }

    func testBuildAttachmentBody() {
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
        let key = Key(keyID: "1",
                      privateKey: OpenPGPDefines.privateKey)
        let encrypted = try "test".encrypt(withKey: key, userKeys: [], mailbox_pwd: OpenPGPDefines.passphrase)

        let (keyPacket, dataPacket) = try sut.preparePackages(encrypted: encrypted)

        let splitMsg = CryptoNewPGPSplitMessageFromArmored(encrypted, nil)
        XCTAssertEqual(keyPacket, splitMsg?.keyPacket)
        XCTAssertEqual(dataPacket, splitMsg?.dataPacket)
    }

    func testClearBodyPackage() throws {
        XCTAssertNil(sut.clearBodyPackage)
        let plainTextPreference = SendPreferences(encrypt: false,
                                                  sign: false,
                                                  pgpScheme: .cleartextInline,
                                                  mimeType: .plainText,
                                                  publicKeys: nil,
                                                  isPublicKeyPinned: false,
                                                  hasApiKeys: false,
                                                  hasPinnedKeys: false,
                                                  error: nil)
        sut.add(email: testEmail, sendPreferences: plainTextPreference)
        XCTAssertNil(sut.clearBodyPackage)

        setupTestBody()

        XCTAssertNotNil(sut.clearBodyPackage)
        let result = try XCTUnwrap(sut.clearBodyPackage)
        XCTAssertEqual(result.algo, algo)
        XCTAssertEqual(result.key, testSession.base64EncodedString())
    }

    func testGeneratePackageBuilder_noAddress_emptyBuilder() throws {
        XCTAssertTrue(sut.addressSendPreferences.isEmpty)
        XCTAssertTrue(try sut.generatePackageBuilder().isEmpty)
    }

    func testGeneratePackageBuilder_internalAddress() throws {
        let internalPreference = SendPreferences(encrypt: true,
                                                 sign: true,
                                                 pgpScheme: .proton,
                                                 mimeType: .mime,
                                                 publicKeys: testPublicKey,
                                                 isPublicKeyPinned: true,
                                                 hasApiKeys: false,
                                                 hasPinnedKeys: true,
                                                 error: nil)
        sut.add(email: testEmail, sendPreferences: internalPreference)
        setupTestBody()

        let result = try sut.generatePackageBuilder()
        XCTAssertFalse(result.isEmpty)
        XCTAssertEqual(result.count, 1)
        let builder = try XCTUnwrap(result.first as? InternalAddressBuilder)
        XCTAssertEqual(builder.sendPreferences, internalPreference)
        XCTAssertEqual(builder.email, testEmail)
        XCTAssertEqual(builder.sendType, .proton)
        XCTAssertEqual(builder.session, sut.bodySessionKey)
        XCTAssertEqual(builder.algo, sut.bodySessionAlgo)
    }

    func testGeneratePackageBuilder_addressWithPlainText_withoutCallingBuild_throwError() throws {
        let internalPreference = SendPreferences(encrypt: false,
                                                 sign: false,
                                                 pgpScheme: .proton,
                                                 mimeType: .plainText,
                                                 publicKeys: nil,
                                                 isPublicKeyPinned: false,
                                                 hasApiKeys: false,
                                                 hasPinnedKeys: false,
                                                 error: nil)
        sut.add(email: testEmail, sendPreferences: internalPreference)
        setupTestBody()

        XCTAssertThrowsError(try sut.generatePackageBuilder())
    }

    func testGeneratePackageBuilder_addressWithPlainText() throws {
        let internalPreference = SendPreferences(encrypt: false,
                                                 sign: false,
                                                 pgpScheme: .proton,
                                                 mimeType: .plainText,
                                                 publicKeys: nil,
                                                 isPublicKeyPinned: false,
                                                 hasApiKeys: false,
                                                 hasPinnedKeys: false,
                                                 error: nil)
        sut.add(email: testEmail, sendPreferences: internalPreference)
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
            let builder = try XCTUnwrap(result.first as? InternalAddressBuilder)
            XCTAssertEqual(builder.sendPreferences, internalPreference)
            XCTAssertEqual(builder.email, self.testEmail)
            XCTAssertEqual(builder.sendType, .proton)
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
        let testEOPassword = Passphrase(value: "EO PWD")
        sut = MessageSendingRequestBuilder(expirationOffset: testEoOffset)
        sut.set(password: testEOPassword, hint: nil)

        let eoPreference = SendPreferences(encrypt: false,
                                           sign: false,
                                           pgpScheme: .encryptedToOutside,
                                           mimeType: .mime,
                                           publicKeys: nil,
                                           isPublicKeyPinned: false,
                                           hasApiKeys: false,
                                           hasPinnedKeys: false,
                                           error: nil)
        sut.add(email: testEmail, sendPreferences: eoPreference)
        setupTestBody()

        let result = try sut.generatePackageBuilder()
        XCTAssertFalse(result.isEmpty)
        XCTAssertEqual(result.count, 1)
        let builder = try XCTUnwrap(result[0] as? EOAddressBuilder)
        XCTAssertEqual(builder.sendPreferences, eoPreference)
        XCTAssertEqual(builder.sendType, .encryptedToOutside)
        XCTAssertEqual(builder.session, sut.bodySessionKey)
        XCTAssertEqual(builder.algo, sut.bodySessionAlgo)
        XCTAssertEqual(builder.password, testEOPassword)
        XCTAssertNil(builder.passwordHint)
    }

    func testGeneratePackageBuilder_ClearAddress() throws {
        sut = MessageSendingRequestBuilder(expirationOffset: nil)

        let clearPreference = SendPreferences(encrypt: false,
                                              sign: false,
                                              pgpScheme: .cleartextInline,
                                              mimeType: .html,
                                              publicKeys: nil,
                                              isPublicKeyPinned: false,
                                              hasApiKeys: false,
                                              hasPinnedKeys: false,
                                              error: nil)
        sut.add(email: "test@test.com", sendPreferences: clearPreference)
        setupTestBody()

        let result = try sut.generatePackageBuilder()
        XCTAssertFalse(result.isEmpty)
        XCTAssertEqual(result.count, 1)
        let builder = try XCTUnwrap(result.first as? ClearAddressBuilder)
        XCTAssertEqual(builder.sendPreferences, clearPreference)
        XCTAssertEqual(builder.email, "test@test.com")
        XCTAssertEqual(builder.sendType, .cleartextInline)
    }

    func testGeneratePackageBuilder_inlinePGPAddress() throws {
        let inlinePGPPreference = SendPreferences(encrypt: true,
                                                  sign: false,
                                                  pgpScheme: .pgpInline,
                                                  mimeType: .html,
                                                  publicKeys: testPublicKey,
                                                  isPublicKeyPinned: false,
                                                  hasApiKeys: false,
                                                  hasPinnedKeys: false,
                                                  error: nil)
        sut.add(email: testEmail, sendPreferences: inlinePGPPreference)
        setupTestBody()

        let result = try sut.generatePackageBuilder()
        XCTAssertFalse(result.isEmpty)
        XCTAssertEqual(result.count, 1)
        let builder = try XCTUnwrap(result.first as? PGPAddressBuilder)
        XCTAssertEqual(builder.sendPreferences, inlinePGPPreference)
        XCTAssertEqual(builder.sendType, .pgpInline)
        XCTAssertEqual(builder.session, sut.bodySessionKey)
        XCTAssertEqual(builder.algo, sut.bodySessionAlgo)
    }

    func testGeneratePackageBuilder_PGPMIMEaddress() throws {
        let pgpMIMEPreference = SendPreferences(encrypt: true,
                                                sign: true,
                                                pgpScheme: .pgpMIME,
                                                mimeType: .mime,
                                                publicKeys: testPublicKey,
                                                isPublicKeyPinned: false,
                                                hasApiKeys: false,
                                                hasPinnedKeys: false,
                                                error: nil)
        sut.add(email: testEmail, sendPreferences: pgpMIMEPreference)
        setupTestBody()

        let testPassphrase = OpenPGPDefines.passphrase
        let testKey = Key(keyID: "1",
                          privateKey: OpenPGPDefines.privateKey)

        let expectation1 = expectation(description: "closure called")

        sut.buildMime(senderKey: testKey,
                      passphrase: testPassphrase,
                      userKeys: [],
                      keys: [],
                      newSchema: false,
                      in: context).done { _ in
            XCTAssertNotNil(self.sut.mimeDataPackage)
            XCTAssertNotNil(self.sut.mimeSessionAlgo)
            XCTAssertNotNil(self.sut.mimeSessionKey)

            let result = try self.sut.generatePackageBuilder()

            XCTAssertFalse(result.isEmpty)
            XCTAssertEqual(result.count, 1)
            let builder = try XCTUnwrap(result.first as? PGPMimeAddressBuilder)
            XCTAssertEqual(builder.sendPreferences, pgpMIMEPreference)
            XCTAssertEqual(builder.sendType, .pgpMIME)
            XCTAssertEqual(builder.session, self.sut.mimeSessionKey)
            XCTAssertEqual(builder.algo, self.sut.mimeSessionAlgo)

            expectation1.fulfill()
        }.catch { _ in
            XCTFail("Should not throw error")
        }
        waitForExpectations(timeout: 2, handler: nil)
    }

    func testGeneratePackageBuilder_clearMIMEaddress() throws {
        let clearMIMEPreference = SendPreferences(encrypt: false,
                                                  sign: false,
                                                  pgpScheme: .cleartextMIME,
                                                  mimeType: .mime,
                                                  publicKeys: nil,
                                                  isPublicKeyPinned: false,
                                                  hasApiKeys: false,
                                                  hasPinnedKeys: false,
                                                  error: nil)
        sut.add(email: testEmail, sendPreferences: clearMIMEPreference)
        setupTestBody()

        let testPassphrase = OpenPGPDefines.passphrase
        let testKey = Key(keyID: "1",
                          privateKey: OpenPGPDefines.privateKey)

        let expectation1 = expectation(description: "closure called")

        sut.buildMime(senderKey: testKey,
                      passphrase: testPassphrase,
                      userKeys: [],
                      keys: [],
                      newSchema: false,
                      in: context).done { _ in
            let result = try self.sut.generatePackageBuilder()

            XCTAssertFalse(result.isEmpty)
            XCTAssertEqual(result.count, 1)
            let builder = try XCTUnwrap(result.first as? ClearMimeAddressBuilder)
            XCTAssertEqual(builder.sendPreferences, clearMIMEPreference)
            XCTAssertEqual(builder.sendType, .cleartextMIME)

            expectation1.fulfill()
        }.catch { _ in
            XCTFail("Should not throw error")
        }
        waitForExpectations(timeout: 2, handler: nil)
    }

    func testGeneratePackageBuilder_inlinePGPAddress_withoutKey() throws {
        let inlinePGPPreference = SendPreferences(encrypt: false,
                                                  sign: true,
                                                  pgpScheme: .pgpInline,
                                                  mimeType: .html,
                                                  publicKeys: nil,
                                                  isPublicKeyPinned: false,
                                                  hasApiKeys: false,
                                                  hasPinnedKeys: false,
                                                  error: nil)
        sut.add(email: testEmail, sendPreferences: inlinePGPPreference)
        setupTestBody()

        let result = try sut.generatePackageBuilder()
        XCTAssertFalse(result.isEmpty)
        XCTAssertEqual(result.count, 1)
        let builder = try XCTUnwrap(result.first as? ClearAddressBuilder)
        XCTAssertEqual(builder.sendPreferences, inlinePGPPreference)
        XCTAssertEqual(builder.sendType, .cleartextInline)
    }

    func testGeneratePackageBuilder_PGPMIMEaddress_withoutKey() throws {
        let pgpMIMEPreference = SendPreferences(encrypt: false,
                                                sign: false,
                                                pgpScheme: .pgpMIME,
                                                mimeType: .mime,
                                                publicKeys: nil,
                                                isPublicKeyPinned: false,
                                                hasApiKeys: false,
                                                hasPinnedKeys: false,
                                                error: nil)
        sut.add(email: testEmail, sendPreferences: pgpMIMEPreference)
        setupTestBody()

        let testPassphrase = OpenPGPDefines.passphrase
        let testKey = Key(keyID: "1",
                          privateKey: OpenPGPDefines.privateKey)

        let expectation1 = expectation(description: "closure called")

        sut.buildMime(senderKey: testKey,
                      passphrase: testPassphrase,
                      userKeys: [],
                      keys: [],
                      newSchema: false,
                      in: context).done { _ in
            XCTAssertNotNil(self.sut.mimeDataPackage)
            XCTAssertNotNil(self.sut.mimeSessionAlgo)
            XCTAssertNotNil(self.sut.mimeSessionKey)

            let result = try self.sut.generatePackageBuilder()

            XCTAssertFalse(result.isEmpty)
            XCTAssertEqual(result.count, 1)
            let builder = try XCTUnwrap(result.first as? ClearMimeAddressBuilder)
            XCTAssertEqual(builder.sendPreferences, pgpMIMEPreference)
            XCTAssertEqual(builder.sendType, .cleartextMIME)

            expectation1.fulfill()
        }.catch { _ in
            XCTFail("Should not throw error")
        }
        waitForExpectations(timeout: 2, handler: nil)
    }

    func testGeneratePackageBuilder_clearMIMEaddress_notCallBuildFunction() throws {
        let clearMIMEPreference = SendPreferences(encrypt: true,
                                                  sign: true,
                                                  pgpScheme: .pgpMIME,
                                                  mimeType: .mime,
                                                  publicKeys: testPublicKey,
                                                  isPublicKeyPinned: false,
                                                  hasApiKeys: false,
                                                  hasPinnedKeys: false,
                                                  error: nil)
        sut.add(email: testEmail, sendPreferences: clearMIMEPreference)
        setupTestBody()

        XCTAssertThrowsError(try sut.generatePackageBuilder())
    }

    private func setupTestBody() {
        sut.update(bodyData: testBody,
                   bodySession: testSession,
                   algo: algo)
    }
}
