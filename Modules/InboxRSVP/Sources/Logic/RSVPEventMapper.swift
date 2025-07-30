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
import proton_app_uniffi

enum RSVPEventMapper {
    static func map(from event: RsvpEvent) -> RSVPEvent {
        RSVPEvent(
            title: event.summary ?? L10n.noEventTitlePlacholder.string,
            banner: banner(from: event.state),
            formattedDate: formattedDate(from: event.startsAt, to: event.endsAt, event.occurrence),
            answerButtons: answerButtonsState(from: event.state),
            calendar: event.calendar,
            recurrence: event.recurrence,
            location: event.location,
            organizer: organizer(from: event.organizer),
            participants: participants(attendees: event.attendees, userIndex: event.userAttendeeIdx),
            userParticipantIndex: Int(event.userAttendeeIdx)
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
            case .addressIsIncorrect:
                regular = L10n.Header.addressIsIncorrect
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

    private static func organizer(from organizer: RsvpOrganizer) -> RSVPEvent.Organizer {
        let name: String = organizer.name ?? organizer.email

        return .init(displayName: L10n.Details.organizer(name: name).string)
    }

    private static func participants(attendees: [RsvpAttendee], userIndex: UInt32) -> [RSVPEvent.Participant] {
        attendees.enumerated().map { index, attendee in
            let isCurrentUser = index == userIndex
            let displayName = isCurrentUser ? userDisplayName(from: attendee) : otherAttendeeDisplayName(from: attendee)

            return RSVPEvent.Participant(displayName: displayName, status: attendee.status)
        }
    }

    private static func userDisplayName(from attendee: RsvpAttendee) -> String {
        L10n.Details.you(email: attendee.email).string
    }

    private static func otherAttendeeDisplayName(from attendee: RsvpAttendee) -> String {
        [attendee.name, attendee.email].compactMap { $0 }.joined(separator: " • ")
    }
}
