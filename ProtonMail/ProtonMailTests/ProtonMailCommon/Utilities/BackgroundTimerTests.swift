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

final class BackgroundTimerTest: XCTestCase {
    var sut: BackgroundTimer!
    var userDefaults: UserDefaults!

    override func setUp() {
        super.setUp()
        userDefaults = UserDefaults(suiteName: #fileID)
        sut = BackgroundTimer(userDefaults: userDefaults)
    }

    override func tearDown() {
        super.tearDown()
        userDefaults.removePersistentDomain(forName: #fileID)
        userDefaults = nil
        sut = nil
    }

    func testShouldReturnFalseWhenNotSet() {
        XCTAssertFalse(sut.wasInBackgroundForMoreThanOneHour)
    }

    func testDateLessThanOneHourShouldReturnFalse() {
        sut.willEnterBackgroundOrTerminate(date: Date())
        XCTAssertFalse(sut.wasInBackgroundForMoreThanOneHour)
    }

    func testDateEqualToOneHourShouldReturnTrue() {
        sut.willEnterBackgroundOrTerminate(date: Date().addingTimeInterval(-3600))
        XCTAssertTrue(sut.wasInBackgroundForMoreThanOneHour)
    }

    func testDateMoreThanOneHourShouldReturnTrue() {
        sut.willEnterBackgroundOrTerminate(date: Date().addingTimeInterval(-7200))
        XCTAssertTrue(sut.wasInBackgroundForMoreThanOneHour)
    }
}
