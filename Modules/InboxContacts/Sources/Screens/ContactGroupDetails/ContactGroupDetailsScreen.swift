// Copyright (c) 2025 Proton Technologies AG
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
import ProtonUIFoundations
import SwiftUI
import proton_app_uniffi

struct ContactGroupDetailsScreen: View {
    @EnvironmentObject private var toastStateStore: ToastStateStore
    @EnvironmentObject private var router: Router<ContactsRoute>
    let group: ContactGroupItem
    private let draftPresenter: ContactsDraftPresenter

    init(group: ContactGroupItem, draftPresenter: ContactsDraftPresenter) {
        self.group = group
        self.draftPresenter = draftPresenter
    }

    var body: some View {
        StoreView(
            store: ContactGroupDetailsStateStore(
                state: group,
                draftPresenter: draftPresenter,
                toastStateStore: toastStateStore,
                router: router
            )
        ) { state, store in
            ScrollView {
                VStack(spacing: DS.Spacing.large) {
                    avatarView(state: state)
                    groupDetails(state: state)
                    newMessageButton(store: store)
                    items(state: state, store: store)
                }
                .padding(.horizontal, DS.Spacing.large)
            }
            .background(DS.Color.Background.secondary)
        }
    }

    // MARK: - Private

    private func avatarView(state: ContactGroupItem) -> some View {
        ContactAvatarView(hexColor: state.avatarColor) {
            Image(DS.Icon.icUsers)
                .resizable()
                .square(size: 40)
                .foregroundStyle(DS.Color.Text.inverted)
        }
    }

    private func groupDetails(state: ContactGroupItem) -> some View {
        ContactAvatarDetailsView(title: state.name, subtitle: .none)
    }

    private typealias NewMessageButton = L10n.ContactGroupDetails.NewMessageButton

    private func newMessageButton(
        store: ContactGroupDetailsStateStore
    ) -> some View {
        Button(action: { store.handle(action: .sendGroupMessageTapped) }) {
            HStack(alignment: .center, spacing: DS.Spacing.large) {
                Image(DS.Icon.icPenSquare)
                    .square(size: 24)
                    .padding(DS.Spacing.standard)
                    .foregroundStyle(DS.Color.Icon.norm)
                VStack(alignment: .leading, spacing: DS.Spacing.compact) {
                    Text(NewMessageButton.title)
                        .font(.body)
                        .fontWeight(.regular)
                        .foregroundStyle(DS.Color.Text.weak)
                    Text(NewMessageButton.subtitle(contactsCount: store.state.contactEmails.count))
                        .font(.subheadline)
                        .fontWeight(.regular)
                        .foregroundStyle(DS.Color.Text.hint)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(DS.Spacing.large)
            .contentShape(Rectangle())
        }
        .background(DS.Color.BackgroundInverted.secondary)
        .buttonStyle(DefaultPressedButtonStyle())
        .roundedRectangleStyle()
    }

    private func items(state: ContactGroupItem, store: ContactGroupDetailsStateStore) -> some View {
        FormList(collection: state.contactEmails) { (item: ContactEmailItem) in
            ContactCellView(item: item).frame(height: 68)
                .onTapGesture { store.handle(action: .contactItemTapped(item)) }
        }
    }
}
