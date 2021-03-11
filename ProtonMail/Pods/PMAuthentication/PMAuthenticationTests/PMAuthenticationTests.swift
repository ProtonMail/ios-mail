//
//  PMAuthenticationTests.swift
//  PMAuthenticationTests - Create on 19/02/2020.
//
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.

import XCTest
@testable import PMAuthentication
import PMCommon

class PMAuthenticationTests: XCTestCase {
    
    func testAuthDrive() {
        let blueApi = PMAPIService(doh: TestDoHMail.default, sessionUID: ObfuscatedConstants.testSessionId)
        let manager = Authenticator(api: blueApi)
        let anonymousService = AnonymousServiceManager()
        anonymousService.appVersion = ObfuscatedConstants.driveAppVersion
        blueApi.serviceDelegate = anonymousService
        let expect = expectation(description: "AuthInfo + Auth")
        manager.authenticate(username: TestUser.blueDriveTestUser.username, password: TestUser.blueDriveTestUser.password) { result in
            switch result {
            case .success(Authenticator.Status.newCredential(_, _)): XCTAssert(true)
            default: XCTFail("Auth flow failed")
            }
            expect.fulfill()
        }
        
        waitForExpectations(timeout: 30) { (error) in
            XCTAssertNil(error, String(describing: error))
        }
    }

    func testAuth() {
        let expect = expectation(description: "AuthInfo + Auth")
        let liveApi = PMAPIService(doh: LiveDoHMail.default, sessionUID: ObfuscatedConstants.testSessionId)
        let liveService = AnonymousServiceManager()
        liveApi.serviceDelegate = liveService
        let manager = Authenticator(api: liveApi)
        manager.authenticate(username: TestUser.liveTestUser.username, password: TestUser.liveTestUser.password) { result in
            switch result {
            case .success: XCTAssert(true)
            case .failure: XCTFail("Auth flow failed")
            }
            expect.fulfill()
        }
        
        waitForExpectations(timeout: 30) { (error) in
            XCTAssertNil(error, String(describing: error))
        }
    }
    
    func testAuthUnauth() {
        let expect = expectation(description: "AuthInfo + Auth + Logout")
        let liveApi = PMAPIService(doh: LiveDoHMail.default, sessionUID: ObfuscatedConstants.testSessionId)
        let liveService = AnonymousServiceManager()
        liveApi.serviceDelegate = liveService
        let manager = Authenticator(api: liveApi)
        let anonymousAuth = AnonymousAuthManager()
        liveApi.authDelegate = anonymousAuth
        manager.authenticate(username: TestUser.liveTestUser.username, password: TestUser.liveTestUser.password) { result in
            switch result {
            case .failure:
                XCTFail("Auth flow failed")
                expect.fulfill()
            case .success(let stage) :
                guard case Authenticator.Status.newCredential(let firstCredential, _) = stage else {
                    XCTFail("No credential in auth flow")
                    return expect.fulfill()
                }
                anonymousAuth.authCredential = AuthCredential(firstCredential)
                manager.closeSession(firstCredential) { result2 in
                    switch result2 {
                    case .success(let response):
                        XCTAssertEqual(response.code, 1000)
                        XCTAssert(true)
                    case .failure: XCTFail("Auth flow failed")
                    }
                    expect.fulfill()
                }
            }
        }
        waitForExpectations(timeout: 30) { (error) in
            XCTAssertNil(error, String(describing: error))
        }
    }
    
    func testAuth2FA() {
        let expect = expectation(description: "AuthInfo + Auth + 2FA")
        let liveApi = PMAPIService(doh: LiveDoHMail.default, sessionUID: ObfuscatedConstants.testSessionId)
        let liveService = AnonymousServiceManager()
        liveApi.serviceDelegate = liveService
        let manager = Authenticator(api: liveApi)
        let anonymousAuth = AnonymousAuthManager()
        liveApi.authDelegate = anonymousAuth
        manager.authenticate(username: TestUser.liveTest2FAUser.username, password: TestUser.liveTest2FAUser.password) { result in
            switch result {
            case .success(let stage):
                guard case Authenticator.Status.ask2FA(let context) = stage else {
                    XCTFail("Auth flow did not ask 2FA")
                    return expect.fulfill()
                }
                anonymousAuth.authCredential = AuthCredential(context.credential)
                manager.confirm2FA("111111", context: context) { result in
                    defer { expect.fulfill() }
                    guard case Result.failure(let serverError) = result,
                        case Authenticator.Errors.serverError(let errorResponse) = serverError else
                    {
                        return XCTFail("Fake 2FA code was accepted by server?")
                    }
                    
                    // "Incorrect login credentials. Please try again" - because 2FA code is wrong
                    XCTAssertEqual(errorResponse.code, 8002)
                }
                
            case .failure:
                XCTFail("Auth flow failed")
                expect.fulfill()
            }
        }
        waitForExpectations(timeout: 60) { (error) in
            XCTAssertNil(error, String(describing: error))
        }
    }
    
