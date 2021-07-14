//
//  Conversation.swift
//  ProtonMail
//
//
//  Copyright (c) 2020 Proton Technologies AG
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

import CoreData
import Foundation

public final class Conversation: NSManagedObject {
    enum Errors: Error {
        case attemptToMergeUnmatchingConversations
    }

    enum Attributes {
        static let entityName = String(describing: Conversation.self)
        static let conversationID = "conversationID"
        static let time = "time"
        static let labels = "labels"
        static let userID = "userID"
        static let numUnread = "numUnread"
    }

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Conversation> {
        return NSFetchRequest<Conversation>(entityName: "Conversation")
    }

    @NSManaged public var conversationID: String
    @NSManaged public var expirationTime: Date?

    @NSManaged public var numAttachments: NSNumber
    @NSManaged public var numMessages: NSNumber

    @NSManaged public var order: NSNumber

    @NSManaged public var senders: String
    @NSManaged public var recipients: String

    @NSManaged public var size: NSNumber?
    @NSManaged public var subject: String
    @NSManaged public var labels: NSSet

    @NSManaged public var userID: String

    class func deleteAll(inContext context: NSManagedObjectContext) {
        context.deleteAll(Attributes.entityName)
    }
}

extension Conversation {
    func getNumAttachments(labelID: String) -> Int {
        guard let contextLabels = self.labels.allObjects as? [ContextLabel] else {
            return 0
        }
        let matchingLabel = contextLabels.filter { $0.labelID == labelID }.first
        guard let matched = matchingLabel else {
            return 0
        }
        return matched.attachmentCount.intValue
    }

    func hasAttachments(labelID: String) -> Bool {
        return getNumAttachments(labelID: labelID) > 0
    }

    func getNumUnread(labelID: String) -> Int {
        guard let contextLabels = self.labels.allObjects as? [ContextLabel] else {
            return 0
        }
        let matchingLabel = contextLabels.filter { $0.labelID == labelID }.first
        guard let matched = matchingLabel else {
            return 0
        }
        return matched.unreadCount.intValue
    }

    func isUnread(labelID: String) -> Bool {
        return getNumUnread(labelID: labelID) != 0
    }

    func getNumMessages(labelID: String) -> Int {
        guard let contextLabels = self.labels.allObjects as? [ContextLabel] else {
            return 0
        }
        let matchingLabel = contextLabels.filter { $0.labelID == labelID }.first
        guard let matched = matchingLabel else {
            return 0
        }
        return matched.messageCount.intValue
    }

    func getTime(labelID: String) -> Date? {
        guard let contextLabels = self.labels.allObjects as? [ContextLabel] else {
            return nil
        }
        let matchingLabel = contextLabels.filter { $0.labelID == labelID }.first
        guard let matched = matchingLabel else {
            return nil
        }
        return matched.time
    }

    func getSize(labelID: String) -> Int {
        guard let contextLabels = self.labels.allObjects as? [ContextLabel] else {
            return 0
        }
        let matchingLabel = contextLabels.filter { $0.labelID == labelID }.first
        guard let matched = matchingLabel else {
            return 0
        }
        return matched.size.intValue
    }

    func contains(of labelID: String) -> Bool {
        guard let contextLabels = self.labels.allObjects as? [ContextLabel] else {
            return false
        }
        return contextLabels.contains { $0.labelID == labelID }
    }

    class func conversationForConversationID(_ conversationID: String, inManagedObjectContext context: NSManagedObjectContext) -> Conversation? {
        return context.managedObjectWithEntityName(Attributes.entityName, forKey: Attributes.conversationID, matchingValue: conversationID) as? Conversation
    }
    
    struct Contact: Decodable {
        var Address: String
        var Name: String
    }
    
    func getSenders() -> [Contact] {
        guard let senderData = senders.data(using: .utf8) else {
            return []
        }
        return (try? JSONDecoder().decode([Contact].self, from: senderData)) ?? []
    }
    
