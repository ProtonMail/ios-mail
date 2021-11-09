// Copyright (c) 2021 Proton Technologies AG
//
// This file is part of ProtonMail.
//
// ProtonMail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// ProtonMail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with ProtonMail. If not, see https://www.gnu.org/licenses/.

import ProtonCore_TestingToolkit
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
        internetConnectionStatusProviderStub = InternetConnectionStatusProvider(notificationCenter: NotificationCenter(),
                                                                                reachability: reachabilityStub)
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

    func testGetPGPTypeLocally() {
        sut = ContactPGPTypeHelper(internetConnectionStatusProvider: internetConnectionStatusProviderStub,
                                   apiService: apiServiceMock,
                                   userSign: 0,
                                   localContacts: localContactsStub)
        sut.getPGPTypeLocally(email: "test@protonmail.com") { pgpType, errorCode, errorString in
            XCTAssertEqual(pgpType, PGPType.internal_normal)
            XCTAssertNil(errorCode)
            XCTAssertNil(errorString)
        }

        sut.getPGPTypeLocally(email: "test@protonmail.ch") { pgpType, errorCode, errorString in
            XCTAssertEqual(pgpType, PGPType.internal_normal)
            XCTAssertNil(errorCode)
            XCTAssertNil(errorString)
        }

        sut.getPGPTypeLocally(email: "test@pm.me") { pgpType, errorCode, errorString in
            XCTAssertEqual(pgpType, PGPType.internal_normal)
            XCTAssertNil(errorCode)
            XCTAssertNil(errorString)
        }

        sut.getPGPTypeLocally(email: "test@pm.mess") { pgpType, errorCode, errorString in
            XCTAssertEqual(pgpType, PGPType.none)
            XCTAssertNil(errorCode)
            XCTAssertNil(errorString)
        }

        sut.getPGPTypeLocally(email: "test@protonmail.chhs") { pgpType, errorCode, errorString in
            XCTAssertEqual(pgpType, PGPType.none)
            XCTAssertNil(errorCode)
            XCTAssertNil(errorString)
        }

        sut.getPGPTypeLocally(email: "testsdfsdfsdf") { pgpType, errorCode, errorString in
            XCTAssertEqual(pgpType, PGPType.failed_validation)
            XCTAssertNotNil(errorCode)
            XCTAssertEqual(errorCode, PGPTypeErrorCode.recipientNotFound.rawValue)
            XCTAssertNil(errorString)
        }
    }

    func testCalculatePGPType_inOfflineMode() {
        reachabilityStub.currentReachabilityStatusStub = .NotReachable
        sut = ContactPGPTypeHelper(internetConnectionStatusProvider: internetConnectionStatusProviderStub,
                                   apiService: apiServiceMock,
                                   userSign: 0,
                                   localContacts: localContactsStub)

        let expect = expectation(description: "calculate pgp type of pm email")
        sut.calculatePGPType(email: "test@protonmail.ch", isMessageHavingPwd: false) { pgpType, errorCode, errorString in
            XCTAssertEqual(pgpType, PGPType.internal_normal)
            XCTAssertNil(errorCode)
            XCTAssertNil(errorString)
            expect.fulfill()
        }

        let expect2 = expectation(description: "calculate pgp type of invalid email")
        sut.calculatePGPType(email: "sdifjsdifjs", isMessageHavingPwd: false) { pgpType, errorCode, _ in
            XCTAssertEqual(pgpType, PGPType.failed_validation)
            XCTAssertNotNil(errorCode)
            XCTAssertEqual(errorCode, PGPTypeErrorCode.recipientNotFound.rawValue)
            expect2.fulfill()
        }

        let expect3 = expectation(description: "calculate pgp type of non-pm email")
        sut.calculatePGPType(email: "test@test.com", isMessageHavingPwd: false) { pgpType, errorCode, errorString in
            XCTAssertEqual(pgpType, PGPType.none)
            XCTAssertNil(errorCode)
            XCTAssertNil(errorString)
            expect3.fulfill()
        }

        wait(for: [expect, expect2, expect3], timeout: 3)
    }

    func testCalculatePGPTypeWith_internalAddressWithPgpKey_returnInternalTrustedKey() {
        let responseStub = KeysResponse()
        responseStub.recipientType = 1
        let fakeKey = "fakeKey".data(using: .utf8)!
        let contactStub = PreContact(email: "test@test.com",
                                     pubKey: fakeKey,
                                     pubKeys: [fakeKey],
                                     sign: false,
                                     encrypt: false,
                                     mime: false,
                                     plainText: false)
        localContactsStub.append(contactStub)
        sut = ContactPGPTypeHelper(internetConnectionStatusProvider: internetConnectionStatusProviderStub,
                                   apiService: apiServiceMock,
                                   userSign: 0,
                                   localContacts: localContactsStub)

        let result = sut.calculatePGPTypeWith(email: "test@test.com",
                                              keyRes: responseStub,
                                              contacts: localContactsStub,
                                              isMessageHavingPwd: false)
        XCTAssertEqual(result, PGPType.internal_trusted_key)
    }

    func testCalculatePGPTypeWith_internalAddressWithPgpKey_withWrongContactEmail_returnInternalNormal() {
        let responseStub = KeysResponse()
        responseStub.recipientType = 1
        let fakeKey = "fakeKey".data(using: .utf8)!
        let contactStub = PreContact(email: "wrong@test.com",
                                     pubKey: fakeKey,
                                     pubKeys: [fakeKey],
                                     sign: false,
                                     encrypt: false,
                                     mime: false,
                                     plainText: false)
        localContactsStub.append(contactStub)
        sut = ContactPGPTypeHelper(internetConnectionStatusProvider: internetConnectionStatusProviderStub,
                                   apiService: apiServiceMock,
                                   userSign: 0,
                                   localContacts: localContactsStub)

        let result = sut.calculatePGPTypeWith(email: "test@test.com",
                                              keyRes: responseStub,
                                              contacts: localContactsStub,
                                              isMessageHavingPwd: false)
        XCTAssertEqual(result, PGPType.internal_normal)
    }

    func testCalculatePGPTypeWith_internalAddress_returnInternalNormal() {
        let responseStub = KeysResponse()
        responseStub.recipientType = 1
        sut = ContactPGPTypeHelper(internetConnectionStatusProvider: internetConnectionStatusProviderStub,
                                   apiService: apiServiceMock,
                                   userSign: 0,
                                   localContacts: localContactsStub)

        let result = sut.calculatePGPTypeWith(email: "test@test.com",
                                              keyRes: responseStub,
                                              contacts: localContactsStub,
                                              isMessageHavingPwd: false)
        XCTAssertEqual(result, PGPType.internal_normal)
    }

    func testCalculatePGPTypeWith_otherAddressNotInContact_returnNone() {
        let responseStub = KeysResponse()
        responseStub.recipientType = 0
        sut = ContactPGPTypeHelper(internetConnectionStatusProvider: internetConnectionStatusProviderStub,
                                   apiService: apiServiceMock,
                                   userSign: 0,
                                   localContacts: localContactsStub)

        let result = sut.calculatePGPTypeWith(email: "test@test.com",
                                              keyRes: responseStub,
                                              contacts: localContactsStub,
                                              isMessageHavingPwd: false)
        XCTAssertEqual(result, .none)
    }

    func testCalculatePGPTypeWith_otherAddressNotInContact_withUserSign_returnPGPSigned() {
        let responseStub = KeysResponse()
        responseStub.recipientType = 0
        sut = ContactPGPTypeHelper(internetConnectionStatusProvider: internetConnectionStatusProviderStub,
                                   apiService: apiServiceMock,
                                   userSign: 1,
                                   localContacts: localContactsStub)

        let result = sut.calculatePGPTypeWith(email: "test@test.com",
                                              keyRes: responseStub,
                                              contacts: localContactsStub,
                                              isMessageHavingPwd: false)
        XCTAssertEqual(result, .pgp_signed)
    }

    func testCalculatePGPTypeWith_otherAddressNotInContact_withMessageHavingPwd_returnEncryptedOutside() {
        let responseStub = KeysResponse()
        responseStub.recipientType = 0
        sut = ContactPGPTypeHelper(internetConnectionStatusProvider: internetConnectionStatusProviderStub,
                                   apiService: apiServiceMock,
                                   userSign: 1,
                                   localContacts: localContactsStub)

        let result = sut.calculatePGPTypeWith(email: "test@test.com",
                                              keyRes: responseStub,
                                              contacts: localContactsStub,
                                              isMessageHavingPwd: true)
        XCTAssertEqual(result, .eo)
    }

    func testCalculatePGPTypeWith_otherAddressInContact_withEncryptSetAndHavingPGPKey_returnPGPEncryptTrustedKey() {
        let responseStub = KeysResponse()
        responseStub.recipientType = 0
        let fakeKey = "fakeKey".data(using: .utf8)!
        let contactStub = PreContact(email: "test@test.com",
                                     pubKey: fakeKey,
                                     pubKeys: [fakeKey],
                                     sign: false,
                                     encrypt: true,
                                     mime: false,
                                     plainText: false)
        localContactsStub.append(contactStub)
        sut = ContactPGPTypeHelper(internetConnectionStatusProvider: internetConnectionStatusProviderStub,
                                   apiService: apiServiceMock,
                                   userSign: 1,
                                   localContacts: localContactsStub)

        let result = sut.calculatePGPTypeWith(email: "test@test.com",
                                              keyRes: responseStub,
                                              contacts: localContactsStub,
                                              isMessageHavingPwd: false)
        XCTAssertEqual(result, .pgp_encrypt_trusted_key)
    }

    func testCalculatePGPTypeWith_otherAddressInContact_withMessageHavingPwd_returnEncryptedOutside() {
        let responseStub = KeysResponse()
        responseStub.recipientType = 0
        let contactStub = PreContact(email: "test@test.com",
                                     pubKey: nil,
                                     pubKeys: [],
                                     sign: false,
                                     encrypt: true,
                                     mime: false,
                                     plainText: false)
        localContactsStub.append(contactStub)
        sut = ContactPGPTypeHelper(internetConnectionStatusProvider: internetConnectionStatusProviderStub,
                                   apiService: apiServiceMock,
                                   userSign: 1,
                                   localContacts: localContactsStub)

        let result = sut.calculatePGPTypeWith(email: "test@test.com",
                                              keyRes: responseStub,
                                              contacts: localContactsStub,
                                              isMessageHavingPwd: true)
        XCTAssertEqual(result, .eo)
    }

    func testCalculatePGPTypeWith_otherAddressInContact_withSignFlagSet_returnPGPSigned() {
        let responseStub = KeysResponse()
        responseStub.recipientType = 0
        let contactStub = PreContact(email: "test@test.com",
                                     pubKey: nil,
                                     pubKeys: [],
                                     sign: true,
                                     encrypt: false,
                                     mime: false,
                                     plainText: false)
        localContactsStub.append(contactStub)
        sut = ContactPGPTypeHelper(internetConnectionStatusProvider: internetConnectionStatusProviderStub,
                                   apiService: apiServiceMock,
                                   userSign: 1,
                                   localContacts: localContactsStub)

        let result = sut.calculatePGPTypeWith(email: "test@test.com",
                                              keyRes: responseStub,
                                              contacts: localContactsStub,
                                              isMessageHavingPwd: false)
        XCTAssertEqual(result, .pgp_signed)
    }

    func testCalculatePGPTypeWith_otherAddressInContact_withoutPGPKeyAndSignFlag_returnPGPSigned() {
        let responseStub = KeysResponse()
        responseStub.recipientType = 0
        let contactStub = PreContact(email: "test@test.com",
                                     pubKey: nil,
                                     pubKeys: [],
                                     sign: false,
                                     encrypt: false,
                                     mime: false,
                                     plainText: false)
        localContactsStub.append(contactStub)
        sut = ContactPGPTypeHelper(internetConnectionStatusProvider: internetConnectionStatusProviderStub,
                                   apiService: apiServiceMock,
                                   userSign: 1,
                                   localContacts: localContactsStub)

        let result = sut.calculatePGPTypeWith(email: "test@test.com",
                                              keyRes: responseStub,
                                              contacts: localContactsStub,
                                              isMessageHavingPwd: false)
        XCTAssertEqual(result, .none)
    }

    func testGetPGPType_withErrorCode33101() {
        sut = ContactPGPTypeHelper(internetConnectionStatusProvider: internetConnectionStatusProviderStub,
                                   apiService: apiServiceMock,
                                   userSign: 1,
                                   localContacts: localContactsStub)
        apiServiceMock.requestStub.bodyIs { _, _, path, _, _, _, _, _, completion in
            if path.contains("/keys") {
                completion?(nil, ["Code": 33101, "Error": "Server failed validation"], nil)
            } else {
                XCTFail("Unexpected path")
                completion?(nil, nil, nil)
            }
        }

        let expectation1 = expectation(description: "get failed server validation error")
        sut.getPGPType(email: "test@test.com",
                       isMessageHavingPwd: false) { pgpType, errorCode, errorString in
            XCTAssertEqual(pgpType, PGPType.failed_server_validation)
            XCTAssertEqual(errorCode, PGPTypeErrorCode.emailAddressFailedValidation.rawValue)
            XCTAssertEqual(errorString, LocalString._signle_address_invalid_error_content)
            expectation1.fulfill()
        }

        waitForExpectations(timeout: 1) { error in
            XCTAssertNil(error)
        }
    }

    func testGetPGPType_withErrorCode33102() {
        sut = ContactPGPTypeHelper(internetConnectionStatusProvider: internetConnectionStatusProviderStub,
                                   apiService: apiServiceMock,
                                   userSign: 1,
                                   localContacts: localContactsStub)
        apiServiceMock.requestStub.bodyIs { _, _, path, _, _, _, _, _, completion in
            if path.contains("/keys") {
                completion?(nil, ["Code": 33102, "Error": "Recipient not found"], nil)
            } else {
                XCTFail("Unexpected path")
                completion?(nil, nil, nil)
            }
        }

        let expectation1 = expectation(description: "get recipient not found")
        sut.getPGPType(email: "test@test.com",
                       isMessageHavingPwd: false) { pgpType, errorCode, errorString in
            XCTAssertEqual(pgpType, PGPType.none)
            XCTAssertEqual(errorCode, PGPTypeErrorCode.recipientNotFound.rawValue)
            XCTAssertEqual(errorString, LocalString._recipient_not_found)
            expectation1.fulfill()
        }

        waitForExpectations(timeout: 1) { error in
            XCTAssertNil(error)
        }
    }

    func testGetPGPType_withNetworkErrorAndInvalidAddress() {
        sut = ContactPGPTypeHelper(internetConnectionStatusProvider: internetConnectionStatusProviderStub,
                                   apiService: apiServiceMock,
                                   userSign: 1,
                                   localContacts: localContactsStub)
        apiServiceMock.requestStub.bodyIs { _, _, path, _, _, _, _, _, completion in
            if path.contains("/keys") {
                completion?(nil, ["Code": 9999, "Error": "Error"], nil)
            } else {
                XCTFail("Unexpected path")
                completion?(nil, nil, nil)
            }
        }

        let expectation1 = expectation(description: "get failed validation")
        sut.getPGPType(email: "testtest.com",
                       isMessageHavingPwd: false) { pgpType, errorCode, errorString in
            XCTAssertEqual(pgpType, PGPType.failed_validation)
            XCTAssertEqual(errorCode, PGPTypeErrorCode.recipientNotFound.rawValue)
            XCTAssertNil(errorString)
            expectation1.fulfill()
        }

        waitForExpectations(timeout: 1) { error in
            XCTAssertNil(error)
        }
    }
}
