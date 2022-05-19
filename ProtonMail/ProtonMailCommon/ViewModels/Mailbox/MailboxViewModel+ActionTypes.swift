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
    /// This enum is used to indicate what types of action should this view to show in the action bar as actions.
    enum ActionTypes {
        case markAsRead
        case markAsUnread
        case labelAs
        case trash
        /// permanently delete the message
        case delete
        case moveTo
        case more
        case reply
        case replyAll

        var iconImage: ImageAsset.Image {
            switch self {
            case .delete:
                return Asset.actionBarDelete.image
            case .trash:
                return Asset.actionBarTrash.image
            case .moveTo:
                return Asset.actionBarMoveTo.image
            case .more:
                return Asset.actionBarMore.image
            case .labelAs:
                return Asset.actionBarLabel.image
            case .reply:
                return Asset.actionBarReply.image
            case .replyAll:
                return Asset.actionBarReplyAll.image
            case .markAsRead:
                return Asset.actionSheetRead.image
            case .markAsUnread:
                return Asset.actionBarReadUnread.image
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
            case .markAsRead:
                return "PMToolBarView.readButton"
            case .markAsUnread:
                return "PMToolBarView.unreadButton"
            }
        }
    }

    func getActionBarActions() -> [ActionTypes] {
        let isAnyMessageRead = containsReadMessages(messageIDs: selectedIDs, labelID: labelID.rawValue)

        let standardActions: [ActionTypes] = [
            .trash,
            isAnyMessageRead ? .markAsUnread : .markAsRead,
            .moveTo,
            .labelAs,
            .more
        ]

        //default inbox
        if let type = Message.Location(self.labelID) {
            switch type {
            case .inbox, .starred, .archive, .allmail, .sent, .draft:
                return standardActions
            case .spam, .trash:
                return [.delete, .moveTo, .labelAs, .more]
            }
        }
        if self.labelProvider.getLabel(by: labelID) != nil {
            return standardActions
        } else {
            return []
        }
    }

    func handleBarActions(_ action: ActionTypes, selectedIDs: Set<String>) {
        switch action {
        case .markAsRead:
            self.mark(IDs: selectedIDs, unread: false)
        case .markAsUnread:
            self.mark(IDs: selectedIDs, unread: true)
        case .trash:
            self.move(IDs: selectedIDs, from: labelID, to: Message.Location.trash.labelID)
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
