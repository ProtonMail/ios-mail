// Copyright (c) 2022 Proton Technologies AG
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
@testable import ProtonMail
import XCTest

final class ResolveSendPreferencesTests: XCTestCase {
    var sut: ResolveSendPreferences!
    private var mockFetchContacts: MockFetchAndVerifyContacts!
    private var mockFetchPublicKeys: MockFetchEmailAddressesPublicKey!

    private let email = "someone@example.com"
    private let fullKey1 = makeKey(flags: [.verificationEnabled, .encryptionEnabled])
    private let fullKey2 = makeKey(flags: [.verificationEnabled, .encryptionEnabled])
    private let onlyVerificationKey = makeKey(flags: [.verificationEnabled])
    private var keyInAddress: Key { fullKey1 }

    private var emptyKeysResponseForProtonAccount: KeysResponse {
        let response = KeysResponse()
        response.recipientType = .internal
        return response
    }
    private var emptyKeysResponseForExternalAccount: KeysResponse {
        let response = KeysResponse()
        response.recipientType = .external
        return response
    }
    private var signSettingHasNoEffect: Bool {
        Bool.random()
    }

    override func setUp() {
        mockFetchContacts = MockFetchAndVerifyContacts()
        mockFetchPublicKeys = MockFetchEmailAddressesPublicKey()
        let dependencies = ResolveSendPreferences.Dependencies(
            fetchVerifiedContacts: mockFetchContacts,
            fetchAddressesPublicKeys: mockFetchPublicKeys
        )
        sut = ResolveSendPreferences(dependencies: dependencies)
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
        mockFetchContacts = nil
        mockFetchPublicKeys = nil
    }


    // MARK: Testing when the recipient is a Proton email address

    func testExecute_whenProtonAccount_andContactAndAPIKeysMatch_thenUniqueKeyIsUsed() {
        mockFetchContacts.result = .success([makeContact(recipientEmail: email, key: fullKey1)])
        mockFetchPublicKeys.result = .success(makeKeysResponse(for: email, key: fullKey1, type: .internal))
        let params = makeParams(recipientEmail: email, isSignEnabled: signSettingHasNoEffect)

        let expectation = expectation(description: "")
        sut.execute(params: params) { [unowned self] result in
            let recipientPreferences = (try! result.get()).first!
            let sendPreferences = recipientPreferences.sendPreferences
            assertCommonExpectationsForProtonAccount(recipientPreferences)

            XCTAssertNotNil(sendPreferences.publicKeys)
            XCTAssertTrue(sendPreferences.hasPinnedKeys)
            XCTAssertTrue(sendPreferences.isPublicKeyPinned)
            XCTAssertTrue(sendPreferences.hasApiKeys)

            XCTAssertNil(sendPreferences.error)
            XCTAssert(recipientPreferences.sendPreferences.publicKeys?.getFingerprint() == fullKey1.fingerprint)

            expectation.fulfill()
        }
        waitForExpectations(timeout: 2.0)
    }

    func testExecute_whenProtonAccount_andContactAndAPIKeysDoNotMatch_thenAPIKeyIsUsed() {
        mockFetchContacts.result = .success([makeContact(recipientEmail: email, key: fullKey1)])
        mockFetchPublicKeys.result = .success(makeKeysResponse(for: email, key: fullKey2, type: .internal))
        let params = makeParams(recipientEmail: email, isSignEnabled: signSettingHasNoEffect)

        let expectation = expectation(description: "")
        sut.execute(params: params) { [unowned self] result in
            let recipientPreferences = (try! result.get()).first!
            let sendPreferences = recipientPreferences.sendPreferences
            assertCommonExpectationsForProtonAccount(recipientPreferences)

            XCTAssertNotNil(sendPreferences.publicKeys)
            XCTAssertTrue(sendPreferences.hasPinnedKeys)
            XCTAssertFalse(sendPreferences.isPublicKeyPinned)
            XCTAssertTrue(sendPreferences.hasApiKeys)

            XCTAssert(sendPreferences.error == .primaryNotPinned)
            XCTAssert(recipientPreferences.sendPreferences.publicKeys?.getFingerprint() == fullKey2.fingerprint)

            expectation.fulfill()
        }
        waitForExpectations(timeout: 2.0)
    }

