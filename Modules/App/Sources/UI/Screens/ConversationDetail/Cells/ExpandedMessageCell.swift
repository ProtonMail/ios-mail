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

import Collections
import InboxDesignSystem
import proton_app_uniffi
import SwiftUI

struct ExpandedMessageCell: View {
    private let mailbox: Mailbox
    private let uiModel: ExpandedMessageCellUIModel
    private let onEvent: (ExpandedMessageCellEvent) -> Void
    private let htmlLoaded: () -> Void
    @Binding var attachmentIDToOpen: ID?

    private let hasShadow: Bool
    private let areActionsDisabled: Bool

    // Determines how the horizontal edges of the card are rendered to give visual
    // continuation to the list (only visible in landscape mode).
    private let isFirstCell: Bool

    private let cardCornerRadius = DS.Radius.extraLarge

    init(
        mailbox: Mailbox,
        uiModel: ExpandedMessageCellUIModel,
        hasShadow: Bool = true,
        isFirstCell: Bool = false,
        areActionsDisabled: Bool,
        attachmentIDToOpen: Binding<ID?>,
        onEvent: @escaping (ExpandedMessageCellEvent) -> Void,
        htmlLoaded: @escaping () -> Void
    ) {
        self.mailbox = mailbox
        self.uiModel = uiModel
        self.hasShadow = hasShadow
        self.isFirstCell = isFirstCell
        self.areActionsDisabled = areActionsDisabled
        self._attachmentIDToOpen = attachmentIDToOpen
        self.onEvent = onEvent
        self.htmlLoaded = htmlLoaded
    }

    var body: some View {
        ZStack(alignment: .top) {
            MessageCardTopView(cornerRadius: cardCornerRadius, hasShadow: hasShadow)

            VStack(spacing: .zero) {
                MessageDetailsView(
                    uiModel: uiModel.messageDetails,
                    areActionsDisabled: areActionsDisabled,
                    onEvent: { event in
                        switch event {
                        case .onTap:
                            onEvent(.onTap)
                        case .onReply:
                            onEvent(.onReply)
                        case .onReplyAll:
                            onEvent(.onReplyAll)
                        case .onMoreActions:
                            onEvent(.onMoreActions)
                        case .onSenderTap:
                            onEvent(.onSenderTap)
                        case .onRecipientTap(let recipient):
                            onEvent(.onRecipientTap(recipient))
                        }
                    }
                )
                MessageBannersView(types: OrderedSet([]), timer: Timer.self)
                MessageBodyAttachmentsView(
                    state: .state(attachments: uiModel.messageDetails.attachments),
                    attachmentIDToOpen: $attachmentIDToOpen
                )
                MessageBodyView(
                    messageId: uiModel.id,
                    mailbox: mailbox, 
                    htmlLoaded: htmlLoaded
                )
                if !areActionsDisabled {
                    MessageActionButtonsView(isSingleRecipient: uiModel.messageDetails.isSingleRecipient, onEvent: { event in
                        switch event {
                        case .reply:
                            onEvent(.onReply)
                        case .replyAll:
                            onEvent(.onReplyAll)
                        case .forward:
                            onEvent(.onForward)
                        }
                    })
                    .padding(.top, DS.Spacing.moderatelyLarge)
                    .padding(.bottom, DS.Spacing.large)
                }
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
    let id: ID
    let unread: Bool
    let messageDetails: MessageDetailsUIModel
}

enum ExpandedMessageCellEvent {
    case onTap

    case onReply
    case onReplyAll
    case onForward
    case onMoreActions

    case onSenderTap
    case onRecipientTap(MessageDetail.Recipient)
}

extension MessageBodyAttachmentsState {

    static func state(attachments: [AttachmentDisplayModel]) -> Self {
        .init(
            attachments: attachments,
            listState: attachments.count > 3 ? .long(isAttachmentsListOpen: false) : .short
        )
    }

}

private extension MessageBody {

    static func testInstance(rawBody: String) -> Self {
        .init(rawBody: rawBody, embeddedImageProvider: DecryptedMessage(noPointer: .init()))
    }

}

#Preview {
    let messageDetails = MessageDetailsPreviewProvider.testData(
        location: .system(name: .inbox, id: .random()),
        labels: [
            .init(labelId: .init(value: 1), text: "Friends and Holidays", color: .blue)
        ]
    )

    return VStack(spacing: 0) {
        ExpandedMessageCell(
            mailbox: Mailbox(noPointer: .init()),
            uiModel: .init(
                id: .init(value: 0),
                unread: false,
                messageDetails: messageDetails
            ),
            hasShadow: false,
            isFirstCell: true, 
            areActionsDisabled: false,
            attachmentIDToOpen: .constant(nil),
            onEvent: { _ in },
            htmlLoaded: {}
        )
        ExpandedMessageCell(
            mailbox: Mailbox(noPointer: .init()),
            uiModel: .init(
                id: .init(value: 1),
                unread: false,
                messageDetails: messageDetails
            ),
            hasShadow: true,
            isFirstCell: false, 
            areActionsDisabled: false, 
            attachmentIDToOpen: .constant(nil),
            onEvent: { _ in },
            htmlLoaded: {}
        )
    }
}
