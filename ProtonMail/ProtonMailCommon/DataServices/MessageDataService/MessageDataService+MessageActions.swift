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
    @discardableResult
    func move(messages: [Message], from fLabels: [String], to tLabel: String, queue: Bool = true) -> Bool {
        guard !messages.isEmpty,
              messages.count == fLabels.count else {
            return false
        }

        for (index, message) in messages.enumerated() {
            _ = self.cacheService.move(message: message, from: fLabels[index], to: tLabel)
        }

        if queue {
            let ids = messages.map{ $0.messageID }
            self.queue(.folder, isConversation: false, data1: "", data2: tLabel, otherData: ids)
        }
        return true
    }
    
    @discardableResult
    func delete(messages: [Message], label: String) -> Bool {
        guard !messages.isEmpty else {
            return false
        }

        for message in messages {
            _ = self.cacheService.delete(message: message, label: label)
        }

        let messagesIds = messages.map(\.messageID)
        self.queue(.delete, isConversation: false, data1: "", data2: "", otherData: messagesIds)
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
        self.queue(unRead ? .unread : .read, isConversation: false, data1: "", data2: "", otherData: ids)
        for message in messages {
            _ = self.cacheService.mark(message: message, labelID: labelID, unRead: unRead)
        }
        return true
    }
    
    @discardableResult
    func label(messages: [Message], label: String, apply: Bool) -> Bool {
        guard !messages.isEmpty else {
            return false
        }

        _ = self.cacheService.label(messages: messages, label: label, apply: apply)

        let messagesIds = messages.map(\.messageID)
        self.queue(apply ? .label : .unlabel, isConversation: false, data1: label, data2: "", otherData: messagesIds)
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
        } catch let ex as NSError {
            PMLog.D(" error: \(ex)")
        }
        return [Message]()
    }
}