    func testAuthRefresh() {
        let expect = expectation(description: "AuthInfo + Auth + Refresh")
        let liveApi = PMAPIService(doh: LiveDoHMail.default, sessionUID: ObfuscatedConstants.testSessionId)
        let liveService = AnonymousServiceManager()
        liveApi.serviceDelegate = liveService
        let manager = Authenticator(api: liveApi)
        let anonymousAuth = AnonymousAuthManager()
        liveApi.authDelegate = anonymousAuth
        manager.authenticate(username: TestUser.liveTestUser.username, password: TestUser.liveTestUser.password) { result in
            switch result {
            case .success(let stage):
                guard case Authenticator.Status.newCredential(let firstCredential, _) = stage else {
                    XCTFail("No credential in auth flow")
                    return expect.fulfill()
                }
                anonymousAuth.authCredential = AuthCredential(firstCredential)
                manager.refreshCredential(firstCredential) { result in
                    defer { expect.fulfill() }
                    guard case Result.success(let stage) = result,
                        case Authenticator.Status.updatedCredential(let updatedCredential) = stage else
                    {
                        return XCTFail("Failed to refresh auth credential")
                    }
                    XCTAssertEqual(updatedCredential.UID, firstCredential.UID)
                    XCTAssertNotEqual(updatedCredential.accessToken, firstCredential.accessToken)
                    XCTAssertNotEqual(updatedCredential.refreshToken, firstCredential.refreshToken)
                    XCTAssertNotEqual(updatedCredential.expiration, firstCredential.expiration)
                }
                
            case .failure:
                XCTFail("Auth flow failed")
                expect.fulfill()
            }
        }
        waitForExpectations(timeout: 30) { (error) in
            XCTAssertNil(error, String(describing: error))
        }
    }
    
    func testUserInfo() {
        let expect = expectation(description: "AuthInfo + Auth + UserInfo")
        let liveApi = PMAPIService(doh: LiveDoHMail.default, sessionUID: ObfuscatedConstants.testSessionId)
        let liveService = AnonymousServiceManager()
        liveApi.serviceDelegate = liveService
        let manager = Authenticator(api: liveApi)
        let anonymousAuth = AnonymousAuthManager()
        liveApi.authDelegate = anonymousAuth
        manager.authenticate(username: TestUser.liveTestUser.username, password: TestUser.liveTestUser.password) { result in
            switch result {
            case .success(let stage):
                guard case Authenticator.Status.newCredential(let firstCredential, _) = stage else {
                    XCTFail("No credential in auth flow")
                    return expect.fulfill()
                }
                anonymousAuth.authCredential = AuthCredential(firstCredential)
                manager.getUserInfo() { result in
                    switch result {
                    case .failure(let error):
                        XCTFail(error.localizedDescription)
                    case .success(let userInfo):
                        XCTAssertEqual(userInfo.email, "\(TestUser.liveTestUser.username)@\(LiveDoHMail.default.signupDomain)")
                    }
                    
                    expect.fulfill()
                }
                
            case .failure:
                XCTFail("Auth flow failed")
                expect.fulfill()
            }
        }
        waitForExpectations(timeout: 30) { (error) in
            XCTAssertNil(error, String(describing: error))
        }
    }

