//
//  MailboxViewModel+ActionTypes.swift
//  ProtonMail - Created on 2021.
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

import Foundation

extension MailboxViewModel {
    ///This enum is used to indicate what types of action should this view to show in the action bar as actions.
    enum ActionTypes {
        case readUnread
        case labelAs
        case trash
        ///permanently delete the message
        case delete
        case moveTo
        case more
        case archive
        case spam
        case reply
        case replyAll
        
        #warning("v4 check later")
        var name: String {
            switch self {
            case .trash:
                return "Trash"
            case .delete:
                return "Delete"
            case .moveTo:
                return "Move to Inbox"
            case .more:
                return "More"
            case .archive:
                return "Archive"
            case .spam:
                return "Spam"
            case .labelAs:
                return "Label"
            case .reply:
                return "Reply"
            case .replyAll:
                return "Reply All"
            default:
                return ""
            }
        }
        
        var iconImage: UIImage? {
            switch self {
            case .archive:
                return UIImage(named: "action_bar_archive")
            case .delete, .trash:
                return UIImage(named: "action_bar_delete")
            case .moveTo:
                return UIImage(named: "action_bar_moveTo")
            case .more:
                return UIImage(named: "action_bar_more")
            case .spam:
                return UIImage(named: "action_bar_spam")
            case .labelAs:
                return UIImage(named: "action_bar_label")
            case .reply:
                return UIImage(named: "action_bar_reply")
            case .replyAll:
                return UIImage(named: "action_bar_replyAll")
            case .readUnread:
                return UIImage(named: "action_bar_readUnread")
            }
        }
    }
    
    //TODO: - v4 change later
    func getActionTypes() -> [ActionTypes] {
        //default inbox
        if let type = Message.Location.init(rawValue: self.labelID) {
            switch type {
            case .inbox, .starred, .archive, .allmail:
                return [.trash, .readUnread, .moveTo, .labelAs, .more]
            case .spam, .trash:
                return [.delete, .moveTo, .labelAs, .more]
            case .sent, .draft:
                return [.trash, .moveTo, .labelAs, .more]
            }
        }
        if let label = self.user.labelService.label(by: self.labelID) {
            if label.type == 3 {
                //custom folder
                return [.trash, .readUnread, .moveTo, .labelAs, .more]
            } else {
                //custom label
                return [.trash, .readUnread, .moveTo, .labelAs, .more]
            }
        } else {
            return []
        }
    }
    
    func handleBarActions(_ action: ActionTypes, selectedIDs: NSMutableSet) {
        switch action {
        case .archive:
            break
        case .readUnread:
            //if all unread -> read
            //if all read -> unread
            //if mixed read and unread -> unread
            let isAnyReadMessage = checkToUseReadOrUnreadAction(messageIDs: selectedIDs)
            self.mark(IDs: selectedIDs, unread: isAnyReadMessage)
        case .trash:
            self.move(IDs: selectedIDs, to: Message.Location.trash.rawValue)
        case .delete:
            self.delete(IDs: selectedIDs)
        case .spam:
            break
        case .reply:
            break
        case .replyAll:
            break
        case .moveTo, .labelAs, .more:
            break
        }
    }
}
