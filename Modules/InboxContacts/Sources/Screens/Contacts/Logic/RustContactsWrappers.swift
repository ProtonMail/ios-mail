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

import proton_app_uniffi

typealias DeleteContactItem = (_ id: Id, _ session: MailUserSession) async -> VoidActionResult

struct RustContactsWrappers {
    let contactsProvider: GroupedContactsProvider
    let contactDeleter: DeleteContactItem
    let contactGroupDeleter: DeleteContactItem
    let contactsWatcher: ContactsWatcher
}

extension RustContactsWrappers {

    static func productionInstance(
        contactsProvider: GroupedContactsProvider,
        contactsWatcher: ContactsWatcher
    ) -> Self {
        .init(
            contactsProvider: contactsProvider,
            contactDeleter: deleteContact(contactId:session:),
            contactGroupDeleter: { _, _ in .ok },
            contactsWatcher: contactsWatcher
        )
    }
}

public struct AllContactsProvider {
    public let contactSuggestions: (
        _ deviceContacts: [DeviceContact],
        _ userSession: MailUserSession
    ) async -> ContactSuggestionsResult

    public init(
        contactSuggestions: @escaping ([DeviceContact], MailUserSession) async -> ContactSuggestionsResult
    ) {
        self.contactSuggestions = contactSuggestions
    }
}

public struct GroupedContactsProvider {
    public let allContacts: (_ userSession: MailUserSession) async -> ContactListResult

    public init(allContacts: @escaping (MailUserSession) async -> ContactListResult) {
        self.allContacts = allContacts
    }
}

public struct ContactsWatcher {
    public let watch: (
        _ session: MailUserSession,
        _ callback: ContactsLiveQueryCallback
    ) async -> WatchContactListResult
}

extension GroupedContactsProvider {

    public static func productionInstance() -> Self {
        .init(allContacts: contactList(session:))
    }

}

extension ContactsWatcher {

    public static func productionInstance() -> Self {
        .init(watch: watchContactList(session:callback:))
    }

}
