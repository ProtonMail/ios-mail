//
//  ConversationActionSheetViewModel.swift
//  Proton Mail
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

import ProtonCore_DataModel

struct ConversationActionSheetViewModel: ActionSheetViewModel {
    let title: String
    private(set) var items: [MessageViewActionSheetAction] = []

    init(title: String, isUnread: Bool, isStarred: Bool, areAllMessagesIn: (LabelLocation) -> Bool) {
        self.title = title

        items.append(isUnread ? .markRead : .markUnread)
        items.append(isStarred ? .unstar : .star)
        items.append(.labelAs)

        if areAllMessagesIn(.trash) || areAllMessagesIn(.draft) || areAllMessagesIn(.sent) {
            items.append(contentsOf: [.inbox, .archive, .delete, .moveTo])
        } else if areAllMessagesIn(.archive) {
            items.append(contentsOf: [.trash, .inbox, .spam, .moveTo])
        } else if areAllMessagesIn(.spam) {
            items.append(contentsOf: [.trash, .spamMoveToInbox, .delete, .moveTo])
        } else {
            items.append(contentsOf: [.trash, .archive, .spam, .moveTo])
        }
        if UserInfo.isToolbarCustomizationEnable {
            items.append(.toolbarCustomization)
        }
    }
}
