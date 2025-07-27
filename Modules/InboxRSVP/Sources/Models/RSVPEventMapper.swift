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
import InboxCoreUI

enum RSVPEventMapper {
    static func map(from details: RsvpEventDetails) -> RSVPEvent {
        RSVPEvent(
            title: details.summary ?? L10n.noEventTitlePlacholder.string,
            banner: banner(from: details.state),
            formattedDate: formattedDate(from: details.startsAt, to: details.endsAt, details.occurrence),
            answerButtons: answerButtonsState(from: details.state),
            calendar: details.calendar,
            recurrence: details.recurrence,
            location: details.location,
            organizer: details.organizer,
            participants: participants(attendees: details.attendees, userIndex: details.userAttendeeIdx),
            userParticipantIndex: Int(details.userAttendeeIdx)
        )
    }

    // MARK: - Private

    private static func formattedDate(
        from startsAt: UnixTimestamp,
        to endsAt: UnixTimestamp,
        _ occurrence: RsvpOccurrence
    ) -> String {
        RSVPDateFormatter.string(from: startsAt, to: endsAt, occurrence: occurrence)
    }

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

    private static func participants(attendees: [RsvpAttendee], userIndex: UInt32) -> [RSVPEvent.Participant] {
        attendees.enumerated().map { index, attendee in
            let isCurrentUser = index == userIndex
            let displayName = isCurrentUser ? L10n.Details.you(email: attendee.email).string : attendee.email

            return RSVPEvent.Participant(displayName: displayName, status: attendee.status)
        }
    }
}
