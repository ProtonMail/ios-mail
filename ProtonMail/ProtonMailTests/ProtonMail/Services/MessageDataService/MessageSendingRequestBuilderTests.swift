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
import ProtonCoreCrypto
import ProtonCoreCryptoGoInterface
import ProtonCoreDataModel
import ProtonCoreTestingToolkitUnitTestsServices
@testable import ProtonMail
import XCTest

class MessageSendingRequestBuilderTests: XCTestCase {

    var sut: MessageSendingRequestBuilder!
    private var context: NSManagedObjectContext!
    private var mockApi: APIServiceMock!

    let testSession = "session".data(using: .utf8)!
    let algo: Algorithm = .AES256
    var testPublicKey: CryptoKey!
    let testEmail = "test@proton.me"

    override func setUpWithError() throws {
        try super.setUpWithError()
        mockApi = .init()
        sut = MessageSendingRequestBuilder(dependencies: .init(apiService: mockApi))
        testPublicKey = try XCTUnwrap(CryptoGo.CryptoKey(fromArmored: OpenPGPDefines.publicKey))
    }

    override func setUp() {
        super.setUp()

        context = MockCoreDataStore.testPersistentContainer.newBackgroundContext()
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
        context = nil
    }

    func testUpdate_bodySessionAndBodyAlgorithm() {
        let testSession = "Key".data(using: .utf8)!
        let testAlgo = Algorithm.TripleDES
        sut.update(bodySession: testSession, algo: testAlgo)
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
                                             publicKey: nil,
                                             isPublicKeyPinned: Bool.random(),
                                             hasApiKeys: Bool.random(),
                                             error: nil)

        sut.add(email: testEmail, sendPreferences: testPreference)

