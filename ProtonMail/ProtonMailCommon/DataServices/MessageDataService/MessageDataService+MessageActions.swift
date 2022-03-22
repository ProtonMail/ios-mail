//
//  MessageDataService+MessageActions.swift
//  ProtonMail
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
import CoreData

extension MessageDataService {

    static func findMessagesWithSourceIds(messages: [Message], customFolderIds: [String], to tLabel: String) -> [(Message, String)] {
        let defaultFoldersLocations: [Message.Location] = [.inbox, .archive, .spam, .trash, .sent, .draft]
        let defaultFoldersLabelIds = defaultFoldersLocations.map(\.rawValue)
        let sourceIdCandidates = customFolderIds + defaultFoldersLabelIds

        return messages.compactMap { message -> (Message, String)? in
            let labelIds: [String] = message.getLabelIDs()
            let source = labelIds.first { labelId in
                sourceIdCandidates.contains(labelId)
            }

            // We didn't find original folder (should not happens)
            guard let sourceId = source else { return nil }
            // Avoid to move a message to his current location
            guard sourceId != tLabel else { return nil }
            // Avoid stupid move
            if [Message.Location.sent.rawValue, Message.Location.draft.rawValue].contains(sourceId) &&
                [Message.Location.spam.rawValue, Message.Location.inbox.rawValue].contains(tLabel) { return nil }

            return (message, sourceId)
        }
    }

    @discardableResult
    func move(messages: [Message], to tLabel: String, isSwipeAction: Bool = false, queue: Bool = true) -> Bool {
        let custom_folders = labelDataService.getAllLabels(of: .folder, context: contextProvider.mainContext).map { $0.labelID }
        let messagesWithSourceIds = MessageDataService
            .findMessagesWithSourceIds(messages: messages,
                                       customFolderIds: custom_folders,
                                       to: tLabel)
        messagesWithSourceIds.forEach { (msg, sourceId) in
            _ = self.cacheService.move(message: msg, from: sourceId, to: tLabel)
        }

        if queue {
            let msgIds = messagesWithSourceIds.map { $0.0.messageID }
            self.queue(.folder(nextLabelID: tLabel, shouldFetch: false, isSwipeAction: isSwipeAction, itemIDs: msgIds, objectIDs: []), isConversation: false)
        }
        return true
    }

    @discardableResult
    func move(messages: [Message], from fLabels: [String], to tLabel: String, isSwipeAction: Bool = false, queue: Bool = true) -> Bool {
        guard !messages.isEmpty,
              messages.count == fLabels.count else {
            return false
        }

        for (index, message) in messages.enumerated() {
            _ = self.cacheService.move(message: message, from: fLabels[index], to: tLabel)
        }

        if queue {
            let ids = messages.map { $0.messageID }
            self.queue(.folder(nextLabelID: tLabel, shouldFetch: false, isSwipeAction: isSwipeAction, itemIDs: ids, objectIDs: []), isConversation: false)
        }
        return true
    }

    @discardableResult
    func delete(messages: [Message], label: String) -> Bool {
        guard !messages.isEmpty else { return false }
        // If the messageID is UUID, that means the message hasn't gotten response from BE
        let messagesIds = messages
            .map(\.messageID)
            .filter { UUID(uuidString: $0) == nil }
        for message in messages {
            _ = self.cacheService.delete(message: message, label: label)
        }

        self.queue(.delete(currentLabelID: nil, itemIDs: messagesIds), isConversation: false)
        return true
    }

    /// mark message to unread
    ///
    /// - Parameter message: message
    /// - Returns: true if change to unread and push to the queue
    @discardableResult
    func mark(messages: [Message], labelID: String, unRead: Bool) -> Bool {
        guard !messages.isEmpty else {
            return false
        }
        let ids = messages.map { $0.objectID.uriRepresentation().absoluteString }
        self.queue(unRead ? .unread(currentLabelID: labelID, itemIDs: [], objectIDs: ids) : .read(itemIDs: [], objectIDs: ids), isConversation: false)
        for message in messages {
            _ = self.cacheService.mark(message: message, labelID: labelID, unRead: unRead)
        }
        return true
    }

    @discardableResult
    func label(messages: [Message], label: String, apply: Bool, isSwipeAction: Bool = false, shouldFetchEvent: Bool = true) -> Bool {
        guard !messages.isEmpty else {
            return false
        }

        _ = self.cacheService.label(messages: messages, label: label, apply: apply)

        let messagesIds = messages.map(\.messageID)
        self.queue(apply ? .label(currentLabelID: label,
                                  shouldFetch: shouldFetchEvent,
                                  isSwipeAction: false,
                                  itemIDs: messagesIds, objectIDs: []) :
                        .unlabel(currentLabelID: label,
                                 shouldFetch: shouldFetchEvent,
                                 isSwipeAction: isSwipeAction,
                                 itemIDs: messagesIds,
                                 objectIDs: []),
                   isConversation: false)
        return true
    }

    func deleteExpiredMessage(completion: (() -> Void)?) {
        self.cacheService.deleteExpiredMessage(completion: completion)
    }
}

extension MessageDataService {
    /// fetch messages with set of message id
    ///
    /// - Parameter selected: MessageIDs
    /// - Returns: fetched message obj
    func fetchMessages(withIDs selected: NSMutableSet, in context: NSManagedObjectContext) -> [Message] {
        let context = context
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: Message.Attributes.entityName)
        fetchRequest.predicate = NSPredicate(format: "%K in %@", Message.Attributes.messageID, selected)
        do {
            if let messages = try context.fetch(fetchRequest) as? [Message] {
                return messages
            }
        } catch {
        }
        return [Message]()
    }
}
