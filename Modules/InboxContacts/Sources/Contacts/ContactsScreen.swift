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
import InboxCoreUI
import InboxDesignSystem
import proton_app_uniffi
import SwiftUI

public struct ContactsScreen: View {
    @StateObject private var store: ContactsStateStore

    /// `state` parameter is exposed only for testing purposes to be able to rely on data source in synchronous manner.
    public init(
        state: ContactsScreenState = .initial,
        mailUserSession: MailUserSession,
        contactsProvider: GroupedContactsProvider,
        contactsWatcher: ContactsWatcher
    ) {
        UISearchBar.appearance().tintColor = UIColor(DS.Color.Text.accent)
        _store = .init(
            wrappedValue: .init(
                state: state,
                mailUserSession: mailUserSession,
                contactsWrappers: .productionInstance(
                    contactsProvider: contactsProvider,
                    contactsWatcher: contactsWatcher
                )
            )
        )
    }

    public var body: some View {
        NavigationStack {
            ContactsControllerRepresentable(
                contacts: store.state.displayItems,
                onDeleteItem: { item in store.handle(action: .onDeleteItem(item)) }
            )
            .ignoresSafeArea()
            .navigationTitle(L10n.Contacts.title.string)
        }
        .deletionAlert(
            alert: DeleteConfirmationAlertFactory.make(for: store.state.itemToDelete),
            isPresented: isDeletionItemAlertPresented,
            confirm: { store.handle(action: .onDeleteItemAlertAction(.confirm)) },
            cancel: { store.handle(action: .onDeleteItemAlertAction(.cancel)) }
        )
        .searchable(
            text: $store.state.search.query,
            isPresented: $store.state.search.isActive,
            placement: .navigationBarDrawer(displayMode: .always)
        )
        .onLoad { store.handle(action: .onLoad) }
    }

    private var isDeletionItemAlertPresented: Binding<Bool> {
        .readonly { store.state.itemToDelete != nil }
    }
}

#Preview {
    ContactsScreen(
        mailUserSession: .init(noPointer: .init()),
        contactsProvider: .previewInstance(),
        contactsWatcher: .previewInstance()
    )
}
