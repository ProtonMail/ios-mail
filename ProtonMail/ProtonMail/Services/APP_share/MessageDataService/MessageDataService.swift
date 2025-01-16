//
//  MessageDataService.swift
//  Proton Mail
//
//
//  Copyright (c) 2019 Proton AG
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

import CoreData
import Foundation
import Groot
import PromiseKit
import ProtonCoreCrypto
import ProtonCoreDataModel
import ProtonCoreNetworking
import ProtonCoreServices
import ProtonMailAnalytics

protocol MessageDataServiceProtocol: AnyObject {
    var pushNotificationMessageID: String? { get set }
    var messageDecrypter: MessageDecrypter { get }

    /// Request to get the messages for a user
    /// - Parameters:
    ///   - labelID: identifier for labels, folders and locations.
    ///   - endTime: timestamp to get messages earlier than this value.
    ///   - fetchUnread: whether we want only unread messages or not.
    func fetchMessages(labelID: LabelID, endTime: Int, fetchUnread: Bool, completion: @escaping (_ task: URLSessionDataTask?, _ result: Swift.Result<JSONDictionary, ResponseError>) -> Void)

    /// Requests the total number of messages
    func fetchMessagesCount(completion: @escaping (MessageCountResponse) -> Void)

    func fetchMessageMetaData(messageIDs: [MessageID], completion: @escaping (FetchMessagesByIDResponse) -> Void)

    func isEventIDValid() -> Bool
    func idsOfMessagesBeingSent() -> [String]

    func getMessageSendingData(for uri: String) -> MessageSendingData?
    func deleteMessage(objectID: String)
    func getMessageEntity(for messageID: MessageID) throws -> MessageEntity
    func getAttachmentEntity(for uri: String) throws -> AttachmentEntity?
    func removeAttachmentFromDB(objectIDs: [ObjectID])
    func updateAttachment(by uploadResponse: UploadAttachment.UploadingResponse, attachmentObjectID: ObjectID)

    func updateMessageAfterSend(
        message: MessageEntity,
        sendResponse: JSONDictionary,
        completionQueue: DispatchQueue,
        completion: @escaping () -> Void
    )
    func messageWithLocation(recipientList: String,
                             bccList: String,
                             ccList: String,
                             title: String,
                             encryptionPassword: String,
                             passwordHint: String,
                             expirationTimeInterval: TimeInterval,
                             body: String,
                             attachments: [Any]?,
                             mailbox_pwd: Passphrase,
                             sendAddress: Address,
                             inManagedObjectContext context: NSManagedObjectContext) -> Message
    func saveDraft(_ message: MessageEntity) throws
    func updateMessage(_ message: Message,
                       expirationTimeInterval: TimeInterval,
                       body: String,
                       mailbox_pwd: Passphrase)
    func mark(messageObjectIDs: [NSManagedObjectID], labelID: LabelID, unRead: Bool) -> Bool
    func updateAttKeyPacket(message: MessageEntity, addressID: String)
    func delete(att: AttachmentEntity, messageID: MessageID) -> Promise<Void>
    func upload(att: Attachment)
    func userAddress(of addressID: AddressID) -> Address?
}

// sourcery: mock
protocol LocalMessageDataServiceProtocol {
    func cleanMessage(removeAllDraft: Bool, cleanBadgeAndNotifications: Bool)
}

/// Message data service
class MessageDataService: MessageDataServiceProtocol, LocalMessageDataServiceProtocol, MessageDataProcessProtocol {

    typealias ReadBlock = (() -> Void)

    // TODO: those 3 var need to double check to clean up
    var pushNotificationMessageID: String?

    let apiService: APIService
    let userID: UserID
    let labelDataService: LabelsDataService
    let localNotificationService: LocalNotificationService
    let contextProvider: CoreDataContextProviderProtocol
    let lastUpdatedStore: LastUpdatedStoreProtocol
    let cacheService: CacheService
    let messageDecrypter: MessageDecrypter

    private var userDataSource: UserDataSource? {
        parent
    }

    weak var queueManager: QueueManager?
    weak var parent: UserManager?
    let dependencies: Dependencies

