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

enum EventMapper {
    static func map(from uniffiModel: RsvpEvent) -> Event {
        Event(
            title: uniffiModel.summary ?? L10n.noEventTitlePlacholder.string,
            banner: banner(from: uniffiModel.state),
            formattedDate: formattedDate(from: uniffiModel.startsAt, to: uniffiModel.endsAt, uniffiModel.occurrence),
            answerButtons: answerButtonsState(from: uniffiModel.state, attendeeIndex: uniffiModel.userAttendeeIdx),
            calendar: uniffiModel.calendar,
            recurrence: uniffiModel.recurrence,
            location: uniffiModel.location,
            organizer: organizer(from: uniffiModel.organizer),
            participants: participants(attendees: uniffiModel.attendees, userIndex: uniffiModel.userAttendeeIdx),
            userParticipantIndex: uniffiModel.userAttendeeIdx.map(Int.init)
        )
    }

    // MARK: - Private

    private static func formattedDate(
        from startsAt: UnixTimestamp,
        to endsAt: UnixTimestamp,
        _ occurrence: RsvpOccurrence
    ) -> String {
        EventDateFormatter.string(from: startsAt, to: endsAt, occurrence: occurrence)
    }

    private static func answerButtonsState(from state: RsvpState, attendeeIndex: UInt32?) -> Event.AnswerButtonsState {
        let buttonsState: Event.AnswerButtonsState

        if case let .answerableInvite(_, attendance) = state, let attendeeIndex {
            buttonsState = .visible(attendance: attendance, attendeeIndex: Int(attendeeIndex))
        } else {
            buttonsState = .hidden
        }

        return buttonsState
    }

    private static func banner(from state: RsvpState) -> Event.Banner? {
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
            case .userIsOrganizer:
                return nil
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

    private static func organizer(from organizer: RsvpOrganizer) -> Event.Organizer {
        let name: String = organizer.name ?? organizer.email

        return .init(displayName: L10n.Details.organizer(name: name).string)
    }

    private static func participants(attendees: [RsvpAttendee], userIndex: UInt32?) -> [Event.Participant] {
        attendees.enumerated().map { index, attendee in
            let isCurrentUser = isCurrentUser(attendeeIndex: index, userAttendeeIndex: userIndex)
            let displayName = isCurrentUser ? userDisplayName(from: attendee) : otherAttendeeDisplayName(from: attendee)

            return Event.Participant(displayName: displayName, status: attendee.status)
        }
    }

    private static func isCurrentUser(attendeeIndex: Int, userAttendeeIndex: UInt32?) -> Bool {
        guard let userAttendeeIndex else {
            return false
        }

        return attendeeIndex == Int(userAttendeeIndex)
    }

    private static func userDisplayName(from attendee: RsvpAttendee) -> String {
        L10n.Details.you(email: attendee.email).string
    }

    private static func otherAttendeeDisplayName(from attendee: RsvpAttendee) -> String {
        [attendee.name, attendee.email].compactMap { $0 }.joined(separator: " • ")
    }
}
