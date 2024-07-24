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

public enum CurrentUserParticipantResolver {

    public static func resolve(participants: [ICalAttendee], addresses: [ICalAddress]) -> ICalParticipant? {
        addresses
            .filter(\.send)
            .compactMap(eventAttendeeLinkedWithAddress(in: participants))
            .sorted(by: \.address, SortingDescriptors.increasing(by: \.order))
            .sorted(by: \.atendee, SortingDescriptors.trueFirst(by: \.answered))
            .first
    }

    private static func eventAttendeeLinkedWithAddress(in attendees: [ICalAttendee]) -> (ICalAddress) -> ICalParticipant? {
        { address in
            let attendee = attendees.first { attendee in
                attendee.user.email.canonicalizedEmailAddress == address.email.canonicalizedEmailAddress
            }

            guard let attendee = attendee else {
                return nil
            }

            return .init(atendee: attendee, address: address)
        }
    }

}

private extension ICalAttendee {

    var answered: Bool {
        let answeredStatuses: [EKParticipantStatus] = [.accepted, .tentative, .declined]
        return answeredStatuses.contains(status)
    }

}
