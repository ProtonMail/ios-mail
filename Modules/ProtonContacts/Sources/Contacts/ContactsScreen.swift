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

import DesignSystem
import proton_app_uniffi
import ProtonCore
import ProtonCoreUI
import SwiftUI

public struct ContactsScreen: View {
    @StateObject private var store: ContactsStateStore

    /// `state` parameter is exposed only for testing purposes to be able to rely on data source in synchronous manner.
    public init(state: [GroupedContacts] = [], repository: GroupedContactsProviding) {
        _store = .init(wrappedValue: .init(state: state, repository: repository))
    }

    public var body: some View {
        NavigationStack {
            ContactsControllerRepresentable(contacts: store.state, backgroundColor: DS.Color.BackgroundInverted.norm)
                .ignoresSafeArea()
                .navigationTitle(L10n.Contacts.title.string)
        }
        .onLoad { store.handle(action: .onLoad) }
    }
}

#Preview {
    ContactsScreen(repository: GroupedContactsRepositoryPreview())
}
