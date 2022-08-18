//
//  MailboxViewModel+LabelAs.swift
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

import ProtonCore_UIFoundations

// MARK: - Label as functions
extension MailboxViewModel: LabelAsActionSheetProtocol {
    func handleLabelAsAction(messages: [MessageEntity], shouldArchive: Bool, currentOptionsStatus: [MenuLabel: PMActionSheetPlainItem.MarkType]) {
        for (label, markType) in currentOptionsStatus {
            if selectedLabelAsLabels
                .contains(where: { $0.rawLabelID == label.location.rawLabelID}) {
                // Add to message which does not have this label
                let messageToApply = messages.filter({ !$0.contains(location: label.location )})
                messageService.label(messages: messageToApply,
                                     label: label.location.labelID,
                                     apply: true,
                                     shouldFetchEvent: false)
            } else if markType != .dash { // Ignore the option in dash
                let messageToRemove = messages.filter({ $0.contains(location: label.location )})
                messageService.label(messages: messageToRemove,
                                     label: label.location.labelID,
                                     apply: false,
                                     shouldFetchEvent: false)
            }
        }

        user.eventsService.fetchEvents(labelID: labelID)

        selectedLabelAsLabels.removeAll()

        if shouldArchive {
            messageService.move(messages: messages,
                                to: Message.Location.archive.labelID,
                                queue: true)
        }
    }
    
    func handleLabelAsAction(conversations: [ConversationEntity], shouldArchive: Bool, currentOptionsStatus: [MenuLabel: PMActionSheetPlainItem.MarkType], completion: (() -> Void)? = nil) {
        let group = DispatchGroup()
        let fetchEvents = { [weak self] (result: Result<Void, Error>) in
            defer {
                group.leave()
            }
            guard let self = self else { return }
            if (try? result.get()) != nil {
                self.eventsService.fetchEvents(labelID: self.labelId)
            }
        }
        for (label, markType) in currentOptionsStatus {
            if selectedLabelAsLabels
                .contains(where: { $0.labelID == label.location.labelID}) {
                group.enter()
                // Add to message which does not have this label
                let conversationsToApply = conversations.filter({ !$0.getLabelIDs().contains(label.location.labelID )})
                conversationProvider.label(conversationIDs: conversationsToApply.map(\.conversationID),
                                          as: label.location.labelID,
                                          isSwipeAction: false,
                                          completion: fetchEvents)
            } else if markType != .dash { // Ignore the option in dash
                group.enter()
                let conversationsToRemove = conversations.filter({ $0.getLabelIDs().contains(label.location.labelID )})
                conversationProvider.unlabel(conversationIDs: conversationsToRemove.map(\.conversationID),
                                            as: label.location.labelID,
                                            isSwipeAction: false,
                                            completion: fetchEvents)
            }
        }

        selectedLabelAsLabels.removeAll()

        if shouldArchive {
            group.enter()
            conversationProvider.move(conversationIDs: conversations.map(\.conversationID),
                                     from: "",
                                     to: Message.Location.archive.labelID,
                                      isSwipeAction: false,
                                      callOrigin: "MailboxViewModel - handleLabelAsAction",
                                     completion: fetchEvents)
        }

        group.notify(queue: .main) {
            completion?()
        }
    }
}
