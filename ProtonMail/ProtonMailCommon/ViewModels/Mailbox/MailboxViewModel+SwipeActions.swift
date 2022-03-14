// Copyright (c) 2022 Proton Technologies AG
//
// This file is part of ProtonMail.
//
// ProtonMail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// ProtonMail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with ProtonMail. If not, see https://www.gnu.org/licenses/.

import Foundation

extension MailboxViewModel {
    func checkIsIndexPathMatch(with itemID: String, indexPath: IndexPath) -> Bool {
        if let message = item(index: indexPath) {
            return message.messageID == itemID
        } else if let conversation = itemOfConversation(index: indexPath) {
            return conversation.conversationID == itemID
        } else {
            return false
        }
    }
    
    func archive(index: IndexPath, isSwipeAction: Bool) {
        if let message = self.item(index: index) {
            // Empty string as source if we don't find a valid folder
            let fLabel = message.firstValidFolder() ?? ""
            messageService.move(messages: [message], from: [fLabel], to: Message.Location.archive.rawValue, isSwipeAction: isSwipeAction)
        } else if let conversation = self.itemOfConversation(index: index) {
            // Empty string as source if we don't find a valid folder
            let fLabel = conversation.firstValidFolder() ?? ""
            conversationProvider.move(conversationIDs: [conversation.conversationID],
                                      from: fLabel,
                                      to: Message.Location.archive.rawValue,
                                      isSwipeAction: isSwipeAction) { [weak self] result in
                guard let self = self else { return }
                if let _ = try? result.get() {
                    self.eventsService.fetchEvents(labelID: self.labelId)
                }
            }
        }
    }

    func spam(index: IndexPath, isSwipeAction: Bool) {
        if let message = self.item(index: index) {
            // Empty string as source if we don't find a valid folder
            let fLabel = message.firstValidFolder() ?? ""
            messageService.move(messages: [message],
                                from: [fLabel],
                                to: Message.Location.spam.rawValue,
                                isSwipeAction: isSwipeAction)
        } else if let conversation = self.itemOfConversation(index: index) {
            // Empty string as source if we don't find a valid folder
            let fLabel = conversation.firstValidFolder() ?? ""
            conversationProvider.move(conversationIDs: [conversation.conversationID],
                                      from: fLabel,
                                      to: Message.Location.spam.rawValue,
                                      isSwipeAction: isSwipeAction) { [weak self] result in
                guard let self = self else { return }
                if let _ = try? result.get() {
                    self.eventsService.fetchEvents(labelID: self.labelId)
                }
            }
        }
    }

    func delete(index: IndexPath, isSwipeAction: Bool) {
        if let message = self.item(index: index) {
            delete(message: message, isSwipeAction : isSwipeAction)
        } else if let conversation = self.itemOfConversation(index: index) {
            delete(conversation: conversation, isSwipeAction: isSwipeAction, completion: nil)
        }

    }

    func delete(message: Message, isSwipeAction: Bool) {
        if self.labelID != Message.Location.trash.rawValue {
            let fromLabelID = labelType == .label ? (message.firstValidFolder() ?? "") : self.labelID
            messageService.move(messages: [message], from: [fromLabelID], to: Message.Location.trash.rawValue, isSwipeAction: isSwipeAction)
        }
    }

    func delete(conversation: Conversation, isSwipeAction: Bool, completion: (() -> Void)?) {
        // Empty string as source if we don't find a valid folder
        let fLabel = conversation.firstValidFolder() ?? ""
        conversationProvider.move(conversationIDs: [conversation.conversationID],
                                 from: fLabel,
                                 to: Message.Location.trash.rawValue,
                                 isSwipeAction: isSwipeAction) { [weak self] result in
            defer {
                completion?()
            }
            guard let self = self else { return }
            if let _ = try? result.get() {
                self.eventsService.fetchEvents(labelID: self.labelId)
            }
        }
    }
}
