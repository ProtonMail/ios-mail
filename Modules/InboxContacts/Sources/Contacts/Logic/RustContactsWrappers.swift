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

struct RustContactsWrappers {
    let contactsProvider: GroupedContactsProvider
    let contactDeleter: ContactDeleter
    let contactGroupDeleter: ContactGroupDeleter
    let contactsWatcher: ContactsWatcher
}

public struct GroupedContactsProvider {
    public let allContacts: (_ userSession: MailUserSession) async throws -> [GroupedContacts]
}

public struct ContactsWatcher {
    public let watch: (
        _ session: MailUserSession,
        _ callback: ContactsLiveQueryCallback
    ) async throws -> WatchedContactList
}

struct ContactDeleter {
    let delete: (_ contactID: Id, _ session: MailUserSession) async throws -> Void
}

struct ContactGroupDeleter {
    let delete: (_ contactGroupID: Id, _ session: MailUserSession) async throws -> Void
}

extension GroupedContactsProvider {

    public static func productionInstance() -> Self {
        .init(allContacts: contactList(session:))
    }

}

extension ContactDeleter {

    static func productionInstance() -> Self {
        .init(delete: deleteContact(contactId:session:))
    }

}

extension ContactGroupDeleter {

    static func productionInstance() -> Self {
        .init(delete: { _, _ in }) // FIXME: Use RustSDK's implementation here
    }

}

extension ContactsWatcher {

    public static func productionInstance() -> Self {
        .init(watch: watchContactList(session:callback:))
    }

}
