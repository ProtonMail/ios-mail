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

import ProtonCoreDataModel
import ProtonCoreNetworking
import ProtonCoreUIFoundations
@testable import ProtonMail
import XCTest

class ContactPGPTypeHelperTests: XCTestCase {
    var sut: ContactPGPTypeHelper!
    var internetConnectionStatusProviderStub: MockInternetConnectionStatusProviderProtocol!
    var localContactsStub: [PreContact] = []

    private var fetchEmailAddressesPublicKey: MockFetchEmailAddressesPublicKeyUseCase!

    override func setUpWithError() throws {
        try super.setUpWithError()
        internetConnectionStatusProviderStub = .init()
        internetConnectionStatusProviderStub.statusStub.fixture = .connectedViaCellular
        fetchEmailAddressesPublicKey = .init()

        sut = ContactPGPTypeHelper(
            internetConnectionStatusProvider: internetConnectionStatusProviderStub,
            fetchEmailAddressesPublicKey: fetchEmailAddressesPublicKey,
            userSign: 0,
            localContacts: [],
            userAddresses: []
        )
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
        internetConnectionStatusProviderStub = nil
        localContactsStub = []
        fetchEmailAddressesPublicKey = nil
    }

    func testCalculateEncryptionIcon_withNoInternet_nonPMValidEmail_returnNil() {
        let mail = "test@mail.com"
        internetConnectionStatusProviderStub.statusStub.fixture = .notConnected

        let expectation1 = expectation(description: "closure is called")
        sut.calculateEncryptionIcon(email: mail,
                                    isMessageHavingPWD: Bool.random()) { encryptionIcon, code in
            XCTAssertNil(encryptionIcon)
            XCTAssertNil(code)
            expectation1.fulfill()
        }
        waitForExpectations(timeout: 1)

        XCTAssertTrue(fetchEmailAddressesPublicKey.executeStub.wasNotCalled)
    }

    func testCalculateEncryptionIcon_withNoInternet_PMValidEmail_returnLockIcon() {
        let mails = ["test@pm.me", "test@protonmail.com", "test@protonmail.ch", "test@proton.me"]
        internetConnectionStatusProviderStub.statusStub.fixture = .notConnected

        mails.forEach {
            let expectation1 = expectation(description: "closure is called")
            sut.calculateEncryptionIcon(email: $0,
                                        isMessageHavingPWD: Bool.random()) { encryptionIcon, code in
                XCTAssertEqual(
                    encryptionIcon,
                    EncryptionIconStatus(iconColor: .blue,
                                         icon: IconProvider.lockFilled,
                                         text: "End-to-end encrypted")
                )
                XCTAssertNil(code)
                expectation1.fulfill()
            }
        }
        waitForExpectations(timeout: 1)

        XCTAssertTrue(fetchEmailAddressesPublicKey.executeStub.wasNotCalled)
    }

    func testCalculateEncryptionIcon_withNoInternet_invalidEmail_returnErrorIcon() {
        let mail = "test@mailcom"
        internetConnectionStatusProviderStub.statusStub.fixture = .notConnected

        let expectation1 = expectation(description: "closure is called")
        sut.calculateEncryptionIcon(email: mail,
                                    isMessageHavingPWD: Bool.random()) { encryptionIcon, code in
            XCTAssertEqual(
                encryptionIcon,
                .init(iconColor: .black,
                      icon: IconProvider.exclamationCircle,
                      text: LocalString._signle_address_invalid_error_content,
                      isInvalid: true,
                      nonExisting: true)
            )
            XCTAssertEqual(code, PGPTypeErrorCode.recipientNotFound.rawValue)
            expectation1.fulfill()
        }
        waitForExpectations(timeout: 1)

        XCTAssertTrue(fetchEmailAddressesPublicKey.executeStub.wasNotCalled)
    }

    func testCalculateEncryption_invalidEmail_returnErrorIcon() {
        fetchEmailAddressesPublicKey.executeStub.bodyIs { _, _ in
            throw ResponseError(responseCode: .emailAddressFailedValidation)
        }

        let expectation1 = expectation(description: "closure is called")
        sut.calculateEncryptionIcon(email: "test@@pm.me",
                                    isMessageHavingPWD: Bool.random()) { encryptionIcon, code in
            XCTAssertEqual(
                encryptionIcon,
                .init(iconColor: .black,
                      icon: IconProvider.exclamationCircle,
                      text: LocalString._signle_address_invalid_error_content,
                      isInvalid: true)
            )
            XCTAssertEqual(code, PGPTypeErrorCode.emailAddressFailedValidation.rawValue)
            expectation1.fulfill()
        }
        waitForExpectations(timeout: 1)

        XCTAssertTrue(fetchEmailAddressesPublicKey.executeStub.wasCalledExactlyOnce)
    }

