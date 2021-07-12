//
//  MailboxViewController+BuildMessageViewModel.swift
//  ProtonMail
//
//
//  Copyright (c) 2021 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.


import UIKit


extension MailboxViewController {

    func buildNewMailboxMessageViewModel(
        message: Message,
        customFolderLabels: [Label],
        weekStart: WeekStart
    ) -> NewMailboxMessageViewModel {
        let labelId = viewModel.labelID
        let isSelected = self.viewModel.selectionContains(id: message.messageID)
        let initial = message.initial(replacingEmails: replacingEmails)
        let sender = message.sender(replacingEmails: replacingEmails)

        var mailboxViewModel = NewMailboxMessageViewModel(
            location: Message.Location(rawValue: viewModel.labelID),
            isLabelLocation: message.isLabelLocation(labelId: labelId),
            style: listEditing ? .selection(isSelected: isSelected) : .normal,
            initial: initial.apply(style: FontManager.body3RegularNorm),
            isRead: !message.unRead,
            sender: sender,
            time: date(of: message, weekStart: weekStart),
            isForwarded: message.forwarded,
            isReply: message.replied,
            isReplyAll: message.repliedAll,
            topic: message.subject,
            isStarred: message.starred,
            hasAttachment: message.numAttachments.intValue > 0,
            tags: message.createTags,
            messageCount: 0,
            folderIcons: []
        )
        if mailboxViewModel.displayOriginIcon {
            mailboxViewModel.folderIcons = message.getFolderIcons(customFolderLabels: customFolderLabels)
        }
        return mailboxViewModel
    }

    func buildNewMailboxMessageViewModel(
        conversation: Conversation,
        customFolderLabels: [Label],
        weekStart: WeekStart
    ) -> NewMailboxMessageViewModel {
        let labelId = viewModel.labelID
        let isSelected = self.viewModel.selectionContains(id: conversation.conversationID)
        let sender = conversation.getJoinedSendersName(replacingEmails)
        let initial = conversation.initial(replacingEmails)
        let messageCount = conversation.numMessages.intValue
        let isInCustomFolder = customFolderLabels.map({ $0.labelID }).contains(labelId)

        var mailboxViewModel = NewMailboxMessageViewModel(
            location: Message.Location(rawValue: viewModel.labelID),
            isLabelLocation: Message.Location(rawValue: viewModel.labelId) == nil && !isInCustomFolder ,
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
            hasAttachment: conversation.numAttachments.intValue > 0,
            tags: conversation.createTags(),
            messageCount: messageCount > 0 ? messageCount : 0,
            folderIcons: [])
        if mailboxViewModel.displayOriginIcon {
            mailboxViewModel.folderIcons = conversation.getFolderIcons(customFolderLabels: customFolderLabels)
        }
        return mailboxViewModel
    }

    private func date(of message: Message, weekStart: WeekStart) -> String {
        guard let date = message.time else { return .empty }
        return PMDateFormatter.shared.string(from: date, weekStart: weekStart)
    }

    private func date(of conversation: Conversation, labelId: String, weekStart: WeekStart) -> String {
        guard let date = conversation.getTime(labelID: labelId) else { return .empty }
        return PMDateFormatter.shared.string(from: date, weekStart: weekStart)
    }

}
