// Copyright (c) 2025 Proton Technologies AG
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

@testable import InboxRSVP
import InboxTesting
import InboxSnapshotTesting
import SnapshotTesting
import SwiftUI
import Testing

@MainActor
@Suite(.calendarZurichEnUS, .calendarGMTEnUS, .currentDate(.fixture("2025-07-25 12:00:00")))
final class RSVPEventViewSnapshotTests {
    @Test(arguments: RsvpEventDetails.allCases)
    func testRSVP(testCase: (eventDetails: RsvpEventDetails, testName: String, isExpanded: Bool)) {
        let view = RSVPEventView(
            eventDetails: testCase.eventDetails,
            areParticipantsExpanded: testCase.isExpanded,
        )

        assertSnapshots(
            matching: UIHostingController(rootView: view),
            on: [("SE", .iPhoneSe), ("13 Pro Max", .iPhone13ProMax)],
            testName: testCase.testName
        )
    }
}

private extension RsvpEventDetails {
    static let allCases: [(event: Self, testName: String, isExpanded: Bool)] = [
        (answerablePendingOptional, "answerable_future_optional_attendance", false),
        (answerableOngoingUnanswered, "answerable_now_unanswered_required_attendance", false),
        (answerableOngoingYes, "answerable_now_yes_required_attendance", false),
        (answerableOngoingMaybe, "answerable_now_maybe_required_attendance", false),
        (answerableOngoingNo, "answerable_now_no_required_attendance", false),
        (answerableEnded, "answerable_ended_required_attendance", false),
        (answerableRecurrentOngoing, "answerable_recurrent_now_required_attendace", true),
        (unanswerableOutdated, "unanswerable_outdated", false),
        (unanswerableUnknown, "unanswerable_offline", false),
        (cancelled, "cancelled", false),
        (cancelledOutdated, "cancelled_outdated", true),
        (reminderPending, "reminder_future", false),
        (reminderOngoing, "reminder_now", false),
        (reminderEnded, "reminder_ended", false),
        (reminderInviteCancelled, "reminder_invitation_cancelled", false),
        (veryLongValues, "very_long_values", false),
    ]

    static let answerablePendingOptional = RsvpEventDetails.testData(
        data: .partDayZeroDuration,
        state: .answerableInvite(progress: .pending, attendance: .optional)
    )

    static let answerableOngoingUnanswered = RsvpEventDetails.testData(
        data: .partDayWithDuration(userStatus: .unanswered),
        state: .answerableInvite(progress: .ongoing, attendance: .required)
    )

    static let answerableOngoingYes = RsvpEventDetails.testData(
        data: .partDayWithDuration(userStatus: .yes),
        state: .answerableInvite(progress: .ongoing, attendance: .required)
    )

    static let answerableOngoingMaybe = RsvpEventDetails.testData(
        data: .partDayWithDuration(userStatus: .maybe),
        state: .answerableInvite(progress: .ongoing, attendance: .required)
    )

    static let answerableOngoingNo = RsvpEventDetails.testData(
        data: .partDayWithDuration(title: .none, userStatus: .no),
        state: .answerableInvite(progress: .ongoing, attendance: .required)
    )

    static let answerableEnded = RsvpEventDetails.testData(
        data: .partDayZeroDuration,
        state: .answerableInvite(progress: .ended, attendance: .required)
    )

    static let answerableRecurrentOngoing = RsvpEventDetails.testData(
        data: .recurrent,
        state: .answerableInvite(progress: .ongoing, attendance: .required)
    )

    static let unanswerableOutdated = RsvpEventDetails.testData(
        data: .recurrent,
        state: .unanswerableInvite(.inviteIsOutdated)
    )

    static let unanswerableUnknown = RsvpEventDetails.testData(
        data: .fullDaySingle,
        state: .unanswerableInvite(.inviteHasUnknownRecency)
    )

    static let cancelled = RsvpEventDetails.testData(
        data: .fullDayMulti,
        state: .cancelledInvite(isOutdated: false)
    )

    static let cancelledOutdated = RsvpEventDetails.testData(
        data: .recurrent,
        state: .cancelledInvite(isOutdated: true)
    )

    static let reminderPending = RsvpEventDetails.testData(
        data: .partDayWithDuration(),
        state: .reminder(.pending)
    )

    static let reminderOngoing = RsvpEventDetails.testData(
        data: .partDayWithDuration(),
        state: .reminder(.ongoing)
    )

    static let reminderEnded = RsvpEventDetails.testData(
        data: .partDayWithDuration(),
        state: .reminder(.ended)
    )

    static let reminderInviteCancelled = RsvpEventDetails.testData(
        data: .recurrent,
        state: .cancelledReminder
    )

    static let veryLongValues = RsvpEventDetails.testData(
        data: .veryLongValues,
        state: .cancelledReminder
    )

    static func testData(data: EventData, state: RsvpState) -> RsvpEventDetails {
        .init(
            summary: data.summary,
            location: data.location,
            description: data.description,
            recurrence: data.recurrence,
            startsAt: data.startsAt,
            endsAt: data.endsAt,
            occurrence: data.occurrence,
            organizer: data.organizer,
            attendees: data.attendees,
            userAttendeeIdx: data.userAttendeeIdx,
            calendar: data.calendar,
            state: state
        )
    }
}

private struct EventData {
    public let summary: String?
    public let location: String?
    public let description: String?
    public let recurrence: String?
    public let startsAt: UnixTimestamp
    public let endsAt: UnixTimestamp
    public let occurrence: RsvpOccurrence
    public let organizer: RsvpOrganizer
    public let attendees: [RsvpAttendee]
    public let userAttendeeIdx: UInt32
    public let calendar: RsvpCalendar?
}