    func testCalculateEncryption_EmailNotExist_returnErrorIcon() {
        fetchEmailAddressesPublicKey.executeStub.bodyIs { _, _ in
            throw ResponseError(responseCode: .recipientNotFound)
        }

        let expectation1 = expectation(description: "closure is called")
        sut.calculateEncryptionIcon(email: "test@pm.me",
                                    isMessageHavingPWD: Bool.random()) { encryptionIcon, code in
            XCTAssertEqual(
                encryptionIcon,
                .init(iconColor: .black,
                      icon: IconProvider.exclamationCircle,
                      text: LocalString._recipient_not_found,
                      isInvalid: true,
                      nonExisting: true)
            )
            XCTAssertEqual(code, PGPTypeErrorCode.recipientNotFound.rawValue)
            expectation1.fulfill()
        }
        waitForExpectations(timeout: 1)

        XCTAssertTrue(fetchEmailAddressesPublicKey.executeStub.wasCalledExactlyOnce)
    }

    func testCalculateEncryption_validEmail_withErrorFromAPI_returnErrorIcon() {
        fetchEmailAddressesPublicKey.executeStub.bodyIs { _, _ in
            throw ResponseError(responseCode: 999)
        }

        let expectation1 = expectation(description: "closure is called")
        sut.calculateEncryptionIcon(email: "test@pm.me",
                                    isMessageHavingPWD: Bool.random()) { encryptionIcon, code in
            XCTAssertEqual(
                encryptionIcon,
                .init(iconColor: .black,
                      icon: IconProvider.exclamationCircle,
                      text: "")
            )
            XCTAssertEqual(code, 999)
            expectation1.fulfill()
        }
        waitForExpectations(timeout: 1)

        XCTAssertTrue(fetchEmailAddressesPublicKey.executeStub.wasCalledExactlyOnce)
    }

    func testCalculateEncryption_invalidEmail_withErrorFromAPI_returnErrorIcon() {
        fetchEmailAddressesPublicKey.executeStub.bodyIs { _, _ in
            throw ResponseError(responseCode: 999)
        }
        let expectation1 = expectation(description: "closure is called")

        sut.calculateEncryptionIcon(email: "test@@pm.me",
                                    isMessageHavingPWD: Bool.random()) { encryptionIcon, code in
            XCTAssertEqual(
                encryptionIcon,
                .init(iconColor: .black,
                      icon: IconProvider.exclamationCircle,
                      text: "",
                      isInvalid: true,
                      nonExisting: true)
            )
            XCTAssertEqual(code, PGPTypeErrorCode.recipientNotFound.rawValue)
            expectation1.fulfill()
        }
        waitForExpectations(timeout: 1)

        XCTAssertTrue(fetchEmailAddressesPublicKey.executeStub.wasCalledExactlyOnce)
    }

    func testCalculateEncryptionIcon_PMMail_noKeyPinned_returnBlueIcon() {
        fetchEmailAddressesPublicKey.executeStub.bodyIs { _, _ in
            KeysResponse(keys: [self.makeKeyResponse()], recipientType: .internal)
        }
        let expectation1 = expectation(description: "closure is called")

        sut.calculateEncryptionIcon(email: "test@pm.me",
                                    isMessageHavingPWD: Bool.random()) { encryptionIcon, code in
            XCTAssertEqual(
                encryptionIcon,
                .init(iconColor: .blue,
                      icon: IconProvider.lockFilled,
                      text: LocalString._end_to_end_encrypted_of_recipient,
                      isPGPPinned: false,
                      isNonePM: false)
            )
            XCTAssertNil(code)
            expectation1.fulfill()
        }
        waitForExpectations(timeout: 1)

        XCTAssertTrue(fetchEmailAddressesPublicKey.executeStub.wasCalledExactlyOnce)
    }

