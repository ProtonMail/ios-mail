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

import ProtonCore_Crypto
import ProtonCore_DataModel
import ProtonCore_Networking
import ProtonCore_TestingToolkit
import XCTest
@testable import ProtonMail

final class ChangePasswordViewModelTests: XCTestCase {
    private var sut: ChangePasswordViewModel!
    private var user: UserManager!
    private var apiService: APIServiceMock!
    private let modulesResponse: [String: Any] = [
        "Code": 1000,
        "Modulus": "-----BEGIN PGP SIGNED MESSAGE-----\nHash: SHA256\n\nu5O8KKH2VYWS0O7JWCYdjGKvO3hTNq1IxJRoExdv2gOdV1x6rp+9PLYetZkc60YmI1A4M6FOaCqpCtdfUrt+diuZGfaWSG8AnbPVQ7ZDsLb2Hp351QTfHqZjGrmrN/u9XMgI/2SSqa6Jrd8hLA0bjqAa4LX9FFlLJABN1h4leeTq5R0cSJSg0F+PsWgKAkMBoIrunDWZFCrByEj2mmieMGYdl11+YZOrRjT7kJbr4xYiSsQUehhI4/JLjVeCNGJ5Z96KuKELuWk5smapKakZ5+2i9NKovzKujJJvmNK6hFku7amWTbiMc+UaoAVjmoWDmquc7lhTrrSrz6+5ZIY28A==\n-----BEGIN PGP SIGNATURE-----\nVersion: ProtonMail\nComment: https://protonmail.com\n\nwl4EARYIABAFAlwB1j0JEDUFhcTpUY8mAAC2+wD9EmUDnJ7gH5ygqwkyQGqL\nTFioFwZDLb7sEW3/bzZXgR0A/0nEhySjl5C0TgpAFuaucGgv//XjstJM8eEa\nNxMJG6cF\n=RP0d\n-----END PGP SIGNATURE-----\n",
        "ModulusID": "Oq_JB_IkrOx5WlpxzlRPocN3_NhJ80V7DGav77eRtSDkOtLxW2jfI3nUpEqANGpboOyN-GuzEFXadlpxgVp7_g=="
    ]

    private let infoResponse: [String: Any] = [
          "Code": 1000,
          "Modulus": "-----BEGIN PGP SIGNED MESSAGE-----\nHash: SHA256\n\n091HBWnHlR+qphOhmi9ZrTWMnPT/jXqWzUh7F8CShuXIfHe5srT4y3BoBi85N89ceDhety3oVKoaS9sTQ6hVoRjjCulEuNQ5L6uN+9jG/f3/c3yVYjl6d9P1ktLsS21p3+2dQEAcNP0SQvMIdJPva1aBWsaoHKA3nzOp7pCIJHRw2Xx7T8AwzndW8r6KcNeZSLltj3FBIbWmKsaA8d3x+Db2D4M2Rngdf/eW2CQ39RlMvPdefMISs3jKSwduCJKCKbhYh6WSCjpgXrombuYIiMynfx38IibvSIURLOhXC9JKXY0k+bCPxZpt5iloe/11wK4ZSwuhYLEukD1ulvR1rw==\n-----BEGIN PGP SIGNATURE-----\nVersion: ProtonMail\nComment: https://protonmail.com\n\nwl4EARYIABAFAlwB1jwJEDUFhcTpUY8mAABQpAD/VWjPiBcTZLU9t9GcLPtI\ntv2iIdcvaOJg3hpl/XyEmAoA/0jNeiOMHl0Hpd4PoF/SCqmO/gDZDByy+t1n\n5xsxCLEM\n=a1KZ\n-----END PGP SIGNATURE-----\n",
          "ServerEphemeral": "Oe9igL3PyWdFWIwEI+CEtyEE9ahMXHILy4uoWbPe0Prw1fycXEqde4dtyOqBo+m48L4EHI3g94roqu7DHmIZBkWitupHpTIkj3qzbuMczXmCZ5Bu9U6JaBJ6vVNYTSKrtUOY88bM+agLCTMKXcs7T0gdsS7K6F4Hb8PH75bNLs3sCaWv6FvjgfWUYEWyjyK+2utIEJrLsNhAFEntS4diDshglBlLYIXgSD4Z/pkmlb/oPYwmRzeBQDLG5frtQ0FODds3zzMV1uLwUyuYSvehDv21MbKiDF5w0v4io25dDSZu+wHP5j/6HoMTSMLuV8dXpN8etSJHTgvXBvDGGhGxaQ==",
          "Version": 4,
          "Salt": "6HbNKcnVPikw4A==",
          "SRPSession": "272f888f68c49da7ccb42cc4f5a21b92"
    ]

    class func mockUser(apiService: APIServiceMock) -> UserManager {
        let userInfo = UserInfo.getDefault()
        let key = Key(keyID: "123", privateKey: KeyTestData.privateKey1, signature: "aa")
        userInfo.userKeys = [key]
        let address = Address(addressID: "321", domainID: nil, email: "abc@pm.me", send: .active, receive: .active, status: .enabled, type: .protonDomain, order: 0, displayName: "Tester", signature: "aa", hasKeys: 1, keys: [key])
        userInfo.userAddresses = [address]
        let auth = AuthCredential(
            sessionID: "id",
            accessToken: "token",
            refreshToken: "refresh",
            userName: "name",
            userID: "1",
            privateKey: nil,
            passwordKeySalt: nil
        )
        auth.mailboxpassword = KeyTestData.passphrash1.value
        return UserManager(
            api: apiService,
            userInfo: userInfo,
            authCredential: auth,
            mailSettings: nil,
            parent: nil,
            appTelemetry: MailAppTelemetry()
        )
    }

