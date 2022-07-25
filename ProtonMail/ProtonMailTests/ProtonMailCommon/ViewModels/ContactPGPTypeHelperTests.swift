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

import ProtonCore_DataModel
import ProtonCore_TestingToolkit
import ProtonCore_UIFoundations
@testable import ProtonMail
import XCTest

class ContactPGPTypeHelperTests: XCTestCase {
    var sut: ContactPGPTypeHelper!
    var reachabilityStub: ReachabilityStub!
    var internetConnectionStatusProviderStub: InternetConnectionStatusProvider!
    var apiServiceMock: APIServiceMock!
    var localContactsStub: [PreContact] = []

    override func setUp() {
        super.setUp()
        reachabilityStub = ReachabilityStub()
        reachabilityStub.currentReachabilityStatusStub = .ReachableViaWWAN
        internetConnectionStatusProviderStub = InternetConnectionStatusProvider(
            notificationCenter: NotificationCenter(),
            reachability: reachabilityStub,
            connectionMonitor: nil
        )
        apiServiceMock = APIServiceMock()
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
        internetConnectionStatusProviderStub = nil
        reachabilityStub = nil
        apiServiceMock = nil
        localContactsStub = []
    }

    func testCalculateEncryptionIcon_withNoInternet_nonPMValidEmail_returnNil() {
        let mail = "test@mail.com"
        reachabilityStub.currentReachabilityStatusStub = .NotReachable
        sut = ContactPGPTypeHelper(
            internetConnectionStatusProvider: internetConnectionStatusProviderStub,
            apiService: apiServiceMock,
            userSign: 0,
            localContacts: [],
            userAddresses: []
        )

        let expectation1 = expectation(description: "closure is called")
        sut.calculateEncryptionIcon(email: mail,
                                    isMessageHavingPWD: Bool.random()) { encryptionIcon, code in
            XCTAssertNil(encryptionIcon)
            XCTAssertNil(code)
            expectation1.fulfill()
        }
        waitForExpectations(timeout: 1)

        XCTAssertTrue(apiServiceMock.requestStub.wasNotCalled)
    }