    func testCalculateEncryptionIcon_PMMail_keyIsPinned_returnBlueIcon() {
        let email = "test@pm.me"
        fetchEmailAddressesPublicKey.executeStub.bodyIs { _, _ in
            KeysResponse(keys: [self.makeKeyResponse()], recipientType: .internal)
        }
        let localContact = PreContact(
            email: email,
            pubKeys: [OpenPGPDefines.publicKey.unArmor!],
            sign: .sign,
            encrypt: true,
            scheme: nil,
            mimeType: nil
        )
        sut = ContactPGPTypeHelper(
            internetConnectionStatusProvider: internetConnectionStatusProviderStub,
            fetchEmailAddressesPublicKey: fetchEmailAddressesPublicKey,
            userSign: 0,
            localContacts: [localContact],
            userAddresses: []
        )
        let expectation1 = expectation(description: "closure is called")

        sut.calculateEncryptionIcon(email: "test@pm.me",
                                    isMessageHavingPWD: Bool.random()) { encryptionIcon, code in
            XCTAssertEqual(
                encryptionIcon,
                .init(iconColor: .blue,
                      icon: IconProvider.lockCheckFilled,
                      text: LocalString._end_to_end_encrypted_to_verified_recipient,
                      isPGPPinned: false,
                      isNonePM: false)
            )
            XCTAssertNil(code)
            expectation1.fulfill()
        }
        waitForExpectations(timeout: 1)

        XCTAssertTrue(fetchEmailAddressesPublicKey.executeStub.wasCalledExactlyOnce)
    }

    func testCalculateEncryptionIcon_externalEmail_withPasswordSet_returnBlueIcon() {
        fetchEmailAddressesPublicKey.executeStub.bodyIs { _, _ in
            KeysResponse(keys: [], recipientType: .external)
        }
        let expectation1 = expectation(description: "closure is called")

        sut.calculateEncryptionIcon(email: "test@mail.me",
                                    isMessageHavingPWD: true) { encryptionIcon, code in
            XCTAssertEqual(
                encryptionIcon,
                .init(iconColor: .blue,
                      icon: IconProvider.lockFilled,
                      text: LocalString._end_to_end_encrypted_of_recipient,
                      isPGPPinned: false,
                      isNonePM: true)
            )
            XCTAssertNil(code)
            expectation1.fulfill()
        }
        waitForExpectations(timeout: 1)

        XCTAssertTrue(fetchEmailAddressesPublicKey.executeStub.wasCalledExactlyOnce)
    }

    func testCalculateEncryptionIcon_externalEmail_returnNoIcon() {
        fetchEmailAddressesPublicKey.executeStub.bodyIs { _, _ in
            KeysResponse(keys: [], recipientType: .external)
        }
        let expectation1 = expectation(description: "closure is called")

        sut.calculateEncryptionIcon(email: "test@mail.me",
                                    isMessageHavingPWD: false) { encryptionIcon, code in
            XCTAssertNil(encryptionIcon)
            XCTAssertNil(code)
            expectation1.fulfill()
        }
        waitForExpectations(timeout: 1)

        XCTAssertTrue(fetchEmailAddressesPublicKey.executeStub.wasCalledExactlyOnce)
    }

    func testCalculateEncryptionIcon_externalEmail_withAPIKey_returnGreenIcon() {
        fetchEmailAddressesPublicKey.executeStub.bodyIs { _, _ in
            KeysResponse(keys: [self.makeKeyResponse()], recipientType: .external)
        }
        let expectation1 = expectation(description: "closure is called")

        sut.calculateEncryptionIcon(email: "test@mail.me",
                                    isMessageHavingPWD: false) { encryptionIcon, code in

            XCTAssertEqual(
                encryptionIcon,
                .init(iconColor: .green,
                      icon: IconProvider.lockFilled,
                      text: LocalString._end_to_end_encrypted_of_recipient,
                      isPGPPinned: true,
                      isNonePM: false)
            )
            XCTAssertNil(code)
            expectation1.fulfill()
        }
        waitForExpectations(timeout: 1)

        XCTAssertTrue(fetchEmailAddressesPublicKey.executeStub.wasCalledExactlyOnce)
    }

