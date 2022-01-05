//
//  LabelboxViewModelImpl.swift
//  ProtonMail - Created on 8/15/15.
//
//
//  Copyright (c) 2019 Proton Technologies AG
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


import Foundation
import CoreData

class LabelboxViewModelImpl : MailboxViewModel {
    private let label : Label
    init(label : Label, userManager: UserManager, usersManager: UsersManager, pushService: PushNotificationService, coreDataService: CoreDataService, lastUpdatedStore: LastUpdatedStoreProtocol, queueManager: QueueManager) {
        self.label = label
        super.init(labelID: self.label.labelID, userManager: userManager, usersManager: usersManager, pushService: pushService, coreDataService: coreDataService, lastUpdatedStore: lastUpdatedStore, queueManager: queueManager)
    }

    override func showLocation () -> Bool {
        return true
    }
    
    override func ignoredLocationTitle() -> String {
        return self.label.type == 3 ? self.label.name : ""
    }
    
    override var localizedNavigationTitle: String {
        return self.label.name
    }
    
    override func getSwipeTitle(_ action: MessageSwipeAction) -> String {
        return action.description;
    }
    
    open override func stayAfterAction (_ action: MessageSwipeAction) -> Bool {
        if action == .trash || action == .spam {
            return false
        }
        return true
    }

    override func delete(conversation: Conversation, isSwipeAction: Bool = false) {
        if [Message.Location.draft.rawValue, Message.Location.spam.rawValue, Message.Location.trash.rawValue].contains(labelID) {
            conversationService.deleteConversations(with: [conversation.conversationID], labelID: labelID) { [weak self] result in
                guard let self = self else { return }
                if let _ = try? result.get() {
                    self.eventsService.fetchEvents(labelID: self.labelId)
                }
            }
        } else {
            // Empty string as source if we don't find a valid folder
            let fLabel = conversation.firstValidFolder() ?? ""
            conversationService.move(conversationIDs: [conversation.conversationID],
                                     from: fLabel,
                                     to: Message.Location.trash.rawValue,
                                     isSwipeAction: isSwipeAction) { [weak self] result in
                guard let self = self else { return }
                if let _ = try? result.get() {
                    self.eventsService.fetchEvents(labelID: self.labelId)
                }
            }
        }
    }

    override func archive(index: IndexPath, isSwipeAction: Bool = false) {
        if let message = self.item(index: index) {
            // Empty string as source if we don't find a valid folder
            let fLabel = message.firstValidFolder() ?? ""
            messageService.move(messages: [message], from: [fLabel], to: Message.Location.archive.rawValue)
        } else if let conversation = self.itemOfConversation(index: index) {
            // Empty string as source if we don't find a valid folder
            let fLabel = conversation.firstValidFolder() ?? ""
            conversationService.move(conversationIDs: [conversation.conversationID],
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
    
    override func spam(index: IndexPath, isSwipeAction: Bool = false) {
        if let message = self.item(index: index) {
            // Empty string as source if we don't find a valid folder
            let fLabel = message.firstValidFolder() ?? ""
            messageService.move(messages: [message], from: [fLabel], to: Message.Location.spam.rawValue)
        } else if let conversation = self.itemOfConversation(index: index) {
            // Empty string as source if we don't find a valid folder
            let fLabel = conversation.firstValidFolder() ?? ""
            conversationService.move(conversationIDs: [conversation.conversationID],
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
  
    override func isShowEmptyFolder() -> Bool {
        return true
    }
    
    override func emptyFolder() {
        messageService.empty(labelID: self.label.labelID)
    }
}