private extension EventData {
    static let partDayZeroDuration: EventData = {
        let eventTime = Date.fixture("2025-07-24 14:00:00").timeIntervalSince1970

        return EventData(
            summary: "Quick Sync",
            location: "Huddle Room",
            description: "A brief check-in.",
            recurrence: nil,
            startsAt: UInt64(eventTime),
            endsAt: UInt64(eventTime),
            occurrence: .dateTime,
            organizer: RsvpOrganizer(email: "organizer1@example.com"),
            attendees: [RsvpAttendee(email: "user@example.com", status: .yes)],
            userAttendeeIdx: 0,
            calendar: RsvpCalendar(name: "Personal", color: "#F5A623")
        )
    }()

    static func partDayWithDuration(
        title: String? = "Design Review",
        userStatus: RsvpAttendeeStatus = .unanswered
    ) -> EventData {
        let startTime = Date.fixture("2025-07-24 08:00:00").timeIntervalSince1970
        let endTime = Date.fixture("2025-07-24 09:30:00").timeIntervalSince1970

        return EventData(
            summary: title,
            location: "Virtual Meeting",
            description: "Reviewing the new UI mockups.",
            recurrence: nil,
            startsAt: UInt64(startTime),
            endsAt: UInt64(endTime),
            occurrence: .dateTime,
            organizer: RsvpOrganizer(email: "organizer2@example.com"),
            attendees: [
                RsvpAttendee(email: "user@example.com", status: userStatus),
                RsvpAttendee(email: "designer@example.com", status: .yes),
            ],
            userAttendeeIdx: 0,
            calendar: RsvpCalendar(name: "Design Team", color: "#BD10E0")
        )
    }

    static let fullDaySingle: EventData = {
        let eventDate = Date.fixture("2025-07-24 00:00:00").timeIntervalSince1970

        return EventData(
            summary: "Company Offsite",
            location: "Zürich Lake",
            description: "Annual company-wide offsite event.",
            recurrence: nil,
            startsAt: UInt64(eventDate),
            endsAt: UInt64(eventDate),
            occurrence: .date,
            organizer: RsvpOrganizer(email: "hr@example.com"),
            attendees: [RsvpAttendee(email: "user@example.com", status: .unanswered)],
            userAttendeeIdx: 0,
            calendar: RsvpCalendar(name: "Company Events", color: "#D0021B")
        )
    }()

    static let fullDayMulti: EventData = {
        let startDate = Date.fixture("2025-07-27 00:00:00").timeIntervalSince1970
        let endDate = Date.fixture("2025-07-29 00:00:00").timeIntervalSince1970

        return EventData(
            summary: "Developer Conference",
            location: "Berlin, Germany",
            description: "A conference for mobile developers.",
            recurrence: nil,
            startsAt: UInt64(startDate),
            endsAt: UInt64(endDate),
            occurrence: .date,
            organizer: RsvpOrganizer(email: "conference@example.com"),
            attendees: [RsvpAttendee(email: "user@example.com", status: .unanswered)],
            userAttendeeIdx: 0,
            calendar: RsvpCalendar(name: "Travel", color: "#7ED321")
        )
    }()

    static let recurrent: EventData = {
        let startDate = Date.fixture("2025-07-28 12:00:00").timeIntervalSince1970
        let endDate = Date.fixture("2025-07-28 12:30:00").timeIntervalSince1970

        return EventData(
            summary: "Weekly Team Sync",
            location: "Conference Room B",
            description: "Weekly sync meeting.",
            recurrence: "Weekly on Monday",
            startsAt: UInt64(startDate),
            endsAt: UInt64(endDate),
            occurrence: .dateTime,
            organizer: RsvpOrganizer(email: "teamlead@example.com"),
            attendees: [
                RsvpAttendee(email: "user@example.com", status: .yes),
                RsvpAttendee(email: "teammate1@example.com", status: .maybe),
                RsvpAttendee(email: "johny@pm.me", status: .no),
            ],
            userAttendeeIdx: 0,
            calendar: RsvpCalendar(name: "Team Calendar", color: "#50E3C2")
        )
    }()

    static let veryLongValues: EventData = {
        let eventTime = Date.fixture("2025-08-01 07:00:00").timeIntervalSince1970

        return EventData(
            summary:
                "This is an extremely long summary for an event designed to test the user interface's ability to handle and truncate very long text fields without breaking the layout or causing visual glitches. It just keeps going and going.",
            location:
                "A Very Long Location Name Spanning Multiple Lines, Including Details like The Grand Ballroom at the International Convention and Exhibition Centre, 1234 Longest Street Name in the World Avenue, Suite 9876, Megalopolis, Earth",
            description:
                "This description field is also exceptionally long to ensure that multi-line text wrapping, truncation with ellipses, and 'show more' functionality can be properly tested across all device sizes and orientations. Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.",
            recurrence: "FREQ=DAILY;INTERVAL=2;COUNT=10;BYDAY=MO,TU,WE,TH,FR;BYHOUR=8,12,17;BYMINUTE=0,15,30,45;BYSECOND=0;WKST=SU",
            startsAt: UInt64(eventTime),
            endsAt: UInt64(eventTime + 3600),
            occurrence: .dateTime,
            organizer: RsvpOrganizer(email: "a.very.long.and.descriptive.email.address.for.the.organizer@international.corporate.events.and.planning.department.com"),
            attendees: [
                RsvpAttendee(email: "a.very.long.email.address.for.an.attendee.to.test.wrapping@example.com", status: .yes),
                RsvpAttendee(email: "another.super.long.attendee.email.just.for.good.measure@example.com", status: .maybe),
            ],
            userAttendeeIdx: 0,
            calendar: RsvpCalendar(name: "Calendar for Extremely Long and Verbose Project Names and Initiatives", color: "#FF00FF")
        )
    }()
}
