//
//  CacheService.swift
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
import Crypto
import CoreData
import Groot
import ProtonCore_DataModel

class CacheService: Service {
    let userID: String
    let lastUpdatedStore: LastUpdatedStoreProtocol
    let coreDataService: CoreDataService
    private var context: NSManagedObjectContext {
        return self.coreDataService.rootSavingContext
    }

    init(userID: String, lastUpdatedStore: LastUpdatedStoreProtocol, coreDataService: CoreDataService) {
        self.userID = userID
        self.lastUpdatedStore = lastUpdatedStore
        self.coreDataService = coreDataService
    }

    // MARK: - Message related functions
    func move(message: Message, from fLabel: String, to tLabel: String) -> Bool {
        var hasError = false
        context.performAndWait {
            guard let msgToUpdate = try? context.existingObject(with: message.objectID) as? Message else {
                hasError = true
                return
            }

            if let lid = msgToUpdate.remove(labelID: fLabel), msgToUpdate.unRead {
                self.updateCounterInsideContext(plus: false, with: lid, context: context)
                if let id = msgToUpdate.selfSent(labelID: lid) {
                    self.updateCounterInsideContext(plus: false, with: id, context: context)
                }
            }
            if let lid = msgToUpdate.add(labelID: tLabel) {
                // if move to trash. clean labels.
                var labelsFound = msgToUpdate.getNormalLabelIDs()
                labelsFound.append(Message.Location.starred.rawValue)
                // prevent the unread being substracted once more
                if fLabel != Message.Location.allmail.rawValue {
                    labelsFound.append(Message.Location.allmail.rawValue)
                }
                if lid == Message.Location.trash.rawValue {
                    self.removeLabel(on: msgToUpdate, labels: labelsFound, cleanUnread: true)
                    msgToUpdate.unRead = false
                }
                if lid == Message.Location.spam.rawValue {
                    self.removeLabel(on: msgToUpdate, labels: labelsFound, cleanUnread: false)
                }

                if msgToUpdate.unRead {
                    self.updateCounterInsideContext(plus: true, with: lid, context: context)
                    if let id = msgToUpdate.selfSent(labelID: lid) {
                        self.updateCounterInsideContext(plus: true, with: id, context: context)
                    }
                }
            }

            let error = context.saveUpstreamIfNeeded()
            if error != nil {
                hasError = true
            }
        }
        return !hasError
    }

    func delete(message: Message, label: String) -> Bool {
        var contextToUse = self.context
        guard let msgContext = message.managedObjectContext else {
            return false
        }

        if msgContext.concurrencyType == .mainQueueConcurrencyType && msgContext != self.coreDataService.mainContext {
            contextToUse = msgContext
        }

        var hasError = false
        contextToUse.performAndWait {
            guard let msgToUpdate = try? contextToUse.existingObject(with: message.objectID) as? Message else {
                hasError = true
                return
            }

            if let lid = msgToUpdate.remove(labelID: label), msgToUpdate.unRead {
                self.updateCounterSync(plus: false, with: lid, context: context)
                if let id = msgToUpdate.selfSent(labelID: lid) {
                    self.updateCounterSync(plus: false, with: id, context: context)
                }
            }
            var labelsFound = msgToUpdate.getNormalLabelIDs()
            labelsFound.append(Message.Location.starred.rawValue)
            labelsFound.append(Message.Location.allmail.rawValue)
            self.removeLabel(on: msgToUpdate, labels: labelsFound, cleanUnread: true)
            let labelObjs = msgToUpdate.mutableSetValue(forKey: "labels")
            labelObjs.removeAllObjects()
            msgToUpdate.setValue(labelObjs, forKey: "labels")
            contextToUse.delete(msgToUpdate)

            let error = contextToUse.saveUpstreamIfNeeded()
            if error != nil {
                hasError = true
            }
        }

        if hasError {
            return false
        }

        return true
    }

