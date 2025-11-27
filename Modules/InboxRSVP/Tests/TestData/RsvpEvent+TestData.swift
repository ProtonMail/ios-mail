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

import proton_app_uniffi

@testable import InboxRSVP

extension RsvpEvent {

    static func testData(
        id: String? = .none,
        summary: String? = .none,
        startsAt: UnixTimestamp = .zero,
        organizer: RsvpOrganizer = .init(name: .empty, email: .empty),
        attendees: [RsvpAttendee] = [],
        userAttendeeIdx: UInt32? = .none,
        calendar: RsvpCalendar? = .none,
        state: RsvpState = .cancelledReminder
    ) -> Self {
        .init(
            id: id,
            summary: summary,
            location: .none,
            description: .none,
            recurrence: .none,
            startsAt: startsAt,
            endsAt: 0,
            occurrence: .date,
            organizer: organizer,
            attendees: attendees,
            userAttendeeIdx: userAttendeeIdx,
            calendar: calendar,
            state: state
        )
    }

}
