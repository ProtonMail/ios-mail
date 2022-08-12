//
//  CacheService.swift
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
import Crypto
import CoreData
import Groot
import ProtonCore_DataModel

protocol CacheServiceProtocol: Service {
    func addNewLabel(serverResponse: [String: Any], objectID: String?, completion: (() -> Void)?)
    func updateLabel(serverReponse: [String: Any], completion: (() -> Void)?)
    func deleteLabels(objectIDs: [NSManagedObjectID], completion: (() -> Void)?)
    func updateContactDetail(serverResponse: [String: Any], completion: ((Contact?, NSError?) -> Void)?)
    func parseMessagesResponse(
        labelID: LabelID,
        isUnread: Bool,
        response: [String: Any],
        idsOfMessagesBeingSent: [String],
        completion: @escaping (Error?) -> Void
    )
}

class CacheService: CacheServiceProtocol {
    let userID: UserID
    let lastUpdatedStore: LastUpdatedStoreProtocol
    let coreDataService: CoreDataContextProviderProtocol

    private var context: NSManagedObjectContext {
        coreDataService.rootSavingContext
    }

    init(userID: UserID, dependencies: Dependencies = Dependencies()) {
        self.userID = userID
        self.lastUpdatedStore = dependencies.lastUpdatedStore
        self.coreDataService = dependencies.coreDataService
    }

    // MARK: - Generic functions

    func selectByIds<T: CoreDataIdentifiable>(
        context: NSManagedObjectContext,
        ids: [String],
        sortByAttr: String? = nil,
        sortAsc: Bool = false
    ) -> [T] {
        let request = NSFetchRequest<T>(entityName: T.entityName)
        let predicate = NSPredicate(format: "%K in %@", T.attributeIdName, ids)
        request.predicate = predicate
        if let sortAttribute = sortByAttr {
            request.sortDescriptors = [NSSortDescriptor(key: sortAttribute, ascending: sortAsc)]
        }
        var results = [T]()
        context.performAndWait {
            results = (try? context.fetch(request)) ?? []
        }
        return results
    }

