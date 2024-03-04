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

struct ConversationMailboxScreen: View {
    @State var model: ConversationMailboxScreenModel

    var body: some View {
        List {
            ForEach(model.conversations) { conversation in
                ConversationCell(
                    senders: conversation.senders,
                    subject: conversation.subject,
                    date: conversation.date,
                    isSelected: conversation.isSelected,
                    isRead: conversation.isRead,
                    isStarred: conversation.isStarred,
                    onEvent: { [weak model] event in
                        switch event {
                        case .onSelectedChange(let isSelected):
                            model?.onConversationSelectionChange(id: conversation.id, isSelected: isSelected)
                        case .onStarredChange(let isStarred):
                            model?.onConversationStarChange(id: conversation.id, isStarred: isStarred)
                        }
                    }
                )
                .listRowInsets(
                    .init(top: 1, leading: 1, bottom: 1, trailing: 0)
                )
                .listRowSeparator(.hidden)
                .clipShape(
                    .rect(
                        topLeadingRadius: 20,
                        bottomLeadingRadius: 20,
                        bottomTrailingRadius: 0,
                        topTrailingRadius: 0
                    )
                )
            }
        }
        .listStyle(.plain)
    }
}

enum ConversationCellEvent {
    case onSelectedChange(isSelected: Bool)
    case onStarredChange(isStarred: Bool)
}

struct ConversationCell: View {
    let senders: String
    let subject: String
    let date: Date
    let isSelected: Bool
    let isRead: Bool
    let isStarred: Bool

    let onEvent: (ConversationCellEvent) -> Void

    var textColor: Color {
        isRead ? MailColor.textWeak : MailColor.textNorm
    }

    var body: some View {
        HStack(spacing: 16.0) {
            AvatarCheckboxView(
                isSelected: isSelected,
                onDidChangeSelection: { onEvent(.onSelectedChange(isSelected: $0)) }
            )
            .frame(width: 40, height: 40)

            VStack(spacing: 2) {
                HStack {
                    Text(senders)
                        .font(.subheadline)
                        .lineLimit(1)
                        .bold(!isRead)
                        .foregroundColor(textColor)
                    Spacer()
                    Text(date.formatted(date: .long, time: .omitted))
                        .font(.footnote)
                        .bold(!isRead)
                        .foregroundColor(textColor)
                }

                HStack {
                    Text(subject)
                        .font(.callout)
                        .lineLimit(1)
                        .bold(!isRead)
                        .foregroundColor(textColor)
                    Spacer()
                    Image(uiImage: isStarred ? MailIcon.icStarFilled : MailIcon.icStar)
                        .resizable()
                        .frame(width: 16, height: 16)
                        .foregroundColor(isStarred ? .yellow : MailColor.textWeak)
                        .onTapGesture {
                            onEvent(.onStarredChange(isStarred: !isStarred))
                        }
                }
            }

        }
        .padding(14)
        .background(isSelected ? MailColor.backgroundSecondary : Color(UIColor.systemBackground))
    }
}

#Preview {
    return ConversationMailboxScreen(model: PreviewData.conversationMailboxScreenModel)
}