    func testUserInfoAndAddressForExternalAccount() {
        let devApi = PMAPIService(doh: DevDoHMail.default, sessionUID: ObfuscatedConstants.testSessionId)
        let devService = AnonymousServiceManager()
        devApi.serviceDelegate = devService
        let manager = Authenticator(api: devApi)
        let anonymousAuth = AnonymousAuthManager()
        devApi.authDelegate = anonymousAuth
        let expect = expectation(description: "AuthInfo + Auth + Addresses")
        
        manager.authenticate(username: TestUser.externalTestUser.username, password: TestUser.externalTestUser.password) { result in
            switch result {
            case .success(let stage):
                guard case Authenticator.Status.newCredential(let firstCredential, _) = stage else {
                    XCTFail("No credential in auth flow")
                    return expect.fulfill()
                }
                anonymousAuth.authCredential = AuthCredential(firstCredential)
                manager.getUserInfo() { result in
                    switch result {
                    case .failure(let error):
                        XCTFail(error.localizedDescription)
                        expect.fulfill()
                    case .success(let userInfo):
                        XCTAssertEqual(userInfo.email, TestUser.externalTestUser.username)
                        manager.getAddresses() { result in
                            switch result {
                            case let .failure(error):
                                XCTFail(error.localizedDescription)
                            case let .success(addresses):
                                XCTAssertEqual(addresses.count, 1)
                            }
                            expect.fulfill()
                        }
                    }
                }
            case .failure:
                XCTFail("Auth flow failed")
                expect.fulfill()
            }
        }
        
        waitForExpectations(timeout: 30) { (error) in
            XCTAssertNil(error, String(describing: error))
        }
    }
    
    func testAddresses() {
        let expect = expectation(description: "AuthInfo + Auth + Addresses")
        let liveApi = PMAPIService(doh: LiveDoHMail.default, sessionUID: ObfuscatedConstants.testSessionId)
        let liveService = AnonymousServiceManager()
        liveApi.serviceDelegate = liveService
        let manager = Authenticator(api: liveApi)
        let anonymousAuth = AnonymousAuthManager()
        liveApi.authDelegate = anonymousAuth
        manager.authenticate(username: TestUser.liveTestUser.username, password: TestUser.liveTestUser.password) { result in
            switch result {
            case .success(let stage):
                guard case Authenticator.Status.newCredential(let firstCredential, _) = stage else {
                    XCTFail("No credential in auth flow")
                    return expect.fulfill()
                }
                anonymousAuth.authCredential = AuthCredential(firstCredential)
                manager.getAddresses() { result in
                    switch result {
                    case .failure(let error):
                        XCTFail(error.localizedDescription)
                    case .success(let addresses):
                        XCTAssertFalse(addresses.isEmpty)
                        XCTAssertEqual(addresses.first!.email, "\(TestUser.liveTestUser.username)@\(LiveDoHMail.default.signupDomain)")
                    }
                    
                    expect.fulfill()
                }
                
            case .failure:
                XCTFail("Auth flow failed")
                expect.fulfill()
            }
        }
        
        waitForExpectations(timeout: 30) { (error) in
            XCTAssertNil(error, String(describing: error))
        }
    }
    
    func testKeySalts() {
        let expect = expectation(description: "AuthInfo + Auth + KeySalts")
        let liveApi = PMAPIService(doh: LiveDoHMail.default, sessionUID: ObfuscatedConstants.testSessionId)
        let liveService = AnonymousServiceManager()
        liveApi.serviceDelegate = liveService
        let manager = Authenticator(api: liveApi)
        let anonymousAuth = AnonymousAuthManager()
        liveApi.authDelegate = anonymousAuth
        manager.authenticate(username: TestUser.liveTestUser.username, password: TestUser.liveTestUser.password) { result in
            switch result {
            case .success(let stage):
                guard case Authenticator.Status.newCredential(let firstCredential, _) = stage else {
                    XCTFail("No credential in auth flow")
                    return expect.fulfill()
                }
                anonymousAuth.authCredential = AuthCredential(firstCredential)
                manager.getKeySalts() { result in
                    switch result {
                    case .failure(let error):
                        XCTFail(error.localizedDescription)
                    case .success(let salts):
                        XCTAssertFalse(salts.isEmpty)
                    }
                    
                    expect.fulfill()
                }
            case .failure:
                XCTFail("Auth flow failed")
                expect.fulfill()
            }
        }
        
        waitForExpectations(timeout: 30) { (error) in
            XCTAssertNil(error, String(describing: error))
        }
    }
    
    func testCodingKeys() {
        let json = """
        {
            "Code": 1000,
            "AccessToken": "AccessToken",
            "ExpiresIn": 864000,
            "TokenType": "Bearer",
            "Scope": "self",
            "Uid": "Uid",
            "UID": "UID",
            "UserID": "UserID",
            "RefreshToken": "RefreshToken",
            "EventID": "EventID",
            "PasswordMode": 1,
            "ServerProof": "ServerProof",
            "TwoFactor": 1,
            "2FA": {
                "Enabled": 1,
                "U2F": null,
                "TOTP": 1
            }
        }
        """
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .decapitaliseFirstLetter
        do {
            let auth = try decoder.decode(AuthService.AuthRouteResponse.self, from: json.data(using: .utf8)!)
            XCTAssertEqual(auth._2FA.enabled, .on)
            XCTAssertEqual(auth.UID, "UID")
            XCTAssertEqual(auth.eventID, "EventID")
        } catch let error {
            XCTFail(error.localizedDescription)
        }
    }