    func mark(message: Message, labelID: String, unRead: Bool) -> Bool {
        var hasError = false
        context.performAndWait {
            guard let msgToUpdate = try? context.existingObject(with: message.objectID) as? Message else {
                hasError = true
                return
            }

            guard msgToUpdate.unRead != unRead else {
                return
            }

            msgToUpdate.unRead = unRead

            if let conversation = Conversation.conversationForConversationID(msgToUpdate.conversationID, inManagedObjectContext: context) {
                conversation.applySingleMarkAsChanges(unRead: unRead, labelID: labelID)
            }
            self.updateCounterSync(markUnRead: unRead, on: msgToUpdate, context: context)

            let error = context.saveUpstreamIfNeeded()
            if error != nil {
                hasError = true
            }
        }

        if let conversation = Conversation.conversationForConversationID(message.conversationID, inManagedObjectContext: self.coreDataService.mainContext) {
            (conversation.labels as? Set<ContextLabel>)?.forEach {
                self.coreDataService.mainContext.refresh(conversation, mergeChanges: true)
                self.coreDataService.mainContext.refresh($0, mergeChanges: true)
            }
        }

        if hasError {
            return false
        }
        return true
    }

    func label(messages: [Message], label: String, apply: Bool) -> Bool {
        var result = false
        var hasError = false
        context.performAndWait {
            for message in messages {
                guard let msgToUpdate = try? context.existingObject(with: message.objectID) as? Message else {
                    hasError = true
                    continue
                }

                if apply {
                    if msgToUpdate.add(labelID: label) != nil && msgToUpdate.unRead {
                        self.updateCounterSync(plus: true, with: label, context: context)
                    }
                } else {
                    if msgToUpdate.remove(labelID: label) != nil && msgToUpdate.unRead {
                        self.updateCounterSync(plus: false, with: label, context: context)
                    }
                }

                if let conversation = Conversation.conversationForConversationID(msgToUpdate.conversationID, inManagedObjectContext: context) {
                    conversation.applyLabelChangesOnOneMessage(labelID: label, apply: apply)
                }
            }

            let error = context.saveUpstreamIfNeeded()
            if error != nil {
                hasError = true
            }
        }

        if hasError {
            result = false
        }
        result = true
        return result
    }

    func removeLabel(on message: Message, labels: [String], cleanUnread: Bool) {
        guard let context = message.managedObjectContext else {
            return
        }
        let unread = cleanUnread ? message.unRead : cleanUnread
        for label in labels {
            if let labelId = message.remove(labelID: label), unread {
                self.updateCounterInsideContext(plus: false, with: labelId, context: context)
                if let id = message.selfSent(labelID: labelId) {
                    self.updateCounterInsideContext(plus: false, with: id, context: context)
                }
            }
        }
    }

    func markMessageAndConversationDeleted(labelID: String) {
        let messageFetch = NSFetchRequest<NSFetchRequestResult>(entityName: Message.Attributes.entityName)
        messageFetch.predicate = NSPredicate(format: "(ANY labels.labelID = %@) AND (%K == %@)", "\(labelID)", Message.Attributes.userID, self.userID)
        
        let contextLabelFetch = NSFetchRequest<NSFetchRequestResult>(entityName: ContextLabel.Attributes.entityName)
        contextLabelFetch.predicate = NSPredicate(format: "(%K == %@) AND (%K == %@)", ContextLabel.Attributes.labelID, labelID, Conversation.Attributes.userID, self.userID)

        context.performAndWait {
            if let messages = try? context.fetch(messageFetch) as? [Message] {
                messages.forEach { $0.isSoftDeleted = true }
            }
            if let contextLabels = try? context.fetch(contextLabelFetch) as? [ContextLabel] {
                contextLabels.forEach { label in
                    label.conversation.isSoftDeleted = true
                    let num = max(0, label.conversation.numMessages.intValue - label.messageCount.intValue)
                    label.conversation.numMessages = NSNumber(value: num)
                    label.isSoftDeleted = true
                }
            }
            _ = context.saveUpstreamIfNeeded()
        }
    }

    func cleanSoftDeletedMessagesAndConversation() {
        let messageFetch = NSFetchRequest<NSFetchRequestResult>(entityName: Message.Attributes.entityName)
        messageFetch.predicate = NSPredicate(format: "%K = %@", Message.Attributes.isSoftDeleted, NSNumber(true))
        
        let contextLabelFetch = NSFetchRequest<NSFetchRequestResult>(entityName: ContextLabel.Attributes.entityName)
        contextLabelFetch.predicate = NSPredicate(format: "%K = %@", ContextLabel.Attributes.isSoftDeleted, NSNumber(true))

        context.performAndWait {
            if let messages = try? context.fetch(messageFetch) as? [Message] {
                messages.forEach(context.delete)
            }
            if let contextLabels = try? context.fetch(contextLabelFetch) as? [ContextLabel] {
                contextLabels.forEach { label in
                    if label.conversation != nil {
                        label.conversation.isSoftDeleted = false
                    }
                    context.delete(label)
                }
            }
            _ = context.saveUpstreamIfNeeded()
        }
    }

