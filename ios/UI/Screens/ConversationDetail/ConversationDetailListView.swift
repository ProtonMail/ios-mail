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

struct ConversationDetailListView: View {
    @ObservedObject private var model: ConversationDetailModel
    @State private var showMessageActionPicker: Bool = false
    
    /// These attributes trigger the different action sheets
    @State private var messageActionTarget: ExpandedMessageCellUIModel?
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
                ProgressView()
                    .padding(.top, DS.Spacing.medium)
                    .accessibilityIdentifier(ConversationDetailListViewIdentifiers.loader)
            case .messagesReady(let previous, let last):
                messageList(previous: previous, last: last)
                    .padding(.top, DS.Spacing.compact)
            }
        }
        .sheet(item: $messageActionTarget, content: messageActionPicker)
        .sheet(item: $senderActionTarget, content: senderActionPicker)
        .sheet(item: $recipientActionTarget, content: recipientActionPicker)
    }

    private func messageActionPicker(target: ExpandedMessageCellUIModel) -> some View {
        let readStatus: SelectionReadStatus = .allRead // because the cell is expanded
        let starStatus: SelectionStarStatus = target.messageDetails.other.contains(.starred)
        ? .allStarred
        : .noneStarred

        let conditionalParams = ConditionalActionResolverParams(
            selectionReadStatus: readStatus,
            selectionStarStatus: starStatus,
            systemFolder: model.seed.selectedMailbox.systemFolder
        )

        return MailboxItemActionPickerView(
            mailboxItemIdentifier: .message(target.messageId),
            isSingleRecipient: target.messageDetails.isSingleRecipient,
            actionResolverParams: conditionalParams,
            onActionTap: { action, item in
                print("action \(action) for item \(item)")
            }
        )
        .pickerViewStyle([.large])
    }

    private func senderActionPicker(target: ExpandedMessageCellUIModel) -> some View {
        return MessageAddressActionPickerView(
            avatarUIModel: target.messageDetails.avatar,
            name: target.messageDetails.sender.name,
            emailAddress: target.messageDetails.sender.address
        )
        .pickerViewStyle([.height(450)])
    }

    private func recipientActionPicker(target: MessageDetail.Recipient) -> some View {
        // TODO: The initials and background color should be provided from the Rust SDK
        let avatarUIModel = AvatarUIModel(
            initials: target.name.first?.uppercased() ?? "",
            backgroundColor: DS.Color.Brand.darken10,
            type: .other
        )
        return MessageAddressActionPickerView(
            avatarUIModel: avatarUIModel,
            name: target.name != target.address ? target.name : "",
            emailAddress: target.address
        )
        .pickerViewStyle([.height(390)])
    }

    private func messageList(previous: [MessageCellUIModel], last: ExpandedMessageCellUIModel) -> some View {
        ScrollViewReader { scrollView in
            VStack(spacing: 0) {
                LazyVStack(spacing: 0) {
                    ForEach(Array(previous.enumerated()), id: \.element.id) { index, cellUIModel in
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
                                uiModel: uiModel,
                                isFirstCell: index == 0,
                                onEvent: { onExpandedMessageCellEvent($0, uiModel: uiModel) }
                            )
                            .id(cellUIModel.cellId)
                            .accessibilityElement(children: .contain)
                            .accessibilityIdentifier(ConversationDetailListViewIdentifiers.expandedCell(index))
                        }
                    }
                }
                ExpandedMessageCell(
                    uiModel: last,
                    hasShadow: !previous.isEmpty,
                    isFirstCell: previous.isEmpty,
                    onEvent: { onExpandedMessageCellEvent($0, uiModel: last) }
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
            model.onMessageTap(messageId: uiModel.messageId)
        case .onReply:
            break
        case .onReplyAll:
            break
        case .onForward:
            break
        case .onMoreActions:
            messageActionTarget = uiModel
        case .onSenderTap:
            senderActionTarget = uiModel
        case .onRecipientTap(let recipient):
            recipientActionTarget = recipient
        }
    }
}

private struct ConversationDetailListViewIdentifiers {
    static let loader = "detail.loader"
    static let messageList = "detail.messageList"

    static func collapsedCell(_ index: Int) -> String {
        "detail.cell.collapsed#\(index)"
    }

    static func expandedCell(_ index: Int) -> String {
        "detail.cell.expanded#\(index)"
    }
}
