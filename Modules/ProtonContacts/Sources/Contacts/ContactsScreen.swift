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
import ProtonCore
import ProtonCoreUI
import SwiftUI

public struct ContactsScreen: View {
    @State private var state: [GroupedContacts] = []

    public init() {}

    public var body: some View {
        NavigationStack {
            ContactsControllerRepresentable(contacts: state, backgroundColor: DS.Color.BackgroundInverted.norm)
                .ignoresSafeArea()
                .navigationTitle(L10n.Contacts.title.string)
        }
        .onLoad { state = groupedContactsRepository.allContacts() }
    }

    // MARK: - Private

    private let groupedContactsRepository = GroupedContactsRepository()
}

#Preview {
    ContactsScreen()
}
