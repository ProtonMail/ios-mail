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
import proton_app_uniffi
import SwiftUI

struct ConversationDetailListView: View {
    @EnvironmentObject var toastStateStore: ToastStateStore
    @ObservedObject private var model: ConversationDetailModel
    private let mailUserSession: MailUserSession
    private let goBack: () -> Void

    /// These attributes trigger the different action sheets
    @State private var senderActionTarget: ExpandedMessageCellUIModel?
    @State private var recipientActionTarget: MessageDetail.Recipient?

    init(model: ConversationDetailModel, mailUserSession: MailUserSession, goBack: @escaping () -> Void) {
        self.model = model
        self.mailUserSession = mailUserSession
        self.goBack = goBack
    }

    var body: some View {
        VStack(spacing: .zero) {
            switch model.state {
            case .initial:
                EmptyView()
            case .fetchingMessages:
                ConversationDetailsSkeletonView()
            case .messagesReady(let messages):
                messageList(messages: messages)
                    .padding(.top, DS.Spacing.compact)
            case .noConnection:
                NoConnectionView()
            }
        }
        .sheet(item: $senderActionTarget, content: senderActionSheet)
        .sheet(item: $recipientActionTarget, content: recipientActionSheet)
        .alert(model: $model.editScheduledMessageConfirmationAlert)
    }

    private func senderActionSheet(target: ExpandedMessageCellUIModel) -> some View {
        MessageAddressActionView(
            avatarUIModel: target.messageDetails.avatar,
            name: target.messageDetails.sender.name,
            emailAddress: target.messageDetails.sender.address,
            mailUserSession: mailUserSession
        )
        .pickerViewStyle([.height(390)])
    }

    private func recipientActionSheet(target: MessageDetail.Recipient) -> some View {
        MessageAddressActionView(
            avatarUIModel: AvatarUIModel(info: target.avatarInfo, type: .other),
            name: target.name,
            emailAddress: target.address,
            mailUserSession: mailUserSession
        )
        .pickerViewStyle([.height(390)])
    }

    private func messageList(messages: [MessageCellUIModel]) -> some View {
        ScrollViewReader { scrollView in
            LazyVStack(spacing: .zero) {
                ForEachEnumerated(messages, id: \.element.id) { cellUIModel, index in
                    cell(for: cellUIModel, index: index)
                        .padding(.bottom, messages.count - 1 == index ? 0 : DS.Spacing.extraLarge)
                        .background(DS.Color.Background.norm)
                        .clipShape(UnevenRoundedRectangle(topLeadingRadius: DS.Radius.extraLarge, topTrailingRadius: DS.Radius.extraLarge))
                        .shadow(DS.Shadows.raisedTop, isVisible: true)
                        .overlay(
                            GeometryReader { geometry in
                                UnevenRoundedRectangle(topLeadingRadius: DS.Radius.extraLarge, topTrailingRadius: DS.Radius.extraLarge)
                                    .stroke(DS.Color.Border.norm, lineWidth: 1)
                                    .padding(.horizontal, geometry.cardNeedsVerticalBorders ? DS.Spacing.tiny : -DS.Spacing.tiny)
                            }
                        )
                        .padding(.bottom, messages.count - 1 == index ? 0 : -DS.Spacing.extraLarge)
                }
            }
            .onChange(
                of: model.scrollToMessage,
                { oldValue, newValue in
                    if let newValue, newValue != oldValue {
                        scrollView.scrollTo(newValue, anchor: .top)
                    }
                }
            )
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier(ConversationDetailListViewIdentifiers.messageList)
        }
    }

    @ViewBuilder
    private func cell(for cellUIModel: MessageCellUIModel, index: Int) -> some View {
        switch cellUIModel.type {
        case .collapsed(let uiModel):
            CollapsedMessageCell(
                uiModel: uiModel,
                onTap: {
                    model.onMessageTap(messageId: cellUIModel.id, isDraft: uiModel.isDraft)
                }
            )
            .id(cellUIModel.cellId)
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier(ConversationDetailListViewIdentifiers.collapsedCell(index))
        case .expanded(let uiModel):
            expandedMessageCell(uiModel: uiModel)
                .id(cellUIModel.cellId)
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier(ConversationDetailListViewIdentifiers.expandedCell(index))
        }
    }

    private func expandedMessageCell(uiModel: ExpandedMessageCellUIModel) -> some View {
        ExpandedMessageCell(
            mailbox: model.mailbox.unsafelyUnwrapped,
            uiModel: uiModel,
            areActionsHidden: model.areActionsHidden,
            attachmentIDToOpen: $model.attachmentIDToOpen,
            onEvent: { onExpandedMessageCellEvent($0, uiModel: uiModel) },
            htmlLoaded: { model.markMessageAsReadIfNeeded(metadata: uiModel.toActionMetadata()) }
        )
        .environment(\.forceLightModeInMessageBody, model.isForcingLightMode(forMessageWithId: uiModel.id))
    }

    private func onExpandedMessageCellEvent(_ event: ExpandedMessageCellEvent, uiModel: ExpandedMessageCellUIModel) -> Void {
        switch event {
        case .onTap:
            model.onMessageTap(messageId: uiModel.id, isDraft: false)
        case .onReply:
            model.onReplyMessage(withId: uiModel.id, toastStateStore: toastStateStore)
        case .onReplyAll:
            model.onReplyAllMessage(withId: uiModel.id, toastStateStore: toastStateStore)
        case .onForward:
            model.onForwardMessage(withId: uiModel.id, toastStateStore: toastStateStore)
        case .onMoreActions:
            let currentLocationID = model.mailbox?.labelId()
            let hasAtMostOneMessageWithCurrentLocation = model.state.hasAtMostOneMessage(
                withLocationID: currentLocationID
            )
            model.actionSheets = model.actionSheets.copy(
                \.mailbox,
                to: .init(
                    id: uiModel.id,
                    type: .message(isLastMessageInCurrentLocation: hasAtMostOneMessageWithCurrentLocation),
                    title: model.seed.subject
                )
            )
        case .onSenderTap:
            senderActionTarget = uiModel
        case .onRecipientTap(let recipient):
            recipientActionTarget = recipient
        case .onEditScheduledMessage:
            model.onEditScheduledMessage(withId: uiModel.id, goBack: goBack, toastStateStore: toastStateStore)
        case .unsnoozeConversation:
            model.unsnoozeConversation(toastStateStore: toastStateStore)
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

private extension ConversationDetailModel.State {

    func hasAtMostOneMessage(withLocationID locationID: ID?) -> Bool {
        switch self {
        case .initial, .fetchingMessages, .noConnection:
            false
        case .messagesReady(let messages):
            messages
                .filter { message in message.locationID == locationID }
                .count == 1
        }
    }

}

private extension GeometryProxy {

    var cardNeedsVerticalBorders: Bool {
        safeAreaInsets.trailing != 0 || safeAreaInsets.leading != 0
    }

}
