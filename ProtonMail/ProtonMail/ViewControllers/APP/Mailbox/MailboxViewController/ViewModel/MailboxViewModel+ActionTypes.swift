//
//  MailboxViewModel+ActionTypes.swift
//  Proton Mail - Created on 2021.
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
        case markAsRead
        case markAsUnread
        case labelAs
        case trash
        /// permanently delete the message
        case delete
        case moveTo
        case more

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
            case .markAsRead:
                return IconProvider.envelopeOpen
            case .markAsUnread:
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
            case .markAsRead:
                return "PMToolBarView.readButton"
            case .markAsUnread:
                return "PMToolBarView.unreadButton"
            }
        }
    }

    func getActionBarActions() -> [ActionTypes] {
        let isAnyMessageRead = selectionContainsReadItems()

        let standardActions: [ActionTypes] = [
            isAnyMessageRead ? .markAsUnread : .markAsRead,
            .trash,
            .moveTo,
            .labelAs,
            .more
        ]

        //default inbox
        if let type = Message.Location(self.labelID) {
            switch type {
            case .inbox, .starred, .archive, .allmail, .sent, .draft, .scheduled:
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

    func handleBarAction(_ action: ActionTypes) {
        switch action {
        case .markAsRead:
            self.mark(IDs: selectedIDs, unread: false)
        case .markAsUnread:
            self.mark(IDs: selectedIDs, unread: true)
        case .trash:
            self.moveSelectedIDs(from: labelID, to: Message.Location.trash.labelID)
        case .delete:
            self.deleteSelectedIDs()
        case .moveTo, .labelAs, .more:
            break
        }
    }
}
