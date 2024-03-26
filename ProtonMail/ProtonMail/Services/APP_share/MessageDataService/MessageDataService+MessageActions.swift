//
//  MessageDataService+MessageActions.swift
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

import Foundation
import CoreData

extension MessageDataService {

    static func findMessagesWithSourceIds(messages: [MessageEntity], customFolderIds: [LabelID], to tLabel: LabelID) -> [(MessageEntity, LabelID)] {
        let defaultFoldersLocations: [Message.Location] = [.inbox, .archive, .spam, .trash, .sent, .draft, .scheduled]
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
    func move(messages: [MessageEntity], to tLabel: LabelID, queue: Bool = true) -> Bool {
        let customFolderIDs = contextProvider.read { context in
            labelDataService.getAllLabels(of: .folder, context: context).map { LabelID($0.labelID) }
        }
        let messagesWithSourceIds = MessageDataService
            .findMessagesWithSourceIds(messages: messages,
                                       customFolderIds: customFolderIDs,
                                       to: tLabel)
        if messagesWithSourceIds.isEmpty { return true }
        try? self.dependencies.moveMessageInCacheUseCase.execute(
            params: .init(
                messagesToBeMoved: messagesWithSourceIds.map { $0.0 },
                from: messagesWithSourceIds.map { $0.1 },
                targetLocation: tLabel
            )
        )

        if queue {
            let msgIds = messagesWithSourceIds.map { $0.0.messageID }
            self.queue(.folder(nextLabelID: tLabel.rawValue, shouldFetch: true, itemIDs: msgIds.map(\.rawValue), objectIDs: []))
        }
        return true
    }

    @discardableResult
    func move(messages: [MessageEntity], from fLabels: [LabelID], to tLabel: LabelID, queue: Bool = true) -> Bool {
        guard !messages.isEmpty,
              messages.count == fLabels.count else {
            return false
        }
        try? dependencies.moveMessageInCacheUseCase.execute(
            params: .init(
                messagesToBeMoved: messages,
                from: fLabels,
                targetLocation: tLabel
            )
        )

        if queue {
            let ids = messages.map{ $0.messageID.rawValue }
            self.queue(.folder(nextLabelID: tLabel.rawValue, shouldFetch: true, itemIDs: ids, objectIDs: []))
        }
        return true
    }

    @discardableResult
    func delete(messages: [MessageEntity], label: LabelID) -> Bool {
        guard !messages.isEmpty else { return false }
        _ = self.cacheService.delete(messages: messages, label: label)

        // If the messageID is UUID, that means the message hasn't gotten response from BE
        let messagesIds = messages
            .map(\.messageID.rawValue)
            .filter { UUID(uuidString: $0) == nil }
        self.queue(.delete(currentLabelID: nil, itemIDs: messagesIds))
        return true
    }

    /// mark message to unread
    ///
    /// - Parameter message: message
    /// - Returns: true if change to unread and push to the queue
    @discardableResult
    func mark(messageObjectIDs: [NSManagedObjectID], labelID: LabelID, unRead: Bool) -> Bool {
        mark(messageObjectIDs: messageObjectIDs, labelID: labelID, unRead: unRead, context: nil)
    }

    @discardableResult
    func mark(messageObjectIDs: [NSManagedObjectID], labelID: LabelID, unRead: Bool, context: NSManagedObjectContext?) -> Bool {
        guard !messageObjectIDs.isEmpty else {
            return false
        }
        let ids = messageObjectIDs.map { $0.uriRepresentation().absoluteString }
        self.queue(unRead ? .unread(currentLabelID: labelID.rawValue, itemIDs: [], objectIDs: ids) : .read(itemIDs: [], objectIDs: ids))
        for messageObjectID in messageObjectIDs {
            if let context = context {
                _ = self.cacheService.mark(messageObjectID: messageObjectID, labelID: labelID, unRead: unRead, context: context)
            } else {
                _ = self.cacheService.mark(messageObjectID: messageObjectID, labelID: labelID, unRead: unRead)
            }
        }
        return true
    }

    func markLocally(messageObjectIDs: [NSManagedObjectID], labelID: LabelID, unRead: Bool) {
        if messageObjectIDs.isEmpty { return }
        for id in messageObjectIDs {
           _ = self.cacheService.mark(messageObjectID: id, labelID: labelID, unRead: unRead, shouldUpdateCounter: false)
        }
    }

    @discardableResult
    func label(messages: [MessageEntity], label: LabelID, apply: Bool, shouldFetchEvent: Bool = true) -> Bool {
        guard !messages.isEmpty else {
            return false
        }

        _ = self.cacheService.label(messages: messages, label: label, apply: apply)

        let messagesIds = messages.map(\.messageID.rawValue)
        self.queue(apply ? .label(currentLabelID: label.rawValue,
                                  shouldFetch: shouldFetchEvent,
                                  itemIDs: messagesIds, objectIDs: []) :
                        .unlabel(currentLabelID: label.rawValue,
                                 shouldFetch: shouldFetchEvent,
                                 itemIDs: messagesIds,
                                 objectIDs: []))
        return true
    }

    /// fetch messages with set of message id
    ///
    /// - Parameter selected: MessageIDs
    /// - Returns: fetched message obj
    func fetchMessages(withIDs selected: NSMutableSet, in context: NSManagedObjectContext) -> [Message] {
        let fetchRequest = NSFetchRequest<Message>(entityName: Message.Attributes.entityName)
        fetchRequest.predicate = NSPredicate(format: "%K in %@", Message.Attributes.messageID, selected)
        do {
            return try context.fetch(fetchRequest)
        } catch {
        }
        return [Message]()
    }

    func isMessageBeingSent(id messageID: MessageID) -> Bool {
        isMessageBeingSent(id: messageID.rawValue)
    }

    func isMessageBeingSent(id messageID: String) -> Bool {
        idsOfMessagesBeingSent().contains(messageID)
    }

    func idsOfMessagesBeingSent() -> [String] {
        guard let queueManager = queueManager else {
            fatalError("queueManager is not supposed to be deallocated")
        }

        return queueManager.messageIDsOfTasks { action in
            switch action {
            case .send:
                return true
            default:
                return false
            }
        }
    }
}