    func deleteMessage(by labelID: String) -> Bool {
        var result = false
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: Message.Attributes.entityName)

        fetchRequest.predicate = NSPredicate(format: "(ANY labels.labelID = %@) AND (%K == %@)", "\(labelID)", Message.Attributes.userID, self.userID)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: Message.Attributes.time, ascending: false)]
        context.performAndWait {
            do {
                if let oldMessages = try context.fetch(fetchRequest) as? [Message] {
                    for message in oldMessages {
                        context.delete(message)
                    }
                    if context.saveUpstreamIfNeeded() == nil {
                        result = true
                    }
                }
            } catch {
            }
        }
        return result
    }

    func deleteMessage(messageID: String, completion: (() -> Void)? = nil) {
        context.perform {
            if let msg = Message.messageForMessageID(messageID, inManagedObjectContext: self.context) {
                let labelObjs = msg.mutableSetValue(forKey: Message.Attributes.labels)
                labelObjs.removeAllObjects()
                self.context.delete(msg)
            }
            _ = self.context.saveUpstreamIfNeeded()
            completion?()
        }
    }

    func cleanReviewItems(completion: (() -> Void)? = nil) {
        context.perform {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: Message.Attributes.entityName)
            fetchRequest.predicate = NSPredicate(format: "(%K == 1) AND (%K == %@)", Message.Attributes.messageType, Message.Attributes.userID, self.userID)
            do {
                if let messages = try self.context.fetch(fetchRequest) as? [Message] {
                    for msg in messages {
                        self.context.delete(msg)
                    }
                    _ = self.context.saveUpstreamIfNeeded()
                }
            } catch {
            }
            completion?()
        }
    }

    func updateExpirationOffset(of message: Message,
                                expirationTime: TimeInterval,
                                pwd: String,
                                pwdHint: String,
                                completion: (() -> Void)?) {
        let contextToUse = message.managedObjectContext ?? context
        contextToUse.perform {
            if let msg = try? self.context.existingObject(with: message.objectID) as? Message {
                msg.time = Date()
                msg.password = pwd
                msg.passwordHint = pwdHint
                msg.expirationOffset = Int32(expirationTime)
                _ = contextToUse.saveUpstreamIfNeeded()
            }
            completion?()
        }
    }

    func deleteExpiredMessage(completion: (() -> Void)?) {
        context.perform {
            #if !APP_EXTENSION
            let processInfo = userCachedStatus
            #else
            let processInfo = userCachedStatus as? SystemUpTimeProtocol
            #endif
            let date = Date.getReferenceDate(processInfo: processInfo)
            let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: Message.Attributes.entityName)
            fetch.predicate = NSPredicate(format: "%K != NULL AND %K < %@",
                                          Message.Attributes.expirationTime,
                                          Message.Attributes.expirationTime,
                                          date as CVarArg)

            if let messages = try? self.context.fetch(fetch) as? [Message] {
                messages.forEach { (msg) in
                    if msg.unRead {
                        let labels: [String] = msg.getLabelIDs()
                        labels.forEach { (label) in
                            self.updateCounterSync(plus: false, with: label, context: self.context)
                        }
                    }
                    self.updateConversation(by: msg)
                    self.context.delete(msg)
                }
                _ = self.context.saveUpstreamIfNeeded()
            }
            DispatchQueue.main.async {
                completion?()
            }
        }
    }

    private func updateConversation(by expiredMessage: Message) {
        let conversationID = expiredMessage.conversationID
        let context = self.context
        guard !conversationID.isEmpty,
              let conversation = Conversation.conversationForConversationID(conversationID, inManagedObjectContext: context) else {
            return
        }
        let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: Message.Attributes.entityName)
        fetch.predicate = NSPredicate(
            format: "%K == %@ AND %K.length != 0",
            Message.Attributes.conversationID,
            conversation.conversationID,
            Message.Attributes.messageID
        )
        guard let messages = try? self.context.fetch(fetch) as? [Message] else {
            conversation.expirationTime = nil
            return
        }
        #if !APP_EXTENSION
        let processInfo = userCachedStatus
        #else
        let processInfo = userCachedStatus as? SystemUpTimeProtocol
        #endif
        let sorted = messages
            .filter({ $0 != expiredMessage && ($0.expirationTime ?? .distantPast) > Date.getReferenceDate(processInfo: processInfo) })
            .sorted(by: { ($0.expirationTime ?? .distantPast) > ($1.expirationTime ?? .distantPast) })
        conversation.expirationTime = sorted.first?.expirationTime
        let numMessages = max(0, conversation.numMessages.intValue - 1)
        conversation.numMessages = NSNumber(value: numMessages)
    }
}

