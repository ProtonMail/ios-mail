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
import ProtonCore_DataModel

extension MailboxViewModel: ToolbarCustomizationActionHandler {
    // Move to trash becomes delete permanently in "Trash" and "Spam".
    // Move to spam becomes Not spam (move to inbox) in "Spam".
    // Archive becomes move to inbox in "Archive" and "Trash".
    func actionsForToolbar() -> [MessageViewActionSheetAction] {
        let isAnyMessageRead = selectionContainsReadItems()
        let isAnyMessageStarred = containsStarMessages(messageIDs: selectedIDs)
        let isInSpam = labelID == Message.Location.spam.labelID
        let isInTrash = labelID == Message.Location.trash.labelID
        let isInArchive = labelID == Message.Location.archive.labelID

        let actions = toolbarActionProvider.listViewToolbarActions
            .addMoreActionToTheLastLocation()
        return replaceActionsLocally(actions: actions,
                                     isInSpam: isInSpam,
                                     isInTrash: isInTrash,
                                     isInArchive: isInArchive,
                                     isRead: isAnyMessageRead,
                                     isStarred: isAnyMessageStarred,
                                     hasMultipleRecipients: false)
    }

    func toolbarActionTypes() -> [MessageViewActionSheetAction] {
        let isAnyMessageRead = selectionContainsReadItems()
        let isAnyStarMessages = containsStarMessages(messageIDs: selectedIDs)
        let isInSpam = labelID == Message.Location.spam.labelID
        let isInTrash = labelID == Message.Location.trash.labelID
        let isInArchive = labelID == Message.Location.archive.labelID

        let actions = toolbarActionProvider.listViewToolbarActions
            .addMoreActionToTheLastLocation()
        return replaceActionsLocally(actions: actions,
                                     isInSpam: isInSpam,
                                     isInTrash: isInTrash,
                                     isInArchive: isInArchive,
                                     isRead: isAnyMessageRead,
                                     isStarred: isAnyStarMessages,
                                     hasMultipleRecipients: false)
    }

    func toolbarCustomizationAllAvailableActions() -> [MessageViewActionSheetAction] {
        let isAnyMessageRead = selectionContainsReadItems()
        let isAnyStarMessages = containsStarMessages(messageIDs: selectedIDs)
        let isInSpam = labelID == Message.Location.spam.labelID
        let isInTrash = labelID == Message.Location.trash.labelID
        let isInArchive = labelID == Message.Location.archive.labelID

        let allItems = actionSheetViewModel.items.map { $0.type }
        return replaceActionsLocally(actions: allItems,
                                     isInSpam: isInSpam,
                                     isInTrash: isInTrash,
                                     isInArchive: isInArchive,
                                     isRead: isAnyMessageRead,
                                     isStarred: isAnyStarMessages,
                                     hasMultipleRecipients: false)
    }

    func saveToolbarAction(actions: [MessageViewActionSheetAction],
                           completion: ((NSError?) -> Void)?) {
        let preference: ToolbarActionPreference = .init(
            conversationActions: nil,
            messageActions: nil,
            listViewActions: actions
        )
        saveToolbarActionUseCase
            .callbackOn(.main)
            .executionBlock(
            params: .init(preference: preference)
        ) { result in
            switch result {
            case .success:
                completion?(nil)
            case let .failure(error):
                completion?(error as NSError)
            }
        }
    }

    func handleBarActions(_ action: MessageViewActionSheetAction, selectedIDs: Set<String>) {
        switch action {
        case .markRead:
            mark(IDs: selectedIDs, unread: false)
        case .markUnread:
            mark(IDs: selectedIDs, unread: true)
        case .trash:
            moveSelectedIDs(from: labelID,
                            to: Message.Location.trash.labelID)
        case .delete:
            deleteSelectedIDs()
        case .inbox, .spamMoveToInbox:
            moveSelectedIDs(from: labelID,
                            to: Message.Location.inbox.labelID)
        case .star:
            label(IDs: selectedIDs,
                  with: Message.Location.starred.labelID,
                  apply: true)
        case .unstar:
            label(IDs: selectedIDs,
                  with: Message.Location.starred.labelID,
                  apply: false)
        case .spam:
            moveSelectedIDs(from: labelID,
                            to: Message.Location.spam.labelID)
        case .archive:
            moveSelectedIDs(from: labelID,
                            to: Message.Location.archive.labelID)
        case .moveTo, .labelAs, .more, .reply, .replyOrReplyAll, .replyAll, .forward,
             .print, .viewHeaders, .viewHTML, .reportPhishing, .dismiss,
             .viewInLightMode, .viewInDarkMode, .toolbarCustomization, .saveAsPDF:
            assertionFailure("should not reach here")
        }
    }
}
