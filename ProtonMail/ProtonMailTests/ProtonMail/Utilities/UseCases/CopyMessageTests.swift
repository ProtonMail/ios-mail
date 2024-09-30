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

import Groot
import ProtonCoreDataModel
import ProtonCoreTestingToolkitUnitTestsServices
import XCTest

@testable import ProtonMail

final class CopyMessageTests: XCTestCase {
    private var sut: CopyMessage!
    private var mockUserData: UserManager!
    private var testContext: NSManagedObjectContext!

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.testContext = MockCoreDataStore.testPersistentContainer.viewContext
        self.mockUserData = UserManager(api: APIServiceMock(), role: .member)
        sut = CopyMessage(
            dependencies: .init(
                contextProvider: MockCoreDataContextProvider(),
                messageDecrypter: mockUserData.messageService.messageDecrypter
            ),
            userDataSource: mockUserData
        )
    }

    override func tearDownWithError() throws {
        self.sut = nil
        self.mockUserData = nil
        self.testContext = nil

        try super.tearDownWithError()
    }

    func testGetFirstAddressKey() {
        let key1 = Key(keyID: "key1", privateKey: KeyTestData.privateKey1)
        let key2 = Key(keyID: "key2", privateKey: KeyTestData.privateKey2)
        let address = Address(addressID: "aaa", domainID: nil, email: "test@abc.com", send: .active, receive: .active, status: .enabled, type: .protonAlias, order: 1, displayName: "", signature: "", hasKeys: 2, keys: [key1, key2])

        self.mockUserData.userInfo.userAddresses = [address]
        var key = sut.getFirstAddressKey(for: nil)
        XCTAssertNil(key)

        key = sut.getFirstAddressKey(for: "aaa")
        XCTAssertEqual(key?.keyID, "key1")
    }

    func testDuplicateMessage() {
        let fakeMessageData = testSentMessageWithToAndCC.parseObjectAny()!
        guard let fakeMsg = try? GRTJSONSerialization.object(withEntityName: "Message", fromJSONDictionary: fakeMessageData, in: testContext) as? Message else {
            XCTFail("The fake data initialize failed")
            return
        }
        let duplicated = sut.duplicate(fakeMsg, context: self.testContext)
        XCTAssertEqual(fakeMsg.toList, duplicated.toList)
        XCTAssertEqual(fakeMsg.title, duplicated.title)
        XCTAssertEqual(fakeMsg.body, duplicated.body)
        XCTAssertNotEqual(fakeMsg.time, duplicated.time)
    }
}

