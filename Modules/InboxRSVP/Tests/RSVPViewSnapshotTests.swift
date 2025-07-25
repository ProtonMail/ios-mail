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
import InboxSnapshotTesting
import SwiftUI
import Testing

@MainActor
final class RSVPViewSnapshotTests {
    @Test(arguments: RsvpEventDetails.allCases)
    func testRSVP(testCase: (event: RsvpEventDetails, testName: String)) {
        assertSnapshotsOnIPhoneX(of: RSVPView(event: testCase.event), testName: testCase.testName)
    }
}

private extension RsvpEventDetails {
    static let allCases: [(event: Self, testName: String)] = [
        (answerablePendingOptional, "answerable_future_optional_attendance"),
        (answerableOngoing, "answerable_now_required_attendance"),
        (answerableEnded, "answerable_ended_required_attendance"),
        (unanswerableOutdated, "unanswerable_outdated"),
        (unanswerableUnknown, "unanswerable_offline"),
        (cancelled, "cancelled"),
        (cancelledOutdated, "cancelled_outdated"),
        (reminderPending, "reminder_future"),
        (reminderOngoing, "reminder_now"),
        (reminderEnded, "reminder_ended"),
        (reminderInviteCancelled, "reminder_invitation_cancelled"),
        (veryLongValues, "very_long_values"),
    ]

    static let answerablePendingOptional = RsvpEventDetails.testData(
        data: .partDayZeroDuration,
        state: .answerableInvite(progress: .pending, attendance: .optional)
    )

    static let answerableOngoing = RsvpEventDetails.testData(
        data: .partDayWithDuration,
        state: .answerableInvite(progress: .ongoing, attendance: .required)
    )

    static let answerableEnded = RsvpEventDetails.testData(
        data: .partDayZeroDuration,
        state: .answerableInvite(progress: .ended, attendance: .required)
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
        data: .partDayWithDuration,
        state: .reminder(.pending)
    )

    static let reminderOngoing = RsvpEventDetails.testData(
        data: .partDayWithDuration,
        state: .reminder(.ongoing)
    )

    static let reminderEnded = RsvpEventDetails.testData(
        data: .partDayWithDuration,
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
    static func date(year: Int, month: Int, day: Int, hour: Int = 0, minute: Int = 0) -> Date {
        var components = DateComponents(year: year, month: month, day: day, hour: hour, minute: minute)
        components.timeZone = TimeZone(identifier: "Europe/Zurich")
        return Calendar.current.date(from: components)!
    }

    static let partDayZeroDuration: EventData = {
        let eventTime = date(year: 2025, month: 7, day: 24, hour: 16, minute: 0).timeIntervalSince1970
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

    static let partDayWithDuration: EventData = {
        let startTime = date(year: 2025, month: 7, day: 24, hour: 10, minute: 0).timeIntervalSince1970
        let endTime = date(year: 2025, month: 7, day: 24, hour: 11, minute: 30).timeIntervalSince1970
        return EventData(
            summary: "Design Review",
            location: "Virtual Meeting",
            description: "Reviewing the new UI mockups.",
            recurrence: nil,
            startsAt: UInt64(startTime),
            endsAt: UInt64(endTime),
            occurrence: .dateTime,
            organizer: RsvpOrganizer(email: "organizer2@example.com"),
            attendees: [
                RsvpAttendee(email: "user@example.com", status: .unanswered),
                RsvpAttendee(email: "designer@example.com", status: .yes),
            ],
            userAttendeeIdx: 0,
            calendar: RsvpCalendar(name: "Design Team", color: "#BD10E0")
        )
    }()

    static let fullDaySingle: EventData = {
        let eventDate = Calendar.current.startOfDay(for: date(year: 2025, month: 7, day: 25)).timeIntervalSince1970
        return EventData(
            summary: "Company Offsite",
            location: "Zürich Lake",
            description: "Annual company-wide offsite event.",
            recurrence: nil,
            startsAt: UInt64(eventDate),
            endsAt: UInt64(eventDate),
            occurrence: .date,
            organizer: RsvpOrganizer(email: "hr@example.com"),
            attendees: [],
            userAttendeeIdx: 0,
            calendar: RsvpCalendar(name: "Company Events", color: "#D0021B")
        )
    }()

    static let fullDayMulti: EventData = {
        let startDate = Calendar.current.startOfDay(for: date(year: 2025, month: 7, day: 28)).timeIntervalSince1970
        let endDate = Calendar.current.startOfDay(for: date(year: 2025, month: 7, day: 30)).timeIntervalSince1970
        return EventData(
            summary: "Developer Conference",
            location: "Berlin, Germany",
            description: "A conference for mobile developers.",
            recurrence: nil,
            startsAt: UInt64(startDate),
            endsAt: UInt64(endDate),
            occurrence: .date,
            organizer: RsvpOrganizer(email: "conference@example.com"),
            attendees: [],
            userAttendeeIdx: 0,
            calendar: RsvpCalendar(name: "Travel", color: "#7ED321")
        )
    }()

    static let recurrent: EventData = {
        let startTime = date(year: 2025, month: 7, day: 28, hour: 14, minute: 0).timeIntervalSince1970
        let endTime = date(year: 2025, month: 7, day: 28, hour: 14, minute: 30).timeIntervalSince1970
        return EventData(
            summary: "Weekly Team Sync",
            location: "Conference Room B",
            description: "Weekly sync meeting.",
            recurrence: "Weekly on Monday",
            startsAt: UInt64(startTime),
            endsAt: UInt64(endTime),
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
        let eventTime = date(year: 2025, month: 8, day: 1, hour: 9, minute: 0).timeIntervalSince1970
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
