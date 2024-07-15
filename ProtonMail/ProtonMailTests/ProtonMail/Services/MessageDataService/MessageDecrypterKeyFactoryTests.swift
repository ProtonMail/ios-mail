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

import ProtonCoreDataModel
import ProtonCoreTestingToolkitUnitTestsServices
import XCTest

@testable import ProtonMail

final class MessageDecrypterKeyFactoryTests: XCTestCase {
    private var mockUserData: UserManager!
    private var sut: MessageDecrypterKeyFactory!

    override func setUpWithError() throws {
        try super.setUpWithError()

        mockUserData = UserManager(api: APIServiceMock(), role: .member)
        sut = MessageDecrypterKeyFactory(userDataSource: mockUserData)
    }

    override func tearDownWithError() throws {
        mockUserData = nil
        sut = nil

        try super.tearDownWithError()
    }

    func testGetAddressKeys_emptyAddressID() {
        let key1 = Key(keyID: "key1", privateKey: KeyTestData.privateKey1)
        let key2 = Key(keyID: "key2", privateKey: KeyTestData.privateKey2)
        let address = Address(addressID: "aaa", domainID: nil, email: "test@abc.com", send: .active, receive: .active, status: .enabled, type: .protonAlias, order: 1, displayName: "", signature: "", hasKeys: 2, keys: [key1, key2])

        self.mockUserData.userInfo.userAddresses = [address]
        let keys = sut.getAddressKeys(for: "")
        XCTAssertEqual(keys.count, 2)
        XCTAssertEqual(keys[0].keyID, "key1")
        XCTAssertEqual(keys[1].keyID, "key2")
    }

    func testGetAddressKeys_hasAddressID() {
        let key1 = Key(keyID: "key1", privateKey: KeyTestData.privateKey1)
        let key2 = Key(keyID: "key2", privateKey: KeyTestData.privateKey2)
        let address = Address(addressID: "address", domainID: nil, email: "test@abc.com", send: .active, receive: .active, status: .enabled, type: .protonAlias, order: 1, displayName: "", signature: "", hasKeys: 1, keys: [key1])
        let address2 = Address(addressID: "address2", domainID: nil, email: "test2@abc.com", send: .active, receive: .active, status: .enabled, type: .protonAlias, order: 1, displayName: "", signature: "", hasKeys: 1, keys: [key2])

        self.mockUserData.userInfo.userAddresses = [address, address2]
        var keys = sut.getAddressKeys(for: "address")
        XCTAssertEqual(keys.count, 1)
        XCTAssertEqual(keys[0].keyID, "key1")
        keys = sut.getAddressKeys(for: "address2")
        XCTAssertEqual(keys.count, 1)
        XCTAssertEqual(keys[0].keyID, "key2")
    }

}
