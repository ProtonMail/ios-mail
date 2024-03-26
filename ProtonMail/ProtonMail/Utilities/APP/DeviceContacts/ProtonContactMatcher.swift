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

    /// Returns the `DeviceContactIdentifiers` that match an existing Proton Contact by uuid or by email
    func matchProtonContacts(
        with identifiers: [DeviceContactIdentifier]
    ) -> (matchByUuid: [DeviceContactIdentifier], matchByEmail: [DeviceContactIdentifier]) {
        var pendingIdentifiers = identifiers

        // Compare passed DeviceContactIdentifier with Proton contacts by uuid
        let normalisedDeviceContactUuids = pendingIdentifiers.map(\.uuidNormalisedForAutoImport)
        let contactEntitiesMatchById = contactProvider.getContactsByUUID(normalisedDeviceContactUuids)
        let uuidsContactEntitiesMatchById = Set(contactEntitiesMatchById.map(\.uuid))
        pendingIdentifiers.removeAll(where: { uuidsContactEntitiesMatchById.contains($0.uuidNormalisedForAutoImport) })

        // Compare remaining DeviceContactIdentifier with Proton contacts by email
        let deviceContactEmails = pendingIdentifiers.flatMap(\.emails)
        let emailEntitiesMatchByAddress = contactProvider.getEmailsByAddress(deviceContactEmails)
        let emailsMatchByAddressSet = Set(emailEntitiesMatchByAddress.map(\.email))

        let deviceContactIdentifiersMatchByUuid = identifiers.filter { deviceContact in
            return contactEntitiesMatchById.map(\.uuid).contains(deviceContact.uuidNormalisedForAutoImport)
        }
        let deviceContactIdentifiersMatchByEmail = identifiers.filter { deviceContact in
            let matchedEmails = deviceContact.emails.filter { email in
                emailsMatchByAddressSet.contains(email)
            }
            return !matchedEmails.isEmpty
        }
        return (deviceContactIdentifiersMatchByUuid, deviceContactIdentifiersMatchByEmail)
    }

    /// This function is specific to the auto import feature and it looks for a contact
    /// that has the same email as the `DeviceContact` passed.
    ///
    /// If there is one single contact that matches, it returns it.
    /// If there are multiple contacts with that email, it will compare the name to
    /// those matches. If only one contact has the same name, it will return that
    /// contact, otherwise it won't return any contact.
    func findContactToMergeMatchingEmail(
        with deviceContact: DeviceContact,
        in contacts: [ContactEntity]
    ) -> ContactEntity? {
        let matchContacts = contacts.filter { entity in
            !entity
                .emailRelations
                .filter { deviceContact.identifier.emails.contains($0.email) }
                .isEmpty
        }
        guard !matchContacts.isEmpty else {
            let message = "findContactToMergeMatchingEmail no contact match"
            SystemLogger.log(message: message, category: .contacts, isError: true)
            return nil
        }
        if matchContacts.count == 1, let contact = matchContacts.first {
            return contact
        } else {
            // if multiple contacts match by email, we return one (if only one macthes the name) or none
            let macthAlsoByName = matchContacts.filter { $0.name == deviceContact.fullName }
            if macthAlsoByName.count == 1, let matchByName = macthAlsoByName.first {
                return matchByName
            } else {
                let message = "findContactToMergeMatchingEmail inconclusive match"
                SystemLogger.log(message: message, category: .contacts, isError: true)
                return nil
            }
        }
    }
}
