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

struct SuggestionContactsRepository {
    private let permissionsHandler: CNContactStoring.Type
    private let contactStore: CNContactStoring
    private let allContacts: (String, [DeviceContact]) async -> [ContactSuggestion]
    
    init(
        permissionsHandler: CNContactStoring.Type,
        contactStore: CNContactStoring,
        allContactsProvider: AllContactsProvider,
        mailUserSession: MailUserSession
    ) {
        self.permissionsHandler = permissionsHandler
        self.contactStore = contactStore
        self.allContacts = { query, deviceContacts in
            let result = await allContactsProvider.contactSuggestions(query, deviceContacts, mailUserSession)
            
            switch result {
            case .ok(let contacts):
                return contacts
            case .error:
                return []
            }
        }
    }
    
    func allContacts(query: String, completion: @escaping ([ContactSuggestion]) -> Void) {
        requestAccessIfNeeded { granted in
            let deviceContacts: [DeviceContact] = granted ? deviceContacts() : []
            
            Task {
                let contacts = await allContacts(query, deviceContacts)
                completion(contacts)
            }
        }
    }
    
    // MARK: - Private
    
    private func requestAccessIfNeeded(completion: @escaping (_ granted: Bool) -> Void) {
        let status: CNAuthorizationStatus = permissionsHandler.authorizationStatus(for: .contacts)
        
        switch status {
        case .notDetermined:
            contactStore.requestAccess(for: .contacts) { granted, _ in
                completion(granted)
            }
        case .authorized:
            completion(true)
        case .restricted, .denied:
            completion(false)
        @unknown default:
            break
        }
    }
    
    private func deviceContacts() -> [DeviceContact] {
        let keys: [CNKeyDescriptor] = [CNContactGivenNameKey, CNContactEmailAddressesKey] as [CNKeyDescriptor]
        let request = CNContactFetchRequest(keysToFetch: keys)
        var contacts: [DeviceContact] = []
        
        try? contactStore.enumerateContacts(with: request) { contact, _ in
            let contact = DeviceContact(
                key: contact.id.uuidString,
                name: contact.givenName,
                emails: contact.emailAddresses.compactMap { address in address.value as String }
            )
            
            contacts.append(contact)
        }
        
        return contacts
    }
}

public struct AllContactsProvider {
    public let contactSuggestions: (
        _ query: String,
        _ deviceContacts: [DeviceContact],
        _ userSession: MailUserSession
    ) async -> ContactSuggestionsResult

    public init(
        contactSuggestions: @escaping (String, [DeviceContact], MailUserSession) async -> ContactSuggestionsResult
    ) {
        self.contactSuggestions = contactSuggestions
    }
}
