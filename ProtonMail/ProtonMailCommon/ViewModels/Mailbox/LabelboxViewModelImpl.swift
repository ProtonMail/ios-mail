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
    init(label : Label, userManager: UserManager, usersManager: UsersManager, pushService: PushNotificationService, coreDataService: CoreDataService) {
        self.label = label
        super.init(labelID: self.label.labelID, userManager: userManager, usersManager: usersManager, pushService: pushService, coreDataService: coreDataService)
    }

    override func showLocation () -> Bool {
        return true
    }
    
    override func ignoredLocationTitle() -> String {
        return self.label.exclusive ? self.label.name : ""
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
            if messageService.move(message: message, from: fLabel, to: Message.Location.trash.rawValue) {
                if self.label.labelID != fLabel {
                    return (.showGeneral, nil)
                }
                return (.showUndo, UndoMessage(msgID: message.messageID, origLabels: fLabel, newLabels: Message.Location.trash.rawValue))
            }
        }
        
        return (.nothing, nil)
    }
    
    override func archive(index: IndexPath) -> (SwipeResponse, UndoMessage?) {
        if let message = self.item(index: index) {
            if let fLabel = message.firstValidFolder() {
                if messageService.move(message: message, from: fLabel, to: Message.Location.archive.rawValue) {
                    if self.label.labelID != fLabel {
                        return (.showGeneral, nil)
                    }
                    return (.showUndo, UndoMessage(msgID: message.messageID, origLabels: fLabel, newLabels: Message.Location.archive.rawValue))
                }
            }
        }
        return (.nothing, nil)
    }
    
    override func spam(index: IndexPath) -> (SwipeResponse, UndoMessage?) {
        if let message = self.item(index: index) {
            if let fLabel = message.firstValidFolder() {
                if messageService.move(message: message, from: fLabel, to: Message.Location.spam.rawValue) {
                    if self.label.labelID != fLabel {
                        return (.showGeneral, nil)
                    }
                    return (.showUndo, UndoMessage(msgID: message.messageID, origLabels: fLabel, newLabels: Message.Location.spam.rawValue))
                }
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
