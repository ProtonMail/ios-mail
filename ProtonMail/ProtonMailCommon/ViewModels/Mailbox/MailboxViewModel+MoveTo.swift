//
//  MailboxViewModel+MoveTo.swift
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

// MARK: - Move to functions
extension MailboxViewModel: MoveToActionSheetProtocol {
    var labelId: LabelID {
        return labelID
    }

    func handleMoveToAction(messages: [MessageEntity], isFromSwipeAction: Bool) {
        guard let destination = selectedMoveToFolder else { return }
        messageService.move(messages: messages, to: destination.location.labelID, isSwipeAction: isFromSwipeAction, queue: true)
        selectedMoveToFolder = nil
    }

    func handleMoveToAction(conversations: [ConversationEntity], isFromSwipeAction: Bool, completion: (() -> Void)? = nil) {
        guard let destination = selectedMoveToFolder else {
            completion?()
            return
        }
        conversationProvider.move(conversationIDs: conversations.map(\.conversationID),
                                  from: "",
                                  to: destination.location.labelID,
                                  isSwipeAction: isFromSwipeAction) { [weak self] result in
            defer {
                completion?()
            }
            guard let self = self else { return }
            if let _ = try? result.get() {
                self.eventsService.fetchEvents(labelID: self.labelId)
            }
        }
        /*
         We pass the empty string because we don't have the source folder here
         The same is done for messages in `move(messages: [Message], to tLabel: String, queue: Bool = true)`
         */
        selectedMoveToFolder = nil
    }
}
