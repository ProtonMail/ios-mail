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
    private let onEvent: (ExpandedMessageCellEvent) -> Void

    private let hasShadow: Bool

    // Determines how the horizontal edges of the card are rendered to give visual
    // continuation to the list (only visible in landscape mode).
    private let isFirstCell: Bool

    private let cardCornerRadius = DS.Radius.extraLarge

    init(
        uiModel: ExpandedMessageCellUIModel,
        hasShadow: Bool = true,
        isFirstCell: Bool = false,
        onEvent: @escaping (ExpandedMessageCellEvent) -> Void
    ) {
        self.uiModel = uiModel
        self.hasShadow = hasShadow
        self.isFirstCell = isFirstCell
        self.onEvent = onEvent
    }

    var body: some View {
        ZStack(alignment: .top) {
            MessageCardTopView(cornerRadius: cardCornerRadius, hasShadow: hasShadow)

            VStack(spacing: 0) {
                MessageDetailsView(uiModel: uiModel.messageDetails, onEvent: { event in
                    switch event {
                    case .onTap:
                        onEvent(.onTap)
                    case .onReply:
                        onEvent(.onReply)
                    case .onReplyAll:
                        onEvent(.onReplyAll)
                    case .onMoreActions:
                        onEvent(.onMoreActions)
                    }
                })
                MessageBodyView(messageBody: uiModel.message, messageId: uiModel.messageId, uiModel: uiModel)

                Spacer()

                MessageActionButtonsView(isSingleRecipient: uiModel.messageDetails.isSingleRecipient)
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

struct ExpandedMessageCellUIModel: Identifiable {
    var id: PMLocalMessageId { messageId }
    let messageId: PMLocalMessageId
    let message: String?
    let messageDetails: MessageDetailsUIModel
}

enum ExpandedMessageCellEvent {
    case onTap
    case onReply
    case onReplyAll
    case onForward
    case onMoreActions
}

#Preview {

    let messageDetails = MessageDetailsUIModel(
        avatar: .init(initials: "Gg", senderImageParams: .init()),
        sender: .init(name: "Camila Hall", address: "camila.hall@protonmail.ch", encryptionInfo: "End to end encrypted and signed"),
        isSenderProtonOfficial: true,
        recipientsTo: [
            .init(name: "Me", address: "eric.norbert@protonmail.ch"),
        ],
        recipientsCc: [
            .init(name: "James Hayes", address: "james@proton.me"),
            .init(name: "Riley Scott", address: "scott375@gmail.com"),
            .init(name: "Layla Robinson", address: "layla.rob@protonmail.ch"),
        ],
        recipientsBcc: [
            .init(name: "Isabella Coleman", address: "isa_coleman@protonmail.com"),
        ],
        date: .now,
        location: .systemFolder(.inbox),
        labels: [.init(labelId: 1, text: "Friends and Holidays", color: .blue)],
        other: [.starred, .pinned]
    )

    return VStack(spacing: 0) {
        ExpandedMessageCell(
            uiModel: .init(
                messageId: 0,
                message: "Hey!!\n\nToday, I bought my plane tickets! 🛫 \nReady for a diet plenty of milanesas, parrilladas and alfajores!!\n\nLooking forward to it",
                messageDetails: messageDetails
            ),
            hasShadow: false,
            isFirstCell: true,
            onEvent: { _ in }
        )
        ExpandedMessageCell(
            uiModel: .init(
                messageId: 1,
                message: "Hey!!\n\nToday, I bought my plane tickets! 🛫 \nReady for a diet plenty of milanesas, parrilladas and alfajores!!\n\nLooking forward to it",
                messageDetails: messageDetails
            ),
            hasShadow: true,
            isFirstCell: false,
            onEvent: { _ in }
        )
    }
}
