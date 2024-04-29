// Copyright (c) 2022 Proton Technologies AG
//
// This file is part of Proton Technologies AG and Proton Calendar.
//
// Proton Calendar is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Calendar is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Calendar. If not, see https://www.gnu.org/licenses/.

import EventKit
import ProtonCoreDataModel
import ProtonInboxICal

public struct AnswerToEventPermissionValidator {

    private let participanceValidator: EventParticipationValidator
    private let emailAddressStorage: EmailAddressStorage

    public init(emailAddressStorage: EmailAddressStorage) {
        self.emailAddressStorage = emailAddressStorage
        self.participanceValidator = .init(emailAddressStorage: emailAddressStorage)
    }

    public func canAnswer(for event: ICalEvent, with calendar: CalendarInfo) -> AnswerToEvent.ValidationResult {
        let canAnswer =
                !calendar.areMemberAddressesDisabled && calendar.isPersonal &&
                !event.isCancelled

        guard canAnswer,
              let organizer = event.organizer, !participanceValidator.isCurrentUserOrganizer(of: event),
              let invitedParticipant = currentUserInvitedActiveAddressWithAttendee(at: event)
        else {
            return .canNotAnswer
        }

        return .canAnswer(.init(organizer: organizer, invitedParticipant: invitedParticipant))
    }

    private func currentUserInvitedActiveAddressWithAttendee(at event: ICalEvent) -> Participant? {
        let addresses = emailAddressStorage.currentUserAddresses()
        let currentUserParticipants = addresses
            .filter(\.send)
            .compactMap(eventAttendeeLinkedWithAddress(in: event.participants))
            .sorted(by: \.address, SortingDescriptors.increasing(by: \.order))
            .sorted(by: \.attendee, SortingDescriptors.trueFirst(by: \.answered))

        return currentUserParticipants.first
    }

    private func eventAttendeeLinkedWithAddress(in attendees: [ICalAttendee]) -> (Address_v2) -> Participant? {
        return { address in
            let attendee = attendees.first { attendee in
                attendee.user.email.canonicalizedEmailAddress == address.email.canonicalizedEmailAddress
            }

            guard let attendee = attendee else {
                return nil
            }

            return .init(attendee: attendee, address: address)
        }
    }

}

private extension ICalEvent {

    var isCancelled: Bool {
        status == "CANCELLED"
    }

}

private extension ICalAttendee {

    var answered: Bool {
        let answeredStatuses: [EKParticipantStatus] = [.accepted, .tentative, .declined]
        return answeredStatuses.contains(status)
    }

}
