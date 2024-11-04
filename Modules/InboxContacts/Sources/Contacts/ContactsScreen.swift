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
    public struct State: Copying, Equatable {
        public struct Search: Equatable {
            var text: String
            var isActive: Bool
        }

        var search: Search
        var allItems: [GroupedContacts]
    }

    @StateObject private var store: ContactsStateStore

    /// `state` parameter is exposed only for testing purposes to be able to rely on data source in synchronous manner.
    public init(
        state: State = .initial,
        mailUserSession: MailUserSession,
        contactsProvider: GroupedContactsProvider
    ) {
        _store = .init(
            wrappedValue: .init(state: state, mailUserSession: mailUserSession, contactsProvider: contactsProvider)
        )
    }

    public var body: some View {
        NavigationStack {
            ContactsControllerRepresentable(contacts: store.state.allItems)
                .ignoresSafeArea()
                .navigationTitle(L10n.Contacts.title.string)
        }
        .onLoad { store.handle(action: .onLoad) }
        .searchable(text: $store.state.search.text)
    }
}

#Preview {
    ContactsScreen(
        mailUserSession: .init(noPointer: .init()),
        contactsProvider: .previewInstance()
    )
}
