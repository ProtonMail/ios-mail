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
                    uiModel: conversation,
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
    let uiModel: ConversationCellUIModel
    let onEvent: (ConversationCellEvent) -> Void

    private var textColor: Color {
        uiModel.isRead ? MailColor.textWeak : MailColor.textNorm
    }

    private var labelLeadingPadding: CGFloat {
        uiModel.labelUIModel.isEmpty ? 0 : 4
    }

    var body: some View {
        HStack(spacing: 16.0) {

            AvatarCheckboxView(
                isSelected: uiModel.isSelected,
                onDidChangeSelection: { onEvent(.onSelectedChange(isSelected: $0)) }
            )
            .frame(width: 40, height: 40)

            VStack(spacing: 2) {

                HStack {

                    Text(uiModel.senders)
                        .font(.subheadline)
                        .lineLimit(1)
                        .bold(!uiModel.isRead)
                        .foregroundColor(textColor)
                    Spacer()
                    Text(uiModel.date.formatted(date: .long, time: .omitted))
                        .font(.footnote)
                        .bold(!uiModel.isRead)
                        .foregroundColor(textColor)
                }

                HStack(spacing: 0) {

                    Text(uiModel.subject)
                        .font(.callout)
                        .lineLimit(1)
                        .bold(!uiModel.isRead)
                        .foregroundColor(textColor)
                        .layoutPriority(1)
                    MailboxLabelView(uiModel: uiModel.labelUIModel)
                        .padding(.leading, labelLeadingPadding)
                    Spacer()
                    Image(uiImage: uiModel.isStarred ? MailIcon.icStarFilled : MailIcon.icStar)
                        .resizable()
                        .frame(width: 16, height: 16)
                        .foregroundColor(uiModel.isStarred ? .yellow : MailColor.textWeak)
                        .onTapGesture {
                            onEvent(.onStarredChange(isStarred: !uiModel.isStarred))
                        }
                }
            }

        }
        .padding(14)
        .background(uiModel.isSelected ? MailColor.backgroundSecondary : Color(UIColor.systemBackground))
    }
}

#Preview {
    return ConversationMailboxScreen(model: PreviewData.conversationMailboxScreenModel)
}
