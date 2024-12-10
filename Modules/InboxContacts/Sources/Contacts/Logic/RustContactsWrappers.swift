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

typealias DeleteContactItem = (_ id: Id, _ session: MailUserSession) async throws -> Void

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
            contactGroupDeleter: { _, _ in },
            contactsWatcher: contactsWatcher
        )
    }
}

public struct GroupedContactsProvider {
    public let allContacts: (_ userSession: MailUserSession) async throws -> [GroupedContacts]

    public init(allContacts: @escaping (MailUserSession) async throws -> [GroupedContacts]) {
        self.allContacts = allContacts
    }
}

public struct ContactsWatcher {
    public let watch: (
        _ session: MailUserSession,
        _ callback: ContactsLiveQueryCallback
    ) async throws -> WatchedContactList
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