    func testCalculateEncryptionIcon_externalEmail_withVerificationOnlyAPIKey_returnErrorIcon() {
        fetchEmailAddressesPublicKey.executeStub.bodyIs { _, _ in
            KeysResponse(keys: [self.makeKeyResponse(flags: .notCompromised)], recipientType: .external)
        }
        let expectation1 = expectation(description: "closure is called")

        sut.calculateEncryptionIcon(email: "test@mail.me",
                                    isMessageHavingPWD: false) { encryptionIcon, code in

            XCTAssertEqual(
                encryptionIcon,
                .init(iconColor: .error,
                      icon: IconProvider.lockExclamationFilled,
                      text: LocalString._encPref_error_internal_user_no_valid_wkd_key)
            )
            XCTAssertNil(code)
            expectation1.fulfill()
        }
        waitForExpectations(timeout: 1)

        XCTAssertTrue(fetchEmailAddressesPublicKey.executeStub.wasCalledExactlyOnce)
    }

    func testCalculateEncryptionIcon_externalEmail_withAPIKeyAndPinnedKey_returnGreenIcon() {
        let email = "test@mail.me"
        fetchEmailAddressesPublicKey.executeStub.bodyIs { _, _ in
            KeysResponse(keys: [self.makeKeyResponse()], recipientType: .external)
        }
        let localContact = PreContact(
            email: email,
            pubKeys: [OpenPGPDefines.publicKey.unArmor!],
            sign: .sign,
            encrypt: true,
            scheme: nil,
            mimeType: nil
        )
        sut = ContactPGPTypeHelper(
            internetConnectionStatusProvider: internetConnectionStatusProviderStub,
            fetchEmailAddressesPublicKey: fetchEmailAddressesPublicKey,
            userSign: 0,
            localContacts: [localContact],
            userAddresses: []
        )
        let expectation1 = expectation(description: "closure is called")

        sut.calculateEncryptionIcon(email: email,
                                    isMessageHavingPWD: false) { encryptionIcon, code in

            XCTAssertEqual(
                encryptionIcon,
                .init(iconColor: .green,
                      icon: IconProvider.lockCheckFilled,
                      text: LocalString._end_to_end_encrypted_to_verified_recipient,
                      isPGPPinned: true,
                      isNonePM: false)
            )
            XCTAssertNil(code)
            expectation1.fulfill()
        }
        waitForExpectations(timeout: 1)

        XCTAssertTrue(fetchEmailAddressesPublicKey.executeStub.wasCalledExactlyOnce)
    }

    func testCalculateEncryptionIcon_externalEmail_withPinnedKey_returnGreenIcon() {
        let email = "test@mail.me"
        fetchEmailAddressesPublicKey.executeStub.bodyIs { _, _ in
            KeysResponse(keys: [], recipientType: .external)
        }
        let localContact = PreContact(
            email: email,
            pubKeys: [OpenPGPDefines.publicKey.unArmor!],
            sign: .sign,
            encrypt: true,
            scheme: nil,
            mimeType: nil
        )
        sut = ContactPGPTypeHelper(
            internetConnectionStatusProvider: internetConnectionStatusProviderStub,
            fetchEmailAddressesPublicKey: fetchEmailAddressesPublicKey,
            userSign: 0,
            localContacts: [localContact],
            userAddresses: []
        )
        let expectation1 = expectation(description: "closure is called")

        sut.calculateEncryptionIcon(email: email,
                                    isMessageHavingPWD: false) { encryptionIcon, code in

            XCTAssertEqual(
                encryptionIcon,
                .init(iconColor: .green,
                      icon: IconProvider.lockCheckFilled,
                      text: LocalString._pgp_encrypted_to_verified_recipient,
                      isPGPPinned: true,
                      isNonePM: false)
            )
            XCTAssertNil(code)
            expectation1.fulfill()
        }
        waitForExpectations(timeout: 1)

        XCTAssertTrue(fetchEmailAddressesPublicKey.executeStub.wasCalledExactlyOnce)
    }

