//
//  KeySetupTests.swift
//  PMAuthenticationTests
//
//  Created by Igor Kulman on 21.12.2020.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

import XCTest
@testable import PMAuthentication
import PMCommon

class KeySetupTests: XCTestCase {
    let addressJson = """
        { "ID": "testId", "email": "test@example.org", "send": 1, "receive": 1, "status": 1, "type": 1, "order": 1, "displayName": "", "signature": "" }
    """
    var testAddress: Address {
        return try! JSONDecoder().decode(Address.self, from: addressJson.data(using: .utf8)!)
    }

    func testAddressKeyGeneration() {
        let keySetup = AddressKeySetup()
        do {
            let key = try keySetup.generateAddressKey(keyName: "Test key", email: "\(TestUser.liveTestUser.username)@\(LiveDoHMail.default.signupDomain)", password: TestUser.liveTestUser.password, salt: Data())
            XCTAssertFalse(key.armoredKey.isEmpty)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testAddressKeyRouteSetup() {
        let keySetup = AddressKeySetup()

        do {
            let key = try keySetup.generateAddressKey(keyName: "Test key", email: "\(TestUser.liveTestUser.username)@\(LiveDoHMail.default.signupDomain)", password: TestUser.liveTestUser.password, salt: Data())
            let route = try keySetup.setupCreateAddressKeyRoute(key: key, modulus: ObfuscatedConstants.modulus, modulusId: ObfuscatedConstants.modulusId, addressId: TestUser.liveTestUser.username, primary: true)
            XCTAssertFalse(route.addressID.isEmpty)
            XCTAssertFalse(route.privateKey.isEmpty)
            XCTAssertEqual(route.primary, true)
            XCTAssertNotNil(route.signedKeyList["Data"])
            XCTAssertNotNil(route.signedKeyList["Signature"])
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testAccountKeyGeneration() {
        let keySetup = AccountKeySetup()
        do {
            let key = try keySetup.generateAccountKey(addresses: [testAddress], password: TestUser.liveTestUser.password)
            XCTAssertFalse(key.addressKeys.isEmpty)
            XCTAssertNotEqual(key.password, TestUser.liveTestUser.password)
            XCTAssertFalse(key.passwordSalt.isEmpty)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testAccountKeyRouteSetup() {
        let keySetup = AccountKeySetup()

        do {
            let key = try keySetup.generateAccountKey(addresses: [testAddress], password: TestUser.liveTestUser.password)
            let route = try keySetup.setupSetupKeysRoute(password: TestUser.liveTestUser.password, key: key, modulus: ObfuscatedConstants.modulus, modulusId: ObfuscatedConstants.modulusId)
            XCTAssertFalse(route.addresses.isEmpty)
            XCTAssertFalse(route.privateKey.isEmpty)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
}
