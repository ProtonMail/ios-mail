//
//  MailboxViewController+BuildMessageViewModel.swift
//  Proton Mail
//
//
//  Copyright (c) 2021 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import UIKit

extension MailboxViewController {

    func buildNewMailboxMessageViewModel(
        message: MessageEntity,
        customFolderLabels: [LabelEntity],
        weekStart: WeekStart
    ) -> NewMailboxMessageViewModel {
        let labelId = viewModel.labelID
        let isSelected = self.viewModel.selectionContains(id: message.messageID.rawValue)
        let contactGroups = viewModel.contactGroups()
        let senderName = message.getSenderName(replacingEmails: replacingEmails, groupContacts: contactGroups)
        let initial = message.getInitial(senderName: senderName)
        let sender = message.getSender(senderName: senderName)
        let isSending = viewModel.messageService.isMessageBeingSent(id: message.messageID)

        var mailboxViewModel = NewMailboxMessageViewModel(
            location: Message.Location(viewModel.labelID),
            isLabelLocation: message.isLabelLocation(labelId: labelId),
            style: listEditing ? .selection(isSelected: isSelected) : .normal,
            initial: initial.apply(style: FontManager.body3RegularNorm),
            isRead: !message.unRead,
            sender: sender,
            time: isSending ? LocalString._mailbox_draft_is_sending : date(of: message, weekStart: weekStart),
            isForwarded: message.isForwarded,
            isReply: message.isReplied,
            isReplyAll: message.isRepliedAll,
            topic: message.title,
            isStarred: message.isStarred,
            hasAttachment: message.numAttachments > 0,
            tags: message.createTags(),
            messageCount: 0,
            folderIcons: []
        )
        if mailboxViewModel.displayOriginIcon {
            mailboxViewModel.folderIcons = message.getFolderIcons(customFolderLabels: customFolderLabels)
        }
        return mailboxViewModel
    }

    func buildNewMailboxMessageViewModel(
        conversation: ConversationEntity,
        conversationTagUIModels: [TagUIModel],
        customFolderLabels: [LabelEntity],
        weekStart: WeekStart
    ) -> NewMailboxMessageViewModel {
        let labelId = viewModel.labelID
        let isSelected = self.viewModel.selectionContains(id: conversation.conversationID.rawValue)
        let sender = conversation.getJoinedSendersName(replacingEmails)
        let initial = conversation.initial(replacingEmails)
        let messageCount = conversation.messageCount
        let isInCustomFolder = customFolderLabels.map({ $0.labelID }).contains(labelId)

        var mailboxViewModel = NewMailboxMessageViewModel(
            location: Message.Location(viewModel.labelID),
            isLabelLocation: Message.Location(viewModel.labelId) == nil && !isInCustomFolder,
            style: listEditing ? .selection(isSelected: isSelected) : .normal,
            initial: initial.apply(style: FontManager.body3RegularNorm),
            isRead: conversation.getNumUnread(labelID: labelId) <= 0,
            sender: sender,
            time: date(of: conversation, labelId: labelId, weekStart: weekStart),
            isForwarded: false,
            isReply: false,
            isReplyAll: false,
            topic: conversation.subject,
            isStarred: conversation.starred,
            hasAttachment: conversation.attachmentCount > 0,
            tags: conversationTagUIModels,
            messageCount: messageCount > 0 ? messageCount : 0,
            folderIcons: [])
        if mailboxViewModel.displayOriginIcon {
            mailboxViewModel.folderIcons = conversation.getFolderIcons(customFolderLabels: customFolderLabels)
        }
        return mailboxViewModel
    }

    private func date(of message: MessageEntity, weekStart: WeekStart) -> String {
        guard let date = message.time else { return .empty }
        return PMDateFormatter.shared.string(from: date, weekStart: weekStart)
    }

    private func date(of conversation: ConversationEntity, labelId: LabelID, weekStart: WeekStart) -> String {
        guard let date = conversation.getTime(labelID: labelId) else { return .empty }
        return PMDateFormatter.shared.string(from: date, weekStart: weekStart)
    }

}