    func testExecute_whenProtonAccount_andThereIsNoContact_thenAPIKeyIsUsed() {
        mockFetchPublicKeys.result = .success(makeKeysResponse(for: email, key: fullKey2, type: .internal))
        let params = makeParams(recipientEmail: email, isSignEnabled: signSettingHasNoEffect)

        let expectation = expectation(description: "")
        sut.execute(params: params) { [unowned self] result in
            let recipientPreferences = (try! result.get()).first!
            let sendPreferences = recipientPreferences.sendPreferences
            assertCommonExpectationsForProtonAccount(recipientPreferences)

            XCTAssertNotNil(sendPreferences.publicKeys)
            XCTAssertFalse(sendPreferences.hasPinnedKeys)
            XCTAssertFalse(sendPreferences.isPublicKeyPinned)
            XCTAssertTrue(sendPreferences.hasApiKeys)

            XCTAssertNil(sendPreferences.error)
            XCTAssert(recipientPreferences.sendPreferences.publicKeys?.getFingerprint() == fullKey2.fingerprint)

            expectation.fulfill()
        }
        waitForExpectations(timeout: 2.0)
    }

    func testExecute_whenProtonAccount_andKeyIsNotForEncryption_thenNoKeyExistsForSending() {
        mockFetchPublicKeys.result = .success(makeKeysResponse(for: email, key: onlyVerificationKey, type: .internal))
        let params = makeParams(recipientEmail: email, isSignEnabled: signSettingHasNoEffect)

        let expectation = expectation(description: "")
        sut.execute(params: params) { [unowned self] result in
            let recipientPreferences = (try! result.get()).first!
            let sendPreferences = recipientPreferences.sendPreferences
            assertCommonExpectationsForProtonAccount(recipientPreferences)

            XCTAssertNil(sendPreferences.publicKeys)
            XCTAssertFalse(sendPreferences.hasPinnedKeys)
            XCTAssertFalse(sendPreferences.isPublicKeyPinned)
            XCTAssertTrue(sendPreferences.hasApiKeys)

            XCTAssert(sendPreferences.error == .internalUserNoValidApiKey)
            XCTAssertNil(recipientPreferences.sendPreferences.publicKeys)

            expectation.fulfill()
        }
        waitForExpectations(timeout: 2.0)
    }

    func testExecute_whenProtonAccount_andThereIsNoAPIKey_thenNoKeyExistsForSending() {
        mockFetchPublicKeys.result = .success([email: emptyKeysResponseForProtonAccount])
        let params = makeParams(recipientEmail: email, isSignEnabled: signSettingHasNoEffect)

        let expectation = expectation(description: "")
        sut.execute(params: params) { [unowned self] result in
            let recipientPreferences = (try! result.get()).first!
            let sendPreferences = recipientPreferences.sendPreferences
            assertCommonExpectationsForProtonAccount(recipientPreferences)

            XCTAssertNil(sendPreferences.publicKeys)
            XCTAssertFalse(sendPreferences.hasPinnedKeys)
            XCTAssertFalse(sendPreferences.isPublicKeyPinned)
            XCTAssertFalse(sendPreferences.hasApiKeys)

            XCTAssert(sendPreferences.error == .internalUserNoApiKey)
            XCTAssertNil(recipientPreferences.sendPreferences.publicKeys)

            expectation.fulfill()
        }
        waitForExpectations(timeout: 2.0)
    }

    private func assertCommonExpectationsForProtonAccount(
        _ recipientPreferences: RecipientSendPreferences,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssertTrue(recipientPreferences.emailAddress == email, file: file, line: line)
        let sendPreferences = recipientPreferences.sendPreferences
        XCTAssertTrue(sendPreferences.encrypt, file: file, line: line)
        XCTAssertTrue(sendPreferences.pgpScheme == .proton, file: file, line: line)
        XCTAssertTrue(sendPreferences.mimeType == .mime, file: file, line: line)
        XCTAssertTrue(sendPreferences.sign, file: file, line: line)
    }


    // MARK: Testing when the recipient is an external email address

