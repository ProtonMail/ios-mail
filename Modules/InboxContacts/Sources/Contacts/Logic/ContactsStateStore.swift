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

import InboxCore
import proton_app_uniffi
import SwiftUI

final class ContactsStateStore: ObservableObject {
    enum Action {
        case onDeleteItem(ContactItemType)
        case onLoad
    }

    @Published var state: ContactsScreenState

    private let repository: GroupedContactsRepository
    private let contactDeleter: ContactItemDeleterAdapter
    private let contactGroupDeleter: ContactItemDeleterAdapter
    private let contactsLiveQueryFactory: () -> ContactsLiveQueryCallbackWrapper
    private let watchContacts: (ContactsLiveQueryCallback) async throws -> Void

    init(
        state: ContactsScreenState,
        mailUserSession session: MailUserSession,
        contactsWrappers wrappers: RustContactsWrappers,
        contactsLiveQueryFactory: @escaping () -> ContactsLiveQueryCallbackWrapper = { .init() }
    ) {
        self.state = state
        self.repository = .init(mailUserSession: session, contactsProvider: wrappers.contactsProvider)
        self.contactDeleter = .init(mailUserSession: session, deleteItem: wrappers.contactDeleter)
        self.contactGroupDeleter = .init(mailUserSession: session, deleteItem: wrappers.contactGroupDeleter)
        self.contactsLiveQueryFactory = contactsLiveQueryFactory
        self.watchContacts = { callback in _ = try await wrappers.contactsWatcher.watch(session, callback) }
    }

    func handle(action: Action) {
        switch action {
        case .onDeleteItem(let item):
            delete(item: item)
        case .onLoad:
            startWatchingUpdates()
            loadAllContacts()
        }
    }

    // MARK: - Private

    private func delete(item: ContactItemType) {
        updateState(with: deleting(item: item, from: state.allItems))

        switch item {
        case .contact(let contactItem):
            deleteContact(id: contactItem.id)
        case .group(let contactGroupItem):
            deleteContactGroup(id: contactGroupItem.id)
        }
    }

    private func deleting(item itemToDelete: ContactItemType, from items: [GroupedContacts]) -> [GroupedContacts] {
        items.compactMap { contactGroup in
            let filteredItems = contactGroup.item.filter { item in item != itemToDelete }
            return filteredItems.isEmpty ? nil : contactGroup.copy(items: filteredItems)
        }
    }

    private func deleteContact(id: Id) {
        Task {
            try await contactDeleter.delete(itemID: id)
        }
    }

    private func deleteContactGroup(id: Id) {
        Task {
            try await contactGroupDeleter.delete(itemID: id)
        }
    }

    private func loadAllContacts() {
        Task {
            let contacts = await repository.allContacts()
            let updateStateWorkItem = DispatchWorkItem { [weak self] in
                self?.updateState(with: contacts)
            }
            Dispatcher.dispatchOnMain(updateStateWorkItem)
        }
    }

    private func updateState(with items: [GroupedContacts]) {
        state = state.copy(\.allItems, to: items)
    }

    private func startWatchingUpdates() {
        let liveQueryCallback = contactsLiveQueryFactory()
        liveQueryCallback.delegate = { [weak self] updatedItems in
            self?.updateState(with: updatedItems)
        }

        Task {
            try await watchContacts(liveQueryCallback)
        }
    }
}
