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

import Foundation
import InboxCore

struct RSVPEvent: Copying {
    enum AnswerButtonsState: Equatable {
        case visible(Attendance)
        case hidden
    }

    struct Banner: Equatable {
        let style: RSVPHeaderView.Style
        let regularText: LocalizedStringResource
        let boldText: LocalizedStringResource

        init(
            style: RSVPHeaderView.Style,
            regularText: LocalizedStringResource,
            boldText: LocalizedStringResource = "".notLocalized.stringResource
        ) {
            self.style = style
            self.regularText = regularText
            self.boldText = boldText
        }
    }

    struct Participant: Copying, Equatable {
        let displayName: String
        var status: RsvpAttendeeStatus
    }

    let title: String
    let banner: Banner?
    let formattedDate: String
    let answerButtons: AnswerButtonsState
    let calendar: RsvpCalendar?
    let recurrence: String?
    let location: String?
    let organizer: RsvpOrganizer
    var participants: [Participant]
    let userParticipantIndex: Int
}