    override func setUpWithError() throws {
        apiService = APIServiceMock()
        user = ChangePasswordViewModelTests.mockUser(apiService: apiService)
    }
    
    override func tearDownWithError() throws {
        sut = nil
        user = nil
        apiService = nil
    }
}

// MARK: - ChangeSinglePasswordViewModel
extension ChangePasswordViewModelTests {
    func testChangeSinglePass_setNewPassword_succeed() throws {
        sut = ChangeSinglePasswordViewModel(user: user)
        setNewPassword_succeed()
    }

    func testChangeSinglePass_setNewPassword_password_empty() {
        sut = ChangeSinglePasswordViewModel(user: user)
        setNewPassword_password_empty()
    }

    func testChangeSinglePass_newPassword_less_than_minimum() {
        sut = ChangeSinglePasswordViewModel(user: user)
        newPassword_less_than_minimum()
    }

    func testChangeSinglePass_newPassword_does_not_match_confirmed() {
        sut = ChangeSinglePasswordViewModel(user: user)
        newPassword_does_not_match_confirmed()
    }
}

// MARK: - ChangeMailboxPWDViewModel
extension ChangePasswordViewModelTests {
    func testChangeMailboxPWD_SetNewPassword_succeed() {
        sut = ChangeMailboxPWDViewModel(user: user)
        setNewPassword_succeed()
    }

    func testChangeMailboxPWD_setNewPassword_password_empty() {
        sut = ChangeMailboxPWDViewModel(user: user)
        setNewPassword_password_empty()
    }

    func testChangeMailboxPWD_newPassword_does_not_match_confirmed() {
        sut = ChangeMailboxPWDViewModel(user: user)
        newPassword_does_not_match_confirmed()
    }
}

// MARK: - ChangeLoginPWDViewModel
extension ChangePasswordViewModelTests {
    func testChangeLoginPWD_setNewPassword_succeed() throws {
        sut = ChangeLoginPWDViewModel(user: user)
        setNewPassword_succeed()
    }

    func testChangeLoginPWD_setNewPassword_password_empty() {
        sut = ChangeLoginPWDViewModel(user: user)
        setNewPassword_password_empty()
    }

    func testChangeLoginPWD_newPassword_less_than_minimum() {
        sut = ChangeLoginPWDViewModel(user: user)
        newPassword_less_than_minimum()
    }

    func testChangeLoginPWD_newPassword_does_not_match_confirmed() {
        sut = ChangeLoginPWDViewModel(user: user)
        newPassword_does_not_match_confirmed()
    }
}

extension ChangePasswordViewModelTests {
    func setNewPassword_succeed() {
        apiService.requestJSONStub.bodyIs { _, _, path, reqParams, _, _, _, _, _, _, completion in
            if path == "/auth/modulus" {
                completion(nil, .success(self.modulesResponse))
            } else if path == "/auth/info" {
                completion(nil, .success(self.infoResponse))
            } else if path == "/keys/private" {
                completion(nil, .success(["Code": 1000]))
            } else if path == "/settings/password" {
                completion(nil, .success(["Code": 1000]))
            } else {
                XCTFail("Unexpected API path")
            }
        }
        let expectation1 = expectation(description: "aa")
        let newPassword = String.randomString(8)
        sut.setNewPassword(
            KeyTestData.passphrash1.value,
            newPassword: Passphrase(value: newPassword),
            confirmNewPassword: Passphrase(value: newPassword),
            tFACode: nil
        ) { error in
            XCTAssertNil(error)
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 5)
    }

    func setNewPassword_password_empty() {
        let expectation1 = expectation(description: "Get set new password completed")
        sut.setNewPassword(
            KeyTestData.passphrash1.value,
            newPassword: Passphrase(value: ""),
            confirmNewPassword: Passphrase(value: "aaa"),
            tFACode: nil
        ) { error in
            XCTAssertEqual(error?.code, 1114128)
            XCTAssertEqual(error?.localizedFailureReason, "The new password can't be empty.")
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 5)

        let expectation2 = expectation(description: "Get set new password completed")
        sut.setNewPassword(
            KeyTestData.passphrash1.value,
            newPassword: Passphrase(value: "aa"),
            confirmNewPassword: Passphrase(value: ""),
            tFACode: nil
        ) { error in
            XCTAssertEqual(error?.code, 1114128)
            XCTAssertEqual(error?.localizedFailureReason, "The new password can't be empty.")
            expectation2.fulfill()
        }
        wait(for: [expectation2], timeout: 5)
    }

    func newPassword_less_than_minimum() {
        let password = String.randomString(7)
        let expectation1 = expectation(description: "Get set new password completed")
        sut.setNewPassword(
            KeyTestData.passphrash1.value,
            newPassword: Passphrase(value: password),
            confirmNewPassword: Passphrase(value: "aaa"),
            tFACode: nil
        ) { error in
            XCTAssertEqual(error?.code, 1114130)
            XCTAssertEqual(error?.localizedFailureReason, "The new password needs to be at least 8 characters long")
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 5)
    }

    func newPassword_does_not_match_confirmed() {
        let password = String.randomString(8)
        let expectation1 = expectation(description: "Get set new password completed")
        sut.setNewPassword(
            KeyTestData.passphrash1.value,
            newPassword: Passphrase(value: password),
            confirmNewPassword: Passphrase(value: "aaa"),
            tFACode: nil
        ) { error in
            XCTAssertEqual(error?.code, 1114121)
            XCTAssertEqual(error?.localizedFailureReason, "The new password does not match.")
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 5)
    }
}

