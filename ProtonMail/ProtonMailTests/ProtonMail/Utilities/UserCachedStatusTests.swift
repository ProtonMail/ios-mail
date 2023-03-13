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

@testable import ProtonMail
import XCTest

class UserCachedStatusTests: XCTestCase {
    var userDefaults: UserDefaults!
    var sut: UserCachedStatus!
    var suiteName = String.randomString(10)

    override func setUp() {
        super.setUp()

        userDefaults = .init(suiteName: suiteName)
        sut = .init(userDefaults: userDefaults)
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
        userDefaults.removePersistentDomain(forName: suiteName)
        userDefaults = nil
    }

    func testFetchValueOf_withBool_noValueExists_returnDefaultValue() {
        let userID = UserID(String.randomString(10))
        let key = String.randomString(10)

        XCTAssertFalse(
            sut.fetchValueOf(userID: userID, key: key, defaultValue: false)
        )
    }

    func testFetchValueOf_withInt_noValueExists_returnDefaultValue() {
        let userID = UserID(String.randomString(10))
        let key = String.randomString(10)

        XCTAssertEqual(
            sut.fetchValueOf(userID: userID, key: key, defaultValue: 1000),
            1000
        )
    }

    func testSetValueOf_withInt_dataIsSaved() {
        let userID = UserID(String.randomString(10))
        let key = String.randomString(10)
        let value = 1000

        sut.setValueOf(userID: userID, value: value, key: key)

        let result = userDefaults.object(forKey: key) as? [String: Int]
        XCTAssertEqual(
            result?[userID.rawValue],
            value
        )
    }

    func testSetValueOf_updateExistingValue() {
        let userID = UserID(String.randomString(10))
        let key = String.randomString(10)
        let value = 1000
        let newValue = Int.random(in: Int.min...Int.max)

        sut.setValueOf(userID: userID, value: value, key: key)

        let result = userDefaults.object(forKey: key) as? [String: Int]
        XCTAssertEqual(
            result?[userID.rawValue],
            value
        )

        sut.setValueOf(userID: userID, value: newValue, key: key)

        let result2 = userDefaults.object(forKey: key) as? [String: Int]
        XCTAssertEqual(
            result2?[userID.rawValue],
            newValue
        )
    }
}
