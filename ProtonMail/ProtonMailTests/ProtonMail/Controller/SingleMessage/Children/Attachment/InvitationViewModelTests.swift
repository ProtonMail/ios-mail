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

import ProtonCoreUIFoundations
import XCTest

@testable import ProtonMail

final class InvitationViewModelTests: XCTestCase {
    func testWhenEventStartsAndEndsOverTheCourseOfASingleDay_thenDurationStringDoesNotMentionTheDayTwice() {
        let eventDetails = EventDetails.make(
            startDate: .fixture("2023-11-16 14:30:00"),
            endDate: .fixture("2023-11-16 15:30:00")
        )
        let sut = InvitationViewModel(eventDetails: eventDetails)
        XCTAssertEqual(sut.durationString, "Nov 16, 2023, 2:30 – 3:30 PM")
    }

    func testWhenEventHasNotEndedAndHasNotBeenCancelled_thenTitleColorIsNormAndStatusIsEmpty() {
        let eventDetails = EventDetails.make(endDate: .distantFuture, status: .confirmed)
        let sut = InvitationViewModel(eventDetails: eventDetails)
        XCTAssertNil(sut.statusString)
        XCTAssert(sut.isStatusViewHidden)
        XCTAssertEqual(sut.titleColor, ColorProvider.TextNorm)
    }

    func testWhenEventHasEndedOrHasBeenCancelled_thenTitleColorIsWeakAndStatusIsNotEmpty() {
        let scenarios: [TestScenario] = [
            .init(endDate: .distantPast, status: .confirmed),
            .init(endDate: .distantFuture, status: .cancelled),
            .init(endDate: .distantPast, status: .cancelled),
        ]

        for scenario in scenarios {
            let eventDetails = EventDetails.make(endDate: scenario.endDate, status: scenario.status)
            let sut = InvitationViewModel(eventDetails: eventDetails)
            XCTAssertNotNil(sut.statusString)
            XCTAssertFalse(sut.isStatusViewHidden)
            XCTAssertEqual(sut.titleColor, ColorProvider.TextWeak)
        }
    }

    func testWhenEventHasEndedButHasNotBeenCancelled_thenAlreadyEndedStatusIsShown() {
        let eventDetails = EventDetails.make(endDate: .distantPast, status: .confirmed)
        let sut = InvitationViewModel(eventDetails: eventDetails)
        XCTAssertEqual(sut.statusString, "This event already ended")
    }

    func testWhenEventHasEndedAndAlsoHasBeenCancelled_thenCancelledStatusHasPriority() {
        let eventDetails = EventDetails.make(endDate: .distantPast, status: .cancelled)
        let sut = InvitationViewModel(eventDetails: eventDetails)
        XCTAssertEqual(sut.statusString, "This event has been cancelled")
    }
}

private struct TestScenario {
    let endDate: Date
    let status: EventDetails.EventStatus
}
