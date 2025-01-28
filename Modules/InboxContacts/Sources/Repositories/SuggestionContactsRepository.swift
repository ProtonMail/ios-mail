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
    private let contactStore: CNContactStoring
    private let allContacts: ([PlatformDeviceContact]) async -> [ContactType]
    
    init(
        contactStore: CNContactStoring,
        allContactsProvider: AllContactsProvider,
        mailUserSession: MailUserSession
    ) {
        self.contactStore = contactStore
        self.allContacts = { deviceContacts in
            let result = await allContactsProvider.allContacts(mailUserSession, deviceContacts)
            
            switch result {
            case .ok(let contacts):
                return contacts
            case .error:
                return []
            }
        }
    }
    
    func allContacts(completion: @escaping ([ContactType]) -> Void) {
        contactStore.requestAccess(for: .contacts) { granted, _ in
            let deviceContacts: [PlatformDeviceContact] = granted ? deviceContacts() : []
            
            Task {
                let contacts = await allContacts(deviceContacts)
                completion(contacts)
            }
        }
    }
    
    // MARK: - Private
    
    private func deviceContacts() -> [PlatformDeviceContact] {
        let keys: [CNKeyDescriptor] = [CNContactGivenNameKey, CNContactEmailAddressesKey] as [CNKeyDescriptor]
        let request = CNContactFetchRequest(keysToFetch: keys)
        var contacts: [PlatformDeviceContact] = []
        
        try? contactStore.enumerateContacts(with: request) { contact, _ in
            let contact = PlatformDeviceContact(
                id: contact.id.uuidString,
                name: contact.givenName,
                emails: contact.emailAddresses.compactMap(\.label)
            )
            
            contacts.append(contact)
        }
        
        return contacts
    }
}

public enum ContactType: Equatable {
    case group(ContactGroupItem)
    case proton(ContactEmailItem)
    case device(DeviceContact)
}

public struct AllContactsProvider {
    // FIXME: To remove after Rust SDK bump
    public enum AllContactResult {
        case ok([ContactType])
        case error(Error)
    }
    
    public let allContacts: (
        _ userSession: MailUserSession,
        _ deviceContacts: [PlatformDeviceContact]
    ) async -> AllContactResult

    public init(allContacts: @escaping (MailUserSession, [PlatformDeviceContact]) async -> AllContactResult) {
        self.allContacts = allContacts
    }
}

public struct PlatformDeviceContact: Equatable {
    public let id: String
    public let name: String
    public let emails: [String]
}

public struct DeviceContact: Equatable {
    public let id: String
    public let name: String
    public let emails: [String]
    public let avatarInformation: AvatarInformation
}
