//
//  MailboxViewModelImpl.swift
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

final class MailboxViewModelImpl : MailboxViewModel {

    private let label : Message.Location

    init(label : Message.Location, userManager: UserManager, usersManager: UsersManager, pushService: PushNotificationService) {
        self.label = label
        super.init(labelID: label.rawValue, userManager: userManager, usersManager: usersManager, pushService: pushService)
    }
    
    override var localizedNavigationTitle: String {
        return self.label.localizedTitle
    }

    override func getSwipeTitle(_ action: MessageSwipeAction) -> String {
        switch(self.label) {
        case .trash, .spam:
            if action == .trash {
                return LocalString._general_delete_action
            }
            return action.description
        default:
            return action.description
        }
    }

    override func isSwipeActionValid(_ action: MessageSwipeAction) -> Bool {
        switch(self.label) {
        case .archive:
            return action != .archive
        case .starred:
            return action != .star
        case .spam:
            return action != .spam
        case .draft:
            return action != .spam && action != .trash && action != .archive
        case .sent:
            return action != .spam
        case .trash:
            return action != .trash
        case .allmail:
            return false
        default:
            return true
        }
    }
    
    override func stayAfterAction (_ action: MessageSwipeAction) -> Bool {
        switch(self.label) {
        case .starred:
            return true
        default:
            return false
        }
    }
    
    override func isDrafts() -> Bool {
        return self.label == .draft
    }
    
    override func isArchive() -> Bool {
        return self.label == .archive
    }
    
    override func isDelete () -> Bool {
        switch(self.label) {
        case .trash, .spam, .draft:
            return true
        default:
            return false
        }
    }
    
    override func showLocation() -> Bool {
        switch(self.label) {
        case .allmail, .sent, .trash, .archive, .draft:
            return true
        default:
            return false
        }
    }
    
    override func isShowEmptyFolder() -> Bool {
        switch(self.label) {
        case .trash, .spam, .draft:
            return true
        default:
            return false
        }
    }
    
    override func emptyFolder() {
        switch(self.label) {
        case .trash, .spam, .draft:
            self.messageService.empty(location: self.label)
        default:
            break
        }
    }
    
    
    override func ignoredLocationTitle() -> String {
        if self.label == .sent {
            return Message.Location.sent.title
        }
        if self.label == .trash {
            return Message.Location.trash.title
        }
        if self.label == .archive {
            return Message.Location.archive.title
        }
        if self.label == .draft {
            return Message.Location.draft.title
        }
        if self.label == .trash {
            return Message.Location.trash.title
        }
        return ""
    }
    
    override func reloadTable() -> Bool {
        return self.label == .draft
    }
    
    override func delete(message: Message) -> (SwipeResponse, UndoMessage?) {
        switch(self.label) {
        case .trash, .spam, .draft:
            if messageService.delete(message: message, label: self.label.rawValue) {
                return (.showGeneral, nil)
            }
        default:
            if messageService.move(message: message, from: self.label.rawValue, to: Message.Location.trash.rawValue) {
                return (.showUndo, UndoMessage(msgID: message.messageID, origLabels: self.label.rawValue, newLabels: Message.Location.trash.rawValue))
            }
        }
        
        return (.nothing, nil)
    }
    

}
