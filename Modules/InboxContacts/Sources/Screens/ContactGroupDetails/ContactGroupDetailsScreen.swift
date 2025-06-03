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

import InboxCoreUI
import InboxDesignSystem
import proton_app_uniffi
import SwiftUI

struct ContactGroupDetailsScreen: View {
    let group: ContactGroupItem

    var body: some View {
        ScrollView {
            VStack(spacing: DS.Spacing.large) {
                avatarView
                contactDetails
                sendGroupMessageButton
                groupItems
            }
            .padding(.horizontal, DS.Spacing.large)
        }
        .background(DS.Color.Background.secondary)
    }

    // MARK: - Private

    private var avatarView: some View {
        ZStack {
            Rectangle()
                .fill(Color(hex: group.avatarColor))
                .square(size: 100)
                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.giant))
            Image(DS.Icon.icUsers)
                .resizable()
                .square(size: 40)
                .foregroundStyle(DS.Color.Text.inverted)
        }
    }

    private var contactDetails: some View {
        Text(group.name)
            .font(.body)
            .fontWeight(.semibold)
            .foregroundStyle(DS.Color.Text.norm)
            .multilineTextAlignment(.center)
    }

    private var sendGroupMessageButton: some View {
        Button(action: {
            // FIXME: Implement send group message action (open composer with all group members)
        }) {
            HStack(alignment: .center, spacing: DS.Spacing.large) {
                Image(DS.Icon.icPenSquare)
                    .square(size: 24)
                    .padding(DS.Spacing.standard)
                    .foregroundStyle(DS.Color.Icon.norm)
                VStack(alignment: .leading, spacing: DS.Spacing.compact) {
                    Text(L10n.ContactGroupDetails.Button.title)
                        .font(.body)
                        .fontWeight(.regular)
                        .foregroundStyle(DS.Color.Text.weak)
                    Text(L10n.ContactGroupDetails.Button.subtitle(contactsCount: group.contactEmails.count))
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

    private var groupItems: some View {
        FormList(collection: group.contactEmails, separator: .invertedNoPadding) { item in
            ContactCellView(item: item).frame(height: 68)
        }
        .listStyle(.insetGrouped)
    }
}

