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

import InboxDesignSystem
import ProtonUIFoundations
import SwiftUI

struct MailboxLegacyTopBar: View {
    @ScaledMetric var scale: CGFloat = 1

    let state: MailboxTopBarState
    let action: (MailboxTopBarAction) -> Void

    var body: some View {
        HStack {
            switch state {
            case .selectionMode(let selectAllState):
                selectAllButton(state: selectAllState)
            case .includeSpamTrash(let isSelected):
                spamTrashToggle(isSelected: isSelected)
            }
            Spacer()
        }
        .padding(.horizontal, DS.Spacing.large)
        .padding(.vertical, DS.Spacing.standard)
        .background(DS.Color.Background.norm)
        .accessibilityIdentifier(UnreadFilterIdentifiers.rootElement)
    }

    private func spamTrashToggle(isSelected: Bool) -> some View {
        SelectableCapsuleButton(isSelected: isSelected) {
            action(.spamTrashToggleTapped)
        } label: {
            Text(L10n.Mailbox.includeTrashSpamToggleTitle)
        }
    }

    private func selectAllButton(state: SelectAllState) -> some View {
        Button {
            action(.selectAllTapped)
        } label: {
            HStack(spacing: DS.Spacing.compact) {
                Image(symbol: state.button.icon)
                    .font(.footnote)
                    .tint(state.button.iconColor)
                Text(state.button.text)
                    .font(.footnote)
                    .foregroundStyle(state.button.textColor)
            }
        }
        .padding(.vertical, DS.Spacing.standard)
        .padding(.horizontal, DS.Spacing.medium * scale)
        .overlay {
            RoundedRectangle(cornerRadius: DS.Radius.massive * scale, style: .continuous)
                .stroke(DS.Color.Border.norm)
        }
    }
}

private struct UnreadFilterIdentifiers {
    static let rootElement = "unread.filter.button"
}