        XCTAssertEqual(sut.addressSendPreferences.count, 1)
        XCTAssertEqual(sut.addressSendPreferences[testEmail], testPreference)
    }

    func testAddAttachment() {
        XCTAssertTrue(sut.preAttachments.isEmpty)
        let testAttachment = AttachmentEntity.make()
        let testPreAttachment = PreAttachment(id: "id",
                                              session: "key".data(using: .utf8)!,
                                              algo: .AES256,
                                              att: testAttachment)
        sut.add(attachment: testPreAttachment)
        XCTAssertEqual(sut.preAttachments.count, 1)
        XCTAssertEqual(sut.preAttachments[0].attachmentId, "id")
    }

    func testContains() throws {
        XCTAssertTrue(sut.addressSendPreferences.isEmpty)
        XCTAssertFalse(sut.contains(type: .pgpMIME))
        let testPreferences = SendPreferences(encrypt: true,
                                              sign: true,
                                              pgpScheme: .pgpMIME,
                                              mimeType: .mime,
                                              publicKey: testPublicKey,
                                              isPublicKeyPinned: true,
                                              hasApiKeys: false,
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
                                                 publicKey: testPublicKey,
                                                 isPublicKeyPinned: false,
                                                 hasApiKeys: false,
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
                                                   publicKey: nil,
                                                   isPublicKeyPinned: false,
                                                   hasApiKeys: false,
                                                   error: nil)
        sut.add(email: testEmail, sendPreferences: plainTextPreferences)

        XCTAssertTrue(sut.hasPlainText)
    }

    func testEncodedSession() {
        let testSessionKey = "Key".data(using: .utf8)!
        let testEncodedSession = testSessionKey.base64EncodedString(options: .init(rawValue: 0))

        sut.update(bodySession: testSessionKey, algo: .AES256)

        XCTAssertEqual(sut.bodySessionKey, testSessionKey)
        XCTAssertEqual(sut.encodedSessionKey, testEncodedSession)
    }

    func testGeneratePlainTextBody() {
        let testClearBody = "<html><head></head><body> <div><br></div><div><br></div> <div id=\"protonmail_mobile_signature_block\"><div>Sent from ProtonMail for iOS</div></div></body></html>"
        sut.set(clearBody: testClearBody)
        XCTAssertEqual(sut.generatePlainTextBody(), "\r\n\r\nSent from ProtonMail for iOS\r\n")
    }

    func testPreparePackages() throws {
        let key = Key(keyID: "1",
                      privateKey: OpenPGPDefines.privateKey)
        let encrypted = try "test".encrypt(withKey: key, userKeys: [], mailboxPassphrase: OpenPGPDefines.passphrase)

        let (keyPacket, dataPacket) = try sut.preparePackages(encrypted: encrypted)

        let splitMsg = CryptoGo.CryptoNewPGPSplitMessageFromArmored(encrypted, nil)
        XCTAssertEqual(keyPacket, splitMsg?.keyPacket)
        XCTAssertEqual(dataPacket, splitMsg?.dataPacket)
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
                                                 publicKey: testPublicKey,
                                                 isPublicKeyPinned: true,
                                                 hasApiKeys: false,
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
                                                 publicKey: nil,
                                                 isPublicKeyPinned: false,
                                                 hasApiKeys: false,
                                                 error: nil)
        sut.add(email: testEmail, sendPreferences: internalPreference)
        setupTestBody()

        XCTAssertThrowsError(try sut.generatePackageBuilder())
    }

    func testGeneratePackageBuilder_EOAddress() throws {
        let testEOPassword = Passphrase(value: "EO PWD")
        sut.set(password: testEOPassword, hint: nil)

        let eoPreference = SendPreferences(encrypt: false,
                                           sign: false,
                                           pgpScheme: .encryptedToOutside,
                                           mimeType: .mime,
                                           publicKey: nil,
                                           isPublicKeyPinned: false,
                                           hasApiKeys: false,
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
        let clearPreference = SendPreferences(encrypt: false,
                                              sign: false,
                                              pgpScheme: .cleartextInline,
                                              mimeType: .html,
                                              publicKey: nil,
                                              isPublicKeyPinned: false,
                                              hasApiKeys: false,
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
                                                  publicKey: testPublicKey,
                                                  isPublicKeyPinned: false,
                                                  hasApiKeys: false,
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

    func testGeneratePackageBuilder_inlinePGPAddress_withoutKey() throws {
        let inlinePGPPreference = SendPreferences(encrypt: false,
                                                  sign: true,
                                                  pgpScheme: .pgpInline,
                                                  mimeType: .html,
                                                  publicKey: nil,
                                                  isPublicKeyPinned: false,
                                                  hasApiKeys: false,
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

    func testGeneratePackageBuilder_inlinePGPAddress_withPublicKey_SignButNoEncrypt() throws {
        let sendPreference = SendPreferences(
            encrypt: false,
            sign: true,
            pgpScheme: .pgpInline,
            mimeType: .html,
            publicKey: CryptoGo.CryptoKey(fromArmored: OpenPGPDefines.publicKey),
            isPublicKeyPinned: false,
            hasApiKeys: false,
            error: nil
        )
        sut.add(email: testEmail, sendPreferences: sendPreference)
        setupTestBody()

        let result = try sut.generatePackageBuilder()
        XCTAssertFalse(result.isEmpty)
        XCTAssertEqual(result.count, 1)
        let builder = try XCTUnwrap(result.first as? ClearAddressBuilder)
        XCTAssertEqual(builder.sendPreferences, sendPreference)
        XCTAssertEqual(builder.sendType, .cleartextInline)
    }

    func testGeneratePackageBuilder_inlinePGPAddress_withPublicKey_SignAndEncrypt() throws {
        let sendPreference = SendPreferences(
            encrypt: true,
            sign: true,
            pgpScheme: .pgpInline,
            mimeType: .html,
            publicKey: testPublicKey,
            isPublicKeyPinned: false,
            hasApiKeys: false,
            error: nil
        )
        sut.add(email: testEmail, sendPreferences: sendPreference)
        setupTestBody()

        let result = try sut.generatePackageBuilder()
        XCTAssertFalse(result.isEmpty)
        XCTAssertEqual(result.count, 1)
        let builder = try XCTUnwrap(result.first as? PGPAddressBuilder)
        XCTAssertEqual(builder.sendPreferences, sendPreference)
        XCTAssertEqual(builder.sendType, .pgpInline)
    }

    func testGeneratePackageBuilder_clearMIMEAddress_notCallBuildFunction_willThrowError() throws {
        let clearMIMEPreference = SendPreferences(
            encrypt: true,
            sign: true,
            pgpScheme: .pgpMIME,
            mimeType: .mime,
            publicKey: testPublicKey,
            isPublicKeyPinned: false,
            hasApiKeys: false,
            error: nil
        )
        sut.add(email: testEmail, sendPreferences: clearMIMEPreference)
        setupTestBody()

        XCTAssertThrowsError(try sut.generatePackageBuilder())
    }

    private func setupTestBody() {
        sut.update(bodySession: testSession, algo: algo)
    }
}