    func testExecute_whenExternalAccount_andHasNoKeys() {
        mockFetchContacts.result = .success([makeContact(recipientEmail: email)])
        mockFetchPublicKeys.result = .success([email: emptyKeysResponseForExternalAccount])
        let params = makeParams(recipientEmail: email, isSignEnabled: signSettingHasNoEffect)

        let expectation = expectation(description: "")
        sut.execute(params: params) { [unowned self] result in
            let recipientPreferences = (try! result.get()).first!
            XCTAssertTrue(recipientPreferences.emailAddress == email)

            let sendPreferences = recipientPreferences.sendPreferences
            XCTAssertFalse(sendPreferences.encrypt)
            XCTAssertTrue(sendPreferences.pgpScheme == .cleartextInline)
            XCTAssertTrue(sendPreferences.mimeType == .mime)
            XCTAssertFalse(sendPreferences.sign)

            XCTAssertNil(sendPreferences.publicKeys)
            XCTAssertFalse(sendPreferences.hasPinnedKeys)
            XCTAssertFalse(sendPreferences.isPublicKeyPinned)
            XCTAssertFalse(sendPreferences.hasApiKeys)

            XCTAssertNil(sendPreferences.error)

            expectation.fulfill()
        }
        waitForExpectations(timeout: 2.0)
    }

    func testExecute_whenExternalAccount_andHasNoKeys_andEmailIsPasswordProtected() {
        mockFetchContacts.result = .success([makeContact(recipientEmail: email)])
        mockFetchPublicKeys.result = .success([email: emptyKeysResponseForExternalAccount])
        let params = makeParams(recipientEmail: email, isPasswordProtected: true, isSignEnabled: signSettingHasNoEffect)

        let expectation = expectation(description: "")
        sut.execute(params: params) { [unowned self] result in
            let recipientPreferences = (try! result.get()).first!
            XCTAssertTrue(recipientPreferences.emailAddress == email)

            let sendPreferences = recipientPreferences.sendPreferences
            XCTAssertTrue(sendPreferences.encrypt)
            XCTAssertTrue(sendPreferences.pgpScheme == .encryptedToOutside)
            XCTAssertTrue(sendPreferences.mimeType == .mime)
            XCTAssertFalse(sendPreferences.sign)

            XCTAssertNil(sendPreferences.publicKeys)
            XCTAssertFalse(sendPreferences.hasPinnedKeys)
            XCTAssertFalse(sendPreferences.isPublicKeyPinned)
            XCTAssertFalse(sendPreferences.hasApiKeys)

            XCTAssertNil(sendPreferences.error)

            expectation.fulfill()
        }
        waitForExpectations(timeout: 2.0)
    }

    func testExecute_whenExternalAccount_andContactAndAPIKeysMatch_thenUniqueKeyIsUsed() {
        mockFetchContacts.result = .success([makeContact(recipientEmail: email, key: fullKey1)])
        mockFetchPublicKeys.result = .success(makeKeysResponse(for: email, key: fullKey1, type: .external))
        let params = makeParams(recipientEmail: email, isSignEnabled: signSettingHasNoEffect)

        let expectation = expectation(description: "")
        sut.execute(params: params) { [unowned self] result in
            let recipientPreferences = (try! result.get()).first!
            let sendPreferences = recipientPreferences.sendPreferences
            assertCommonExpectationsForExternalWhenEncrypted(recipientPreferences)

            XCTAssertNotNil(sendPreferences.publicKeys)
            XCTAssertTrue(sendPreferences.hasPinnedKeys)
            XCTAssertTrue(sendPreferences.isPublicKeyPinned)
            XCTAssertTrue(sendPreferences.hasApiKeys)

            XCTAssertNil(sendPreferences.error)
            XCTAssert(sendPreferences.publicKeys?.getFingerprint() == fullKey1.fingerprint)

            expectation.fulfill()
        }
        waitForExpectations(timeout: 2.0)
    }

