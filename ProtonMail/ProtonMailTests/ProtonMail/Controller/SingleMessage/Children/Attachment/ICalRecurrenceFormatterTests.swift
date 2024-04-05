// Copyright (c) 2024 Proton Technologies AG
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

import ProtonInboxICal
import XCTest

@testable import ProtonMail

final class ICalRecurrenceFormatterTests: XCTestCase {
    private var sut: ICalRecurrenceFormatter!

    private let startDate = Date.fixture("2024-04-06 00:00:00")
    private let endDate = Date.fixture("2025-09-27 00:00:00")

    override func setUp() {
        super.setUp()

        sut = .init()
    }

    override func tearDown() {
        sut = nil

        super.tearDown()
    }

    func testDoesntRepeat() {
        let recurrence = ICalRecurrence(doesRepeat: false)
        let localizedDescription = sut.string(from: recurrence, startDate: startDate)
        XCTAssertNil(localizedDescription)
    }

    func testDaily() {
        let recurrence = ICalRecurrence(doesRepeat: true, repeatEveryType: .day, repeatEvery: 1)
        let localizedDescription = sut.string(from: recurrence, startDate: startDate)
        XCTAssertEqual(localizedDescription, "Daily")
    }

    func testEvery3Days() {
        let recurrence = ICalRecurrence(doesRepeat: true, repeatEveryType: .day, repeatEvery: 3)
        let localizedDescription = sut.string(from: recurrence, startDate: startDate)
        XCTAssertEqual(localizedDescription, "Every 3 days")
    }

    func testWeekly() {
        let recurrence = ICalRecurrence(doesRepeat: true, repeatEveryType: .week, repeatEvery: 1, repeatWeekOn: [7])
        let localizedDescription = sut.string(from: recurrence, startDate: startDate)
        XCTAssertEqual(localizedDescription, "Weekly on Saturday")
    }

    func testEvery3Weeks() {
        let recurrence = ICalRecurrence(doesRepeat: true, repeatEveryType: .week, repeatEvery: 3, repeatWeekOn: [5, 7])
        let localizedDescription = sut.string(from: recurrence, startDate: startDate)
        XCTAssertEqual(localizedDescription, "Every 3 weeks on Thursday, Saturday")
    }

    func testMonthly() {
        let recurrence = ICalRecurrence(doesRepeat: true, repeatEveryType: .month, repeatEvery: 1, repeatMonthOnWeekDay: 6)
        let localizedDescription = sut.string(from: recurrence, startDate: startDate)
        XCTAssertEqual(localizedDescription, "Monthly on day 6")
    }

    func testMonthlyWithoutRepeatDaySpecified() {
        let recurrence = ICalRecurrence(doesRepeat: true, repeatEveryType: .month, repeatEvery: 1)
        let localizedDescription = sut.string(from: recurrence, startDate: startDate)
        XCTAssertEqual(localizedDescription, "Monthly on day 6")
    }

    func testEvery3Months() {
        let recurrence = ICalRecurrence(
            doesRepeat: true,
            repeatEveryType: .month,
            repeatEvery: 3,
            repeatMonthOnIth: .first,
            repeatMonthOnWeekDay: 7
        )
        let localizedDescription = sut.string(from: recurrence, startDate: startDate)
        XCTAssertEqual(localizedDescription, "Every 3 months on the first Saturday")
    }

    func testYearly() {
        let recurrence = ICalRecurrence(doesRepeat: true, repeatEveryType: .year, repeatEvery: 1)
        let localizedDescription = sut.string(from: recurrence, startDate: startDate)
        XCTAssertEqual(localizedDescription, "Yearly")
    }

    func testEvery3Years() {
        let recurrence = ICalRecurrence(doesRepeat: true, repeatEveryType: .year, repeatEvery: 3)
        let localizedDescription = sut.string(from: recurrence, startDate: startDate)
        XCTAssertEqual(localizedDescription, "Every 3 years")
    }

    func testEndingOn() {
        let recurrence = ICalRecurrence(
            doesRepeat: true,
            repeatEveryType: .month,
            repeatEvery: 4,
            repeatMonthOnWeekDay: 13,
            endsOnDate: endDate
        )
        let localizedDescription = sut.string(from: recurrence, startDate: startDate)
        XCTAssertEqual(localizedDescription, "Every 4 months on day 13, until Sep 27, 2025")
    }

    func testEndingAfter() {
        let recurrence = ICalRecurrence(
            doesRepeat: true,
            repeatEveryType: .week,
            endsAfterNum: 2,
            repeatEvery: 3,
            repeatWeekOn: [3, 7]
        )
        let localizedDescription = sut.string(from: recurrence, startDate: startDate)
        XCTAssertEqual(localizedDescription, "Every 3 weeks on Tuesday, Saturday, 2 times")
    }
}
