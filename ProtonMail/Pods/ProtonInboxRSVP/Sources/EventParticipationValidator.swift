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

import ProtonCoreDataModel
import ProtonInboxICal

public struct EventParticipationValidator {

    private var currentUserAddresses: [Address_v2] {
        emailAddressStorage.currentUserAddresses()
    }

    private let emailAddressStorage: EmailAddressStorage

    public init(emailAddressStorage: EmailAddressStorage) {
        self.emailAddressStorage = emailAddressStorage
    }

    public func isCurrentUserOrganizer(of event: ICalEvent) -> Bool {
        guard let organizer = event.organizer else {
            return false
        }
        let organizerCanonicalizedEmailAddress = organizer.user.email.canonicalizedEmailAddress
        let isCurrentUserOrganizer = currentUserAddresses.contains { address in
            address.email.canonicalizedEmailAddress == organizerCanonicalizedEmailAddress
        }
        return isCurrentUserOrganizer
    }

    public func isCurrentUserParticipant(of event: ICalEvent) -> Bool {
        guard !event.participants.isEmpty else {
            return false
        }
        let participantCanonicalizedEmailAddress = event.participants.map { $0.user.email.canonicalizedEmailAddress }
        let isCurrentUserParticipant = currentUserAddresses.contains { address in
            participantCanonicalizedEmailAddress.contains(address.email.canonicalizedEmailAddress)
        }
        return isCurrentUserParticipant
    }

}
