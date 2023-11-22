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

struct ProtonContactMatcher {
    let contactProvider: ContactProviderProtocol

    /// Returns the DeviceContactIdentifiers that match an existing Proton Contact by uuid or by email
    func matchProtonContacts(with identifiers: [DeviceContactIdentifier]) -> [DeviceContactIdentifier] {
        var pendingIdentifiers = identifiers

        // Compare passed DeviceContactIdentifier with Proton contacts by uuid
        let deviceContactUuids = pendingIdentifiers.map(\.uuid)
        let contactEntitiesMatchById = contactProvider.getContactsByUUID(deviceContactUuids)
        pendingIdentifiers.removeAll(where: { contactEntitiesMatchById.map(\.uuid).contains($0.uuid) })

        // Compare remaining DeviceContactIdentifier with Proton contacts by email
        let deviceContactEmails = pendingIdentifiers.flatMap(\.emails)
        let emailEntitiesMatch = contactProvider.getEmailsByAddress(deviceContactEmails)

        let deviceContactIdentifiersMatchById = identifiers.filter { deviceContact in
            return contactEntitiesMatchById.map(\.uuid).contains(deviceContact.uuid)
        }
        let deviceContactIdentifiersMatchByEmail = identifiers.filter { deviceContact in
            let matchedEmails = deviceContact.emails.filter { email in
                emailEntitiesMatch.map(\.email).contains(email)
            }
            return !matchedEmails.isEmpty
        }
        return deviceContactIdentifiersMatchById + deviceContactIdentifiersMatchByEmail
    }
}
