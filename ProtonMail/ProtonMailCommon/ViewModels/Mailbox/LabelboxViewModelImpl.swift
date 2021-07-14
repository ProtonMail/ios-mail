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
    
    override func delete(message: Message) -> (SwipeResponse, UndoMessage?) {
        if let fLabel = message.firstValidFolder() {
            if messageService.move(messages: [message], from: [fLabel], to: Message.Location.trash.rawValue) {
                if self.label.labelID != fLabel {
                    return (.showGeneral, nil)
                }
                return (.showUndo, UndoMessage(msgID: message.messageID, origLabels: fLabel, origHasStar: message.starred, newLabels: Message.Location.trash.rawValue))
            }
        }
        
        return (.nothing, nil)
    }

    override func delete(conversationIDs: [String]) -> (SwipeResponse, UndoMessage?) {
        if [Message.Location.draft.rawValue, Message.Location.spam.rawValue, Message.Location.trash.rawValue].contains(labelID) {
            conversationService.deleteConversations(with: conversationIDs, labelID: labelID) { [weak self] result in
                guard let self = self else { return }
                if let _ = try? result.get() {
                    self.eventsService.fetchEvents(labelID: self.labelId)
                }
            }
        } else {
            conversationService.move(conversationIDs: conversationIDs,
                                     from: self.labelID,
                                     to: Message.Location.trash.rawValue) { [weak self] result in
                guard let self = self else { return }
                if let _ = try? result.get() {
                    self.eventsService.fetchEvents(labelID: self.labelId)
                }
            }
        }
        return (.nothing, nil)
    }

    override func archive(index: IndexPath) -> (SwipeResponse, UndoMessage?) {
        if let message = self.item(index: index) {
            if let fLabel = message.firstValidFolder() {
                if messageService.move(messages: [message], from: [fLabel], to: Message.Location.archive.rawValue) {
                    if self.label.labelID != fLabel {
                        return (.showGeneral, nil)
                    }
                    return (.showUndo, UndoMessage(msgID: message.messageID, origLabels: fLabel, origHasStar: message.starred, newLabels: Message.Location.archive.rawValue))
                }
            }
        } else if let conversation = self.itemOfConversation(index: index) {
            if let fLabel = conversation.firstValidFolder() {
                conversationService.move(conversationIDs: [conversation.conversationID],
                                         from: fLabel,
                                         to: Message.Location.archive.rawValue) { [weak self] result in
                    guard let self = self else { return }
                    if let _ = try? result.get() {
                        self.eventsService.fetchEvents(labelID: self.labelId)
                    }
                }
                if self.label.labelID != fLabel {
                    return (.showGeneral, nil)
                }
                return (.showUndo, UndoMessage(msgID: conversation.conversationID, origLabels: fLabel, origHasStar: conversation.starred, newLabels: Message.Location.archive.rawValue))
            }
        }
        return (.nothing, nil)
    }
    
    override func spam(index: IndexPath) -> (SwipeResponse, UndoMessage?) {
        if let message = self.item(index: index) {
            if let fLabel = message.firstValidFolder() {
                if messageService.move(messages: [message], from: [fLabel], to: Message.Location.spam.rawValue) {
                    if self.label.labelID != fLabel {
                        return (.showGeneral, nil)
                    }
                    return (.showUndo, UndoMessage(msgID: message.messageID, origLabels: fLabel, origHasStar: message.starred, newLabels: Message.Location.spam.rawValue))
                }
            }
        } else if let conversation = self.itemOfConversation(index: index) {
            if let fLabel = conversation.firstValidFolder() {
                conversationService.move(conversationIDs: [conversation.conversationID],
                                         from: fLabel,
                                         to: Message.Location.spam.rawValue) { [weak self] result in
                    guard let self = self else { return }
                    if let _ = try? result.get() {
                        self.eventsService.fetchEvents(labelID: self.labelId)
                    }
                }
                if self.label.labelID != fLabel {
                    return (.showGeneral, nil)
                }
                return (.showUndo, UndoMessage(msgID: conversation.conversationID, origLabels: fLabel, origHasStar: conversation.starred, newLabels: Message.Location.archive.rawValue))
            }
        }
        return (.nothing, nil)
    }
  
    override func isShowEmptyFolder() -> Bool {
        return true
    }
    
    override func emptyFolder() {
        messageService.empty(labelID: self.label.labelID)
    }
}
