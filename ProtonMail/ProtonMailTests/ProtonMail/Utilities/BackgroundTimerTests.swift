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

final class BackgroundTimerTests: XCTestCase {
    var sut: BackgroundTimer!
    var userDefaults: UserDefaults!

    private let calendar = Calendar.autoupdatingCurrent

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
        XCTAssertFalse(sut.wasInBackgroundLongEnoughForDataToBecomeOutdated)
    }

    func testWhenDateIsNow_thenShouldReturnFalse() {
        sut.willEnterBackgroundOrTerminate(date: Date())
        XCTAssertFalse(sut.wasInBackgroundLongEnoughForDataToBecomeOutdated)
    }

    func testWhen6DaysHavePassed_thenShouldReturnFalse() {
        let lastForegroundDate = calendar.date(byAdding: .day, value: -6, to: .now)
        sut.willEnterBackgroundOrTerminate(date: lastForegroundDate)
        XCTAssertFalse(sut.wasInBackgroundLongEnoughForDataToBecomeOutdated)
    }

    func testWhen7DaysHavePassed_thenShouldReturnTrue() {
        let lastForegroundDate = calendar.date(byAdding: .day, value: -7, to: .now)
        sut.willEnterBackgroundOrTerminate(date: lastForegroundDate)
        XCTAssertTrue(sut.wasInBackgroundLongEnoughForDataToBecomeOutdated)
    }
}
