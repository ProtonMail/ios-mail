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

@testable import ProtonMail
import XCTest

final class SharedUserDefaultsTests: XCTestCase {
    private var sut: SharedUserDefaults!
    private var mockUserDefaults: UserDefaults!

    override func setUp() {
        super.setUp()
        mockUserDefaults = UserDefaults(suiteName: #fileID)
        mockUserDefaults.removePersistentDomain(forName: #fileID)
        sut = SharedUserDefaults(dependencies: .init(userDefaults: mockUserDefaults))
    }

    override func tearDown() {
        super.tearDown()
        mockUserDefaults.removePersistentDomain(forName: #fileID)
        sut = nil
    }

    func testMarkPushNotificationDecryptionFailure_itShouldSaveTheFlag() {
        sut.markPushNotificationDecryptionFailure()
        XCTAssertTrue(mockUserDefaults.bool(forKey: "failedPushNotificationDecryption"))
    }

    func testHadPushNotificationDecryptionFailed_whenNotMarkedAsFailed_itShouldReturnFalse() {
        XCTAssertFalse(sut.hadPushNotificationDecryptionFailed)
    }

    func testHadPushNotificationDecryptionFailed_whenMarkedAsFailed_itShouldReturnTrue() {
        mockUserDefaults.setValue(true, forKey: "failedPushNotificationDecryption")
        XCTAssertTrue(sut.hadPushNotificationDecryptionFailed)
    }

    func testClearPushNotificationDecryptionFailure_itShouldRemoveFlag() {
        mockUserDefaults.setValue(true, forKey: "failedPushNotificationDecryption")
        sut.clearPushNotificationDecryptionFailure()

        XCTAssertFalse(mockUserDefaults.bool(forKey: "failedPushNotificationDecryption"))
    }
}
