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
        case onDeleteItemAlertAction(DeleteItemAlertAction)
        case onLoad
    }

    @Published var state: ContactsScreenState

    private let repository: GroupedContactsRepository
    private let contactDeleter: ContactItemDeleterAdapter
    private let contactGroupDeleter: ContactItemDeleterAdapter
    private let makeContactsLiveQuery: () -> ContactsLiveQueryCallbackWrapper
    private let watchContacts: (ContactsLiveQueryCallback) async throws -> Void
    private lazy var contactsLiveQueryCallback: ContactsLiveQueryCallbackWrapper = makeContactsLiveQuery()

    init(
        state: ContactsScreenState,
        mailUserSession session: MailUserSession,
        contactsWrappers wrappers: RustContactsWrappers,
        makeContactsLiveQuery: @escaping () -> ContactsLiveQueryCallbackWrapper = { .init() }
    ) {
        self.state = state
        self.repository = .init(mailUserSession: session, contactsProvider: wrappers.contactsProvider)
        self.contactDeleter = .init(mailUserSession: session, deleteItem: wrappers.contactDeleter)
        self.contactGroupDeleter = .init(mailUserSession: session, deleteItem: wrappers.contactGroupDeleter)
        self.makeContactsLiveQuery = makeContactsLiveQuery
        self.watchContacts = { callback in _ = try await wrappers.contactsWatcher.watch(session, callback) }
    }

    func handle(action: Action) {
        switch action {
        case .onDeleteItemAlertAction(let alertAction):
            handle(alertAction: alertAction)
        case .onDeleteItem(let item):
            state = state.copy(\.itemToDelete, to: item)
        case .onLoad:
            startWatchingUpdates()
            loadAllContacts()
        }
    }

    // MARK: - Private

    private func handle(alertAction: DeleteItemAlertAction) {
        switch alertAction {
        case .confirm:
            if let item = state.itemToDelete {
                delete(item: item)
            }
        case .cancel:
            break
        }

        state = state.copy(\.itemToDelete, to: nil)
    }

    private func delete(item: ContactItemType) {
        switch item {
        case .contact(let contactItem):
            deleteContact(id: contactItem.id)
        case .group(let contactGroupItem):
            deleteContactGroup(id: contactGroupItem.id)
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

    private func startWatchingUpdates() {
        contactsLiveQueryCallback.delegate = { [weak self] updatedItems in
            self?.updateState(with: updatedItems)
        }

        Task {
            try await watchContacts(contactsLiveQueryCallback)
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
}
