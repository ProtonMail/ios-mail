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

import InboxCoreUI
import InboxDesignSystem
import SwiftUI

struct ConversationDetailListView: View {
    @EnvironmentObject var toastStateStore: ToastStateStore
    @ObservedObject private var model: ConversationDetailModel

    /// These attributes trigger the different action sheets
    @State private var senderActionTarget: ExpandedMessageCellUIModel?
    @State private var recipientActionTarget: MessageDetail.Recipient?

    init(model: ConversationDetailModel) {
        self.model = model
    }

    var body: some View {
        VStack(spacing: 0) {
            switch model.state {
            case .initial:
                EmptyView()
            case .fetchingMessages:
                ConversationDetailsSkeletonView()
            case .messagesReady(let previous, let last):
                messageList(previous: previous, last: last)
                    .padding(.top, DS.Spacing.compact)
            }
        }
        .sheet(item: $senderActionTarget, content: senderActionPicker)
        .sheet(item: $recipientActionTarget, content: recipientActionPicker)
    }

    private func senderActionPicker(target: ExpandedMessageCellUIModel) -> some View {
        MessageAddressActionPickerView(
            avatarUIModel: target.messageDetails.avatar,
            name: target.messageDetails.sender.name,
            emailAddress: target.messageDetails.sender.address
        )
        .pickerViewStyle([.height(450)])
    }

    private func recipientActionPicker(target: MessageDetail.Recipient) -> some View {
        MessageAddressActionPickerView(
            avatarUIModel: AvatarUIModel(info: target.avatarInfo, type: .other),
            name: target.name,
            emailAddress: target.address
        )
        .pickerViewStyle([.height(390)])
    }

    private func messageList(previous: [MessageCellUIModel], last: ExpandedMessageCellUIModel) -> some View {
        ScrollViewReader { scrollView in
            VStack(spacing: .zero) {
                LazyVStack(spacing: .zero) {
                    ForEachEnumerated(previous, id: \.element.id) { cellUIModel, index in
                        switch cellUIModel.type {
                        case .collapsed(let uiModel):
                            CollapsedMessageCell(uiModel: uiModel, isFirstCell: index == 0, onTap: {
                                model.onMessageTap(messageId: cellUIModel.id)
                            })
                            .id(cellUIModel.cellId)
                            .accessibilityElement(children: .contain)
                            .accessibilityIdentifier(ConversationDetailListViewIdentifiers.collapsedCell(index))
                        case .expanded(let uiModel):
                            ExpandedMessageCell(
                                mailbox: model.mailbox.unsafelyUnwrapped,
                                uiModel: uiModel,
                                isFirstCell: index == 0,
                                attachmentIDToOpen: $model.attachmentIDToOpen,
                                onEvent: { onExpandedMessageCellEvent($0, uiModel: uiModel) },
                                htmlLoaded: { model.markMessageAsReadIfNeeded(metadata: uiModel.toActionMetadata()) }
                            )
                            .id(cellUIModel.cellId)
                            .accessibilityElement(children: .contain)
                            .accessibilityIdentifier(ConversationDetailListViewIdentifiers.expandedCell(index))
                        }
                    }
                }
                ExpandedMessageCell(
                    mailbox: model.mailbox.unsafelyUnwrapped,
                    uiModel: last,
                    hasShadow: !previous.isEmpty,
                    isFirstCell: previous.isEmpty,
                    attachmentIDToOpen: $model.attachmentIDToOpen,
                    onEvent: { onExpandedMessageCellEvent($0, uiModel: last) },
                    htmlLoaded: { model.markMessageAsReadIfNeeded(metadata: last.toActionMetadata()) }
                )
                .id(ConversationDetailModel.lastCellId) // static value because it won't be replaced with CollapsedMessageCell
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier(ConversationDetailListViewIdentifiers.expandedCell(previous.count))
            }
            .task {
                scrollView.scrollTo(model.scrollToMessage, anchor: .top)
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier(ConversationDetailListViewIdentifiers.messageList)
        }
    }

    private func onExpandedMessageCellEvent(_ event: ExpandedMessageCellEvent, uiModel: ExpandedMessageCellUIModel) -> Void {
        switch event {
        case .onTap:
            model.onMessageTap(messageId: uiModel.id)
        case .onReply:
            model.onReplyMessage(withId: uiModel.id, toastStateStore: toastStateStore)
        case .onReplyAll:
            model.onReplyAllMessage(withId: uiModel.id, toastStateStore: toastStateStore)
        case .onForward:
            model.onForwardMessage(withId: uiModel.id, toastStateStore: toastStateStore)
        case .onMoreActions:
            model.actionSheets = model.actionSheets.copy(
                \.mailbox, to: .init(ids: [uiModel.id], type: .message, title: model.seed.subject)
            )
        case .onSenderTap:
            senderActionTarget = uiModel
        case .onRecipientTap(let recipient):
            recipientActionTarget = recipient
        }
    }
}

private struct ConversationDetailListViewIdentifiers {
    static let messageList = "detail.messageList"

    static func collapsedCell(_ index: Int) -> String {
        "detail.cell.collapsed#\(index)"
    }

    static func expandedCell(_ index: Int) -> String {
        "detail.cell.expanded#\(index)"
    }
}

private extension ExpandedMessageCellUIModel {

    func toActionMetadata() -> MarkMessageAsReadMetadata {
        .init(messageID: id, unread: unread)
    }

}