// MARK: - Attachment related functions
extension CacheService {
    func delete(attachment: Attachment, completion: (() -> Void)?) {
        context.perform {
            if let att = try? self.context.existingObject(with: attachment.objectID) as? Attachment {
                att.isSoftDeleted = true
                _ = self.context.saveUpstreamIfNeeded()
            }
            completion?()
        }
    }

    func cleanOldAttachment() {
        context.perform {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: Attachment.Attributes.entityName)
            fetchRequest.predicate = NSPredicate(format: "(%K == 1) AND %K == NULL", Attachment.Attributes.isSoftDelete, Attachment.Attributes.message)
            let request = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            do {
                try self.context.execute(request)
            } catch {
            }
        }
    }
}

extension CacheService {
    func parseMessagesResponse(labelID: String, isUnread: Bool, response: [String: Any], completion: ((Error?) -> Void)?) {
        guard var messagesArray = response["Messages"] as? [[String: Any]] else {
            completion?(NSError.unableToParseResponse(response))
            return
        }

        for (index, _) in messagesArray.enumerated() {
            messagesArray[index]["UserID"] = self.userID
        }
        let messagesCount = response["Total"] as? Int ?? 0

        context.perform {
            //Prevent the draft is overriden while sending
            if labelID == Message.Location.draft.rawValue, let sendingMessageIDs = Message.getIDsofSendingMessage(managedObjectContext: self.context) {
                let idsSet = Set(sendingMessageIDs)
                var msgIDsOfMessageToRemove: [String] = []

                messagesArray.forEach { (messageDict) in
                    if let msgID = messageDict["ID"] as? String, idsSet.contains(msgID) {
                        msgIDsOfMessageToRemove.append(msgID)
                    }
                }

                msgIDsOfMessageToRemove.forEach { (msgID) in
                    messagesArray.removeAll { (msgDict) -> Bool in
                        if let id = msgDict["ID"] as? String {
                            return id == msgID
                        }
                        return false
                    }
                }
            }

            do {
                if let messages = try GRTJSONSerialization.objects(withEntityName: Message.Attributes.entityName, fromJSONArray: messagesArray, in: self.context) as? [Message] {
                    for msg in messages {
                        // mark the status of metadata being set
                        msg.messageStatus = 1
                    }
                    _ = self.context.saveUpstreamIfNeeded()

                    if let lastMsg = messages.last, let firstMsg = messages.first {
                        self.updateLastUpdatedTime(labelID: labelID, isUnread: isUnread, startTime: firstMsg.time ?? Date(), endTime: lastMsg.time ?? Date(), msgCount: messagesCount, msgType: .singleMessage)
                    }

                    completion?(nil)
                }
            } catch {
                completion?(error)
            }
        }
    }
}

// MARK: - Counter related functions
extension CacheService {
    func updateLastUpdatedTime(labelID: String, isUnread: Bool, startTime: Date, endTime: Date, msgCount: Int, msgType: ViewMode) {
        context.performAndWait {
            let updateTime = self.lastUpdatedStore.lastUpdateDefault(by: labelID, userID: self.userID, context: context, type: msgType)
            if isUnread {
                //Update unread date query time
                if updateTime.isUnreadNew {
                    updateTime.unreadStart = startTime
                }
                if updateTime.unreadEndTime.compare(endTime) == .orderedDescending || updateTime.unreadEndTime == .distantPast {
                    updateTime.unreadEnd = endTime
                }
                updateTime.unreadUpdate = Date()
            } else {
                if updateTime.isNew {
                    updateTime.start = startTime
                    updateTime.total = Int32(msgCount)
                }
                if updateTime.endTime.compare(endTime) == .orderedDescending || updateTime.endTime == .distantPast {
                    updateTime.end = endTime
                }
                updateTime.update = Date()
            }
            _ = context.saveUpstreamIfNeeded()
        }
    }