    /// This method will return a string that contains the name of all senders with ',' between them.
    /// e.g Georage, Paul, Ringo
    /// - Returns: String of all name of the senders.
    func getJoinedSendersName(_ replacingEmails: [Email]) -> String {
        let lists: [String] = self.getSenders().map { contact in
            if let name = replacingEmails.first(where: {$0.email == contact.Address})?.name {
                return name
            } else if !contact.Name.isEmpty {
                return contact.Name
            } else {
                return contact.Address
            }
        }
        if lists.isEmpty {
            return ""
        }
        return lists.joined(separator: ", ")
    }

    func getSendersName(_ replacingEmails: [Email]) -> [String] {
        return self.getSenders().map { contact in
            if let name = replacingEmails.first(where: {$0.email == contact.Address})?.name {
                return name
            } else if !contact.Name.isEmpty {
                return contact.Name
            } else {
                return contact.Address
            }
        }
    }
    
    func getRecipients() -> [Contact] {
        guard let recipientData = recipients.data(using: .utf8) else {
            return []
        }
        return (try? JSONDecoder().decode([Contact].self, from: recipientData)) ?? []
    }
    
    /// This method will return a string that contains the name of all recipients with ',' between them.
    /// e.g Georage, Paul, Ringo
    /// - Returns: String of all name of the recipients.
    func getRecipientsName(_ replacingEmails: [Email]) -> String {
        let lists: [String] = self.getRecipients().map { contact in
            replacingEmails.first(where: {$0.email == contact.Address})?.name ?? contact.Name
        }
        if lists.isEmpty {
            return ""
        }
        return lists.joined(separator: ", ")
    }
    
    /// Fetch the Label from local cache based on the labelIDs from contextLabel
    /// - Returns: array of labels
    func getLabels() -> [Label] {
        guard let context = self.managedObjectContext else {
            return []
        }
        let labelIDs = self.labels.compactMap{ ($0 as? ContextLabel)?.labelID }
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: Label.Attributes.entityName)
        request.predicate = NSPredicate(format: "(labelID IN %@) AND (%K == 1) AND (%K == %@)", labelIDs, Label.Attributes.type, Label.Attributes.userID, self.userID)
        do {
            return (try context.fetch(request) as? [Label]) ?? []
        } catch {
            PMLog.D("error: \(error)")
            return []
        }
    }
}

// MARK: Apply local changes
extension Conversation {
    /// Apply single mark as changes for single message in conversation.
    func applySingleMarkAsChanges(unRead: Bool, labelID: String) {
        let labels = self.mutableSetValue(forKey: Conversation.Attributes.labels)
        let contextNumUnread = labels.compactMap{$0 as? ContextLabel}.filter{ $0.labelID == labelID }.first?.unreadCount ?? 0
        
        let updatedContextNumUnread = unRead ? contextNumUnread.intValue + 1 : max(contextNumUnread.intValue - 1, 0)
        for label in labels {
            if let l = label as? ContextLabel, l.labelID == labelID {
                l.unreadCount = NSNumber(value: updatedContextNumUnread)
            }
        }
    }
    