    // MARK: - Message related functions
    func move(message: MessageEntity, from fLabel: LabelID, to tLabel: LabelID) -> Bool {
        var hasError = false
        context.performAndWait {
            guard let msgToUpdate = try? context.existingObject(with: message.objectID.rawValue) as? Message else {
                hasError = true
                return
            }

            if let lid = msgToUpdate.remove(labelID: fLabel.rawValue), msgToUpdate.unRead {
                self.updateCounterInsideContext(plus: false, with: lid)
                if let id = msgToUpdate.selfSent(labelID: lid) {
                    self.updateCounterInsideContext(plus: false, with: id)
                }
            }
            if let lid = msgToUpdate.add(labelID: tLabel.rawValue) {
                // if move to trash. clean labels.
                var labelsFound = msgToUpdate.getNormalLabelIDs()
                labelsFound.append(Message.Location.starred.rawValue)
                // prevent the unread being substracted once more
                if fLabel != Message.Location.allmail.labelID {
                    labelsFound.append(Message.Location.allmail.rawValue)
                }
                if lid == Message.Location.trash.rawValue {
                    self.removeLabel(on: msgToUpdate, labels: labelsFound, cleanUnread: true)
                    msgToUpdate.unRead = false
                    PushUpdater().remove(notificationIdentifiers: [msgToUpdate.notificationId])
                }
                if lid == Message.Location.spam.rawValue {
                    self.removeLabel(on: msgToUpdate, labels: labelsFound, cleanUnread: false)
                }

                if msgToUpdate.unRead {
                    self.updateCounterInsideContext(plus: true, with: lid)
                    if let id = msgToUpdate.selfSent(labelID: lid) {
                        self.updateCounterInsideContext(plus: true, with: id)
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

    func delete(message: MessageEntity, label: LabelID) -> Bool {
        let contextToUse = self.context

        var hasError = false
        contextToUse.performAndWait {
            guard let msgToUpdate = try? contextToUse.existingObject(with: message.objectID.rawValue) as? Message else {
                hasError = true
                return
            }

            if let lid = msgToUpdate.remove(labelID: label.rawValue), msgToUpdate.unRead {
                self.updateCounterSync(plus: false, with: LabelID(lid))
                if let id = msgToUpdate.selfSent(labelID: lid) {
                    self.updateCounterSync(plus: false, with: LabelID(id))
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

    func mark(message: MessageEntity, labelID: LabelID, unRead: Bool) -> Bool {
        var hasError = false
        context.performAndWait {
            guard let msgToUpdate = try? context.existingObject(with: message.objectID.rawValue) as? Message else {
                hasError = true
                return
            }

            guard msgToUpdate.unRead != unRead else {
                return
            }

            msgToUpdate.unRead = unRead

            if unRead == false {
                PushUpdater().remove(notificationIdentifiers: [msgToUpdate.notificationId])
            }
            if let conversation = Conversation.conversationForConversationID(message.conversationID.rawValue, inManagedObjectContext: context) {
                conversation.applySingleMarkAsChanges(unRead: unRead, labelID: labelID.rawValue)
            }
            self.updateCounterSync(markUnRead: unRead, on: message.getLabelIDs().map(\.rawValue))

            let error = context.saveUpstreamIfNeeded()
            if error != nil {
                hasError = true
            }
        }

        if hasError {
            return false
        }
        return true
    }

    func label(messages: [MessageEntity], label: LabelID, apply: Bool) -> Bool {
        var result = false
        var hasError = false
        context.performAndWait {
            for message in messages {
                guard let msgToUpdate = try? context.existingObject(with: message.objectID.rawValue) as? Message else {
                    hasError = true
                    continue
                }

                if apply {
                    if msgToUpdate.add(labelID: label.rawValue) != nil && msgToUpdate.unRead {
                        self.updateCounterSync(plus: true, with: label)
                    }
                } else {
                    if msgToUpdate.remove(labelID: label.rawValue) != nil && msgToUpdate.unRead {
                        self.updateCounterSync(plus: false, with: label)
                    }
                }

                if let conversation = Conversation.conversationForConversationID(msgToUpdate.conversationID, inManagedObjectContext: context) {
                    conversation.applyLabelChangesOnOneMessage(labelID: label.rawValue, apply: apply)
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
        let unread = cleanUnread ? message.unRead : cleanUnread
        for label in labels {
            if let labelId = message.remove(labelID: label), unread {
                self.updateCounterInsideContext(plus: false, with: labelId)
                if let id = message.selfSent(labelID: labelId) {
                    self.updateCounterInsideContext(plus: false, with: id)
                }
            }
        }
    }

    func markMessageAndConversationDeleted(labelID: LabelID) {
        let messageFetch = NSFetchRequest<Message>(entityName: Message.Attributes.entityName)
        messageFetch.predicate = NSPredicate(format: "(ANY labels.labelID = %@) AND (%K == %@)", "\(labelID)", Message.Attributes.userID, self.userID.rawValue)

        let contextLabelFetch = NSFetchRequest<ContextLabel>(entityName: ContextLabel.Attributes.entityName)
        contextLabelFetch.predicate = NSPredicate(format: "(%K == %@) AND (%K == %@)", ContextLabel.Attributes.labelID, labelID.rawValue, Conversation.Attributes.userID, self.userID.rawValue)

        context.performAndWait {
            if let messages = try? context.fetch(messageFetch) {
                messages.forEach { $0.isSoftDeleted = true }
            }
            if let contextLabels = try? context.fetch(contextLabelFetch) {
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
        let messageFetch = NSFetchRequest<Message>(entityName: Message.Attributes.entityName)
        messageFetch.predicate = NSPredicate(format: "%K = %@", Message.Attributes.isSoftDeleted, NSNumber(true))

        let contextLabelFetch = NSFetchRequest<ContextLabel>(entityName: ContextLabel.Attributes.entityName)
        contextLabelFetch.predicate = NSPredicate(format: "%K = %@", ContextLabel.Attributes.isSoftDeleted, NSNumber(true))

        context.performAndWait {
            if let messages = try? context.fetch(messageFetch) {
                messages.forEach(context.delete)
            }
            if let contextLabels = try? context.fetch(contextLabelFetch) {
                contextLabels.forEach { label in
                    let conversation: Conversation? = label.conversation
                    if conversation != nil {
                        label.conversation.isSoftDeleted = false
                    }
                    context.delete(label)
                }
            }
            _ = context.saveUpstreamIfNeeded()
        }
    }

    func cleanReviewItems(completion: (() -> Void)? = nil) {
        context.perform {
            let fetchRequest = NSFetchRequest<Message>(entityName: Message.Attributes.entityName)
            fetchRequest.predicate = NSPredicate(format: "(%K == 1) AND (%K == %@)", Message.Attributes.messageType, Message.Attributes.userID, self.userID.rawValue)
            do {
                let messages = try self.context.fetch(fetchRequest)
                for msg in messages {
                    self.context.delete(msg)
                }
                _ = self.context.saveUpstreamIfNeeded()
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
            if let msg = try? contextToUse.existingObject(with: message.objectID) as? Message {
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
            let fetch = NSFetchRequest<Message>(entityName: Message.Attributes.entityName)
            fetch.predicate = NSPredicate(format: "%K != NULL AND %K < %@",
                                          Message.Attributes.expirationTime,
                                          Message.Attributes.expirationTime,
                                          date as CVarArg)

            if let messages = try? self.context.fetch(fetch) {
                messages.forEach { (msg) in
                    if msg.unRead {
                        let labels = msg.getLabelIDs().map{ LabelID($0) }
                        labels.forEach { label in
                            self.updateCounterSync(plus: false, with: label)
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
        let fetch = NSFetchRequest<Message>(entityName: Message.Attributes.entityName)
        fetch.predicate = NSPredicate(
            format: "%K == %@ AND %K.length != 0",
            Message.Attributes.conversationID,
            conversation.conversationID,
            Message.Attributes.messageID
        )
        guard let messages = try? self.context.fetch(fetch) else {
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
    func delete(attachment: AttachmentEntity, completion: (() -> Void)?) {
        context.perform {
            if let att = try? self.context.existingObject(with: attachment.objectID.rawValue) as? Attachment {
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
                try self.context.executeAndMergeChanges(using: request)
            } catch {
                assertionFailure("Old attachment deletion failed: \(error.localizedDescription)")
            }
        }
    }
}

extension CacheService {
    func parseMessagesResponse(
        labelID: LabelID,
        isUnread: Bool,
        response: [String: Any],
        idsOfMessagesBeingSent: [String],
        completion: @escaping (Error?) -> Void) {
        guard var messagesArray = response["Messages"] as? [[String: Any]] else {
            completion(NSError.unableToParseResponse(response))
            return
        }

        for (index, _) in messagesArray.enumerated() {
            messagesArray[index]["UserID"] = self.userID.rawValue
        }
        let messagesCount = response["Total"] as? Int ?? 0

        if labelID == Message.Location.draft.labelID {
            //Prevent drafts from being overriden while sending
            messagesArray.removeAll { messageDict in
                guard let msgID = messageDict["ID"] as? String else {
                    return true
                }

                return idsOfMessagesBeingSent.contains(msgID)
            }
        }

        context.perform {
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
                }
                completion(nil)
            } catch {
                completion(error)
            }
        }
    }
}

// MARK: - Counter related functions
extension CacheService {
    func updateLastUpdatedTime(labelID: LabelID, isUnread: Bool, startTime: Date, endTime: Date, msgCount: Int, msgType: ViewMode) {
        context.performAndWait {
            let updateTime = self.lastUpdatedStore.lastUpdateDefault(by: labelID.rawValue, userID: self.userID.rawValue, type: msgType)
            if isUnread {
                // Update unread date query time
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

    func updateCounterSync(markUnRead: Bool, on message: Message) {
        self.updateCounterSync(markUnRead: markUnRead, on: message.getLabelIDs())
    }

    func updateCounterSync(markUnRead: Bool, on labelIDs: [String]) {
        let offset = markUnRead ? 1 : -1
        for lID in labelIDs {
            let unreadCount: Int = lastUpdatedStore.unreadCount(by: lID, userID: self.userID.rawValue, type: .singleMessage)
            var count = unreadCount + offset
            if count < 0 {
                count = 0
            }
            lastUpdatedStore.updateUnreadCount(by: lID, userID: self.userID.rawValue, unread: count, total: nil, type: .singleMessage, shouldSave: false)

            // Conversation Count
            let conversationUnreadCount: Int = lastUpdatedStore.unreadCount(by: lID, userID: self.userID.rawValue, type: .conversation)
            var conversationCount = conversationUnreadCount + offset
            if conversationCount < 0 {
                conversationCount = 0
            }
            lastUpdatedStore.updateUnreadCount(by: lID, userID: self.userID.rawValue, unread: conversationCount, total: nil, type: .conversation, shouldSave: false)
        }
    }

    func updateCounterSync(plus: Bool, with labelID: LabelID) {
        let offset = plus ? 1 : -1
        // Message Count
        let unreadCount: Int = lastUpdatedStore.unreadCount(by: labelID.rawValue, userID: self.userID.rawValue, type: .singleMessage)
        var count = unreadCount + offset
        if count < 0 {
            count = 0
        }
        lastUpdatedStore.updateUnreadCount(by: labelID.rawValue, userID: self.userID.rawValue, unread: count, total: nil, type: .singleMessage, shouldSave: true)

        // Conversation Count
        let conversationUnreadCount: Int = lastUpdatedStore.unreadCount(by: labelID.rawValue, userID: self.userID.rawValue, type: .conversation)
        var conversationCount = conversationUnreadCount + offset
        if conversationCount < 0 {
            conversationCount = 0
        }
        lastUpdatedStore.updateUnreadCount(by: labelID.rawValue, userID: self.userID.rawValue, unread: conversationCount, total: nil, type: .conversation, shouldSave: true)
    }

    private func updateCounterInsideContext(plus: Bool, with labelID: String) {
        let offset = plus ? 1 : -1
        // Message Count
        let labelCount: LabelCount? = lastUpdatedStore.lastUpdate(by: labelID, userID: userID.rawValue, type: .singleMessage)
        let unreadCount = Int(labelCount?.unread ?? 0)
        var count = unreadCount + offset
        if count < 0 {
            count = 0
        }
        labelCount?.unread = Int32(count)

        // Conversation Count
        let contextLabelCount: LabelCount? = lastUpdatedStore.lastUpdate(by: labelID, userID: userID.rawValue, type: .conversation)
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
                response["UserID"] = self.userID.rawValue
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
                response["UserID"] = self.userID.rawValue
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
                    c.userID = self.userID.rawValue
                    if shouldFixName {
                        _ = c.fixName(force: true)
                    }
                    if let emails = c.emails.allObjects as? [Email] {
                        emails.forEach { (e) in
                            e.userID = self.userID.rawValue
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

    func updateContact(contactID: ContactID, cardsJson: [String: Any], completion: ((Result<[Contact], NSError>) -> Void)?) {
        context.perform {
            do {
                // remove all emailID associated with the current contact in the core data
                // since the new data will be added to the core data (parse from response)
                if let originalContact = Contact.contactForContactID(contactID.rawValue, inManagedObjectContext: self.context) {
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

    func deleteContact(by contactID: ContactID, completion: ((NSError?) -> Void)?) {
        context.perform {
            var err: NSError?
            if let contact = Contact.contactForContactID(contactID.rawValue, inManagedObjectContext: self.context) {
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

extension CacheService {
    struct Dependencies {
        let coreDataService: CoreDataContextProviderProtocol
        let lastUpdatedStore: LastUpdatedStoreProtocol

        init(
            coreDataService: CoreDataContextProviderProtocol = sharedServices.get(by: CoreDataService.self),
            lastUpdatedStore: LastUpdatedStoreProtocol = sharedServices.get(by: LastUpdatedStore.self)
        ) {
            self.coreDataService = coreDataService
            self.lastUpdatedStore = lastUpdatedStore
        }
    }
}
