//
//  MailboxViewModel+MoveTo.swift
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

// MARK: - Move to functions
extension MailboxViewModel: MoveToActionSheetProtocol {

    var labelId: LabelID {
        return labelID
    }

    func handleMoveToAction(messages: [MessageEntity], to folder: MenuLabel) {
        let folderID = folder.location.labelID
        messageService.move(messages: messages, to: folderID, queue: true)
    }

    func handleMoveToAction(conversations: [ConversationEntity], to folder: MenuLabel, completion: (() -> Void)?) {
        conversationProvider.move(
            conversationIDs: conversations.map(\.conversationID),
            from: labelId,
            to: folder.location.labelID,
            callOrigin: "MailboxViewModel - handleMoveToAction"
        ) { [weak self] result in
            defer {
                completion?()
            }
            guard let self = self else { return }
            if let _ = try? result.get() {
                self.eventsService.fetchEvents(labelID: self.labelId)
            }
        }
    }
}