    func testExecute_whenExternalAccount_andContactAndAPIKeysDoNotMatch_thenAPIKeyIsUsed() {
        mockFetchContacts.result = .success([makeContact(recipientEmail: email, key: fullKey1)])
        mockFetchPublicKeys.result = .success(makeKeysResponse(for: email, key: fullKey2, type: .external))
        let params = makeParams(recipientEmail: email, isSignEnabled: signSettingHasNoEffect)

        let expectation = expectation(description: "")
        sut.execute(params: params) { [unowned self] result in
            let recipientPreferences = (try! result.get()).first!
            let sendPreferences = recipientPreferences.sendPreferences
            assertCommonExpectationsForExternalWhenEncrypted(recipientPreferences)

            XCTAssertNotNil(sendPreferences.publicKeys)
            XCTAssertTrue(sendPreferences.hasPinnedKeys)
            XCTAssertFalse(sendPreferences.isPublicKeyPinned)
            XCTAssertTrue(sendPreferences.hasApiKeys)

            XCTAssert(sendPreferences.error == .primaryNotPinned)
            XCTAssert(sendPreferences.publicKeys?.getFingerprint() == fullKey2.fingerprint)

            expectation.fulfill()
        }
        waitForExpectations(timeout: 2.0)
    }

    func testExecute_whenExternalAccount_andHasOnlyAPIKey() {
        mockFetchPublicKeys.result = .success(makeKeysResponse(for: email, key: fullKey1, type: .external))
        let params = makeParams(recipientEmail: email, isSignEnabled: signSettingHasNoEffect)

        let expectation = expectation(description: "")
        sut.execute(params: params) { [unowned self] result in
            let recipientPreferences = (try! result.get()).first!
            let sendPreferences = recipientPreferences.sendPreferences
            assertCommonExpectationsForExternalWhenEncrypted(recipientPreferences)

            XCTAssertNotNil(sendPreferences.publicKeys)
            XCTAssertFalse(sendPreferences.hasPinnedKeys)
            XCTAssertFalse(sendPreferences.isPublicKeyPinned)
            XCTAssertTrue(sendPreferences.hasApiKeys)

            XCTAssertNil(sendPreferences.error)
            XCTAssert(sendPreferences.publicKeys?.getFingerprint() == fullKey1.fingerprint)

            expectation.fulfill()
        }
        waitForExpectations(timeout: 2.0)
    }

    func testExecute_whenExternalAccount_hasContactAndAPIKeys_andContactKeyIsNotForEncryption_thenNoKeyForSending() {
        mockFetchContacts.result = .success([makeContact(recipientEmail: email, key: onlyVerificationKey)])
        mockFetchPublicKeys.result = .success(makeKeysResponse(for: email, key: fullKey1, type: .external))
        let params = makeParams(recipientEmail: email, isSignEnabled: signSettingHasNoEffect)

        let expectation = expectation(description: "")
        sut.execute(params: params) { [unowned self] result in
            let recipientPreferences = (try! result.get()).first!
            let sendPreferences = recipientPreferences.sendPreferences

            assertCommonExpectationsForExternalWhenEncrypted(recipientPreferences)

            XCTAssertNotNil(sendPreferences.publicKeys)
            XCTAssertTrue(sendPreferences.hasPinnedKeys)
            XCTAssertFalse(sendPreferences.isPublicKeyPinned)
            XCTAssertTrue(sendPreferences.hasApiKeys)

            XCTAssert(sendPreferences.error == .primaryNotPinned)
            XCTAssert(sendPreferences.publicKeys?.getFingerprint() == fullKey1.fingerprint)

            expectation.fulfill()
        }
        waitForExpectations(timeout: 2.0)
    }

    private func assertCommonExpectationsForExternalWhenEncrypted(
        _ recipientPreferences: RecipientSendPreferences,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssertTrue(recipientPreferences.emailAddress == email, file: file, line: line)
        let sendPreferences = recipientPreferences.sendPreferences
        XCTAssertTrue(sendPreferences.encrypt, file: file, line: line)
        XCTAssertTrue(sendPreferences.pgpScheme == .pgpMIME, file: file, line: line)
        XCTAssertTrue(sendPreferences.mimeType == .mime, file: file, line: line)
        XCTAssertTrue(sendPreferences.sign, file: file, line: line)
    }


    // MARK: Testing when the recipient is one the sender's own addresses in the authenticated account

