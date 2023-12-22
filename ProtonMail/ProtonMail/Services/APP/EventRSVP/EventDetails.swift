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

import Foundation

struct EventDetails: Equatable {
    struct Calendar: Equatable {
        let name: String
        let iconColor: String
    }

    struct Location: Equatable {
        let name: String
    }

    struct Participant: Equatable {
        // design team is not sure if we want name or just email
        //        let name: String
        let email: String
        // I suppose bool is enough, we don't need to see all possible roles
        let isOrganizer: Bool
        // should we go with a 4th case (undecided) instead of optional?
        let status: ParticipantStatus?
    }

    // do we want to mimic EKParticipantStatus more closely?
    enum ParticipantStatus: Equatable {
        case attending
        case maybeAttending
        case notAttending
    }

    let title: String
    // do we use DateInterval to include both dates?
    let startDate: Date
    let endDate: Date
    let calendar: Calendar
    let location: Location?
    let participants: [Participant]
}
