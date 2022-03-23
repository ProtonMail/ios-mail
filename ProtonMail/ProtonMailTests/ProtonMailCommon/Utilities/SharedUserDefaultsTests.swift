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

@testable import ProtonMail
import XCTest

final class UserDefaultsPersistenceMock: TimestampPushPersistable, RegistrationRequiredPersistable {
    var dict: [String: Any] = [:]

    func set(_ value: Any?, forKey defaultName: String) {
        dict[defaultName] = value
    }

    func string(forKey defaultName: String) -> String? {
        dict[defaultName] as? String
    }

    func array(forKey defaultName: String) -> [Any]? {
        dict[defaultName] as? [Any]
    }
}

class SharedUserDefaultsTests: XCTestCase {
    var persistenceMock: UserDefaultsPersistenceMock!
    var sut: SharedUserDefaults!

    override func setUp() {
        super.setUp()
        persistenceMock = UserDefaultsPersistenceMock()
        sut = SharedUserDefaults(timestampPushPersistable: persistenceMock, registrationRequiredPersistable: persistenceMock)
    }

    override func tearDown() {
        super.tearDown()
        persistenceMock = nil
        sut = nil
    }

    func testEmptyShouldReturnUndefined() {
        XCTAssertEqual(sut.lastReceivedPushTimestamp, "Undefined")
    }

    func testSettingShouldDefaultToFalseForAnyUID() {
        XCTAssertFalse(sut.shouldRegisterAgain(for: "dummy"))
    }

    func testSettingShouldSaveUIDToRegisterAgain() {
        let expectedUID = String.randomString(8)
        sut.setNeedsToRegisterAgain(for: expectedUID)
        XCTAssertTrue(sut.shouldRegisterAgain(for: expectedUID))
    }

    func testSettingShouldRemoveUID() {
        let expectedUID = String.randomString(8)
        sut.setNeedsToRegisterAgain(for: expectedUID)
        XCTAssertTrue(sut.shouldRegisterAgain(for: expectedUID))
        sut.didRegister(for: expectedUID)
        XCTAssertFalse(sut.shouldRegisterAgain(for: expectedUID))
    }
}
