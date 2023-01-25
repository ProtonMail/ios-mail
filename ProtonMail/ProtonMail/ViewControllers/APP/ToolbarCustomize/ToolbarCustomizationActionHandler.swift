// Copyright (c) 2022 Proton AG
//
// This file is part of Proton Mail.
//
// Proton Mail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Mail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Mail. If not, see https://www.gnu.org/licenses/.

import Foundation

protocol ToolbarCustomizationActionHandler: AnyObject {
    func actionsForToolbarCustomizeView() -> [MessageViewActionSheetAction]
    func toolbarActionTypes() -> [MessageViewActionSheetAction]
    func updateToolbarActions(actions: [MessageViewActionSheetAction], completion: ((NSError?) -> Void)?)
    func saveToolbarAction(actions: [MessageViewActionSheetAction], completion: ((NSError?) -> Void)?)
    func replaceActionsLocally(
        actions: [MessageViewActionSheetAction],
        isInSpam: Bool,
        isInTrash: Bool,
        isInArchive: Bool,
        isRead: Bool,
        isStarred: Bool,
        hasMultipleRecipients: Bool
    ) -> [MessageViewActionSheetAction]
}

extension ToolbarCustomizationActionHandler {
    func actionsForToolbarCustomizeView() -> [MessageViewActionSheetAction] {
        toolbarActionTypes().filter({ $0 != .more })
    }

    func updateToolbarActions(actions: [MessageViewActionSheetAction], completion: ((NSError?) -> Void)?) {
        saveToolbarAction(actions: actions.removeMoreAction(), completion: completion)
    }

    /// Replace toolbar actions with proper action locally in specific conditions.
    func replaceActionsLocally(
        actions: [MessageViewActionSheetAction],
        isInSpam: Bool,
        isInTrash: Bool,
        isInArchive: Bool,
        isRead: Bool,
        isStarred: Bool,
        hasMultipleRecipients: Bool
    ) -> [MessageViewActionSheetAction] {
        return actions
            .replaceCorrectUnreadAction(isAnyMessageRead: isRead)
            .replaceCorrectStarAction(isAnyStarMessages: isStarred)
            .replaceCorrectReplyOrReplyAll(hasMultipleRecipients: hasMultipleRecipients)
            .replaceCorrectArchiveAction(isInArchiveOrTrash: isInTrash || isInArchive)
            .replaceCorrectMoveToSpamOrInbox(isInSpam: isInSpam)
            .replaceCorrectTrashOrDeleteAction(isInTrashOrSpam: isInTrash || isInSpam)
    }
}
