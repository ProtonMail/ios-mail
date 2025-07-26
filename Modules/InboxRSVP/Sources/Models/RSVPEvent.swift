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
import InboxCoreUI

struct RSVPEvent: Copying {
    enum AnswerButtonsState {
        case visible(Attendance)
        case hidden
    }

    struct Banner {
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

    struct Participant: Copying {
        let displayName: String
        var status: RsvpAttendeeStatus
    }

    let title: String
    let banner: Banner?
    let formattedDate: String
    let answerButtons: AnswerButtonsState
    let initialStatus: RsvpAttendeeStatus
    let calendar: RsvpCalendar?
    let recurrence: String?
    let location: String?
    let organizer: RsvpOrganizer
    var participants: [Participant]
    let userParticipantIndex: Int
}

enum RsvpEventDetailsMapper {
    static func map(_ details: RsvpEventDetails) -> RSVPEvent {
        let formattedDate = RSVPDateFormatter.string(
            from: details.startsAt,
            to: details.endsAt,
            occurrence: details.occurrence
        )
        let initialStatus = details.attendees[Int(details.userAttendeeIdx)].status
        let participants = details.attendees.enumerated().map { index, attendee in
            let isCurrentUser = index == details.userAttendeeIdx
            let displayName = isCurrentUser ? L10n.Details.you(email: attendee.email).string : attendee.email

            return RSVPEvent.Participant(displayName: displayName, status: attendee.status)
        }

        return RSVPEvent(
            title: details.summary ?? L10n.noEventTitlePlacholder.string,
            banner: banner(from: details.state),
            formattedDate: formattedDate,
            answerButtons: answerButtonsState(from: details.state),
            initialStatus: initialStatus,
            calendar: details.calendar,
            recurrence: details.recurrence,
            location: details.location,
            organizer: details.organizer,
            participants: participants,
            userParticipantIndex: Int(details.userAttendeeIdx)
        )
    }

    // MARK: - Private

    private static func answerButtonsState(from state: RsvpState) -> RSVPEvent.AnswerButtonsState {
        let buttonsState: RSVPEvent.AnswerButtonsState

        if case let .answerableInvite(_, attendance) = state {
            buttonsState = .visible(attendance)
        } else {
            buttonsState = .hidden
        }

        return buttonsState
    }

    private static func banner(from state: RsvpState) -> RSVPEvent.Banner? {
        switch state {
        case let .answerableInvite(progress, _), let .reminder(progress):
            switch progress {
            case .pending:
                return nil
            case .ongoing:
                return .init(style: .now, regularText: L10n.Header.happening, boldText: L10n.Header.now)
            case .ended:
                return .init(style: .ended, regularText: L10n.Header.event, boldText: L10n.Header.ended)
            }
        case .unanswerableInvite(let reason):
            let regular: LocalizedStringResource
            switch reason {
            case .inviteIsOutdated:
                regular = L10n.Header.inviteIsOutdated
            case .inviteHasUnknownRecency:
                regular = L10n.Header.offlineWarning
            }
            return .init(style: .generic, regularText: regular)
        case .cancelledInvite(let isOutdated):
            if isOutdated {
                return .init(style: .cancelled, regularText: L10n.Header.cancelledAndOutdated)
            } else {
                return .init(style: .cancelled, regularText: L10n.Header.event, boldText: L10n.Header.canceled)
            }
        case .cancelledReminder:
            return nil
        }
    }
}