    init(
        api: APIService,
        userID: UserID,
        labelDataService: LabelsDataService,
        localNotificationService: LocalNotificationService,
        queueManager: QueueManager?,
        contextProvider: CoreDataContextProviderProtocol,
        lastUpdatedStore: LastUpdatedStoreProtocol,
        user: UserManager,
        cacheService: CacheService,
        dependencies: Dependencies
    ) {
        self.apiService = api
        self.userID = userID
        self.labelDataService = labelDataService
        self.localNotificationService = localNotificationService
        self.contextProvider = contextProvider
        self.lastUpdatedStore = lastUpdatedStore
        self.parent = user
        self.cacheService = cacheService
        self.messageDecrypter = MessageDecrypter(userDataSource: user)
        self.dependencies = dependencies

        setupNotifications()
        self.queueManager = queueManager
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func fetchMessages(
        labelID: LabelID,
        endTime: Int,
        fetchUnread: Bool,
        completion: @escaping (_ task: URLSessionDataTask?, _ result: Swift.Result<JSONDictionary, ResponseError>) -> Void
    ) {
        var descending = true
        if labelID == Message.Location.scheduled.labelID || labelID == Message.Location.snooze.labelID {
            descending = false
        }
        let request = FetchMessagesByLabelRequest(
            labelID: labelID.rawValue,
            endTime: endTime,
            sort: labelID == Message.Location.snooze.labelID ? .snoozeTime : .time,
            isUnread: fetchUnread,
            descending: descending
        )
        apiService.perform(request: request, jsonDictionaryCompletion: completion)
    }

    func fetchMessagesCount(completion: @escaping (MessageCountResponse) -> Void) {
        let counterRoute = MessageCountRequest()
        apiService.perform(request: counterRoute, response: MessageCountResponse()) { _, response in
            completion(response)
        }
    }

    // MAKR : upload attachment

    // MARK: - - Refactored functions

    ///  nonmaly fetching the message from server based on label and time. //TODO:: change to promise
    ///
    /// - Parameters:
    ///   - labelID: labelid, location id, forlder id
    ///   - time: the latest update time
    ///   - forceClean: force clean the exsition messages first
    ///   - onDownload: Closure called when items have been downloaded but not yet parsed. Gives a chance to clean up right before we add a new dataset
    ///   - completion: aync complete handler

    @available(*, deprecated, message: "Moving to FetchMessagesUseCase")
    func fetchMessages(byLabel labelID: LabelID, time: Int, forceClean: Bool, isUnread: Bool, queued: Bool = true, completion: @escaping CompletionBlock, onDownload: (() -> Void)? = nil) {
        let queue = queued ? queueManager?.queue : noQueue
        queue? {
            let completionWrapper: (_ task: URLSessionDataTask?, _ result: Swift.Result<JSONDictionary, ResponseError>) -> Void = { task, result in
                do {
                    let response = try result.get()
                    onDownload?()
                    try self.cacheService.parseMessagesResponse(
                        labelID: labelID,
                        isUnread: isUnread,
                        response: response,
                        idsOfMessagesBeingSent: self.idsOfMessagesBeingSent()
                    )

                            let counterRoute = MessageCountRequest()
                            self.apiService.perform(request: counterRoute, response: MessageCountResponse()) { _, response in
                                if response.error == nil {
                                    self.parent?.eventsService.processEvents(messageCounts: response.counts)
                                }
                            }
                            DispatchQueue.main.async {
                                completion(task, response, nil)
                            }
                } catch {
                    DispatchQueue.main.async {
                        completion(task, nil, error as NSError?)
                    }
                }
            }
            var descending = true
            if labelID == Message.Location.scheduled.labelID || labelID == Message.Location.snooze.labelID {
                descending = false
            }
            let request = FetchMessagesByLabelRequest(
                labelID: labelID.rawValue,
                endTime: time,
                sort: labelID == Message.Location.snooze.labelID ? .snoozeTime : .time,
                isUnread: isUnread,
                descending: descending
            )
            self.apiService.perform(request: request, jsonDictionaryCompletion: completionWrapper)
        }
    }

    func isEventIDValid() -> Bool {
        let eventID = lastUpdatedStore.lastEventID(userID: self.userID)
        let isValid = eventID != "" && eventID != "0"
        if !isValid {
            SystemLogger.log(message: "Unexpected eventID: \(eventID)")
        }
        return isValid
    }

    /// Sync mail setting when user in composer
    /// workaround
    func syncMailSetting() {
        self.queueManager?.queue {
            let eventAPI = EventCheckRequest(
                eventID: self.lastUpdatedStore.lastEventID(userID: self.userID),
                discardContactsMetadata: EventCheckRequest.isNoMetaDataForContactsEnabled
            )
            self.apiService.perform(request: eventAPI, response: EventCheckResponse()) { _, response in
                guard response.responseCode == 1000 else {
                    return
                }
                self.parent?.eventsService.processEvents(mailSettings: response.mailSettings)
                self.parent?.eventsService.processEvents(space: response.usedSpace)
            }
        }
    }

    /// upload attachment to server
    ///
    /// - Parameter att: Attachment
    func upload(att: Attachment) {
        self.queue(att: att, action: .uploadAtt(attachmentObjectID: att.objectID.uriRepresentation().absoluteString))
    }

    /// delete attachment from server
    ///
    /// - Parameter att: Attachment
    func delete(att: AttachmentEntity, messageID: MessageID) -> Promise<Void> {
        SystemLogger.log(message: "MDS deleting att \(att.id)", category: .draft)

        return Promise { seal in
            let objectID = att.objectID.rawValue.uriRepresentation().absoluteString
            let task = QueueManager.Task(
                messageID: messageID.rawValue,
                action: .deleteAtt(attachmentObjectID: objectID,
                                   attachmentID: att.id.rawValue),
                userID: self.userID,
                dependencyIDs: [],
                isConversation: false
            )
            self.queueManager?.addTask(task)
            self.cacheService.delete(attachment: att) {
                seal.fulfill_()
            }
        }
    }

    func updateAttKeyPacket(message: MessageEntity, addressID: String) {
        let objectID = message.objectID.rawValue.uriRepresentation().absoluteString
        self.queue(.updateAttKeyPacket(messageObjectID: objectID, addressID: addressID))
    }

    // MARK : Send message

    func send(inQueue message: MessageEntity, deliveryTime: Date?) throws {
            self.localNotificationService.scheduleMessageSendingFailedNotification(
                .init(messageID: message.messageID, subtitle: message.title)
            )

        try queueMessage(
            with: message.objectID,
            action: .send(messageObjectID: message.objectID.rawValue.uriRepresentation().absoluteString, deliveryTime: deliveryTime)
        )
    }

    // TODO: fixme - double check it  // this way is a little bit hacky. future we will prebuild the send message body
    func injectTransientValuesIntoMessages() {
        let ids = queueManager?.queuedMessageIds() ?? []
        contextProvider.performOnRootSavingContext { context in
            ids.forEach { messageID in
                guard let objectID = self.contextProvider.managedObjectIDForURIRepresentation(messageID),
                      let managedObject = try? context.existingObject(with: objectID) else {
                    return
                }
                if let message = managedObject as? Message {
                    self.cachePropertiesForBackground(in: message)
                }
                if let attachment = managedObject as? Attachment {
                    self.cachePropertiesForBackground(in: attachment.message)
                }
            }
        }
    }

    //// only needed for drafts
    private func cachePropertiesForBackground(in message: Message) {
        // these cached objects will allow us to update the draft, upload attachment and send the message after the mainKey will be locked
        // they are transient and will not be persisted in the db, only in managed object context
        message.cachedPassphrase = userDataSource?.mailboxPassword
        message.cachedAuthCredential = userDataSource?.authCredential
        message.cachedUser = userDataSource?.userInfo
        if let addressID = message.addressID {
            message.cachedAddress = defaultUserAddress(of: AddressID(addressID)) // computed property depending on current user settings
        }
    }

    func empty(location: Message.Location) {
        self.empty(labelID: location.labelID)
    }

    func empty(labelID: LabelID) {
        self.cacheService.markMessageAndConversationDeleted(labelID: labelID)
        self.labelDataService.resetCounter(labelID: labelID)
        queue(.empty(currentLabelID: labelID.rawValue))
    }

    private func noQueue(_ readBlock: @escaping ReadBlock) {
        readBlock()
    }

    @available(*, deprecated, message: "Moving to FetchMessageDetailUseCase")
    func forceFetchDetailForMessage(
        _ message: MessageEntity,
        runInQueue: Bool = true,
        ignoreDownloaded: Bool = false,
        completion: @escaping (NSError?) -> Void
    ) {
        let msgID = message.messageID
        let closure = runInQueue ? self.queueManager?.queue : noQueue
        closure? {
            let completionWrapper: (_ task: URLSessionDataTask?, _ result: Swift.Result<JSONDictionary, ResponseError>) -> Void = { _, result in
                let objectId = message.objectID.rawValue
                self.contextProvider.performOnRootSavingContext { context in
                    let response = try? result.get()
                    var error = result.error as NSError?
                    if let newMessage = context.object(with: objectId) as? Message, response != nil {
                        // TODO: need check the response code
                        if var msg: [String: Any] = response?["Message"] as? [String: Any] {
                            msg.removeValue(forKey: "Location")
                            msg.removeValue(forKey: "Starred")
                            msg.removeValue(forKey: "test")
                            msg["UserID"] = self.userID.rawValue
                            msg.addAttachmentOrderField()

                            do {
                                if !ignoreDownloaded,
                                   newMessage.isDetailDownloaded,
                                   let time = msg["Time"] as? TimeInterval,
                                   let oldTime = newMessage.time?.timeIntervalSince1970 {
                                    // remote time and local time are not empty
                                    if oldTime > time {
                                        DispatchQueue.main.async {
                                            completion(error)
                                        }
                                        return
                                    }
                                }
                                let localAttachments = newMessage.attachments.allObjects.compactMap { $0 as? Attachment}.filter { attach in
                                    if attach.isSoftDeleted {
                                        return false
                                    }
                                    return !attach.inline()
                                }
                                let localAttachmentCount = localAttachments.count

                                // This will remove all attachments that are still not uploaded to BE
                                try GRTJSONSerialization.object(withEntityName: Message.Attributes.entityName, fromJSONDictionary: msg, in: context)

                                // Adds back the attachments that are still uploading
                                for att in localAttachments {
                                    if att.managedObjectContext != nil {
                                        if !newMessage.attachments.contains(att) {
                                            newMessage.attachments.adding(att)
                                            att.message = newMessage
                                        }
                                    } else {
                                        if let newAtt = context.object(with: att.objectID) as? Attachment {
                                            if !newMessage.attachments.contains(newAtt) {
                                                newMessage.attachments.adding(newAtt)
                                                newAtt.message = newMessage
                                            }
                                        }
                                    }
                                }

                                // Use local attachment count since the not-uploaded attachment is not counted
                                newMessage.numAttachments = NSNumber(value: localAttachmentCount)
                                newMessage.isDetailDownloaded = true
                                newMessage.messageStatus = 1
                                if newMessage.unRead {
                                    self.cacheService.updateCounterSync(markUnRead: false, on: newMessage)
                                    if let labelID = newMessage.firstValidFolder() {
                                        self.mark(
                                            messageObjectIDs: [objectId],
                                            labelID: LabelID(labelID),
                                            unRead: false,
                                            context: context
                                        )
                                    }
                                }

                                newMessage.unRead = false
                                self.dependencies.pushUpdater.remove(notificationIdentifiers: [newMessage.notificationId])
                                error = context.saveUpstreamIfNeeded()
                                DispatchQueue.main.async {
                                    completion(error)
                                }
                            } catch let ex as NSError {
                                DispatchQueue.main.async {
                                    completion(ex)
                                }
                            }
                        } else {
                            DispatchQueue.main.async {
                                completion(NSError.badResponse())
                            }
                        }
                    } else {
                        error = NSError.unableToParseResponse(response)
                        DispatchQueue.main.async {
                            completion(error)
                        }
                    }
                }
            }
            let request = MessageDetailRequest(messageID: msgID)
            self.apiService.perform(request: request, jsonDictionaryCompletion: completionWrapper)
        }
    }

    func fetchNotificationMessageDetail(_ messageID: MessageID, completion: @escaping (Swift.Result<MessageEntity, Error>) -> Void) {
        SystemLogger.log(
            message: "fetchNotificationMessageDetail queue enqueue",
            category: .notificationDebug
        )
        self.queueManager?.queue {
            SystemLogger.log(
                message: "fetchNotificationMessageDetail queue start",
                category: .notificationDebug
            )
            let completionWrapper: (_ task: URLSessionDataTask?, _ result: Swift.Result<JSONDictionary, ResponseError>) -> Void = { task, result in
                SystemLogger.log(
                    message: "fetchNotificationMessageDetail request end",
                    category: .notificationDebug
                )
                self.contextProvider.performOnRootSavingContext { context in
                    switch result {
                    case .success(let response):
                        // TODO: need check the respons code
                        if var msg: [String: Any] = response["Message"] as? [String: Any] {
                            msg.removeValue(forKey: "Location")
                            msg.removeValue(forKey: "Starred")
                            msg.removeValue(forKey: "test")
                            msg["UserID"] = self.userID.rawValue
                            msg.addAttachmentOrderField()

                            do {
                                if let messageOut = try GRTJSONSerialization.object(withEntityName: Message.Attributes.entityName, fromJSONDictionary: msg, in: context) as? Message {
                                    messageOut.messageStatus = 1
                                    messageOut.isDetailDownloaded = true
                                    if messageOut.unRead == true {
                                        messageOut.unRead = false
                                        self.dependencies.pushUpdater.remove(notificationIdentifiers: [messageOut.notificationId])
                                        self.cacheService.updateCounterSync(markUnRead: false, on: messageOut)
                                    }

                                    if let error = context.saveUpstreamIfNeeded() {
                                        throw error
                                    }

                                    if let labelID = messageOut.firstValidFolder() {
                                        self.mark(
                                            messageObjectIDs: [messageOut.objectID],
                                            labelID: LabelID(labelID),
                                            unRead: false,
                                            context: context
                                        )
                                    }

                                    let message = MessageEntity(messageOut)

                                    DispatchQueue.main.async {
                                        completion(.success(message))
                                    }
                                }
                            } catch {
                                DispatchQueue.main.async {
                                    completion(.failure(error))
                                }
                            }
                        } else {
                            DispatchQueue.main.async {
                                completion(.failure(NSError.badResponse()))
                            }
                        }
                    case .failure(let error):
                        DispatchQueue.main.async {
                            completion(.failure(error))
                        }
                    }
                }
            }

            self.contextProvider.performOnRootSavingContext { context in
                guard
                    let message = Message.messageForMessageID(messageID.rawValue,
                                                              inManagedObjectContext: context),
                    message.isDetailDownloaded
                else {
                    let request = MessageDetailRequest(messageID: messageID)
                    SystemLogger.log(
                        message: "fetchNotificationMessageDetail request start",
                        category: .notificationDebug
                    )
                    self.apiService.perform(request: request, jsonDictionaryCompletion: completionWrapper)
                    return
                }
                if let labelID = message.firstValidFolder() {
                    self.mark(messageObjectIDs: [message.objectID], labelID: LabelID(labelID), unRead: false)
                }

                let entity = MessageEntity(message)

                DispatchQueue.main.async {
                    completion(.success(entity))
                }
            }
        }
    }

    // MARK: fuctions for only fetch the local cache
    /**
     fetch the message by location from local cache

     :param: location message location enum

     :returns: NSFetchedResultsController
     */
    func fetchedResults(
        by labelID: LabelID,
        viewMode: ViewMode,
        isUnread: Bool = false,
        isAscending: Bool = false
    ) -> NSFetchedResultsController<NSFetchRequestResult>? {
        guard let parent = parent else { return nil }
        let showMoved = parent.mailSettings.showMoved
        switch viewMode {
        case .singleMessage:
            let predicate = predicatesForSingleMessageMode(
                labelID: labelID,
                isUnread: isUnread,
                showMoved: showMoved
            )
            var sortDescriptors: [NSSortDescriptor] = []
            if labelID == Message.Location.snooze.labelID {
                sortDescriptors = [
                    NSSortDescriptor(
                        key: #keyPath(Message.snoozeTime),
                        ascending: true
                    ),
                    NSSortDescriptor(key: #keyPath(Message.order), ascending: isAscending)
                ]
            } else {
                sortDescriptors = [
                    NSSortDescriptor(
                        key: #keyPath(Message.time),
                        ascending: isAscending
                    ),
                    NSSortDescriptor(key: #keyPath(Message.order), ascending: isAscending)
                ]
            }
            return contextProvider.createFetchedResultsController(
                entityName: Message.Attributes.entityName,
                predicate: predicate,
                sortDescriptors: sortDescriptors,
                fetchBatchSize: 30,
                sectionNameKeyPath: nil
            )
        case .conversation:
            let predicate = predicatesForConversationMode(labelID: labelID, isUnread: isUnread)
            var sortDescriptors: [NSSortDescriptor] = []
            if labelID == Message.Location.snooze.labelID {
                sortDescriptors = [
                    NSSortDescriptor(keyPath: \ContextLabel.snoozeTime, ascending: true),
                    NSSortDescriptor(keyPath: \ContextLabel.order, ascending: isAscending)
                ]
            } else if labelID == Message.Location.inbox.labelID {
                sortDescriptors = [
                    NSSortDescriptor(keyPath: \ContextLabel.snoozeTime, ascending: isAscending),
                    NSSortDescriptor(keyPath: \ContextLabel.time, ascending: isAscending),
                    NSSortDescriptor(keyPath: \ContextLabel.order, ascending: isAscending)
                ]
            }
            else {
                sortDescriptors = [
                    NSSortDescriptor(keyPath: \ContextLabel.time, ascending: isAscending),
                    NSSortDescriptor(keyPath: \ContextLabel.order, ascending: isAscending)
                ]
            }
            return contextProvider.createFetchedResultsController(
                entityName: ContextLabel.Attributes.entityName,
                predicate: predicate,
                sortDescriptors: sortDescriptors,
                fetchBatchSize: 30,
                sectionNameKeyPath: nil
            )
        }
    }

    private func predicatesForSingleMessageMode(labelID: LabelID, isUnread: Bool, showMoved: ShowMoved) -> NSPredicate {
        let userIDPredicate = NSPredicate(format: "%K == %@", Message.Attributes.userID, userID.rawValue)
        let statusPredicate = NSPredicate(format: "%K > %d", Message.Attributes.messageStatus, 0)
        let softDeletePredicate = NSPredicate(format: "%K == %@", Message.Attributes.isSoftDeleted, NSNumber(false))
        let unreadPredicate = NSPredicate(format: "%K == %@", Message.Attributes.unRead, NSNumber(value: isUnread))
        var subpredicates = [userIDPredicate, statusPredicate, softDeletePredicate]

        if isUnread {
            subpredicates.append(unreadPredicate)
        }

        if labelID == LabelLocation.draft.labelID && showMoved.keepDraft {
            subpredicates.append(
                NSPredicate(
                    format: "(ANY labels.labelID == %@) OR (ANY labels.labelID == %@)",
                    labelID.rawValue,
                    LabelLocation.hiddenDraft.rawLabelID
                )
            )
        } else if labelID == LabelLocation.sent.labelID && showMoved.keepSent {
            subpredicates.append(
                NSPredicate(
                    format: "(ANY labels.labelID == %@) OR (ANY labels.labelID == %@)",
                    labelID.rawValue,
                    LabelLocation.hiddenSent.rawLabelID
                )
            )
        } else {
            subpredicates.append(NSPredicate(format: "(ANY labels.labelID = %@)", labelID.rawValue))
        }
        return NSCompoundPredicate(andPredicateWithSubpredicates: subpredicates)
    }

    private func predicatesForConversationMode(labelID: LabelID, isUnread: Bool) -> NSPredicate {
        let userIDPredicate = NSPredicate(format: "%K == %@", ContextLabel.Attributes.userID, userID.rawValue)
        let nonNilConversation = NSPredicate(format: "conversation != nil")
        let softDeletePredicate = NSPredicate(
            format: "%K == %@",
            "conversation.\(Conversation.Attributes.isSoftDeleted)",
            NSNumber(false)
        )
        let labelIDPredicate = NSPredicate(format: "%K == %@", ContextLabel.Attributes.labelID, labelID.rawValue)
        var subpredicates = [userIDPredicate, nonNilConversation, softDeletePredicate, labelIDPredicate]
        if isUnread {
            let unreadPredicate = NSPredicate(format: "(%K > 0)", ContextLabel.Attributes.unreadCount)
            subpredicates.append(unreadPredicate)
        }
        return NSCompoundPredicate(andPredicateWithSubpredicates: subpredicates)
    }

    /**
     clean all the local cache data.
     when use this :
     1. logout
     2. local cache version changed
     3. hacked action detacted
     4. use wraped manully.
     */
    func cleanUp() {
        cleanMessage(cleanBadgeAndNotifications: true)
            self.lastUpdatedStore.removeUpdateTime(by: self.userID)
            self.signout()
    }

    func signin() {
        self.queue(.signin)
    }

    private func signout() {
        self.queue(.signout)
    }

    func cleanMessage(removeAllDraft: Bool = true, cleanBadgeAndNotifications: Bool) {
            self.contextProvider.performAndWaitOnRootSavingContext { context in
                self.removeMessageFromDB(context: context, removeAllDraft: removeAllDraft)

                let contextLabelFetch = NSFetchRequest<ContextLabel>(entityName: ContextLabel.Attributes.entityName)
                contextLabelFetch.predicate = NSPredicate(format: "%K == %@ AND %K == %@",
                                                          ContextLabel.Attributes.userID,
                                                          self.userID.rawValue,
                                                          ContextLabel.Attributes.isSoftDeleted,
                                                          NSNumber(false))
                if let labels = try? context.fetch(contextLabelFetch) {
                    labels.forEach { context.delete($0) }
                }

                let conversationFetch = NSFetchRequest<Conversation>(entityName: Conversation.Attributes.entityName)
                conversationFetch.predicate = NSPredicate(format: "%K == %@ AND %K == %@",
                                                          Conversation.Attributes.userID.rawValue,
                                                          self.userID.rawValue,
                                                          Conversation.Attributes.isSoftDeleted.rawValue,
                                                          NSNumber(false))
                if let conversations = try? context.fetch(conversationFetch) {
                    conversations.forEach { context.delete($0) }
                }

                _ = context.saveUpstreamIfNeeded()

                if cleanBadgeAndNotifications {
                    UIApplication.setBadge(badge: 0)
                }
        }
    }

    // Remove message from db
    // In some conditions, some of the messages can't be deleted
    private func removeMessageFromDB(context: NSManagedObjectContext, removeAllDraft: Bool) {
        let fetch = NSFetchRequest<Message>(entityName: Message.Attributes.entityName)
        // Don't delete the soft deleted message
        // Or they would come back when user pull down to refresh
        fetch.predicate = NSPredicate(format: "%K == %@ AND %K == %@",
                                      Message.Attributes.userID,
                                      self.userID.rawValue,
                                      Message.Attributes.isSoftDeleted,
                                      NSNumber(false))

        guard let results = try? context.fetch(fetch) else {
            return
        }

        if removeAllDraft {
            results.forEach { context.delete($0) }
            return
        }
        let draftID = Message.Location.draft.rawValue

        for message in results {
            if let labels = message.labels.allObjects as? [Label] {
                if !labels.contains(where: { $0.labelID == draftID }) {
                    context.delete(message)
                }
            }
        }

        // The remove is triggered by pull down to refresh
        // So if the messages correspond to some conditions, can't delete it
        for message in results {
            if let labels = message.labels.allObjects as? [Label],
               labels.contains(where: { $0.labelID == draftID }) {
                if let attachments = message.attachments.allObjects as? [Attachment],
                   attachments.contains(where: { $0.attachmentID == "0" }) {
                    // If the draft is uploading attachments, don't delete it
                    continue
                } else if isMessageBeingSent(id: message.messageID) {
                    // If the draft is sending, don't delete it
                    continue
                } else if let _ = UUID(uuidString: message.messageID) {
                    // If the message ID is UUiD, means hasn't created draft, don't delete it
                    continue
                }
                context.delete(message)
            }
        }
    }

    func saveDraft(_ message: MessageEntity) throws {
        if message.title.isEmpty {
            try contextProvider.write { context in
                guard let msg = try context.existingObject(with: message.objectID.rawValue) as? Message else { return }
                
                msg.title = "(No Subject)"
                
            }
        }

        try queueMessage(
            with: message.objectID,
            action: .saveDraft(messageObjectID: message.objectID.rawValue.uriRepresentation().absoluteString)
        )
    }

    func deleteDraft(message: MessageEntity) {
        queueManager?.removeAllTasks(of: message.messageID.rawValue, removalCondition: { action in
            switch action {
            case .saveDraft:
                return true
            default:
                return false
            }
        }, completeHandler: { [weak self] in
            self?.delete(messages: [message], label: Message.Location.draft.labelID)
        })
    }

    func fetchMessageMetaData(messageIDs: [MessageID], completion: @escaping (FetchMessagesByIDResponse) -> Void) {
        let messages: [String] = messageIDs.map(\.rawValue)
        let request = FetchMessagesByID(msgIDs: messages)
        self.apiService
            .perform(request: request, response: FetchMessagesByIDResponse()) { _, response in
                completion(response)
            }
    }

    // MARK: old functions

    func getMessageSendingData(for uri: String) -> MessageSendingData? {
        // TODO: Use `CoreDataContextProviderProtocol.read` when available
        var messageSendingData: MessageSendingData?
        contextProvider.performAndWaitOnRootSavingContext { [weak self] context in
            guard let objectID = self?.contextProvider.managedObjectIDForURIRepresentation(uri) else {
                return
            }
            guard let message = context.find(with: objectID) as? Message else {
                return
            }
            let msg = MessageEntity(message)
            messageSendingData = MessageSendingData(
                message: msg,
                cachedUserInfo: message.cachedUser,
                cachedAuthCredential: message.cachedAuthCredential,
                cachedSenderAddress: message.cachedAddress,
                cachedPassphrase: message.cachedPassphrase,
                defaultSenderAddress: self?.defaultUserAddress(of: msg.addressID)
            )
        }
        return messageSendingData
    }

    func deleteMessage(objectID: String) {
        contextProvider.performAndWaitOnRootSavingContext { [weak self] context in
            guard let objectID = self?.contextProvider.managedObjectIDForURIRepresentation(objectID),
                  let message = context.find(with: objectID) as? Message else {
                return
            }
            context.delete(message)
            _ = context.saveUpstreamIfNeeded()
        }
    }

    func getMessage(for messageID: MessageID) throws -> Message {
        try contextProvider.performAndWaitOnRootSavingContext { _ in
            let fetchRequest = NSFetchRequest<Message>(entityName: Message.Attributes.entityName)
            fetchRequest.predicate = NSPredicate(format: "%K == %@", Message.Attributes.messageID, messageID.rawValue)
            fetchRequest.sortDescriptors = [
                NSSortDescriptor(key: Message.Attributes.time, ascending: false),
                NSSortDescriptor(key: #keyPath(Message.order), ascending: false)
            ]
            let messages = try fetchRequest.execute()
            guard let first = messages.first else {
                throw MessageDataServiceError.messageNotFoundForMessageID(messageID)
            }
            return first
        }
    }

    func getMessageEntity(for messageID: MessageID) throws -> MessageEntity {
        let message = try getMessage(for: messageID)
        return try contextProvider.performAndWaitOnRootSavingContext { _ in
            return MessageEntity(message)
        }
    }

    func getAttachmentEntity(for uri: String) throws -> AttachmentEntity? {
        try contextProvider.performAndWaitOnRootSavingContext { [weak self] context in
            guard let objectID = self?.contextProvider.managedObjectIDForURIRepresentation(uri),
                  let attachment = context.find(with: objectID) as? Attachment else {
                return nil
            }
            return AttachmentEntity(attachment)
        }
    }

    func removeAttachmentFromDB(objectIDs: [ObjectID]) {
        contextProvider.performOnRootSavingContext { context in
            for objectID in objectIDs {
                guard let attachment = context.find(with: objectID.rawValue) as? Attachment else { continue }
                context.delete(attachment)
            }
            _ = context.saveUpstreamIfNeeded()
        }
    }

    func updateAttachment(by uploadResponse: UploadAttachment.UploadingResponse, attachmentObjectID: ObjectID) {
        guard
            let attachmentDict = uploadResponse.response["Attachment"] as? [String: Any],
            let id = attachmentDict["ID"] as? String
        else {
            return
        }
        contextProvider.performAndWaitOnRootSavingContext { context in
            guard let attachment = context.find(with: attachmentObjectID.rawValue) as? Attachment else {
                // User could log out
                return
            }
            attachment.attachmentID = id
            attachment.keyPacket = uploadResponse.keyPacket
                .base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
            attachment.fileData = nil // encrypted attachment is successfully uploaded -> no longer need it cleartext

            // proper headers from BE - important for inline attachments
            if let headerInfoDict = attachmentDict["Headers"] as? Dictionary<String, String> {
                attachment.headerInfo = "{" + headerInfoDict.compactMap { " \"\($0)\":\"\($1)\" " }.joined(separator: ",") + "}"
            }
            attachment.cleanLocalURLs()

            _ = context.saveUpstreamIfNeeded()
            NotificationCenter
                .default
                .post(
                    name: .attachmentUploaded,
                    object: nil,
                    userInfo: [
                        "objectID": attachment.objectID.uriRepresentation().absoluteString,
                        "attachmentID": attachment.attachmentID
                    ]
                )
        }
    }

    func updateMessageAfterSend(
        message: MessageEntity,
        sendResponse: JSONDictionary,
        completionQueue: DispatchQueue,
        completion: @escaping () -> Void
    ) {
        contextProvider.performOnRootSavingContext { [unowned self] context in
            if let newMessage = try? GRTJSONSerialization.object(
                withEntityName: Message.Attributes.entityName,
                fromJSONDictionary: sendResponse["Sent"] as! [String: Any],
                in: context
            ) as? Message {
                newMessage.messageStatus = 1
                newMessage.isDetailDownloaded = true
                newMessage.unRead = false
            } else {
                assertionFailure("Failed to parse response Message")
            }
            if context.saveUpstreamIfNeeded() == nil {
                _ = markReplyStatus(message.originalMessageID, action: message.action)
            }
            completionQueue.async {
                completion()
            }
        }
    }

    func cancelQueuedSendingTask(messageID: MessageID) {
        self.queueManager?.removeAllTasks(of: messageID.rawValue, removalCondition: { action in
            switch action {
            case .send:
                return true
            default:
                return false
            }
        }, completeHandler: { [weak self] in
            self?.localNotificationService
                .unscheduleMessageSendingFailedNotification(.init(messageID: messageID))
        })
    }

    private func markReplyStatus(_ oriMsgID: MessageID?, action : NSNumber?) -> Promise<Void> {
        guard let originMessageID = oriMsgID,
              let act = action,
              !originMessageID.rawValue.isEmpty else {
            return Promise()
        }

        let fetchRequest = NSFetchRequest<Message>(entityName: Message.Attributes.entityName)
        fetchRequest.predicate = NSPredicate(format: "%K == %@", Message.Attributes.messageID, originMessageID.rawValue)
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: Message.Attributes.time, ascending: false),
            NSSortDescriptor(key: #keyPath(Message.order), ascending: false)
        ]

        return Promise { seal in
            self.contextProvider.performOnRootSavingContext { context in
                do {
                    guard let msgToUpdate = try fetchRequest.execute().first else {
                        seal.fulfill_()
                        return
                    }

                    // {0|1|2} // Optional, reply = 0, reply all = 1, forward = 2
                    if act == 0 {
                        msgToUpdate.replied = true
                    } else if act == 1 {
                        msgToUpdate.repliedAll = true
                    } else if act == 2 {
                        msgToUpdate.forwarded = true
                    } else {
                        // ignore
                    }

                    if let error = context.saveUpstreamIfNeeded(){
                        throw error
                    }

                    seal.fulfill_()
                } catch {
                    seal.reject(error)
                }
            }
        }
    }

    // MARK: Notifications

    private func setupNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(MessageDataService.didSignOutNotification),
                                               name: .didSignOutLastAccount,
                                               object: nil)
        // TODO: add monitoring for didBecomeActive
    }

    @objc fileprivate func didSignOutNotification() {
        cleanUp()
    }

    private func queueMessage(with messageObjectID: ObjectID, action: MessageAction) throws {
        let messageID: String = try contextProvider.write { context in
            guard let message = try context.existingObject(with: messageObjectID.rawValue) as? Message else {
                SystemLogger.log(message: "No Message with ID \(messageObjectID.rawValue)", category: .queue)
                return ""
            }
            
            if message.objectID.isTemporaryID {
                do {
                    try context.obtainPermanentIDs(for: [message])
                } catch {
                    assertionFailure("\(error)")
                }
            }
            self.cachePropertiesForBackground(in: message)
            return message.messageID
        }
        
        let task = QueueManager.Task(messageID: messageID, action: action, userID: userID, dependencyIDs: [], isConversation: false)

        queueManager!.addTask(task)
    }

    func queue(_ action: MessageAction) {
        let task = QueueManager.Task(messageID: "", action: action, userID: self.userID, dependencyIDs: [], isConversation: false)
        self.queueManager?.addTask(task)
    }

    private func queue(att: Attachment, action: MessageAction) {
        if att.objectID.isTemporaryID {
            att.managedObjectContext?.performAndWait {
                try? att.managedObjectContext?.obtainPermanentIDs(for: [att])
            }
        }
        att.managedObjectContext?.performAndWait {
            self.cachePropertiesForBackground(in: att.message)
        }
        let updatedID = att.objectID.uriRepresentation().absoluteString
        var updatedAction: MessageAction?
        switch action {
        case .uploadAtt:
            updatedAction = .uploadAtt(attachmentObjectID: updatedID)
        case .uploadPubkey:
            updatedAction = .uploadPubkey(attachmentObjectID: updatedID)
        case .deleteAtt:
            updatedAction = .deleteAtt(attachmentObjectID: updatedID,
                                       attachmentID: att.attachmentID)
        default:
            break
        }
        let task = QueueManager.Task(messageID: att.message.messageID, action: updatedAction ?? action, userID: self.userID, dependencyIDs: [], isConversation: false)
        self.queueManager?.addTask(task)
    }

    func encryptBody(_ addressID: AddressID,
                     clearBody: String,
                     mailbox_pwd: Passphrase) throws -> String {
        // TODO: Refactor this method later.
        let addressId = addressID.rawValue
        if addressId.isEmpty {
            return .empty
        }

        if let key = self.userDataSource?.userInfo.getAddressKey(address_id: addressId) {
            return try clearBody.encrypt(withKey: key,
                                         userKeys: self.userDataSource!.userInfo.userPrivateKeys,
                                         mailboxPassphrase: mailbox_pwd)
        } else { // fallback
            let key = self.userDataSource!.userInfo.getAddressPrivKey(address_id: addressId)
            return try clearBody.encryptNonOptional(withPrivKey: key, mailbox_pwd: mailbox_pwd.value)
        }
    }

    func defaultUserAddress(of addressID: AddressID) -> Address? {
        guard let userInfo = userDataSource?.userInfo else {
            return nil
        }
        if !addressID.rawValue.isEmpty {
            if let addr = userInfo.userAddresses.address(byID: addressID.rawValue),
               addr.send == .active {
                return addr
            } else {
                if let addr = userInfo.userAddresses.defaultSendAddress() {
                    return addr
                }
            }
        } else {
            if let addr = userInfo.userAddresses.defaultSendAddress() {
                return addr
            }
        }
        return nil
    }

    func userAddress(of addressID: AddressID) -> Address? {
        guard let userInfo = userDataSource?.userInfo else {
            return nil
        }
        return userInfo.userAddresses.address(byID: addressID.rawValue)
    }

    func messageWithLocation(recipientList: String,
                             bccList: String,
                             ccList: String,
                             title: String,
                             encryptionPassword: String,
                             passwordHint: String,
                             expirationTimeInterval: TimeInterval,
                             body: String,
                             attachments: [Any]?,
                             mailbox_pwd: Passphrase,
                             sendAddress: Address,
                             inManagedObjectContext context: NSManagedObjectContext) -> Message {
        let message = Message(context: context)
        message.messageID = MessageID.generateLocalID().rawValue
        message.toList = recipientList
        message.bccList = bccList
        message.ccList = ccList
        message.title = title
        message.passwordHint = passwordHint
        message.time = Date()
        message.expirationOffset = Int32(expirationTimeInterval)
        message.messageStatus = 1
        message.setAsDraft()
        message.userID = self.userID.rawValue
        message.addressID = sendAddress.addressID

        if expirationTimeInterval > 0 {
            message.expirationTime = Date(timeIntervalSinceNow: expirationTimeInterval)
        }

        do {
            message.body = try self.encryptBody(.init(message.addressID ?? ""), clearBody: body, mailbox_pwd: mailbox_pwd)
            if !encryptionPassword.isEmpty {
                message.passwordEncryptedBody = try body.encryptNonOptional(password: encryptionPassword)
            }
            if let attachments = attachments {
                for (index, attachment) in attachments.enumerated() {
                    if let image = attachment as? UIImage {
                        if let fileData = image.pngData() {
                            let attachment = Attachment(context: context)
                            attachment.attachmentID = "0"
                            attachment.message = message
                            attachment.fileName = "\(index).png"
                            attachment.mimeType = "image/png"
                            attachment.fileData = fileData
                            attachment.fileSize = fileData.count as NSNumber
                            continue
                        }
                    }
                }
            }
        } catch {}
        return message
    }

    func updateMessage(_ message: Message,
                       expirationTimeInterval: TimeInterval,
                       body: String,
                       mailbox_pwd: Passphrase) {
        if expirationTimeInterval > 0 {
            message.expirationTime = Date(timeIntervalSinceNow: expirationTimeInterval)
        }
        message.body = (try? self.encryptBody(.init(message.addressID ?? ""), clearBody: body, mailbox_pwd: mailbox_pwd)) ?? ""
    }

    func undoSend(
        of messageId: MessageID,
        completion: @escaping (Swift.Result<UndoSendResponse, ResponseError>) -> Void
    ) {
        let request = UndoSendRequest(messageID: messageId)
        apiService.perform(request: request) { task, result in
            completion(result)
        }
    }
}

extension MessageDataService {
    struct Dependencies {
        let moveMessageInCacheUseCase: MoveMessageInCacheUseCase
        let pushUpdater: PushUpdater
    }
}

enum MessageDataServiceError: LocalizedError {
    case messageNotFoundForMessageID(MessageID)

    var errorDescription: String? {
        switch self {
        case .messageNotFoundForMessageID(let messageID):
            return "Message not found for MessageID \(messageID.rawValue)"
        }
    }
}
