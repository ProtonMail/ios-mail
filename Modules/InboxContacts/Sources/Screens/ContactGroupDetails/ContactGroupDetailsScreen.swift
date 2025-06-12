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
import proton_app_uniffi
import SwiftUI

struct ContactGroupDetailsScreen: View {
    @StateObject var store: ContactGroupDetailsStateStore

    init(group: ContactGroupItem, draftPresenter: ContactsDraftPresenter) {
        _store = .init(wrappedValue: .init(state: group, draftPresenter: draftPresenter))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: DS.Spacing.large) {
                avatarView
                groupDetails
                newMessageButton
                items
            }
            .padding(.horizontal, DS.Spacing.large)
        }
        .background(DS.Color.Background.secondary)
    }

    // MARK: - Private

    private var avatarView: some View {
        ContactAvatarView(hexColor: store.state.avatarColor) {
            Image(DS.Icon.icUsers)
                .resizable()
                .square(size: 40)
                .foregroundStyle(DS.Color.Text.inverted)
        }
    }

    private var groupDetails: some View {
        ContactAvatarDetailsView(title: store.state.name, subtitle: .none)
    }

    private typealias NewMessageButton = L10n.ContactGroupDetails.NewMessageButton

    private var newMessageButton: some View {
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

    private var items: some View {
        FormList(collection: store.state.contactEmails, separator: .invertedNoPadding) { item in
            ContactCellView(item: item).frame(height: 68)
        }
    }
}
