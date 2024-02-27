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

import SwiftUI

struct ConversationMailboxScreen: View {
    let model: ConversationMailboxModel

    var body: some View {
        List {
            ForEach(model.conversations) { conversation in
                ConversationCell(
                    senders: conversation.senders,
                    subject: conversation.subject,
                    date: conversation.date,
                    isSelected: model.selectedConversations.contains(conversation.id),
                    onEvent: { [weak model] event in
                        switch event {
                        case .onSelectedChange(let isSelected):
                            model?.onConversationSelectionChange(id: conversation.id, isSelected: isSelected)
                        }
                    }
                )
            }
        }
        .listStyle(.plain)
    }
}

enum ConversationCellEvent {
    case onSelectedChange(isSelected: Bool)
}

struct ConversationCell: View {
    let senders: String
    let subject: String
    let date: Date
    let isSelected: Bool

    let onEvent: (ConversationCellEvent) -> Void

    var body: some View {

        HStack {
            AvatarCheckboxView(
                isSelected: isSelected,
                onDidChangeSelection: { onEvent(.onSelectedChange(isSelected: $0)) }
            )
            .frame(width: 24, height: 24)

            VStack {
                HStack {
                    Text(senders)
                        .font(.headline)
                        .lineLimit(1)
                    Spacer()
                    Text(date.formatted(date: .long, time: .omitted))
                        .font(.footnote)
                }

                HStack {
                    Text(subject)
                        .font(.subheadline)
                        .lineLimit(1)
                    Spacer()
                }
            }
        }
    }
}

#Preview {
    return ConversationMailboxScreen(model: PreviewData.conversationMailboxModel)
}
