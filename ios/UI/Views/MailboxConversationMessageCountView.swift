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

struct MailboxConversationMessageCountView: View {
    let numMessages: UInt64

    private let cornerRadius = 6.0

    var body: some View {
        if let unreadFormatted = UnreadCountFormatter.string(count: numMessages) {
            Text(unreadFormatted)
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(DS.Color.Text.weak)
                .padding(.vertical, DS.Spacing.tiny)
                .padding(.horizontal, DS.Spacing.small)
                .frame(minWidth: 20)
                .fixedSize()
                .lineLimit(1)
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(DS.Color.Background.secondary)
                )
                .accessibilityIdentifier(MailConversationMessageCountView.countText)
        }
    }
}

#Preview {
    VStack(spacing: 10) {
        MailboxConversationMessageCountView(numMessages: 0)
        MailboxConversationMessageCountView(numMessages: 1)
        MailboxConversationMessageCountView(numMessages: 12)
        MailboxConversationMessageCountView(numMessages: 23889)
    }
    .border(.purple)
}

private struct MailConversationMessageCountView {
    static let countText = "count.text"
}
