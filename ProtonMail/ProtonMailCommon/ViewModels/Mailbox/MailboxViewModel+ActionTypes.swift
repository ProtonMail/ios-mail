//
//  MailboxViewModel+ActionTypes.swift
//  ProtonMail - Created on 2021.
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

import Foundation
import ProtonCore_UIFoundations

extension MailboxViewModel {
    /// This enum is used to indicate what types of action should this view to show in the action bar as actions.
    enum ActionTypes {
        case readUnread
        case labelAs
        case trash
        /// permanently delete the message
        case delete
        case moveTo
        case more
        case reply
        case replyAll

        var name: String {
            switch self {
            case .trash:
                return LocalString._action_bar_title_trash
            case .delete:
                return LocalString._action_bar_title_delete
            case .moveTo:
                return LocalString._action_bar_title_moveTo
            case .more:
                return LocalString._action_bar_title_more
            case .labelAs:
                return LocalString._action_bar_title_labelAs
            case .reply:
                return LocalString._action_bar_title_reply
            case .replyAll:
                return LocalString._action_bar_title_replyAll
            default:
                return ""
            }
        }

        var iconImage: ImageAsset.Image {
            switch self {
            case .delete:
                return IconProvider.trashCross
            case .trash:
                return IconProvider.trash
            case .moveTo:
                return IconProvider.folderArrowIn
            case .more:
                return IconProvider.threeDotsHorizontal
            case .labelAs:
                return IconProvider.tag
            case .reply:
                return IconProvider.arrowUpAndLeft
            case .replyAll:
                return IconProvider.arrowsUpAndLeft
            case .readUnread:
                return IconProvider.envelopeDot
            }
        }

        var accessibilityIdentifier: String {
            switch self {
            case .delete:
                return "PMToolBarView.deleteButton"
            case .trash:
                return "PMToolBarView.trashButton"
            case .moveTo:
                return "PMToolBarView.moveToButton"
            case .more:
                return "PMToolBarView.moreButton"
            case .labelAs:
                return "PMToolBarView.labelAsButton"
            case .reply:
                return "PMToolBarView.replyButton"
            case .replyAll:
                return "PMToolBarView.replyAllButton"
            case .readUnread:
                return "PMToolBarView.unreadButton"
            }
        }
    }

    func getActionBarActions() -> [ActionTypes] {
        // default inbox
        if let type = Message.Location.init(rawValue: self.labelID) {
            switch type {
            case .inbox, .starred, .archive, .allmail, .sent, .draft:
                return [.trash, .readUnread, .moveTo, .labelAs, .more]
            case .spam, .trash:
                return [.delete, .moveTo, .labelAs, .more]
            }
        }
        if let label = self.labelProvider.getLabel(by: labelID) {
            if label.type == 3 {
                // custom folder
                return [.trash, .readUnread, .moveTo, .labelAs, .more]
            } else {
                // custom label
                return [.trash, .readUnread, .moveTo, .labelAs, .more]
            }
        } else {
            return []
        }
    }

    func handleBarActions(_ action: ActionTypes, selectedIDs: Set<String>) {
        switch action {
        case .readUnread:
            // if all unread -> read
            // if all read -> unread
            // if mixed read and unread -> unread
            let isAnyReadMessage = checkToUseReadOrUnreadAction(messageIDs: selectedIDs, labelID: labelID)
            self.mark(IDs: selectedIDs, unread: isAnyReadMessage)
        case .trash:
            self.move(IDs: selectedIDs, from: labelID, to: Message.Location.trash.rawValue)
        case .delete:
            self.delete(IDs: selectedIDs)
        case .reply:
            break
        case .replyAll:
            break
        case .moveTo, .labelAs, .more:
            break
        }
    }
}
