//
//  ConversationActionSheetViewModel.swift
//  ProtonMail
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

struct ConversationActionSheetViewModel: ActionSheetViewModel {
    let title: String
    private(set) var items: [MessageViewActionSheetAction] = []

    init(title: String, labelID: LabelID, isUnread: Bool, isStarred: Bool, isAllMessagesInTrash: Bool) {
        self.title = title

        items.append(isUnread ? .markRead : .markUnread)
        items.append(isStarred ? .unstar : .star)
        items.append(.labelAs)

        if labelID != Message.Location.trash.labelID && !isAllMessagesInTrash {
            items.append(.trash)
        }

        if ![Message.Location.archive.labelID, Message.Location.spam.labelID].contains(labelID) {
            items.append(.archive)
        }

        if labelID == Message.Location.archive.labelID {
            items.append(.inbox)
        }

        if labelID == Message.Location.spam.labelID {
            items.append(.spamMoveToInbox)
        }

        let foldersContainsDeleteAction = [
            Message.Location.draft.labelID,
            Message.Location.sent.labelID,
            Message.Location.spam.labelID,
            Message.Location.trash.labelID
        ]
        if foldersContainsDeleteAction.contains(labelID) {
            items.append(.delete)
        } else {
            items.append(.spam)
        }

        items.append(.moveTo)
    }
}
