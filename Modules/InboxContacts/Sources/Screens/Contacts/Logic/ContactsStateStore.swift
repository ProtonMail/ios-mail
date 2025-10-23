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

import Combine
import InboxCore
import proton_app_uniffi
import SwiftUI

final class ContactsStateStore: ObservableObject {
    enum Action {
        case createTapped
        case dismissCreateSheet
        case createSheetAction(CreateContactSheetAction)
        case goBack
        case onDeleteItem(ContactItemType)
        case onDeleteItemAlertAction(DeleteItemAlertAction)
        case onTapItem(ContactItemType)
        case onLoad
    }

    enum CreateContactSheetAction {
        case openSafari
        case dismiss
    }

    @Published var state: ContactsScreenState

    let router = Router<ContactsRoute>()

    private let apiConfig: ApiConfig
    private let repository: GroupedContactsRepository
    private let contactDeleter: ContactItemDeleterAdapter
    private let contactGroupDeleter: ContactItemDeleterAdapter
    private let makeContactsLiveQuery: () -> ContactsLiveQueryCallbackWrapper
    private let watchContacts: (ContactsLiveQueryCallback) async throws -> WatchedContactList
    private lazy var contactsLiveQueryCallback: ContactsLiveQueryCallbackWrapper = makeContactsLiveQuery()
    private var cancellables: Set<AnyCancellable> = Set()
    private var watchContactsConnection: WatchedContactList?

    init(
        apiConfig: ApiConfig,
        state: ContactsScreenState,
        mailUserSession session: MailUserSession,
        contactsWrappers wrappers: RustContactsWrappers,
        makeContactsLiveQuery: @escaping () -> ContactsLiveQueryCallbackWrapper = { .init() }
    ) {
        self.apiConfig = apiConfig
        self.state = state
        self.repository = .init(mailUserSession: session, contactsProvider: wrappers.contactsProvider)
        self.contactDeleter = .init(mailUserSession: session, deleteItem: wrappers.contactDeleter)
        self.contactGroupDeleter = .init(mailUserSession: session, deleteItem: wrappers.contactGroupDeleter)
        self.makeContactsLiveQuery = makeContactsLiveQuery
        self.watchContacts = { callback in
            try await wrappers.contactsWatcher.watch(session, callback).get()
        }
        setUpNestedObservableObjectUpdates()
    }

    @MainActor
    func handle(action: Action) async {
        switch action {
        case .createTapped:
            state = state.copy(\.displayCreateContactSheet, to: true)
        case .createSheetAction(let action):
            state = state.copy(\.displayCreateContactSheet, to: false)

            if case .openSafari = action {
                state = state.copy(\.createContactURL, to: .init(url: .Contact.create(domain: apiConfig.envId.domain)))
            }
        case .dismissCreateSheet:
            state = state.copy(\.createContactURL, to: nil)
        case .goBack:
            router.goBack()
        case .onDeleteItemAlertAction(let alertAction):
            await handle(alertAction: alertAction)
        case .onDeleteItem(let item):
            state = state.copy(\.itemToDelete, to: item)
        case .onTapItem(let item):
            goToDetails(item: item)
        case .onLoad:
            await startWatchingUpdates()
            await loadAllContacts()
        }
    }

    // MARK: - Private

    private func handle(alertAction: DeleteItemAlertAction) async {
        switch alertAction {
        case .confirm:
            if let item = state.itemToDelete {
                await delete(item: item)
            }
        case .cancel:
            break
        }

        state = state.copy(\.itemToDelete, to: nil)
    }

    private func delete(item: ContactItemType) async {
        switch item {
        case .contact(let contactItem):
            await deleteContact(id: contactItem.id)
        case .group(let contactGroupItem):
            await deleteContactGroup(id: contactGroupItem.id)
        }
    }

    private func deleteContact(id: Id) async {
        try? await contactDeleter.delete(itemID: id)
    }

    private func deleteContactGroup(id: Id) async {
        try? await contactGroupDeleter.delete(itemID: id)
    }

    private func startWatchingUpdates() async {
        contactsLiveQueryCallback.delegate = { [weak self] updatedItems in
            await self?.updateState(with: updatedItems)
        }

        watchContactsConnection = try? await watchContacts(contactsLiveQueryCallback)
    }

    private func loadAllContacts() async {
        let contacts = await repository.allContacts()
        await updateState(with: contacts)
    }

    private func goToDetails(item: ContactItemType) {
        switch item {
        case .contact(let contact):
            router.go(to: .contactDetails(.init(contact)))
        case .group(let group):
            router.go(to: .contactGroupDetails(group))
        }
    }

    @MainActor
    private func updateState(with items: [GroupedContacts]) {
        state = state.copy(\.allItems, to: items)
    }

    private func setUpNestedObservableObjectUpdates() {
        router.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }
}
