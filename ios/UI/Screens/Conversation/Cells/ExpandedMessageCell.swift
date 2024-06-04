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

struct ExpandedMessageCell: View {
    private let uiModel: ExpandedMessageCellUIModel
    private let onTap: () -> Void

    /**
     Determines how the horizontal edges of the card are rendered to give visual
     continuation to the list (only visible in landscape mode).
     */
    private let isFirstCell: Bool

    private let cardCornerRadius = DS.Radius.extraLarge

    init(uiModel: ExpandedMessageCellUIModel, isFirstCell: Bool = false, onTap: @escaping () -> Void) {
        self.uiModel = uiModel
        self.isFirstCell = isFirstCell
        self.onTap = onTap
    }

    var body: some View {
        ZStack(alignment: .top) {
            MessageCardTopView(cornerRadius: cardCornerRadius)

            VStack(spacing: 0) {
                ExpandedMessageHeaderView(uiModel: uiModel, onTap: onTap)
                MessageBodyView(messageBody: uiModel.message, messageId: uiModel.messageId, uiModel: uiModel)

                Spacer()

                MessageActionButtonsView(isSingleRecipient: uiModel.isSingleRecipient)
            }
            .overlay { borderOnTheSides(show: isFirstCell) }
            .padding(.top, cardCornerRadius)
        }
        .overlay { borderOnTheSides(show: !isFirstCell) }
    }

    private func borderOnTheSides(show: Bool) -> some View {
        EdgeBorder(
            width: 1,
            edges: [.leading, .trailing]
        )
        .foregroundColor(DS.Color.Border.strong)
        .removeViewIf(!show)
    }
}

struct ExpandedMessageCellUIModel {
    let messageId: PMLocalMessageId
    let message: String?
    let sender: String
    let date: Date
    let senderPrivacy: String
    let recipients: String
    let isSingleRecipient: Bool
    let avatar: AvatarUIModel
}

#Preview {

    VStack(spacing: 0) {
        ExpandedMessageCell(
            uiModel: .init(
                messageId: 0,
                message: "Hey!!\n\nToday, I bought my plane tickets! 🛫 \nReady for a diet plenty of milanesas, parrilladas and alfajores!!\n\nLooking forward to it",
                sender: "john@gmail.com",
                date: .now,
                senderPrivacy: "john@gmail.com",
                recipients: "adrian@pm.me, brianne@proton.me, john_malkovich@yahoo.es",
                isSingleRecipient: false,
                avatar: .init(initials: "Gg", senderImageParams: .init())
            ), 
            isFirstCell: true,
            onTap: {}
        )
        ExpandedMessageCell(
            uiModel: .init(
                messageId: 1,
                message: "Hey!!\n\nToday, I bought my plane tickets! 🛫 \nReady for a diet plenty of milanesas, parrilladas and alfajores!!\n\nLooking forward to it",
                sender: "john@gmail.com",
                date: .now,
                senderPrivacy: "john@gmail.com",
                recipients: "adrian@pm.me, brianne@proton.me, john_malkovich@yahoo.es",
                isSingleRecipient: false,
                avatar: .init(initials: "Gg", senderImageParams: .init())
            ),
            isFirstCell: false,
            onTap: {}
        )
    }
}
