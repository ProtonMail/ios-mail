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
import InboxCore
import InboxCoreUI
import InboxDesignSystem
import proton_app_uniffi
import SwiftUI

struct ExpandedMessageCell: View {
    private let mailbox: Mailbox
    private let uiModel: ExpandedMessageCellUIModel
    private let draftPresenter: RecipientDraftPresenter
    private let messageAppearanceOverrideStore: MessageAppearanceOverrideStore
    private let onEvent: (ExpandedMessageCellEvent) -> Void
    private let htmlDisplayed: () -> Void
    private let areActionsHidden: Bool
    @Binding var attachmentIDToOpen: ID?
    @State private var isBodyLoaded: Bool = false
    @State private var viewDidAppear = false

    private var actionButtonsState: MessageDetailsView.ActionButtonsState {
        guard !areActionsHidden else { return .hidden }
        return isBodyLoaded ? .enabled : .disabled
    }

    init(
        mailbox: Mailbox,
        uiModel: ExpandedMessageCellUIModel,
        draftPresenter: RecipientDraftPresenter,
        messageAppearanceOverrideStore: MessageAppearanceOverrideStore,
        areActionsHidden: Bool,
        attachmentIDToOpen: Binding<ID?>,
        onEvent: @escaping (ExpandedMessageCellEvent) -> Void,
        htmlDisplayed: @escaping () -> Void
    ) {
        self.mailbox = mailbox
        self.uiModel = uiModel
        self.draftPresenter = draftPresenter
        self.messageAppearanceOverrideStore = messageAppearanceOverrideStore
        self.areActionsHidden = areActionsHidden
        self._attachmentIDToOpen = attachmentIDToOpen
        self.onEvent = onEvent
        self.htmlDisplayed = htmlDisplayed
    }

    var body: some View {
        VStack(spacing: .zero) {
            MessageDetailsView(
                uiModel: uiModel.messageDetails,
                mailbox: mailbox,
                messageAppearanceOverrideStore: messageAppearanceOverrideStore,
                actionButtonsState: actionButtonsState,
                onEvent: { event in
                    switch event {
                    case .onTap:
                        onEvent(.onTap)
                    case .onReply:
                        onEvent(.onReply)
                    case .onReplyAll:
                        onEvent(.onReplyAll)
                    case .onMessageAction(let action):
                        onEvent(.onMessageAction(action))
                    case .onSenderTap:
                        onEvent(.onSenderTap)
                    case .onRecipientTap(let recipient):
                        onEvent(.onRecipientTap(recipient))
                    case .onEditToolbar:
                        onEvent(.onEditToolbar)
                    }
                }
            )
            MessageBodyView(
                messageID: uiModel.id,
                emailAddress: uiModel.messageDetails.sender.address,
                attachments: uiModel.messageDetails.attachments,
                mailbox: mailbox,
                isBodyLoaded: $isBodyLoaded,
                attachmentIDToOpen: $attachmentIDToOpen,
                editScheduledMessage: { onEvent(.onEditScheduledMessage) },
                unsnoozeConversation: { onEvent(.unsnoozeConversation) },
                draftPresenter: draftPresenter
            )
            if !areActionsHidden {
                MessageActionButtonsView(
                    isSingleRecipient: uiModel.messageDetails.isSingleRecipient,
                    isDisabled: !isBodyLoaded,
                    onEvent: { event in
                        switch event {
                        case .reply:
                            onEvent(.onReply)
                        case .replyAll:
                            onEvent(.onReplyAll)
                        case .forward:
                            onEvent(.onForward)
                        }
                    }
                )
                .padding(.top, DS.Spacing.moderatelyLarge)
                .padding(.bottom, DS.Spacing.huge)
            }
        }
        .padding(.top, DS.Spacing.large)
        .onDidAppear {
            viewDidAppear = true
        }
        .onChange(of: isBodyLoaded && viewDidAppear) {
            htmlDisplayed()
        }
    }
}

struct ExpandedMessageCellUIModel: Identifiable, Equatable {
    let id: ID
    let unread: Bool
    let messageDetails: MessageDetailsUIModel
}

enum ExpandedMessageCellEvent {
    case onTap

    case onReply
    case onReplyAll
    case onForward

    case onSenderTap
    case onRecipientTap(MessageDetail.Recipient)

    case onEditScheduledMessage
    case unsnoozeConversation

    case onEditToolbar
    case onMessageAction(MessageAction)
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
            mailbox: .dummy,
            uiModel: .init(
                id: .init(value: 0),
                unread: false,
                messageDetails: messageDetails
            ),
            draftPresenter: DraftPresenter.dummy(),
            messageAppearanceOverrideStore: .init(),
            areActionsHidden: false,
            attachmentIDToOpen: .constant(nil),
            onEvent: { _ in },
            htmlDisplayed: {}
        )
        ExpandedMessageCell(
            mailbox: .dummy,
            uiModel: .init(
                id: .init(value: 1),
                unread: false,
                messageDetails: messageDetails
            ),
            draftPresenter: DraftPresenter.dummy(),
            messageAppearanceOverrideStore: .init(),
            areActionsHidden: false,
            attachmentIDToOpen: .constant(nil),
            onEvent: { _ in },
            htmlDisplayed: {}
        )
    }.environmentObject(ToastStateStore(initialState: .initial))
}