    func testCalculateEncryptionIcon_withNoInternet_PMValidEmail_returnLockIcon() {
        let mails = ["test@pm.me", "test@protonmail.com", "test@protonmail.ch", "test@proton.me"]
        reachabilityStub.currentReachabilityStatusStub = .NotReachable
        sut = ContactPGPTypeHelper(
            internetConnectionStatusProvider: internetConnectionStatusProviderStub,
            apiService: apiServiceMock,
            userSign: 0,
            localContacts: [],
            userAddresses: []
        )

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
                XCTAssertEqual(code, 0)
                expectation1.fulfill()
            }
        }
        waitForExpectations(timeout: 1)

        XCTAssertTrue(apiServiceMock.requestStub.wasNotCalled)
    }

    func testCalculateEncryptionIcon_withNoInternet_invalidEmail_returnErrorIcon() {
        let mail = "test@mailcom"
        reachabilityStub.currentReachabilityStatusStub = .NotReachable
        sut = ContactPGPTypeHelper(
            internetConnectionStatusProvider: internetConnectionStatusProviderStub,
            apiService: apiServiceMock,
            userSign: 0,
            localContacts: [],
            userAddresses: []
        )

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

        XCTAssertTrue(apiServiceMock.requestStub.wasNotCalled)
    }

    func testCalculateEncryption_invalidEmail_returnErrorIcon() {
        apiServiceMock.requestStub.bodyIs { _, _, path, _, _, _, _, _, _, completion in
            if path.contains("/keys") {
                let response: [String: Any] = [
                    "Code": PGPTypeErrorCode.emailAddressFailedValidation.rawValue
                ]
                completion?(nil, response, nil)
            } else {
                XCTFail("Unexpected path")
                completion?(nil, nil, nil)
            }
        }

        sut = ContactPGPTypeHelper(
            internetConnectionStatusProvider: internetConnectionStatusProviderStub,
            apiService: apiServiceMock,
            userSign: 0,
            localContacts: [],
            userAddresses: []
        )

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

        XCTAssertTrue(apiServiceMock.requestStub.wasCalledExactlyOnce)
    }

    func testCalculateEncryption_EmailNotExist_returnErrorIcon() {
        apiServiceMock.requestStub.bodyIs { _, _, path, _, _, _, _, _, _, completion in
            if path.contains("/keys") {
                let response: [String: Any] = [
                    "Code": PGPTypeErrorCode.recipientNotFound.rawValue
                ]
                completion?(nil, response, nil)
            } else {
                XCTFail("Unexpected path")
                completion?(nil, nil, nil)
            }
        }

        sut = ContactPGPTypeHelper(
            internetConnectionStatusProvider: internetConnectionStatusProviderStub,
            apiService: apiServiceMock,
            userSign: 0,
            localContacts: [],
            userAddresses: []
        )

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

        XCTAssertTrue(apiServiceMock.requestStub.wasCalledExactlyOnce)
    }

    func testCalculateEncryption_validEmail_withErrorFromAPI_returnErrorIcon() {
        apiServiceMock.requestStub.bodyIs { _, _, path, _, _, _, _, _, _, completion in
            if path.contains("/keys") {
                let response: [String: Any] = [
                    "Code": 999
                ]
                completion?(nil, response, nil)
            } else {
                XCTFail("Unexpected path")
                completion?(nil, nil, nil)
            }
        }

        sut = ContactPGPTypeHelper(
            internetConnectionStatusProvider: internetConnectionStatusProviderStub,
            apiService: apiServiceMock,
            userSign: 0,
            localContacts: [],
            userAddresses: []
        )

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

        XCTAssertTrue(apiServiceMock.requestStub.wasCalledExactlyOnce)
    }

    func testCalculateEncryption_invalidEmail_withErrorFromAPI_returnErrorIcon() {
        apiServiceMock.requestStub.bodyIs { _, _, path, _, _, _, _, _, _, completion in
            if path.contains("/keys") {
                let response: [String: Any] = [
                    "Code": 999
                ]
                completion?(nil, response, nil)
            } else {
                XCTFail("Unexpected path")
                completion?(nil, nil, nil)
            }
        }

        sut = ContactPGPTypeHelper(
            internetConnectionStatusProvider: internetConnectionStatusProviderStub,
            apiService: apiServiceMock,
            userSign: 0,
            localContacts: [],
            userAddresses: []
        )
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

        XCTAssertTrue(apiServiceMock.requestStub.wasCalledExactlyOnce)
    }

    func testCalculateEncryptionIcon_PMMail_noKeyPinned_returnBlueIcon() {
        apiServiceMock.requestStub.bodyIs { _, _, path, _, _, _, _, _, _, completion in
            if path.contains("/keys") {
                let keyResponse: [[String: Any]] = [
                    [
                        "Flags": 3,
                        "PublicKey": OpenPGPDefines.publicKey
                    ]
                ]
                let response: [String: Any] = [
                    "Code": 1000,
                    "RecipientType": 1,
                    "MIMEType": "text/html",
                    "Keys": keyResponse
                ]
                completion?(nil, response, nil)
            } else {
                XCTFail("Unexpected path")
                completion?(nil, nil, nil)
            }
        }
        sut = ContactPGPTypeHelper(
            internetConnectionStatusProvider: internetConnectionStatusProviderStub,
            apiService: apiServiceMock,
            userSign: 0,
            localContacts: [],
            userAddresses: []
        )
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

        XCTAssertTrue(apiServiceMock.requestStub.wasCalledExactlyOnce)
    }

    func testCalculateEncryptionIcon_PMMail_keyIsPinned_returnBlueIcon() {
        let email = "test@pm.me"
        apiServiceMock.requestStub.bodyIs { _, _, path, _, _, _, _, _, _, completion in
            if path.contains("/keys") {
                let keyResponse: [[String: Any]] = [
                    [
                        "Flags": 3,
                        "PublicKey": OpenPGPDefines.publicKey
                    ]
                ]
                let response: [String: Any] = [
                    "Code": 1000,
                    "RecipientType": 1,
                    "MIMEType": "text/html",
                    "Keys": keyResponse
                ]
                completion?(nil, response, nil)
            } else {
                XCTFail("Unexpected path")
                completion?(nil, nil, nil)
            }
        }
        let localContact = PreContact(
            email: email,
            pubKey: OpenPGPDefines.publicKey.unArmor,
            pubKeys: [OpenPGPDefines.publicKey.unArmor!],
            sign: true,
            encrypt: true,
            mime: true,
            plainText: false,
            isContactSignatureVerified: true,
            scheme: nil,
            mimeType: nil
        )
        sut = ContactPGPTypeHelper(
            internetConnectionStatusProvider: internetConnectionStatusProviderStub,
            apiService: apiServiceMock,
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

        XCTAssertTrue(apiServiceMock.requestStub.wasCalledExactlyOnce)
    }

    func testCalculateEncryptionIcon_externalEmail_withPasswordSet_returnBlueIcon() {
        apiServiceMock.requestStub.bodyIs { _, _, path, _, _, _, _, _, _, completion in
            if path.contains("/keys") {
                let response: [String: Any] = [
                    "Code": 1000,
                    "RecipientType": 2,
                    "MIMEType": "text/html",
                    "Keys": []
                ]
                completion?(nil, response, nil)
            } else {
                XCTFail("Unexpected path")
                completion?(nil, nil, nil)
            }
        }
        sut = ContactPGPTypeHelper(
            internetConnectionStatusProvider: internetConnectionStatusProviderStub,
            apiService: apiServiceMock,
            userSign: 0,
            localContacts: [],
            userAddresses: []
        )
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

        XCTAssertTrue(apiServiceMock.requestStub.wasCalledExactlyOnce)
    }

    func testCalculateEncryptionIcon_externalEmail_returnNoIcon() {
        apiServiceMock.requestStub.bodyIs { _, _, path, _, _, _, _, _, _, completion in
            if path.contains("/keys") {
                let response: [String: Any] = [
                    "Code": 1000,
                    "RecipientType": 2,
                    "MIMEType": "text/html",
                    "Keys": []
                ]
                completion?(nil, response, nil)
            } else {
                XCTFail("Unexpected path")
                completion?(nil, nil, nil)
            }
        }
        sut = ContactPGPTypeHelper(
            internetConnectionStatusProvider: internetConnectionStatusProviderStub,
            apiService: apiServiceMock,
            userSign: 0,
            localContacts: [],
            userAddresses: []
        )
        let expectation1 = expectation(description: "closure is called")

        sut.calculateEncryptionIcon(email: "test@mail.me",
                                    isMessageHavingPWD: false) { encryptionIcon, code in
            XCTAssertNil(encryptionIcon)
            XCTAssertNil(code)
            expectation1.fulfill()
        }
        waitForExpectations(timeout: 1)

        XCTAssertTrue(apiServiceMock.requestStub.wasCalledExactlyOnce)
    }

    func testCalculateEncryptionIcon_externalEmail_withAPIKey_returnGreenIcon() {
        apiServiceMock.requestStub.bodyIs { _, _, path, _, _, _, _, _, _, completion in
            if path.contains("/keys") {
                let keyResponse: [[String: Any]] = [
                    [
                        "Flags": 3,
                        "PublicKey": OpenPGPDefines.publicKey
                    ]
                ]
                let response: [String: Any] = [
                    "Code": 1000,
                    "RecipientType": 2,
                    "MIMEType": "text/html",
                    "Keys": keyResponse
                ]
                completion?(nil, response, nil)
            } else {
                XCTFail("Unexpected path")
                completion?(nil, nil, nil)
            }
        }
        sut = ContactPGPTypeHelper(
            internetConnectionStatusProvider: internetConnectionStatusProviderStub,
            apiService: apiServiceMock,
            userSign: 0,
            localContacts: [],
            userAddresses: []
        )
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

        XCTAssertTrue(apiServiceMock.requestStub.wasCalledExactlyOnce)
    }

    func testCalculateEncryptionIcon_externalEmail_withVerificationOnlyAPIKey_returnErrorIcon() {
        apiServiceMock.requestStub.bodyIs { _, _, path, _, _, _, _, _, _, completion in
            if path.contains("/keys") {
                let keyResponse: [[String: Any]] = [
                    [
                        "Flags": 1,
                        "PublicKey": OpenPGPDefines.publicKey
                    ]
                ]
                let response: [String: Any] = [
                    "Code": 1000,
                    "RecipientType": 2,
                    "MIMEType": "text/html",
                    "Keys": keyResponse
                ]
                completion?(nil, response, nil)
            } else {
                XCTFail("Unexpected path")
                completion?(nil, nil, nil)
            }
        }
        sut = ContactPGPTypeHelper(
            internetConnectionStatusProvider: internetConnectionStatusProviderStub,
            apiService: apiServiceMock,
            userSign: 0,
            localContacts: [],
            userAddresses: []
        )
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

        XCTAssertTrue(apiServiceMock.requestStub.wasCalledExactlyOnce)
    }

    func testCalculateEncryptionIcon_externalEmail_withAPIKeyAndPinnedKey_returnGreenIcon() {
        let email = "test@mail.me"
        apiServiceMock.requestStub.bodyIs { _, _, path, _, _, _, _, _, _, completion in
            if path.contains("/keys") {
                let keyResponse: [[String: Any]] = [
                    [
                        "Flags": 3,
                        "PublicKey": OpenPGPDefines.publicKey
                    ]
                ]
                let response: [String: Any] = [
                    "Code": 1000,
                    "RecipientType": 2,
                    "MIMEType": "text/html",
                    "Keys": keyResponse
                ]
                completion?(nil, response, nil)
            } else {
                XCTFail("Unexpected path")
                completion?(nil, nil, nil)
            }
        }
        let localContact = PreContact(
            email: email,
            pubKey: OpenPGPDefines.publicKey.unArmor,
            pubKeys: [OpenPGPDefines.publicKey.unArmor!],
            sign: true,
            encrypt: true,
            mime: true,
            plainText: false,
            isContactSignatureVerified: true,
            scheme: nil,
            mimeType: nil
        )
        sut = ContactPGPTypeHelper(
            internetConnectionStatusProvider: internetConnectionStatusProviderStub,
            apiService: apiServiceMock,
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

        XCTAssertTrue(apiServiceMock.requestStub.wasCalledExactlyOnce)
    }

    func testCalculateEncryptionIcon_externalEmail_withPinnedKey_returnGreenIcon() {
        let email = "test@mail.me"
        apiServiceMock.requestStub.bodyIs { _, _, path, _, _, _, _, _, _, completion in
            if path.contains("/keys") {
                let response: [String: Any] = [
                    "Code": 1000,
                    "RecipientType": 2,
                    "MIMEType": "text/html",
                    "Keys": []
                ]
                completion?(nil, response, nil)
            } else {
                XCTFail("Unexpected path")
                completion?(nil, nil, nil)
            }
        }
        let localContact = PreContact(
            email: email,
            pubKey: OpenPGPDefines.publicKey.unArmor,
            pubKeys: [OpenPGPDefines.publicKey.unArmor!],
            sign: true,
            encrypt: true,
            mime: true,
            plainText: false,
            isContactSignatureVerified: true,
            scheme: nil,
            mimeType: nil
        )
        sut = ContactPGPTypeHelper(
            internetConnectionStatusProvider: internetConnectionStatusProviderStub,
            apiService: apiServiceMock,
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

        XCTAssertTrue(apiServiceMock.requestStub.wasCalledExactlyOnce)
    }

    func testCalculateEncryptionIcon_externalEmail_withKeyInContactToSign_returnGreenIcon() {
        let email = "test@mail.me"
        apiServiceMock.requestStub.bodyIs { _, _, path, _, _, _, _, _, _, completion in
            if path.contains("/keys") {
                let response: [String: Any] = [
                    "Code": 1000,
                    "RecipientType": 2,
                    "MIMEType": "text/html",
                    "Keys": []
                ]
                completion?(nil, response, nil)
            } else {
                XCTFail("Unexpected path")
                completion?(nil, nil, nil)
            }
        }
        let localContact = PreContact(
            email: email,
            pubKey: OpenPGPDefines.publicKey.unArmor,
            pubKeys: [OpenPGPDefines.publicKey.unArmor!],
            sign: true,
            encrypt: false,
            mime: true,
            plainText: false,
            isContactSignatureVerified: false,
            scheme: nil,
            mimeType: nil
        )
        sut = ContactPGPTypeHelper(
            internetConnectionStatusProvider: internetConnectionStatusProviderStub,
            apiService: apiServiceMock,
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

        XCTAssertTrue(apiServiceMock.requestStub.wasCalledExactlyOnce)
    }

    func testCalculateEncryptionIcon_selfEmail__returnBlueIcon() {
        let email = "test@pm.me"
        apiServiceMock.requestStub.bodyIs { _, _, path, _, _, _, _, _, _, completion in
            if path.contains("/keys") {
                let keyResponse: [[String: Any]] = [
                    [
                        "Flags": 3,
                        "PublicKey": OpenPGPDefines.publicKey
                    ]
                ]
                let response: [String: Any] = [
                    "Code": 1000,
                    "RecipientType": 1,
                    "MIMEType": "text/html",
                    "Keys": keyResponse
                ]
                completion?(nil, response, nil)
            } else {
                XCTFail("Unexpected path")
                completion?(nil, nil, nil)
            }
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
            apiService: apiServiceMock,
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

        XCTAssertTrue(apiServiceMock.requestStub.wasCalledExactlyOnce)
    }
}
