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
import SwiftUI

struct MailboxEmptyView: View {

    var body: some View {
        VStack(spacing: 0) {
            Text(L10n.Mailbox.EmptyState.title)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(DS.Color.Text.weak)
                .multilineTextAlignment(.center)
                .padding(.top, DS.Spacing.large)
                .accessibilityIdentifier(MailboxEmptyViewIdentifiers.emptyTitle)
            Text(L10n.Mailbox.EmptyState.message)
                .font(.subheadline)
                .foregroundStyle(DS.Color.Text.weak)
                .multilineTextAlignment(.center)
                .padding(.top, DS.Spacing.compact)
                .accessibilityIdentifier(MailboxEmptyViewIdentifiers.emptyDescription)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, DS.Spacing.jumbo)
        .background(DS.Color.Background.norm)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(MailboxEmptyViewIdentifiers.rootItem)
    }
}

private struct MailboxEmptyViewIdentifiers {
    static let rootItem = "mailbox.empty.rootItem"
    static let emptyIcon = "mailbox.empty.icon"
    static let emptyTitle = "mailbox.empty.title"
    static let emptyDescription = "mailbox.empty.description"
}
