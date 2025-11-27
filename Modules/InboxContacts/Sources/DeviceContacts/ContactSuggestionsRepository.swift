// Copyright (c) 2024 Proton Technologies AG
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

import Contacts
import proton_app_uniffi

public struct ContactSuggestionsRepository {
    private let contactStore: CNContactStoring
    private let allContacts: ([DeviceContact]) async -> ContactSuggestionsProtocol?

    public init(
        contactStore: CNContactStoring,
        allContactsProvider: AllContactsProvider,
        mailUserSession: MailUserSession
    ) {
        self.contactStore = contactStore
        self.allContacts = { deviceContacts in
            try? await allContactsProvider.contactSuggestions(deviceContacts, mailUserSession).get()
        }
    }

    public func allContacts() async -> ContactSuggestionsProtocol? {
        let permissionsGranted = contactStore.authorizationStatus(for: .contacts).granted
        let deviceContacts = permissionsGranted ? deviceContacts() : []

        return await allContacts(deviceContacts)
    }

    // MARK: - Private

    private func deviceContacts() -> [DeviceContact] {
        let keys: [CNKeyDescriptor] =
            [
                CNContactGivenNameKey,
                CNContactFamilyNameKey,
                CNContactEmailAddressesKey,
            ] as [CNKeyDescriptor]
        let request = CNContactFetchRequest(keysToFetch: keys)
        var contacts: [DeviceContact] = []

        try? contactStore.enumerateContacts(with: request) { contact, _ in
            let name = [contact.givenName, contact.familyName].joined(separator: " ").trimmingCharacters(in: .whitespaces)
            let emails = contact.emailAddresses.compactMap { address in address.value as String }
            if name.isEmpty {
                for email in emails {
                    let contact = DeviceContact(key: contact.identifier, name: email, emails: [email])
                    contacts.append(contact)
                }
            } else {
                let contact = DeviceContact(key: contact.identifier, name: name, emails: emails)
                contacts.append(contact)
            }
        }

        return contacts
    }
}

private extension CNAuthorizationStatus {

    var granted: Bool {
        switch self {
        case .notDetermined, .restricted, .denied:
            false
        case .authorized, .limited:
            true
        @unknown default:
            false
        }
    }

}
