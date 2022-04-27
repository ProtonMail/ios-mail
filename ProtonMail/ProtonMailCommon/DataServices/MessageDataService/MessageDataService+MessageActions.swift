//
//  MessageDataService+MessageActions.swift
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

import Foundation
import CoreData

extension MessageDataService {

    static func findMessagesWithSourceIds(messages: [MessageEntity], customFolderIds: [LabelID], to tLabel: LabelID) -> [(MessageEntity, LabelID)] {
        let defaultFoldersLocations: [Message.Location] = [.inbox, .archive, .spam, .trash, .sent, .draft]
        let defaultFoldersLabelIds = defaultFoldersLocations.map(\.labelID)
        let sourceIdCandidates = customFolderIds + defaultFoldersLabelIds

        return messages.compactMap { message -> (MessageEntity, LabelID)? in
            let labelIds: [LabelID] = message.getLabelIDs()
            let source = labelIds.first { labelId in
                sourceIdCandidates.contains(labelId)
            }

            // We didn't find original folder (should not happens)
            guard let sourceId = source else { return nil }
            // Avoid to move a message to his current location
            guard sourceId != tLabel else { return nil }
            // Avoid stupid move
            if [Message.Location.sent.labelID, Message.Location.draft.labelID].contains(sourceId) &&
                [Message.Location.spam.labelID, Message.Location.inbox.labelID].contains(tLabel) { return nil }

            return (message, sourceId)
        }
    }

    @discardableResult
    func move(messages: [MessageEntity], to tLabel: LabelID, isSwipeAction: Bool = false, queue: Bool = true) -> Bool {
        let custom_folders = labelDataService.getAllLabels(of: .folder, context: contextProvider.mainContext).map { LabelID($0.labelID) }
        let messagesWithSourceIds = MessageDataService
            .findMessagesWithSourceIds(messages: messages,
                                       customFolderIds: custom_folders,
                                       to: tLabel)
        messagesWithSourceIds.forEach { (msg, sourceId) in
            _ = self.cacheService.move(message: msg, from: sourceId, to: tLabel)
        }

        if queue {
            let msgIds = messagesWithSourceIds.map { $0.0.messageID }
            self.queue(.folder(nextLabelID: tLabel.rawValue, shouldFetch: false, isSwipeAction: isSwipeAction, itemIDs: msgIds.map(\.rawValue), objectIDs: []), isConversation: false)
        }
        return true
    }

    @discardableResult
    func move(messages: [MessageEntity], from fLabels: [LabelID], to tLabel: LabelID, isSwipeAction: Bool = false, queue: Bool = true) -> Bool {
        guard !messages.isEmpty,
              messages.count == fLabels.count else {
            return false
        }

        for (index, message) in messages.enumerated() {
            _ = self.cacheService.move(message: message, from: fLabels[index], to: tLabel)
        }

        if queue {
            let ids = messages.map{ $0.messageID.rawValue }
            self.queue(.folder(nextLabelID: tLabel.rawValue, shouldFetch: false, isSwipeAction: isSwipeAction, itemIDs: ids, objectIDs: []), isConversation: false)
        }
        return true
    }

    @discardableResult
    func delete(messages: [MessageEntity], label: LabelID) -> Bool {
        guard !messages.isEmpty else { return false }
        for message in messages {
            _ = self.cacheService.delete(message: message, label: label)
        }

        // If the messageID is UUID, that means the message hasn't gotten response from BE
        let messagesIds = messages
            .map(\.messageID.rawValue)
            .filter { UUID(uuidString: $0) == nil }
        self.queue(.delete(currentLabelID: nil, itemIDs: messagesIds), isConversation: false)
        return true
    }

    /// mark message to unread
    ///
    /// - Parameter message: message
    /// - Returns: true if change to unread and push to the queue
    @discardableResult
    func mark(messages: [MessageEntity], labelID: LabelID, unRead: Bool) -> Bool {
        guard !messages.isEmpty else {
            return false
        }
        let ids = messages.map { $0.objectID.rawValue.uriRepresentation().absoluteString }
        self.queue(unRead ? .unread(currentLabelID: labelID.rawValue, itemIDs: [], objectIDs: ids) : .read(itemIDs: [], objectIDs: ids), isConversation: false)
        for message in messages {
            _ = self.cacheService.mark(message: message, labelID: labelID, unRead: unRead)
        }
        return true
    }

    @discardableResult
    func label(messages: [MessageEntity], label: LabelID, apply: Bool, isSwipeAction: Bool = false, shouldFetchEvent: Bool = true) -> Bool {
        guard !messages.isEmpty else {
            return false
        }

        _ = self.cacheService.label(messages: messages, label: label, apply: apply)

        let messagesIds = messages.map(\.messageID.rawValue)
        self.queue(apply ? .label(currentLabelID: label.rawValue,
                                  shouldFetch: shouldFetchEvent,
                                  isSwipeAction: false,
                                  itemIDs: messagesIds, objectIDs: []) :
                        .unlabel(currentLabelID: label.rawValue,
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

    func fetchMessages(with messageIDs: [MessageID]) -> [MessageEntity] {
        let context = contextProvider.mainContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: Message.Attributes.entityName)
        fetchRequest.predicate = NSPredicate(format: "%K in %@", Message.Attributes.messageID, NSSet(array: messageIDs))
        do {
            if let messages = try context.fetch(fetchRequest) as? [Message] {
                return messages.map(MessageEntity.init)
            }
        } catch {
        }
        return []
    }
}
