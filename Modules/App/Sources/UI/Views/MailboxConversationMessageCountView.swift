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
import SwiftUI

struct MailboxConversationMessageCountView: View {
    let isRead: Bool
    let messagesCount: UInt64

    var body: some View {
        if let unreadFormatted = UnreadCountFormatter.stringIfGreaterThan0(count: messagesCount) {
            Text(unreadFormatted)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(isRead ? DS.Color.Text.weak : DS.Color.Text.norm)
                .padding(.vertical, DS.Spacing.tiny)
                .padding(.horizontal, DS.Spacing.small)
                .frame(minWidth: 18)
                .fixedSize()
                .lineLimit(1)
                .overlay(
                    RoundedRectangle(cornerRadius: DS.Radius.small)
                        .stroke(isRead ? DS.Color.Icon.weak : DS.Color.Icon.norm, lineWidth: 1)
                )
                .accessibilityIdentifier(MailConversationMessageCountView.countText)
        }
    }
}

#Preview {
    VStack(spacing: 10) {
        MailboxConversationMessageCountView(isRead: false, messagesCount: 0)
        MailboxConversationMessageCountView(isRead: true, messagesCount: 1)
        MailboxConversationMessageCountView(isRead: false, messagesCount: 12)
        MailboxConversationMessageCountView(isRead: false, messagesCount: 23889)
    }
    .border(.purple)
}

private struct MailConversationMessageCountView {
    static let countText = "count.text"
}