    func testUsernameUnavailable() {
        let blueApi = PMAPIService(doh: TestDoHMail.default, sessionUID: ObfuscatedConstants.testSessionId)
        let manager = Authenticator(api: blueApi)
        let anonymousService = AnonymousServiceManager()
        blueApi.serviceDelegate = anonymousService
        let expect = expectation(description: "UserAvailable")
        manager.checkAvailable(ObfuscatedConstants.existingUsername) { result in
            switch result {
            case let .failure(error):
                let authError = error as NSError
                XCTAssertEqual(authError.code, 12106)
            case .success:
               XCTFail("Unavailable username check should fail")
            }
            expect.fulfill()
        }
        
        waitForExpectations(timeout: 30) { (error) in
            XCTAssertNil(error, String(describing: error))
        }
    }

    func testUsernameAvailable() {
        let liveApi = PMAPIService(doh: LiveDoHMail.default, sessionUID: ObfuscatedConstants.testSessionId)
        let liveService = AnonymousServiceManager()
        liveApi.serviceDelegate = liveService
        let manager = Authenticator(api: liveApi)
        let anonymousAuth = AnonymousAuthManager()
        liveApi.authDelegate = anonymousAuth
        let expect = expectation(description: "UserAvailable")

        manager.checkAvailable(ObfuscatedConstants.nonExistingUsername) { result in
            switch result {
            case let .failure(error):
                XCTFail(error.localizedDescription)
            case .success:
                break
            }
            expect.fulfill()
        }

        waitForExpectations(timeout: 30) { (error) in
            XCTAssertNil(error, String(describing: error))
        }
    }

    func testGettingRandomModulus() {
        let liveApi = PMAPIService(doh: LiveDoHMail.default, sessionUID: ObfuscatedConstants.testSessionId)
        let liveService = AnonymousServiceManager()
        liveApi.serviceDelegate = liveService
        let manager = Authenticator(api: liveApi)
        let anonymousAuth = AnonymousAuthManager()
        liveApi.authDelegate = anonymousAuth
        let expect = expectation(description: "Modulus")

        manager.getRandomSRPModulus { result in
            switch result {
            case let .failure(error):
                XCTFail(error.localizedDescription)
            case let .success(response):
                XCTAssertFalse(response.modulus.isEmpty)
                XCTAssertFalse(response.modulusID.isEmpty)
            }
            expect.fulfill()
        }

        waitForExpectations(timeout: 30) { (error) in
            XCTAssertNil(error, String(describing: error))
        }
    }

    func testWrong2FA() {
        let liveApi = PMAPIService(doh: LiveDoHMail.default, sessionUID: ObfuscatedConstants.testSessionId)
        let liveService = AnonymousServiceManager()
        liveApi.serviceDelegate = liveService
        let manager = Authenticator(api: liveApi)
        let anonymousAuth = AnonymousAuthManager()
        liveApi.authDelegate = anonymousAuth
        let expect = expectation(description: "testWrong2FA")

        manager.authenticate(username: TestUser.liveTest2FAUser.username, password: TestUser.liveTest2FAUser.password) { result in
            switch result {
            case let .failure(error):
                XCTFail(error.localizedDescription)
                expect.fulfill()
            case let .success(status):
                switch status {
                case .updatedCredential, .newCredential :
                    XCTFail()
                    expect.fulfill()
                case let .ask2FA(context):
                    manager.confirm2FA("555656565655656", context: context) { result in
                        switch result {
                        case .success:
                            XCTFail()
                            expect.fulfill()
                        case let .failure(error):
                            guard case Authenticator.Errors.serverError(let errorResponse) = error else {
                                XCTFail()
                                expect.fulfill()
                                return
                            }
                            XCTAssertEqual(errorResponse.code, 8002)
                            expect.fulfill()
                        }
                    }
                }
            }
        }

        waitForExpectations(timeout: 30) { (error) in
            XCTAssertNil(error, String(describing: error))
        }
    }
}
