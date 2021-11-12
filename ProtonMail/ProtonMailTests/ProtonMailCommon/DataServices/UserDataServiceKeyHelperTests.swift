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

import XCTest
@testable import ProtonMail
import ProtonCore_DataModel

class UserDataServiceKeyHelperTests: XCTestCase {

    var sut: UserDataServiceKeyHelper!
    override func setUp() {
        super.setUp()
        sut = UserDataServiceKeyHelper()
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
    }

    func testUpdatePasswordV2_withOneActiveKey() throws {
        let testKey = Key(keyID: "123", privateKey: KeyTestData.privateKey1.rawValue)
        let newPWD = "new"
        let result = try sut.updatePasswordV2(userKeys: [testKey], oldPassword: KeyTestData.passphrash1.rawValue, newPassword: newPWD)

        XCTAssertTrue(result.originalUserKeys.isEmpty)
        XCTAssertEqual(result.updatedUserKeys.count, 1)
        XCTAssertFalse(result.hashedNewPassword.isEmpty)
        XCTAssertEqual(result.saltOfNewPassword.dataSize, 16) // 16 bytes

        let updatedKey = try XCTUnwrap(result.updatedUserKeys.first)
        XCTAssertTrue(updatedKey.privateKey.check(passphrase: result.hashedNewPassword))
    }

    func testUpdatePasswordV2_withOneActiveKeyAndOneInactiveKey() throws {
        let activeKey = Key(keyID: "1", privateKey: KeyTestData.privateKey1.rawValue)
        let inactiveKey = Key(keyID: "2", privateKey: KeyTestData.privateKey2.rawValue)
        let newPWD = "new"

        let result = try sut.updatePasswordV2(userKeys: [activeKey, inactiveKey], oldPassword: KeyTestData.passphrash1.rawValue, newPassword: newPWD)

        XCTAssertEqual(result.originalUserKeys.count, 1)
        XCTAssertEqual(result.updatedUserKeys.count, 1)
        XCTAssertFalse(result.hashedNewPassword.isEmpty)
        XCTAssertEqual(result.saltOfNewPassword.dataSize, 16)

        let updatedKey = try XCTUnwrap(result.updatedUserKeys.first)
        XCTAssertTrue(updatedKey.privateKey.check(passphrase: result.hashedNewPassword))

        let originalKey = try XCTUnwrap(result.originalUserKeys.first)
        XCTAssertFalse(originalKey.privateKey.check(passphrase: result.hashedNewPassword))
        XCTAssertTrue(originalKey.privateKey.check(passphrase: KeyTestData.passphrash2.rawValue))
    }

    func testUpdatePassword() throws {
        let activeKey = Key(keyID: "1", privateKey: KeyTestData.privateKey1.rawValue)
        let testAddressKey = Key(keyID: "key",
                                 privateKey: KeyTestData.privateKey11.rawValue)
        let testAddress = Address(addressID: "id",
                                  domainID: nil,
                                  email: "test@test.com",
                                  send: .active,
                                  receive: .active,
                                  status: .enabled,
                                  type: .externalAddress,
                                  order: 0,
                                  displayName: "",
                                  signature: "",
                                  hasKeys: 1,
                                  keys: [testAddressKey])
        let newPWD = "new"
        let result = try sut.updatePassword(userKeys: [activeKey],
                                        addressKeys: [testAddress],
                                        oldPassword: KeyTestData.passphrash1.rawValue,
                                        newPassword: newPWD)
        XCTAssertEqual(result.updatedUserKeys.count, 1)
        XCTAssertTrue(result.originalUserKeys.isEmpty)
        XCTAssertEqual(result.updatedAddresses?.count, 1)

        let updatedKey = try XCTUnwrap(result.updatedUserKeys.first)
        XCTAssertTrue(updatedKey.privateKey.check(passphrase: result.hashedNewPassword))

        let address = try XCTUnwrap(result.updatedAddresses?.first)
        let addressKey = try XCTUnwrap(address.keys.first?.privateKey)
        XCTAssertTrue(addressKey.check(passphrase: result.hashedNewPassword))
    }
}
