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

extension RsvpEventDetails {

    static func testData(
        summary: String? = .none,
        organizer: RsvpOrganizer = .init(name: .empty, email: .empty),
        attendees: [RsvpAttendee] = [],
        userAttendeeIdx: UInt32 = 0,
        state: RsvpState = .cancelledReminder
    ) -> Self {
        .init(
            id: .none,
            summary: summary,
            location: .none,
            description: .none,
            recurrence: .none,
            startsAt: 0,
            endsAt: 0,
            occurrence: .date,
            organizer: organizer,
            attendees: attendees,
            userAttendeeIdx: userAttendeeIdx,
            calendar: .none,
            state: state
        )
    }

}