    func updateCounterSync(markUnRead: Bool, on message: Message, context: NSManagedObjectContext) {
        let offset = markUnRead ? 1 : -1
        let labelIDs: [String] = message.getLabelIDs()
        for lID in labelIDs {
            let unreadCount: Int = lastUpdatedStore.unreadCount(by: lID, userID: self.userID, type: .singleMessage)
            var count = unreadCount + offset
            if count < 0 {
                count = 0
            }
            lastUpdatedStore.updateUnreadCount(by: lID, userID: self.userID, unread: count, total: nil, type: .singleMessage, shouldSave: false)

            // Conversation Count
            let conversationUnreadCount: Int = lastUpdatedStore.unreadCount(by: lID, userID: self.userID, type: .conversation)
            var conversationCount = conversationUnreadCount + offset
            if conversationCount < 0 {
                conversationCount = 0
            }
            lastUpdatedStore.updateUnreadCount(by: lID, userID: self.userID, unread: conversationCount, total: nil, type: .conversation, shouldSave: false)
        }
    }

    func updateCounterSync(plus: Bool, with labelID: String, context: NSManagedObjectContext) {
        let offset = plus ? 1 : -1
        // Message Count
        let unreadCount: Int = lastUpdatedStore.unreadCount(by: labelID, userID: self.userID, type: .singleMessage)
        var count = unreadCount + offset
        if count < 0 {
            count = 0
        }
        lastUpdatedStore.updateUnreadCount(by: labelID, userID: self.userID, unread: count, total: nil, type: .singleMessage, shouldSave: true)

        // Conversation Count
        let conversationUnreadCount: Int = lastUpdatedStore.unreadCount(by: labelID, userID: self.userID, type: .conversation)
        var conversationCount = conversationUnreadCount + offset
        if conversationCount < 0 {
            conversationCount = 0
        }
        lastUpdatedStore.updateUnreadCount(by: labelID, userID: self.userID, unread: conversationCount, total: nil, type: .conversation, shouldSave: true)
    }

    func updateCounterInsideContext(plus: Bool, with labelID: String, context: NSManagedObjectContext) {
        let offset = plus ? 1 : -1
        // Message Count
        let labelCount = lastUpdatedStore.lastUpdate(by: labelID, userID: userID, context: context, type: .singleMessage)
        let unreadCount = Int(labelCount?.unread ?? 0)
        var count = unreadCount + offset
        if count < 0 {
            count = 0
        }
        labelCount?.unread = Int32(count)

        // Conversation Count
        let contextLabelCount = lastUpdatedStore.lastUpdate(by: labelID, userID: userID, context: context, type: .conversation)
        let conversationUnreadCount = Int(contextLabelCount?.unread ?? 0)
        var conversationCount = conversationUnreadCount + offset
        if conversationCount < 0 {
            conversationCount = 0
        }
        contextLabelCount?.unread = Int32(conversationCount)
    }
}

// MARK: - label related functions
extension CacheService {
    func addNewLabel(serverResponse: [String: Any], objectID: String? = nil, completion: (() -> Void)?) {
        context.perform { [weak self] in
            do {
                guard let self = self else { return }
                if let objectID = objectID,
                    let id = self.coreDataService.managedObjectIDForURIRepresentation(objectID),
                    let managedObject = try? self.context.existingObject(with: id),
                    let label = managedObject as? Label,
                    let labelID = serverResponse["ID"] as? String {
                    label.labelID = labelID
                }
                var response = serverResponse
                response["UserID"] = self.userID
                try GRTJSONSerialization.object(withEntityName: Label.Attributes.entityName, fromJSONDictionary: response, in: self.context)
                _ = self.context.saveUpstreamIfNeeded()
            } catch {
            }
            completion?()
        }
    }
    
    func updateLabel(serverReponse: [String: Any], completion: (() -> Void)?) {
        context.perform {
            do {
                var response = serverReponse
                response["UserID"] = self.userID
                if response["ParentID"] == nil {
                    response["ParentID"] = ""
                }
                try GRTJSONSerialization.object(withEntityName: Label.Attributes.entityName, fromJSONDictionary: response, in: self.context)
                _ = self.context.saveUpstreamIfNeeded()
            } catch {
            }
            DispatchQueue.main.async {
                completion?()
            }
        }
    }
    
