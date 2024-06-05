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

    func testAllDayEvent_whenIsSingleDay_thenDurationStringDoesNotMentionTheDayTwice() {
        let eventDetails = EventDetails.make(
            startDate: .fixture("2023-11-16 00:00:00"),
            endDate: .fixture("2023-11-17 00:00:00"),
            isAllDay: true
        )
        let sut = InvitationViewModel(eventDetails: eventDetails)
        XCTAssertEqual(sut.durationString, "Nov 16, 2023")
    }

    func testAllDayEvent_whenSpansMultipleDays_thenEndDateIsOneDayEarlier() {
        let eventDetails = EventDetails.make(
            startDate: .fixture("2023-11-16 00:00:00"),
            endDate: .fixture("2023-11-18 00:00:00"),
            isAllDay: true
        )
        let sut = InvitationViewModel(eventDetails: eventDetails)
        XCTAssertEqual(sut.durationString, "Nov 16 – 17, 2023")
    }

    func testWhenUserIsNotAmongInvitees_thenOptionalAttendanceIsNotShown() {
        let eventDetails = EventDetails.make(currentUserAmongInvitees: nil)
        let sut = InvitationViewModel(eventDetails: eventDetails)
        XCTAssert(sut.isOptionalAttendanceLabelHidden)
    }

    func testWhenUserIsARequiredInvitee_thenOptionalAttendanceIsNotShown() {
        let currentUser = EventDetails.Participant(email: "user@example.com", role: .required, status: .unknown)
        let eventDetails = EventDetails.make(invitees: [currentUser], currentUserAmongInvitees: currentUser)
        let sut = InvitationViewModel(eventDetails: eventDetails)
        XCTAssert(sut.isOptionalAttendanceLabelHidden)
    }

    func testWhenUserIsAnOptionalInvitee_thenOptionalAttendanceIsNotShown() {
        let currentUser = EventDetails.Participant(email: "user@example.com", role: .optional, status: .unknown)
        let eventDetails = EventDetails.make(invitees: [currentUser], currentUserAmongInvitees: currentUser)
        let sut = InvitationViewModel(eventDetails: eventDetails)
        XCTAssertFalse(sut.isOptionalAttendanceLabelHidden)
    }

    func testWhenEventHasNotEndedAndHasNotBeenCancelled_thenTitleColorIsNormAndStatusIsEmpty() {
        let eventDetails = EventDetails.make(endDate: .distantFuture, status: .confirmed)
        let sut = InvitationViewModel(eventDetails: eventDetails)
        XCTAssertNil(sut.statusString)
        XCTAssert(sut.isStatusViewHidden)
        XCTAssertEqual(sut.titleColor, ColorProvider.TextNorm)
    }

    func testWhenEventHasEndedOrHasBeenCancelled_thenTitleColorIsWeakAndStatusIsNotEmpty() {
        struct TestScenario {
            let endDate: Date
            let status: EventDetails.EventStatus
        }

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

    func testWhenEventHasEndedButIsRecurring_thenAlreadyEndedStatusIsNotShown() {
        let eventDetails = EventDetails.make(endDate: .distantPast, recurrence: "anything")
        let sut = InvitationViewModel(eventDetails: eventDetails)
        XCTAssertNil(sut.statusString)
    }

    func testWhenThereIsFewInvitees_thenExpansionButtonIsNotNeeded() {
        let eventDetails = EventDetails.make(
            invitees: [.init(email: "attendee@example.com", role: .unknown, status: .unknown)]
        )
        let sut = InvitationViewModel(eventDetails: eventDetails)
        XCTAssertNil(sut.expansionButtonTitle)
    }

    func testWhenThereIsManyInvitees_thenTheyAreOnlyVisibleAfterTogglingExpansion() {
        let eventDetails = EventDetails.make()
        var sut = InvitationViewModel(eventDetails: eventDetails)

        XCTAssertEqual(sut.visibleInvitees, [])
        XCTAssertEqual(sut.expansionButtonTitle, "3 participants")

        sut.toggleParticipantListExpansion()

        XCTAssertEqual(sut.visibleInvitees, eventDetails.invitees)
        XCTAssertEqual(sut.expansionButtonTitle, "Show less")

        sut.toggleParticipantListExpansion()

        XCTAssertEqual(sut.visibleInvitees, [])
        XCTAssertEqual(sut.expansionButtonTitle, "3 participants")
    }

    func testWhenEventHasNoTitle_thenNoTitleStringIsShown() {
        let emptyTitles: [String?] = [nil, ""]

        for emptyTitle in emptyTitles {
            let eventDetails = EventDetails.make(title: emptyTitle)
            let sut = InvitationViewModel(eventDetails: eventDetails)
            XCTAssertEqual(sut.title, "(no title)")
        }
    }
}
