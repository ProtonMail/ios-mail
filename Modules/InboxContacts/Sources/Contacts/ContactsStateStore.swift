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
    private let contactDeleter: ContactDeleterAdapter

    init(
        state: ContactsScreenState,
        mailUserSession: MailUserSession,
        contactsProvider: GroupedContactsProvider,
        contactsDeleter: ContactDeleter
    ) {
        self.state = state
        self.repository = .init(mailUserSession: mailUserSession, contactsProvider: contactsProvider)
        self.contactDeleter = .init(mailUserSession: mailUserSession, contactDeleter: contactsDeleter)
    }

    func handle(action: Action) {
        switch action {
        case .onDeleteItem(let item):
            updateState(with: deleting(item: item, from: state.allItems))

            switch item {
            case .contact(let contactItem):
                Task {
                    try await contactDeleter.delete(contactID: contactItem.id)
                }
            case .group:
                break
            }
        case .onLoad:
            Task {
                let contacts = await repository.allContacts()
                let updateStateWorkItem = DispatchWorkItem { [weak self] in
                    self?.updateState(with: contacts)
                }
                Dispatcher.dispatchOnMain(updateStateWorkItem)
            }
        }
    }

    // MARK: - Private

    private func updateState(with items: [GroupedContacts]) {
        state = state.copy(\.allItems, to: items)
    }

    private func deleting(item: ContactItemType, from items: [GroupedContacts]) -> [GroupedContacts] {
        items.compactMap { contactGroup in
            let filteredItems = contactGroup.item.filter { $0 != item }
            return filteredItems.isEmpty ? nil : contactGroup.copy(items: filteredItems)
        }
    }
}