    func updateLabel(_ label: Label, name: String, color: String, completion: (() -> Void)?) {
        context.perform {
            if let labelToUpdate = try? self.context.existingObject(with: label.objectID) as? Label {
                labelToUpdate.name = name
                labelToUpdate.color = color
                _ = self.context.saveUpstreamIfNeeded()
            }
            DispatchQueue.main.async {
                completion?()
            }
        }
    }

    func deleteLabel(_ label: Label, completion: (() -> Void)?) {
        context.perform {
            if let labelToDelete = try? self.context.existingObject(with: label.objectID) {
                self.context.delete(labelToDelete)
                _ = self.context.saveUpstreamIfNeeded()
            }
            DispatchQueue.main.async {
                completion?()
            }
        }
    }
    
    func deleteLabels(objectIDs: [NSManagedObjectID], completion: (() -> Void)?) {
        context.perform {
            for id in objectIDs {
                guard let label = try? self.context.existingObject(with: id) else {
                    continue
                }
                self.context.delete(label)
            }
            _ = self.context.saveUpstreamIfNeeded()
        }
        DispatchQueue.main.async {
            completion?()
        }
    }
}

// MARK: - contact related functions
extension CacheService {
    func addNewContact(serverResponse: [[String: Any]], shouldFixName: Bool = false, objectID: String? = nil, completion: (([Contact]?, NSError?) -> Void)?) {
        context.perform { [weak self] in
            guard let self = self else { return }
            do {
                if let id = objectID,
                   let objectID = self.coreDataService.managedObjectIDForURIRepresentation(id),
                   let managedObject = try? self.context.existingObject(with: objectID),
                   let contact = managedObject as? Contact,
                   let contactID = serverResponse[0]["ID"] as? String {
                    contact.contactID = contactID
                }

                let contacts = try GRTJSONSerialization.objects(withEntityName: Contact.Attributes.entityName,
                                                                fromJSONArray: serverResponse,
                                                                in: self.context) as? [Contact]
                contacts?.forEach { (c) in
                    c.userID = self.userID
                    if shouldFixName {
                        _ = c.fixName(force: true)
                    }
                    if let emails = c.emails.allObjects as? [Email] {
                        emails.forEach { (e) in
                            e.userID = self.userID
                        }
                    }
                }
                if let error = self.context.saveUpstreamIfNeeded() {
                    completion?(nil, error)
                } else {
                    completion?(contacts, nil)
                }
            } catch {
                completion?(nil, error as NSError)
            }
        }
    }

    func updateContact(contactID: String, cardsJson: [String: Any], completion: ((Result<[Contact], NSError>) -> Void)?) {
        context.perform {
            do {
                // remove all emailID associated with the current contact in the core data
                // since the new data will be added to the core data (parse from response)
                if let originalContact = Contact.contactForContactID(contactID, inManagedObjectContext: self.context) {
                    if let emailObjects = originalContact.emails.allObjects as? [Email] {
                        for emailObject in emailObjects {
                            self.context.delete(emailObject)
                        }
                    }
                }

                if let newContact = try GRTJSONSerialization.object(withEntityName: Contact.Attributes.entityName, fromJSONDictionary: cardsJson, in: self.context) as? Contact {
                    newContact.needsRebuild = true
                    if self.context.saveUpstreamIfNeeded() == nil {
                        completion?(.success([newContact]))
                    }
                }
            } catch {
                completion?(.failure(error as NSError))
            }
        }
    }

    func deleteContact(by contactID: String, completion: ((NSError?) -> Void)?) {
        context.perform {
            var err: NSError?
            if let contact = Contact.contactForContactID(contactID, inManagedObjectContext: self.context) {
                self.context.delete(contact)
            }
            if let error = self.context.saveUpstreamIfNeeded() {
                err = error
            }
            completion?(err)
        }
    }

    func updateContactDetail(serverResponse: [String: Any], completion: ((Contact?, NSError?) -> Void)?) {
        context.perform {
            do {
                if let contact = try GRTJSONSerialization.object(withEntityName: Contact.Attributes.entityName, fromJSONDictionary: serverResponse, in: self.context) as? Contact {
                    contact.isDownloaded = true
                    _ = contact.fixName(force: true)
                    if let error = self.context.saveUpstreamIfNeeded() {
                        completion?(nil, error)
                    } else {
                        completion?(contact, nil)
                    }
                } else {
                    completion?(nil, NSError.unableToParseResponse(serverResponse))
                }
            } catch {
                completion?(nil, error as NSError)
            }
        }
    }
}
