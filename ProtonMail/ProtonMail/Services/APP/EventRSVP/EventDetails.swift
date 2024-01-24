// Copyright (c) 2023 Proton Technologies AG
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

import EventKit
import ProtonInboxICal

struct EventDetails: Equatable {
    struct Calendar: Equatable {
        let name: String
        let iconColor: String
    }

    enum EventStatus: String, Equatable {
        case cancelled
        case confirmed
        case tentative
    }

    struct Location: Equatable {
        let name: String
    }

    struct Participant: Equatable {
        let email: String
        let status: EKParticipantStatus
    }

    let title: String?
    let startDate: Date
    let endDate: Date
    let calendar: Calendar
    let location: Location?
    let organizer: Participant?
    let attendees: [Participant]
    let status: EventStatus?
    let calendarAppDeepLink: URL
}

extension EventDetails.Participant {
    init(attendeeModel: ICalAttendee) {
        self.init(email: attendeeModel.user.email, status: attendeeModel.status)
    }
}