    /// Apply mark as changes to whole conversation.
    func applyMarksAsChanges(unRead: Bool, labelID: String, context: NSManagedObjectContext) {
        let labels = self.mutableSetValue(forKey: Conversation.Attributes.labels)
        let contextLabels = labels.compactMap{ $0 as? ContextLabel }
        let messages = Message
            .messagesForConversationID(self.conversationID,
                                       inManagedObjectContext: context) ?? []
        
        var changedLabels: Set<String> = []
        if unRead {
            // It marks the latest message of the conversation of the current location (inbox, archive, etc...) as unread.
            if let message = messages
                    .filter({ $0.contains(label: labelID)})
                    .last {
                message.unRead = true
                if let messageLabels = message.labels.allObjects as? [Label] {
                    let changed = messageLabels.map { $0.labelID }
                    for id in changed {
                        changedLabels.insert(id)
                    }
                }
            }
        } else {
            // It marks the entire all messages attach to the conversation (Conversation.Messages) as read.
            for message in messages {
                guard message.unRead == true else { continue }
                message.unRead = false
                guard let messageLabels = message.labels.allObjects as? [Label] else { continue }
                let changed = messageLabels.map { $0.labelID }
                for id in changed {
                    changedLabels.insert(id)
                }
            }
        }
        
        for label in contextLabels where changedLabels.contains(label.labelID) || label.labelID == labelID {
            let offset = unRead ? 1: -1
            var unreadCount = label.unreadCount.intValue + offset
            unreadCount = max(unreadCount, 0)
            label.unreadCount = NSNumber(value: unreadCount)
            
            
            if let contextLabelInContext = ConversationCount
                .lastContextUpdate(by: label.labelID,
                                userID: self.userID,
                                inManagedObjectContext: context) {
                contextLabelInContext.unread += Int32(offset)
                contextLabelInContext.unread = max(contextLabelInContext.unread, 0)
            }
        }
    }
    
    /// Apply label changes on one message of a conversation.
    func applyLabelChangesOnOneMessage(labelID: String, apply: Bool) {
        let labels = self.mutableSetValue(forKey: Conversation.Attributes.labels).compactMap{ $0 as? ContextLabel }
        let hasLabel = labels.contains(where: { $0.labelID == labelID })
        let numMessages = labels.first(where: {$0.labelID == labelID})?.messageCount.intValue ?? 0
        
        if apply {
            if hasLabel {
                if let label = labels.first(where: {$0.labelID == labelID}) {
                    label.messageCount = NSNumber(value: numMessages + 1)
                } else {
                    fatalError()
                }
            } else {
                #warning("v4 check this later")
                let newLabel = ContextLabel(context: self.managedObjectContext!)
                newLabel.labelID = labelID
                newLabel.messageCount = 1
                newLabel.time = Date()
                newLabel.userID = self.userID
                newLabel.size = self.size ?? NSNumber(value: 0)
                newLabel.attachmentCount = self.numAttachments
                self.mutableSetValue(forKey: Conversation.Attributes.labels).add(newLabel)
            }
        } else if hasLabel, let label = labels.first(where: {$0.labelID == labelID}) {
            if numMessages <= 1 {
                self.mutableSetValue(forKey: Conversation.Attributes.labels).remove(label)
            } else {
                label.messageCount = NSNumber(value: numMessages - 1)
            }
        }
    }
    
    ///Apply label changes of a conversation.
    func applyLabelChanges(labelID: String, apply: Bool, context: NSManagedObjectContext) {
        if apply {
            if self.contains(of: labelID) {
                if let target = self.labels.compactMap({ $0 as? ContextLabel }).filter({ $0.labelID == labelID }).first {
                    target.messageCount = self.numMessages
                } else {
                    fatalError()
                }
            } else {
                let newLabel = ContextLabel(context: self.managedObjectContext!)
                newLabel.labelID = labelID
                newLabel.messageCount = self.numMessages
                newLabel.time = Date()
                newLabel.userID = self.userID
                newLabel.size = self.size ?? NSNumber(value: 0)
                newLabel.attachmentCount = self.numAttachments
                
                let messages = Message
                    .messagesForConversationID(self.conversationID,
                                               inManagedObjectContext: context) ?? []
                newLabel.unreadCount = NSNumber(value: messages.filter { $0.unRead }.count)
                self.mutableSetValue(forKey: Conversation.Attributes.labels).add(newLabel)
            }
        } else {
            if self.contains(of: labelID), let label = labels.compactMap({ $0 as? ContextLabel }).filter({ $0.labelID == labelID }).first {
                self.mutableSetValue(forKey: Conversation.Attributes.labels).remove(label)
            }
        }
    }
}