    func testCalculateEncryptionIcon_externalEmail_withKeyInContactToSign_returnGreenIcon() {
        let email = "test@mail.me"
        fetchEmailAddressesPublicKey.executeStub.bodyIs { _, _ in
            KeysResponse(keys: [], recipientType: .external)
        }
        let localContact = PreContact(
            email: email,
            pubKeys: [OpenPGPDefines.publicKey.unArmor!],
            sign: .sign,
            encrypt: false,
            scheme: nil,
            mimeType: nil
        )
        sut = ContactPGPTypeHelper(
            internetConnectionStatusProvider: internetConnectionStatusProviderStub,
            fetchEmailAddressesPublicKey: fetchEmailAddressesPublicKey,
            userSign: 0,
            localContacts: [localContact],
            userAddresses: []
        )
        let expectation1 = expectation(description: "closure is called")

        sut.calculateEncryptionIcon(email: email,
                                    isMessageHavingPWD: false) { encryptionIcon, code in

            XCTAssertEqual(
                encryptionIcon,
                .init(iconColor: .green,
                      icon: IconProvider.lockOpenPenFilled,
                      text: LocalString._pgp_signed_to_recipient,
                      isPGPPinned: false,
                      isNonePM: true)
            )
            XCTAssertNil(code)
            expectation1.fulfill()
        }
        waitForExpectations(timeout: 1)

        XCTAssertTrue(fetchEmailAddressesPublicKey.executeStub.wasCalledExactlyOnce)
    }

    func testCalculateEncryptionIcon_selfEmail__returnBlueIcon() {
        let email = "test@pm.me"
        fetchEmailAddressesPublicKey.executeStub.bodyIs { _, _ in
            KeysResponse(keys: [self.makeKeyResponse()], recipientType: .internal)
        }
        let address = Address(addressID: "",
                              domainID: nil,
                              email: email,
                              send: .active,
                              receive: .active,
                              status: .enabled,
                              type: .protonDomain,
                              order: 0,
                              displayName: "",
                              signature: "",
                              hasKeys: 1,
                              keys:
                              [Key(keyID: "", privateKey: OpenPGPDefines.privateKey)])
        sut = ContactPGPTypeHelper(
            internetConnectionStatusProvider: internetConnectionStatusProviderStub,
            fetchEmailAddressesPublicKey: fetchEmailAddressesPublicKey,
            userSign: 0,
            localContacts: [],
            userAddresses: [address]
        )
        let expectation1 = expectation(description: "closure is called")

        sut.calculateEncryptionIcon(email: email,
                                    isMessageHavingPWD: false) { encryptionIcon, code in

            XCTAssertEqual(
                encryptionIcon,
                .init(iconColor: .blue,
                      icon: IconProvider.lockFilled,
                      text: LocalString._end_to_end_encrypted_of_recipient,
                      isPGPPinned: false,
                      isNonePM: false)
            )
            XCTAssertNil(code)
            expectation1.fulfill()
        }
        waitForExpectations(timeout: 1)

        XCTAssertTrue(fetchEmailAddressesPublicKey.executeStub.wasCalledExactlyOnce)
    }

    func testCalculateEncryptionIcon_withEncryptedOutsideAndExternalPGP_EOWillOverrideExternalPGP() {
        let email = "test@mail.me"
        fetchEmailAddressesPublicKey.executeStub.bodyIs { _, _ in
            KeysResponse(keys: [], recipientType: .external)
        }
        let localContact = PreContact(
            email: email,
            pubKeys: [OpenPGPDefines.publicKey.unArmor!],
            sign: .sign,
            encrypt: false,
            scheme: nil,
            mimeType: nil
        )
        sut = ContactPGPTypeHelper(
            internetConnectionStatusProvider: internetConnectionStatusProviderStub,
            fetchEmailAddressesPublicKey: fetchEmailAddressesPublicKey,
            userSign: 0,
            localContacts: [localContact],
            userAddresses: []
        )
        let expectation1 = expectation(description: "closure is called")

        sut.calculateEncryptionIcon(
            email: email,
            isMessageHavingPWD: true
        ) { encryptionIcon, code in

            XCTAssertEqual(
                encryptionIcon,
                .init(iconColor: .blue,
                      icon: IconProvider.lockFilled,
                      text: LocalString._end_to_end_encrypted_of_recipient,
                      isPGPPinned: false,
                      isNonePM: true)
            )
            XCTAssertNil(code)
            expectation1.fulfill()
        }
        waitForExpectations(timeout: 1)

        XCTAssertTrue(fetchEmailAddressesPublicKey.executeStub.wasCalledExactlyOnce)
    }

    private func makeKeyResponse(flags: Key.Flags = [.notCompromised, .notObsolete]) -> KeyResponse {
        KeyResponse(flags: flags, publicKey: OpenPGPDefines.publicKey)
    }
}