    func testExecute_whenSelfAccount() {
        mockFetchContacts.result = .success([makeContact(recipientEmail: email)])
        mockFetchPublicKeys.result = .success([email: emptyKeysResponseForExternalAccount])
        let params = makeParams(recipientEmail: email, isSignEnabled: signSettingHasNoEffect, isEmailToSelf: true)

        let expectation = expectation(description: "")
        sut.execute(params: params) { [unowned self] result in
            let recipientPreferences = (try! result.get()).first!
            let sendPreferences = recipientPreferences.sendPreferences
            assertCommonExpectationsForProtonAccount(recipientPreferences)

            XCTAssertNotNil(sendPreferences.publicKeys)
            XCTAssertFalse(sendPreferences.hasPinnedKeys)
            XCTAssertFalse(sendPreferences.isPublicKeyPinned)
            XCTAssertFalse(sendPreferences.hasApiKeys)

            XCTAssertNil(sendPreferences.error)
            XCTAssert(sendPreferences.publicKeys?.getFingerprint() == keyInAddress.fingerprint)

            expectation.fulfill()
        }
        waitForExpectations(timeout: 2.0)
    }

    // MARK: Testing when requests fail

    func testExecute_whenFetchContactFails_thenDoesNotReturnError() {
        mockFetchContacts.result = .failure(NSError.badResponse())
        mockFetchPublicKeys.result = .success([email: emptyKeysResponseForExternalAccount])
        let params = makeParams(recipientEmail: email)

        let expectation = expectation(description: "")
        sut.execute(params: params) { result in
            switch result {
            case .success:
                XCTAssert(true)
            case .failure:
                XCTAssert(false)
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2.0)
    }

    func testExecute_whenFetchPublicKeysFails_thenReturnsError() {
        mockFetchContacts.result = .success([makeContact(recipientEmail: email)])
        mockFetchPublicKeys.result = .failure(NSError.badResponse())
        let params = makeParams(recipientEmail: email)

        let expectation = expectation(description: "")
        sut.execute(params: params) { result in
            switch result {
            case .success:
                XCTAssert(false)
            case .failure:
                XCTAssert(true)
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2.0)
    }

}

private extension ResolveSendPreferencesTests {

    func makeParams(
        recipientEmail: String,
        isPasswordProtected: Bool = false,
        isSignEnabled: Bool = false,
        isEmailToSelf: Bool = false
    ) -> ResolveSendPreferences.Params {
        return ResolveSendPreferences.Params(
            recipientsEmailAddresses: [recipientEmail],
            isEmailBeingSentPasswordProtected: isPasswordProtected,
            isSenderSignMessagesEnabled: isSignEnabled,
            currentUserEmailAddresses: isEmailToSelf ? [makeAddress(email: email)] : [makeAddress()]
        )
    }

    func makeContact(
        recipientEmail: String,
        key: Key? = nil,
        sign: Bool = false,
        encrypt: Bool = false
    ) -> PreContact {
        var pubKeys = [Data]()
        if let publicKey = key?.publicKey.unArmor {
            pubKeys = [publicKey]
        }
        return PreContact(
            email: recipientEmail,
            pubKeys: pubKeys,
            sign: sign,
            encrypt: encrypt,
            scheme: nil,
            mimeType: nil
        )
    }

    func makeAddress(email: String = "") -> Address {
        return Address(
            addressID: UUID().uuidString,
            domainID: nil,
            email: email,
            send: .active,
            receive: .active,
            status: .enabled,
            type: .externalAddress,
            order: 1,
            displayName: "John",
            signature: "Yours truly",
            hasKeys: 1,
            keys: [keyInAddress]
        )
    }

    func makeKeysResponse(for email: String, key: Key, type: KeysResponse.RecipientType) -> [String: KeysResponse] {
        let keysResponse = KeysResponse()
        keysResponse.keys = [KeyResponse(flags: key.flags, publicKey: key.publicKey)]
        keysResponse.recipientType = type
        return [email: keysResponse]
    }

    static func makeKey(flags: [Key.Flags]) -> Key {
        let keyPair = try! MailCrypto.generateRandomKeyPair()
        let key = Key(keyID: UUID().uuidString, privateKey: keyPair.privateKey)
        key.keyFlags = flags.map(\.rawValue).reduce(0, +)
        key.signature = "signature is needed to make this a V2 key"
        return key
    }
}
