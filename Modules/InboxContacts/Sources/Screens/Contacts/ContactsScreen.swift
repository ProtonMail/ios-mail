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
    @Environment(\.dismissTestable) var dismiss: Dismissable
    @StateObject private var store: ContactsStateStore
    private let contactViewFactory: ContactViewFactory

    var onLoad: ((Self) -> Void)?

    /// `state` parameter is exposed only for testing purposes to be able to rely on data source in synchronous manner.
    public init(
        state: ContactsScreenState = .initial,
        mailUserSession: MailUserSession,
        contactsProvider: GroupedContactsProvider,
        contactsWatcher: ContactsWatcher,
        draftPresenter: ContactsDraftPresenter
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
        self.contactViewFactory = .init(mailUserSession: mailUserSession, draftPresenter: draftPresenter)
    }

    public var body: some View {
        NavigationStack(path: navigationPath) {
            ContactsControllerRepresentable(
                contacts: store.state.displayItems,
                onDeleteItem: { item in store.handle(action: .onDeleteItem(item)) },
                onTapItem: { item in store.handle(action: .onTapItem(item)) }
            )
            .ignoresSafeArea()
            .navigationTitle(L10n.Contacts.title.string)
            .navigationDestination(for: ContactsRoute.self) { route in
                contactViewFactory
                    .makeView(for: route)
                    .navigationBarBackButtonHidden()
                    .toolbar {
                        ToolbarItemFactory.back { store.handle(action: .goBack) }
                    }
            }
            .toolbar {
                ToolbarItemFactory.leading(Image(symbol: .xmark)) {
                    dismiss()
                }
            }
        }
        .alert(model: deletionAlert)
        .searchable(
            text: $store.state.search.query,
            isPresented: $store.state.search.isActive,
            placement: .navigationBarDrawer(displayMode: .always)
        )
        .onLoad {
            store.handle(action: .onLoad)
            onLoad?(self)
        }
    }

    // MARK: - Private

    private var navigationPath: Binding<[ContactsRoute]> {
        .init(
            get: { store.router.stack },
            set: { newStack in store.router.stack = newStack }
        )
    }

    private var deletionAlert: Binding<AlertModel?> {
        .readonly {
            store.state.itemToDelete.map { itemType in
                DeleteConfirmationAlertFactory.make(
                    for: itemType,
                    action: { action in store.handle(action: .onDeleteItemAlertAction(action)) }
                )
            }
        }
    }
}

#Preview {
    ContactsScreen(
        mailUserSession: .init(noPointer: .init()),
        contactsProvider: .previewInstance(),
        contactsWatcher: .previewInstance(),
        draftPresenter: ContactsDraftPresenterDummy()
    )
}
