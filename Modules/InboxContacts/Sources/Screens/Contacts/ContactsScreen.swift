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

    private let initialState: ContactsScreenState
    private let mailUserSession: MailUserSession
    private let contactsProvider: GroupedContactsProvider
    private let contactsWatcher: ContactsWatcher
    private let contactViewFactory: ContactViewFactory

    /// `state` parameter is exposed only for testing purposes to be able to rely on data source in synchronous manner.
    public init(
        state: ContactsScreenState = .initial,
        mailUserSession: MailUserSession,
        contactsProvider: GroupedContactsProvider,
        contactsWatcher: ContactsWatcher,
        draftPresenter: ContactsDraftPresenter
    ) {
        UISearchBar.appearance().tintColor = UIColor(DS.Color.Text.accent)
        self.initialState = state
        self.mailUserSession = mailUserSession
        self.contactsProvider = contactsProvider
        self.contactsWatcher = contactsWatcher
        self.contactViewFactory = .init(mailUserSession: mailUserSession, draftPresenter: draftPresenter)
    }

    public var body: some View {
        StoreView(
            store: ContactsStateStore(
                state: initialState,
                mailUserSession: mailUserSession,
                contactsWrappers: .productionInstance(
                    contactsProvider: contactsProvider,
                    contactsWatcher: contactsWatcher
                )
            ),
            content: { state, store in
                NavigationStack(path: navigationPath(store: store)) {
                    ContactsControllerRepresentable(
                        contacts: state.displayItems,
                        onDeleteItem: { item in store.handle(action: .onDeleteItem(item)) },
                        onTapItem: { item in store.handle(action: .onTapItem(item)) }
                    )
                    .ignoresSafeArea()
                    .navigationTitle(L10n.Contacts.title.string)
                    .navigationDestination(for: ContactsRoute.self) { route in
                        contactViewFactory
                            .makeView(for: route)
                            .environmentObject(store.router)
                            .navigationBarBackButtonHidden()
                            .toolbar {
                                ToolbarItemFactory.back { store.handle(action: .goBack) }
                            }
                    }
                    .toolbar {
                        ToolbarItemFactory.leading(Image(symbol: .xmark)) {
                            dismiss()
                        }
                        ToolbarItemFactory.trailing(Image(symbol: .plus)) {
                            store.handle(action: .createContact)
                        }
                    }
                }
                .sheet(
                    isPresented: store.binding(\.displayCreateContactSheet),
                    content: {
                        PromptSheet(
                            model: .init(
                                image: DS.Images.contactsWebSheet,
                                title: "Available in web".stringResource,
                                subtitle: "Creating contacts or groups in the app is not yet ready. For now, you can create them in the web app and they’ll sync to your device.".stringResource,
                                actionButtonTitle: "Create in web".stringResource,
                                onAction: { store.handle(action: .createContactSheetAction(.openWebView)) },
                                onDismiss: { store.handle(action: .createContactSheetAction(.dismiss)) }
                            )
                        )
                    }
                )
                .sheet(
                    item: store.binding(\.createContactURL),
                    onDismiss: { store.handle(action: .dismissCreateContact) },
                    content: SafariView.init
                )
                .alert(model: deletionAlert(state: state, store: store))
                .searchable(
                    text: store.binding(\.search.query),
                    isPresented: store.binding(\.search.isActive),
                    placement: .navigationBarDrawer(displayMode: .always)
                )
                .onLoad { store.handle(action: .onLoad) }
            }
        )
    }

    // MARK: - Private

    private func navigationPath(store: ContactsStateStore) -> Binding<[ContactsRoute]> {
        .init(
            get: { store.router.stack },
            set: { newStack in store.router.stack = newStack }
        )
    }

    private func deletionAlert(state: ContactsScreenState, store: ContactsStateStore) -> Binding<AlertModel?> {
        .readonly {
            state.itemToDelete.map { itemType in
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
