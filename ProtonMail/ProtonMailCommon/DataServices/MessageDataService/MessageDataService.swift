//
//  MessageDataService.swift
//  ProtonMail
//
//
//  Copyright (c) 2019 Proton Technologies AG
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
import Groot
import PromiseKit
import ProtonCore_DataModel
import ProtonCore_Networking
import ProtonCore_Services

/// Message data service
class MessageDataService: Service, HasLocalStorage, MessageDataProcessProtocol, MessageProvider {

    /// Message fetch details
    internal typealias CompletionFetchDetail = (_ task: URLSessionDataTask?,
                                                _ response: [String: Any]?,
                                                _ message: Message.ObjectIDContainer?,
                                                _ error: NSError?) -> Void

    typealias ReadBlock = (() -> Void)

    // TODO:: those 3 var need to double check to clean up
    var pushNotificationMessageID: String?

    let apiService: APIService
    let userID: String
    weak var userDataSource: UserDataSource?
    let labelDataService: LabelsDataService
    let contactDataService: ContactDataService
    let localNotificationService: LocalNotificationService
    let contextProvider: CoreDataContextProviderProtocol
    let lastUpdatedStore: LastUpdatedStoreProtocol
    let cacheService: CacheService
    let messageDecrypter: MessageDecrypterProtocol

    weak var viewModeDataSource: ViewModeDataSource?

    weak var queueManager: QueueManager?
    weak var parent: UserManager?

    init(api: APIService, userID: String, labelDataService: LabelsDataService, contactDataService: ContactDataService, localNotificationService: LocalNotificationService, queueManager: QueueManager?, contextProvider: CoreDataContextProviderProtocol, lastUpdatedStore: LastUpdatedStoreProtocol, user: UserManager, cacheService: CacheService) {
        self.apiService = api
        self.userID = userID
        self.labelDataService = labelDataService
        self.contactDataService = contactDataService
        self.localNotificationService = localNotificationService
        self.contextProvider = contextProvider
        self.lastUpdatedStore = lastUpdatedStore
        self.parent = user
        self.cacheService = cacheService
        self.messageDecrypter = MessageDecrypter(userDataSource: user)

        setupNotifications()
        self.queueManager = queueManager
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
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

    func fetchMessages(byLabel labelID: String, time: Int, forceClean: Bool, isUnread: Bool, queued: Bool = true, completion: CompletionBlock?, onDownload: (() -> Void)? = nil) {
        let queue = queued ? queueManager?.queue : noQueue
        queue? {
            let completionWrapper: CompletionBlock = { task, responseDict, error in
                if error != nil {
                    DispatchQueue.main.async {
                        completion?(task, responseDict, error)
                    }
                } else if let response = responseDict {
                    onDownload?()
                    self.cacheService.parseMessagesResponse(labelID: labelID, isUnread: isUnread, response: response) { (errorFromParsing) in
                        if let err = errorFromParsing {
                            DispatchQueue.main.async {
                                completion?(task, responseDict, err as NSError)
                            }
                        } else {
                            let counterRoute = MessageCount()
                            self.apiService.exec(route: counterRoute, responseObject: MessageCountResponse()) { response in
                                if response.error == nil {
                                    self.parent?.eventsService.processEvents(counts: response.counts)
                                }
                            }
                            DispatchQueue.main.async {
                                completion?(task, responseDict, errorFromParsing as NSError?)
                            }
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        completion?(task, responseDict, NSError.unableToParseResponse(responseDict))
                    }
                }
            }
            let request = FetchMessagesByLabel(labelID: labelID, endTime: time, isUnread: isUnread)
            self.apiService.GET(request, completion: completionWrapper)
        }
    }

    /// fetching the message from server based on label and time also reset the events status //TODO:: change to promise
    ///
    /// - Parameters:
    ///   - labelID: labelid, location id, forlder id
    ///   - time: the latest update time
    ///   - cleanContact: Clean contact data or not
    ///   - removeAllDraft: Remove all draft or not, including sending draft...etc
    ///   - completion: async complete handler
    func fetchMessagesWithReset(byLabel labelID: String,
                                time: Int,
                                cleanContact: Bool = true,
                                removeAllDraft: Bool = false,
                                queued: Bool = true,
                                unreadOnly: Bool = false,
                                completion: CompletionBlock?) {
        let queue = queued ? queueManager?.queue : noQueue
        queue? {
            let getLatestEventID = EventLatestIDRequest()
            self.apiService.exec(route: getLatestEventID, responseObject: EventLatestIDResponse()) { [weak self] (task, IDRes) in
                guard !IDRes.eventID.isEmpty,
                      let self = self else {
                    completion?(task, nil, nil)
                    return
                }

                let completionWrapper: CompletionBlock = { task, responseDict, error in
                    guard error == nil else {
                        DispatchQueue.main.async {
                            completion?(task, responseDict, error)
                        }
                        return
                    }
                    self.lastUpdatedStore.clear()
                    _ = self.lastUpdatedStore.updateEventID(by: self.userID, eventID: IDRes.eventID).ensure {
                        completion?(task, responseDict, error)
                    }
                }

                self.fetchMessages(byLabel: labelID, time: time, forceClean: false, isUnread: unreadOnly, queued: queued, completion: completionWrapper) {
                    self.cleanMessage(removeAllDraft: removeAllDraft, cleanBadgeAndNotifications: false).then { (_) -> Promise<Void> in
                        self.lastUpdatedStore.removeUpdateTimeExceptUnread(by: self.userID, type: .singleMessage)
                        self.lastUpdatedStore.removeUpdateTimeExceptUnread(by: self.userID, type: .conversation)
                        if cleanContact {
                            return self.contactDataService.cleanUp()
                        } else {
                            return Promise<Void>()
                        }
                    }.ensure {
                        if cleanContact {
                            self.contactDataService.fetchContacts(completion: nil)
                        }
                        self.labelDataService.fetchV4Labels().cauterize()

                    }.cauterize()
                }
            }
        }
    }

    func isEventIDValid(context: NSManagedObjectContext) -> Bool {
        let eventID = lastUpdatedStore.lastEventID(userID: self.userID)
        return eventID != "" && eventID != "0"
    }

    /// Sync mail setting when user in composer
    /// workaround
    func syncMailSetting(labelID: String = "0") {
        self.queueManager?.queue {
            let eventAPI = EventCheckRequest(eventID: self.lastUpdatedStore.lastEventID(userID: self.userID))
            self.apiService.exec(route: eventAPI, responseObject: EventCheckResponse()) { response in
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
    func upload( att: Attachment) {
        self.queue(att, action: .uploadAtt(attachmentObjectID: att.objectID.uriRepresentation().absoluteString))
    }

    /// upload attachment to server
    ///
    /// - Parameter att: Attachment
    func upload( pubKey: Attachment) {
        self.queue(pubKey, action: .uploadPubkey(attachmentObjectID: pubKey.objectID.uriRepresentation().absoluteString))
    }

    /// delete attachment from server
    ///
    /// - Parameter att: Attachment
    func delete(att: Attachment!) -> Promise<Void> {
        return Promise { seal in
            let context = att.managedObjectContext
            if att.objectID.isTemporaryID {
                context?.performAndWait {
                    try? context?.obtainPermanentIDs(for: [att])
                }
            }

            let objectID = att.objectID.uriRepresentation().absoluteString
            let task = QueueManager.Task(messageID: att.message.messageID, action: .deleteAtt(attachmentObjectID: objectID), userID: self.userID, dependencyIDs: [], isConversation: false)
            _ = self.queueManager?.addTask(task)
            self.cacheService.delete(attachment: att) {
                seal.fulfill_()
            }
        }
    }

    func updateAttKeyPacket(message: Message, addressID: String) {
        let objectID = message.objectID.uriRepresentation().absoluteString
        self.queue(.updateAttKeyPacket(messageObjectID: objectID, addressID: addressID), isConversation: false)
    }

    typealias base64AttachmentDataComplete = (_ based64String: String) -> Void
    func base64AttachmentData(att: Attachment, _ complete : @escaping base64AttachmentDataComplete) {
        guard let user = self.userDataSource else {
            complete("")
            return
        }
        let context = self.contextProvider.mainContext
        context.perform {
            if let localURL = att.localURL, FileManager.default.fileExists(atPath: localURL.path, isDirectory: nil) {
                complete( att.base64DecryptAttachment(userInfo: user.userInfo, passphrase: user.mailboxPassword) )
                return
            }

            if let data = att.fileData, data.count > 0 {
                complete( att.base64DecryptAttachment(userInfo: user.userInfo, passphrase: user.mailboxPassword) )
                return
            }

            att.localURL = nil
            self.fetchAttachmentForAttachment(att, downloadTask: { (taskOne: URLSessionDownloadTask) -> Void in }, completion: { [weak self] (_, url, error) -> Void in
                guard let self = self else {
                    complete("")
                    return
                }
                self.contextProvider.mainContext.perform {
                    guard let attachment = try? context.existingObject(with: att.objectID) as? Attachment else {
                        complete("")
                        return
                    }
                    if attachment.localURL == nil {
                        attachment.localURL = url
                    }
                    complete( attachment.base64DecryptAttachment(userInfo: user.userInfo, passphrase: user.mailboxPassword) )
                }
            })
        }
    }

    // MARK: Send message
    func send(inQueue message: Message!, completion: CompletionBlock?) {
        self.localNotificationService.scheduleMessageSendingFailedNotification(.init(messageID: message.messageID, subtitle: message.title))
        message.managedObjectContext?.performAndWait {
            message.isSending = true
            _ = message.managedObjectContext?.saveUpstreamIfNeeded()
        }
        self.queue(message, action: .send(messageObjectID: message.objectID.uriRepresentation().absoluteString))
        DispatchQueue.main.async {
            completion?(nil, nil, nil)
        }
    }

    func updateMessageCount(completion: (() -> Void)? = nil) {
        self.queueManager?.queue {
            guard let viewMode = self.viewModeDataSource?.getCurrentViewMode() else {
                completion?()
                return
            }

            switch viewMode {
            case .singleMessage:
                let counterApi = MessageCount()
                self.apiService.exec(route: counterApi, responseObject: MessageCountResponse()) { (task, response) in
                    guard response.error == nil else {
                        completion?()
                        return
                    }
                    self.parent?.eventsService.processEvents(counts: response.counts)
                    completion?()
                }
            case .conversation:
                let conversationCountApi = ConversationCountRequest(addressID: nil)
                self.apiService.exec(route: conversationCountApi, responseObject: ConversationCountResponse()) { (task, response) in
                    guard response.error == nil else {
                        completion?()
                        return
                    }
                    let countDict = response.responseDict?["Counts"] as? [[String: Any]]
                    self.parent?.eventsService.processEvents(conversationCounts: countDict)
                    completion?()
                }
            }

        }
    }

    /// TODO::fixme - double check it  // this way is a little bit hacky. future we will prebuild the send message body
    func injectTransientValuesIntoMessages() {
        let ids = queueManager?.queuedMessageIds() ?? []
        let context = self.contextProvider.rootSavingContext
        context.perform {
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
        message.cachedPassphrase = userDataSource!.mailboxPassword
        message.cachedAuthCredential = userDataSource!.authCredential
        message.cachedUser = userDataSource!.userInfo
        message.cachedAddress = defaultAddress(message) // computed property depending on current user settings
    }

    func empty(location: Message.Location) {
        self.empty(labelID: location.rawValue)
    }

    func empty(labelID: String) {
        self.cacheService.markMessageAndConversationDeleted(labelID: labelID)
        self.labelDataService.resetCounter(labelID: labelID)
        queue(.empty(currentLabelID: labelID), isConversation: false)
    }
    /// fetch message meta data with message obj
    ///
    /// - Parameter messages: Message
    private func fetchMetadata(with messageIDs: [String]) {
        guard !messageIDs.isEmpty else {
            return
        }
        self.queueManager?.queue {
            let completionWrapper: CompletionBlock = { task, responseDict, error in
                if var messagesArray = responseDict?["Messages"] as? [[String: Any]] {
                    for (index, _) in messagesArray.enumerated() {
                        messagesArray[index]["UserID"] = self.userID
                    }
                    let context = self.contextProvider.rootSavingContext
                    context.perform {
                        do {
                            if let messages = try GRTJSONSerialization.objects(withEntityName: Message.Attributes.entityName, fromJSONArray: messagesArray, in: context) as? [Message] {
                                for message in messages {
                                    message.messageStatus = 1
                                }
                                _ = context.saveUpstreamIfNeeded()
                            }
                        } catch {
                        }
                    }
                }
            }

            let request = FetchMessagesByID(msgIDs: messageIDs)
            self.apiService.GET(request, completion: completionWrapper)
        }
    }

    // old functions
    var isFirstTimeSaveAttData: Bool = false

    /// downloadTask returns the download task for use with UIProgressView+AFNetworking
    func fetchAttachmentForAttachment(_ attachment: Attachment,
                                      customAuthCredential: AuthCredential? = nil,
                                      downloadTask: ((URLSessionDownloadTask) -> Void)?,
                                      completion: ((URLResponse?, URL?, NSError?) -> Void)?) {
        if attachment.downloaded, let localURL = attachment.localURL {
            completion?(nil, localURL as URL, nil)
            return
        }

        // TODO: check for existing download tasks and return that task rather than start a new download
        if attachment.managedObjectContext != nil {
            self.apiService.downloadAttachment(byID: attachment.attachmentID,
                                               destinationDirectoryURL: FileManager.default.attachmentDirectory,
                                               customAuthCredential: customAuthCredential,
                                               downloadTask: downloadTask,
                                               completion: { task, fileURL, error in
                let context = self.contextProvider.rootSavingContext
                context.perform {
                    if let fileURL = fileURL, let attachmentToUpdate = try? context.existingObject(with: attachment.objectID) as? Attachment {
                        attachmentToUpdate.localURL = fileURL
                        if #available(iOS 12, *) {
                            if !self.isFirstTimeSaveAttData {
                                attachmentToUpdate.fileData = try? Data(contentsOf: fileURL)
                            }
                        } else {
                            attachmentToUpdate.fileData = try? Data(contentsOf: fileURL)
                        }
                        _ = context.saveUpstreamIfNeeded()
                    }
                    completion?(task, fileURL, error)
                }
            })
        } else {
            completion?(nil, nil, nil)
        }
    }

    private func noQueue(_ readBlock: @escaping ReadBlock) {
        readBlock()
    }

    func ForcefetchDetailForMessage(_ message: Message, runInQueue: Bool = true, completion: @escaping CompletionFetchDetail) {
        let msgID = message.messageID
        let closure = runInQueue ? self.queueManager?.queue: noQueue
        closure? {
            let completionWrapper: CompletionBlock = { task, response, error in
                let objectId = message.objectID
                let context = self.contextProvider.rootSavingContext
                context.perform {
                    var error: NSError?
                    if let newMessage = context.object(with: objectId) as? Message, response != nil {
                        // TODO need check the respons code
                        if var msg: [String: Any] = response?["Message"] as? [String: Any] {
                            msg.removeValue(forKey: "Location")
                            msg.removeValue(forKey: "Starred")
                            msg.removeValue(forKey: "test")
                            msg["UserID"] = self.userID

                            do {
                                if newMessage.isDetailDownloaded, let time = msg["Time"] as? TimeInterval, let oldtime = newMessage.time?.timeIntervalSince1970 {
                                    // remote time and local time are not empty
                                    if oldtime > time {
                                        DispatchQueue.main.async {
                                            completion(task, response, Message.ObjectIDContainer(newMessage), error)
                                        }
                                        return
                                    }
                                }
                                let realAttachments = userCachedStatus.realAttachments
                                let localAttachments = newMessage.attachments.allObjects.compactMap { $0 as? Attachment}.filter { attach in
                                    if attach.isSoftDeleted {
                                        return false
                                    } else if realAttachments {
                                        return !attach.inline()
                                    }
                                    return true
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
                                if let labelID = newMessage.firstValidFolder() {
                                    self.mark(messages: [newMessage], labelID: labelID, unRead: false)
                                }
                                if newMessage.unRead {
                                    self.cacheService.updateCounterSync(markUnRead: false, on: newMessage, context: context)
                                }
                                newMessage.unRead = false
                                PushUpdater().remove(notificationIdentifiers: [newMessage.notificationId])
                                error = context.saveUpstreamIfNeeded()
                                DispatchQueue.main.async {
                                    completion(task, response, Message.ObjectIDContainer(newMessage), error)
                                }
                            } catch let ex as NSError {
                                DispatchQueue.main.async {
                                    completion(task, response, Message.ObjectIDContainer(newMessage), ex)
                                }
                            }
                        } else {
                            DispatchQueue.main.async {
                                completion(task, response, Message.ObjectIDContainer(newMessage), NSError.badResponse())
                            }
                        }
                    } else {
                        error = NSError.unableToParseResponse(response)
                        DispatchQueue.main.async {
                            completion(task, response, Message.ObjectIDContainer(message), error)
                        }
                    }
                }
            }
            self.apiService.messageDetail(messageID: msgID, completion: completionWrapper)
        }
    }

    func fetchMessageDetailForMessage(_ message: Message, labelID: String, runInQueue: Bool = true, completion: @escaping CompletionFetchDetail) {
        if !message.isDetailDownloaded {
            let msgID = message.messageID
            let closure = runInQueue ? queueManager?.queue: noQueue
            closure? {
                let completionWrapper: CompletionBlock = { task, response, error in
                    let context = self.contextProvider.rootSavingContext
                    context.perform {
                        if response != nil {
                            if var msg: [String: Any] = response?["Message"] as? [String: Any] {
                                msg.removeValue(forKey: "Location")
                                msg.removeValue(forKey: "Starred")
                                msg.removeValue(forKey: "test")
                                msg["UserID"] = self.userID
                                do {
                                    if let message_n = try GRTJSONSerialization.object(withEntityName: Message.Attributes.entityName, fromJSONDictionary: msg, in: context) as? Message {
                                        message_n.messageStatus = 1
                                        message_n.isDetailDownloaded = true

                                        let tmpError = context.saveUpstreamIfNeeded()
                                        DispatchQueue.main.async {
                                            completion(task, response, Message.ObjectIDContainer(message_n), tmpError)
                                        }
                                    } else {
                                        DispatchQueue.main.async {
                                            completion(task, response, nil, error)
                                        }
                                    }
                                } catch let ex as NSError {
                                    DispatchQueue.main.async {
                                        completion(task, response, nil, ex)
                                    }
                                }
                            } else {
                                DispatchQueue.main.async {
                                    completion(task, response, nil, error)
                                }

                            }
                        } else {
                            DispatchQueue.main.async {
                                completion(task, response, nil, error)
                            }
                        }
                    }
                }
                self.apiService.messageDetail(messageID: msgID, completion: completionWrapper)
            }
        } else {
            self.mark(messages: [message], labelID: labelID, unRead: false)
            DispatchQueue.main.async {
                completion(nil, nil, Message.ObjectIDContainer(message), nil)
            }
        }
    }

    func fetchNotificationMessageDetail(_ messageID: String, completion: @escaping CompletionFetchDetail) {
        self.queueManager?.queue {
            let completionWrapper: CompletionBlock = { task, response, error in
                let context = self.contextProvider.rootSavingContext
                context.perform {
                    if response != nil {
                        // TODO need check the respons code
                        if var msg: [String: Any] = response?["Message"] as? [String: Any] {
                            msg.removeValue(forKey: "Location")
                            msg.removeValue(forKey: "Starred")
                            msg.removeValue(forKey: "test")
                            msg["UserID"] = self.userID
                            do {
                                if let messageOut = try GRTJSONSerialization.object(withEntityName: Message.Attributes.entityName, fromJSONDictionary: msg, in: context) as? Message {
                                    messageOut.messageStatus = 1
                                    messageOut.isDetailDownloaded = true
                                    if let labelID = messageOut.firstValidFolder() {
                                        self.mark(messages: [messageOut], labelID: labelID, unRead: false)
                                    }
                                    if messageOut.unRead == true {
                                        messageOut.unRead = false
                                        PushUpdater().remove(notificationIdentifiers: [messageOut.notificationId])
                                        self.cacheService.updateCounterSync(markUnRead: false, on: messageOut, context: context)
                                    }
                                    let tmpError = context.saveUpstreamIfNeeded()

                                    DispatchQueue.main.async {
                                        completion(task, response, Message.ObjectIDContainer(messageOut), tmpError)
                                    }
                                }
                            } catch let ex as NSError {
                                DispatchQueue.main.async {
                                    completion(task, response, nil, ex)
                                }
                            }
                        } else {
                            DispatchQueue.main.async {
                                completion(task, response, nil, NSError.badResponse())
                            }
                        }
                    } else {
                        DispatchQueue.main.async {
                            completion(task, response, nil, error)
                        }
                    }
                }
            }

            let context = self.contextProvider.rootSavingContext
            context.perform {
                if let message = Message.messageForMessageID(messageID, inManagedObjectContext: context) {
                    if message.isDetailDownloaded {
                        DispatchQueue.main.async {
                            completion(nil, nil, Message.ObjectIDContainer(message), nil)
                        }
                    } else {
                        self.apiService.messageDetail(messageID: messageID, completion: completionWrapper)
                    }
                } else {
                    self.apiService.messageDetail(messageID: messageID, completion: completionWrapper)
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
    func fetchedResults(by labelID: String, viewMode: ViewMode, isUnread: Bool = false) -> NSFetchedResultsController<NSFetchRequestResult>? {
        switch viewMode {
        case .singleMessage:
            let moc = self.contextProvider.mainContext
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: Message.Attributes.entityName)
            if isUnread {
                fetchRequest.predicate = NSPredicate(format: "(ANY labels.labelID = %@) AND (%K > %d) AND (%K == %@) AND (%K == %@) AND (%K == %@)",
                                                     labelID,
                                                     Message.Attributes.messageStatus,
                                                     0,
                                                     Message.Attributes.userID,
                                                     self.userID,
                                                     Message.Attributes.unRead,
                                                     NSNumber(true),
                                                     Message.Attributes.isSoftDeleted,
                                                     NSNumber(false))
            } else {
                fetchRequest.predicate = NSPredicate(format: "(ANY labels.labelID = %@) AND (%K > %d) AND (%K == %@) AND (%K == %@)",
                                                     labelID,
                                                     Message.Attributes.messageStatus,
                                                     0,
                                                     Message.Attributes.userID,
                                                     self.userID,
                                                     Message.Attributes.isSoftDeleted,
                                                     NSNumber(false))
            }
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(Message.time), ascending: false), NSSortDescriptor(key: #keyPath(Message.order), ascending: false)]
            fetchRequest.fetchBatchSize = 30
            fetchRequest.includesPropertyValues = true
            return NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: moc, sectionNameKeyPath: nil, cacheName: nil)
        case .conversation:
            let moc = self.contextProvider.mainContext
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: ContextLabel.Attributes.entityName)
            if isUnread {
                fetchRequest.predicate = NSPredicate(format: "(%K == %@) AND (%K == %@) AND (conversation != nil) AND (%K > 0) AND (%K == %@)",
                                                     ContextLabel.Attributes.labelID,
                                                     labelID,
                                                     ContextLabel.Attributes.userID,
                                                     self.userID,
                                                     ContextLabel.Attributes.unreadCount,
                                                     ContextLabel.Attributes.isSoftDeleted,
                                                     NSNumber(false))
            } else {
                fetchRequest.predicate = NSPredicate(format: "(%K == %@) AND (%K == %@) AND (conversation != nil) AND (%K == %@)",
                                                     ContextLabel.Attributes.labelID,
                                                     labelID,
                                                     ContextLabel.Attributes.userID,
                                                     self.userID,
                                                     ContextLabel.Attributes.isSoftDeleted,
                                                     NSNumber(false))
            }
            fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \ContextLabel.time, ascending: false), NSSortDescriptor(keyPath: \ContextLabel.order, ascending: false)]
            fetchRequest.fetchBatchSize = 30
            fetchRequest.includesPropertyValues = true
            return NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: moc, sectionNameKeyPath: nil, cacheName: nil)
        }
    }

    /**
     fetch the message from local cache use message id
     
     :param: messageID String
     
     :returns: NSFetchedResultsController
     */
    func fetchedMessageControllerForID(_ messageID: String) -> NSFetchedResultsController<NSFetchRequestResult>? {
        let moc = self.contextProvider.mainContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: Message.Attributes.entityName)
        fetchRequest.predicate = NSPredicate(format: "%K == %@", Message.Attributes.messageID, messageID)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: Message.Attributes.time, ascending: false), NSSortDescriptor(key: #keyPath(Message.order), ascending: false)]
        return NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: moc, sectionNameKeyPath: nil, cacheName: nil)
    }

    /**
     clean all the local cache data.
     when use this :
     1. logout
     2. local cache version changed
     3. hacked action detacted
     4. use wraped manully.
     */
    func cleanUp() -> Promise<Void> {
        return self.cleanMessage(cleanBadgeAndNotifications: true).done { (_) in
            self.lastUpdatedStore.clear()
            self.lastUpdatedStore.removeUpdateTime(by: self.userID, type: .singleMessage)
            self.lastUpdatedStore.removeUpdateTime(by: self.userID, type: .conversation)
            self.signout()
        }
    }

    func signin() {
        self.queue(.signin, isConversation: false)
    }

    private func signout() {
        self.queue(.signout, isConversation: false)
    }

    static func cleanUpAll() -> Promise<Void> {
        return Promise { seal in
            let queueManager = sharedServices.get(by: QueueManager.self)
            queueManager.clearAll {
                let coreDateService = sharedServices.get(by: CoreDataService.self)
                let context = coreDateService.operationContext
                coreDateService.enqueue(context: context) { (context) in
                    Message.deleteAll(inContext: context)
                    Conversation.deleteAll(inContext: context)
                    _ = context.saveUpstreamIfNeeded()
                    seal.fulfill_()
                }
            }
        }
    }

    func cleanMessage(removeAllDraft: Bool = true, cleanBadgeAndNotifications: Bool) -> Promise<Void> {
        return Promise { seal in
            let context = self.contextProvider.rootSavingContext
            context.perform {
                if #available(iOS 12, *) {
                    self.isFirstTimeSaveAttData = true
                }
                self.removeMessageFromDB(context: context, removeAllDraft: removeAllDraft)

                let contextLabelFetch = NSFetchRequest<NSFetchRequestResult>(entityName: ContextLabel.Attributes.entityName)
                contextLabelFetch.predicate = NSPredicate(format: "%K == %@ AND %K == %@",
                                                          ContextLabel.Attributes.userID,
                                                          self.userID,
                                                          ContextLabel.Attributes.isSoftDeleted,
                                                          NSNumber(false))
                if let labels = try? context.fetch(contextLabelFetch) as? [ContextLabel] {
                    labels.forEach { context.delete($0) }
                }

                let conversationFetch = NSFetchRequest<NSFetchRequestResult>(entityName: Conversation.Attributes.entityName)
                conversationFetch.predicate = NSPredicate(format: "%K == %@ AND %K == %@",
                                                          Conversation.Attributes.userID,
                                                          self.userID,
                                                          Conversation.Attributes.isSoftDeleted,
                                                          NSNumber(false))
                if let conversations = try? context.fetch(conversationFetch) as? [Conversation] {
                    conversations.forEach { context.delete($0) }
                }

                _ = context.saveUpstreamIfNeeded()
                context.refreshAllObjects()

                if cleanBadgeAndNotifications {
                    UIApplication.setBadge(badge: 0)
                }
                seal.fulfill_()
            }
        }
    }

    // Remove message from db
    // In some conditions, some of the messages can't be deleted
    private func removeMessageFromDB(context: NSManagedObjectContext, removeAllDraft: Bool = true) {
        let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: Message.Attributes.entityName)
        // Don't delete the soft deleted message
        // Or they would come back when user pull down to refresh
        fetch.predicate = NSPredicate(format: "%K == %@ AND %K == %@",
                                      Message.Attributes.userID,
                                      self.userID,
                                      Message.Attributes.isSoftDeleted,
                                      NSNumber(false))

        guard let results = try? context.fetch(fetch) as? [NSManagedObject] else {
            return
        }

        if removeAllDraft {
            results.forEach { context.delete($0) }
            return
        }
        let draftID = Message.Location.draft.rawValue

        for message in results {
            if let message = message as? Message, let labels = message.labels.allObjects as? [Label] {
                if !labels.contains(where: { $0.labelID == draftID }) {
                    context.delete(message)
                }
            }
        }

        // The remove is triggered by pull down to refresh
        // So if the messages correspond to some conditions, can't delete it
        for obj in results {
            guard let message = obj as? Message else { continue }
            if let labels = message.labels.allObjects as? [Label],
               labels.contains(where: { $0.labelID == draftID }) {

                if let attachments = message.attachments.allObjects as? [Attachment],
                   attachments.contains(where: { $0.attachmentID == "0" }) {
                    // If the draft is uploading attachments, don't delete it
                    continue
                } else if message.isSending {
                    // If the draft is sending, don't delete it
                    continue
                } else if let _ = UUID(uuidString: message.messageID) {
                    // If the message ID is UUiD, means hasn't created draft, don't delete it
                    continue
                }
                context.delete(obj)
            }
        }
    }

    func search(_ query: String, page: Int, completion: (([Message.ObjectIDContainer]?, NSError?) -> Void)?) {
        let completionWrapper: CompletionBlock = {task, response, error in
            if error != nil {
                completion?(nil, error)
            }

            if var messagesArray = response?["Messages"] as? [[String: Any]] {
                for (index, _) in messagesArray.enumerated() {
                    messagesArray[index]["UserID"] = self.userID
                }
                let context = self.contextProvider.rootSavingContext
                context.perform {
                    do {
                        if let messages = try GRTJSONSerialization.objects(withEntityName: Message.Attributes.entityName, fromJSONArray: messagesArray, in: context) as? [Message] {
                            for message in messages {
                                message.messageStatus = 1
                            }
                            _ = context.saveUpstreamIfNeeded()

                            if error != nil {
                                completion?(nil, error)
                            } else {
                                completion?(messages.map(ObjectBox.init), error)
                            }
                        } else {
                            completion?(nil, error)
                        }
                    } catch let ex as NSError {
                        if let completion = completion {
                            completion(nil, ex)
                        }
                    }
                }
            }
        }
        let api = SearchMessage(keyword: query, page: page)
        self.apiService.exec(route: api, responseObject: SearchMessageResponse()) { (task, response) in
            if let error = response.error {
                completionWrapper(task, nil, error.toNSError)
            } else {
                completionWrapper(task, response.jsonDic, nil)
            }
        }
    }

    func saveDraft(_ message: Message?) {
        if let message = message, let context = message.managedObjectContext {
            context.performAndWait {
                _ = context.saveUpstreamIfNeeded()
            }
            self.queue(message, action: .saveDraft(messageObjectID: message.objectID.uriRepresentation().absoluteString))
        }
    }

    func purgeOldMessages() { // TODO:: later we need to clean the message with a bad user id
        // need fetch status bad messages
        let context = self.contextProvider.rootSavingContext
        context.perform {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: Message.Attributes.entityName)
            fetchRequest.predicate = NSPredicate(format: "(%K == 0) AND %K == %@", Message.Attributes.messageStatus, Contact.Attributes.userID, self.userID)
            do {
                if let badMessages = try context.fetch(fetchRequest) as? [Message] {
                    var badIDs: [String] = []
                    for message in badMessages {
                        badIDs.append(message.messageID)
                    }

                    self.fetchMessageInBatches(messageIDs: badIDs)
                }
            } catch {
            }
        }
    }

    func fetchMessageInBatches(messageIDs: [String]) {
        guard !messageIDs.isEmpty else { return }
        // split the api call in case there are too many messages
        var temp: [String] = []
        for i in 0..<messageIDs.count {
            if temp.count > 20 {
                self.fetchMetadata(with: temp)
                temp.removeAll()
            } else {
                temp.append(messageIDs[i])
            }
        }
        if !temp.isEmpty {
            self.fetchMetadata(with: temp)
        }
    }

    // MARK: old functions

    fileprivate func attachmentsForMessage(_ message: Message) -> [Attachment] {
        if let all = message.attachments.allObjects as? [Attachment] {
            return all.filter { !$0.isSoftDeleted }
        }
        return []
    }

    struct SendStatus: OptionSet {
        let rawValue: Int

        static let justStart             = SendStatus([])
        static let fetchEmailOK          = SendStatus(rawValue: 1 << 0)
        static let getBody               = SendStatus(rawValue: 1 << 1)
        static let updateBuilder         = SendStatus(rawValue: 1 << 2)
        static let processKeyResponse    = SendStatus(rawValue: 1 << 3)
        static let checkMimeAndPlainText = SendStatus(rawValue: 1 << 4)
        static let setAtts               = SendStatus(rawValue: 1 << 5)
        static let goNext                = SendStatus(rawValue: 1 << 6)
        static let checkMime             = SendStatus(rawValue: 1 << 7)
        static let buildMime             = SendStatus(rawValue: 1 << 8)
        static let checkPlainText        = SendStatus(rawValue: 1 << 9)
        static let buildPlainText        = SendStatus(rawValue: 1 << 10)
        static let initBuilders          = SendStatus(rawValue: 1 << 11)
        static let encodeBody            = SendStatus(rawValue: 1 << 12)
        static let buildSend             = SendStatus(rawValue: 1 << 13)
        static let sending               = SendStatus(rawValue: 1 << 14)
        static let done                  = SendStatus(rawValue: 1 << 15)
        static let doneWithError         = SendStatus(rawValue: 1 << 16)
        static let exceptionCatched      = SendStatus(rawValue: 1 << 17)
    }

    enum SendingError: Error {
        case emptyEncodedBody
    }

    func send(byID messageID: String, writeQueueUUID: UUID, UID: String, completion: CompletionBlock?) {
        let errorBlock: CompletionBlock = { task, response, error in
            completion?(task, response, error)
        }

        // TODO: needs to refractor
        let context = self.contextProvider.rootSavingContext
        context.perform {
            guard let objectID = self.contextProvider.managedObjectIDForURIRepresentation(messageID),
                  let message = context.find(with: objectID) as? Message else {
                errorBlock(nil, nil, NSError.badParameter(messageID))
                return
            }
            guard let userManager = self.parent, userManager.userinfo.userId == UID else {
                errorBlock(nil, nil, NSError.userLoggedOut())
                return
            }

            if message.messageID.isEmpty {//
                errorBlock(nil, nil, NSError.badParameter(messageID))
                return
            }

            if message.managedObjectContext == nil {
                NSError.alertLocalCacheErrorToast()
                let err = RuntimeError.bad_draft.error
                errorBlock(nil, nil, err)
                return
            }

            // start track status here :
            var status = SendStatus.justStart

            let userInfo = message.cachedUser ?? userManager.userInfo

            _ = userInfo.userPrivateKeys

            let userPrivKeysArray = userInfo.userPrivateKeysArray
            let addrPrivKeys = userInfo.addressKeys
            let newSchema = addrPrivKeys.newSchema

            let authCredential = message.cachedAuthCredential ?? userManager.authCredential
            let passphrase = message.cachedPassphrase ?? userManager.mailboxPassword
            guard let addressKey = (message.cachedAddress ?? userManager.messageService.defaultAddress(message))?.keys.first else {
                errorBlock(nil, nil, NSError.lockError())
                return
            }

            var requests: [UserEmailPubKeys] = [UserEmailPubKeys]()
            let emails = message.allEmails
            for email in emails {
                requests.append(UserEmailPubKeys(email: email, authCredential: authCredential))
            }

            // is encrypt outside
            let isEO = !message.password.isEmpty

            // get attachment
            let attachments = self.attachmentsForMessage(message)

            // create builder
            let sendBuilder = MessageSendingRequestBuilder(expirationOffset: message.expirationOffset)

            // build contacts if user setup key pinning
            var contacts: [PreContact] = [PreContact]()
            firstly {
                // fech addresses contact
                userManager.messageService.contactDataService.fetch(byEmails: emails, context: context)
            }.then { (cs) -> Guarantee<[Result<KeysResponse>]> in
                // Debug info
                status.insert(SendStatus.fetchEmailOK)
                // fech email keys from api
                contacts.append(contentsOf: cs)
                return when(resolved: requests.getPromises(api: userManager.apiService))
            }.then { results -> Promise<MessageSendingRequestBuilder> in
                // Debug info
                status.insert(SendStatus.getBody)
                // all prebuild errors need pop up from here
                guard let splited = try message.split(),
                      let bodyData = splited.dataPacket,
                      let keyData = splited.keyPacket,
                      let session = newSchema ?
                        try keyData.getSessionFromPubKeyPackage(userKeys: userPrivKeysArray,
                                                                passphrase: passphrase,
                                                                keys: addrPrivKeys) :
                        try message.getSessionKey(keys: addrPrivKeys.binPrivKeysArray,
                                                  passphrase: passphrase) else {
                    throw RuntimeError.cant_decrypt.error
                }
                // Debug info
                status.insert(SendStatus.updateBuilder)
                guard let key = session.key else {
                    throw RuntimeError.cant_decrypt.error
                }
                sendBuilder.update(bodyData: bodyData, bodySession: key, algo: session.algo)
                sendBuilder.set(password: message.password, hint: message.passwordHint)
                // Debug info
                status.insert(SendStatus.processKeyResponse)

                for (index, result) in results.enumerated() {
                    switch result {
                    case .fulfilled(let value):
                        let req = requests[index]
                        // check contacts have pub key or not
                        if let contact = contacts.find(email: req.email) {
                            if value.recipientType == 1 {
                                // if type is internal check is key match with contact key
                                // compare the key if doesn't match
                                sendBuilder.add(address: PreAddress(email: req.email, pubKey: value.firstKey(), pgpKey: contact.firstPgpKey, recipintType: value.recipientType, isEO: isEO, mime: false, sign: true, pgpencrypt: false, plainText: contact.plainText))
                            } else {
                                // sendBuilder.add(addr: PreAddress(email: req.email, pubKey: nil, pgpKey: contact.pgpKey, recipintType: value.recipientType, eo: isEO, mime: true))
                                sendBuilder.add(address: PreAddress(email: req.email, pubKey: nil, pgpKey: contact.firstPgpKey, recipintType: value.recipientType, isEO: isEO, mime: isEO ? true : contact.mime, sign: contact.sign, pgpencrypt: contact.encrypt, plainText: isEO ? false : contact.plainText))
                            }
                        } else {
                            if userInfo.sign == 1 {
                                sendBuilder.add(address: PreAddress(email: req.email, pubKey: value.firstKey(), pgpKey: nil, recipintType: value.recipientType, isEO: isEO, mime: true, sign: true, pgpencrypt: false, plainText: false))
                            } else {
                                sendBuilder.add(address: PreAddress(email: req.email, pubKey: value.firstKey(), pgpKey: nil, recipintType: value.recipientType, isEO: isEO, mime: false, sign: false, pgpencrypt: false, plainText: false))
                            }
                        }
                    case .rejected(let error):
                        throw error
                    }
                }
                // Debug info
                status.insert(SendStatus.checkMimeAndPlainText)
                if sendBuilder.hasMime || sendBuilder.hasPlainText {
                    guard let clearbody = newSchema ?
                            try message.decryptBody(keys: addrPrivKeys,
                                                    userKeys: userPrivKeysArray,
                                                    passphrase: passphrase) :
                            try message.decryptBody(keys: addrPrivKeys,
                                                    passphrase: passphrase) else {
                        throw RuntimeError.cant_decrypt.error
                    }
                    sendBuilder.set(clearBody: clearbody)
                }
                // Debug info
                status.insert(SendStatus.setAtts)

                for att in attachments {
                    if att.managedObjectContext != nil {
                        if let sessionPack = newSchema ?
                            try att.getSession(userKey: userPrivKeysArray,
                                               keys: addrPrivKeys,
                                               mailboxPassword: userManager.mailboxPassword) :
                            try att.getSession(keys: addrPrivKeys.binPrivKeysArray,
                                               mailboxPassword: userManager.mailboxPassword) {
                            guard let key = sessionPack.key else {
                                continue
                            }
                            sendBuilder.add(attachment: PreAttachment(id: att.attachmentID,
                                                                      session: key,
                                                                      algo: sessionPack.algo,
                                                                      att: att))
                        }
                    }
                }
                // Debug info
                status.insert(SendStatus.goNext)

                return .value(sendBuilder)
            }.then { (sendbuilder) -> Promise<MessageSendingRequestBuilder> in
                if !sendBuilder.hasMime {
                    return .value(sendBuilder)
                }
                return sendbuilder
                    .fetchAttachmentBodyForMime(passphrase: passphrase,
                                                msgService: self,
                                                userInfo: userInfo)
            }.then { (sendbuilder) -> Promise<MessageSendingRequestBuilder> in
                // Debug info
                status.insert(SendStatus.checkMime)

                if !sendBuilder.hasMime {
                    return .value(sendBuilder)
                }
                // Debug info
                status.insert(SendStatus.buildMime)

                // build pgp sending mime body
                return sendBuilder.buildMime(senderKey: addressKey,
                                             passphrase: passphrase,
                                             userKeys: userPrivKeysArray,
                                             keys: addrPrivKeys,
                                             newSchema: newSchema)
            }.then { (sendbuilder) -> Promise<MessageSendingRequestBuilder> in
                // Debug info
                status.insert(SendStatus.checkPlainText)

                if !sendBuilder.hasPlainText {
                    return .value(sendBuilder)
                }
                // Debug info
                status.insert(SendStatus.buildPlainText)

                // build pgp sending mime body
                return sendBuilder.buildPlainText(senderKey: addressKey,
                                                  passphrase: passphrase,
                                                  userKeys: userPrivKeysArray,
                                                  keys: addrPrivKeys,
                                                  newSchema: newSchema)
            } .then { sendbuilder -> Guarantee<[Result<AddressPackageBase>]> in
                // Debug info
                status.insert(SendStatus.initBuilders)
                // build address packages
                let promises = try sendBuilder.getBuilderPromises()
                return when(resolved: promises)
            }.then { results -> Promise<SendResponse> in
                // Debug info
                status.insert(SendStatus.encodeBody)

                // build api request
                guard let encodedBody = sendBuilder.bodyDataPacket?.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0)) else {
                    throw SendingError.emptyEncodedBody
                }

                var msgs = [AddressPackageBase]()
                for res in results {
                    switch res {
                    case .fulfilled(let value):
                        msgs.append(value)
                    case .rejected(let error):
                        throw error
                    }
                }
                // Debug info
                status.insert(SendStatus.buildSend)

                if let _ = UUID(uuidString: message.messageID) {
                    // Draft saved failed, can't send this message
                    let parseError = NSError(domain: APIServiceErrorDomain,
                                             code: APIErrorCode.badParameter,
                                             localizedDescription: "Invalid ID")
                    throw parseError
                }

                let sendApi = SendMessage(messageID: message.messageID,
                                          expirationTime: message.expirationOffset,
                                          messagePackage: msgs,
                                          body: encodedBody,
                                          clearBody: sendBuilder.clearBodyPackage, clearAtts: sendBuilder.clearAtts,
                                          mimeDataPacket: sendBuilder.mimeBody, clearMimeBody: sendBuilder.clearMimeBodyPackage,
                                          plainTextDataPacket: sendBuilder.plainBody, clearPlainTextBody: sendBuilder.clearPlainBodyPackage,
                                          authCredential: authCredential)
                // Debug info
                status.insert(SendStatus.sending)
                return userManager.apiService.run(route: sendApi)
            }.done { (res) in
                // Debug info

                let error = res.error
                if error == nil {
                    self.localNotificationService.unscheduleMessageSendingFailedNotification(.init(messageID: message.messageID))

                    NSError.alertMessageSentToast()

                    context.performAndWait {
                        if let newMessage = try? GRTJSONSerialization.object(withEntityName: Message.Attributes.entityName,
                                                                             fromJSONDictionary: res.responseDict["Sent"] as! [String: Any],
                                                                             in: context) as? Message {

                            newMessage.messageStatus = 1
                            newMessage.isDetailDownloaded = true
                            newMessage.unRead = false
                            PushUpdater().remove(notificationIdentifiers: [newMessage.notificationId])
                        } else {
                            assert(false, "Failed to parse response Message")
                        }
                    }

                    if context.saveUpstreamIfNeeded() == nil {
                        _ = self.markReplyStatus(message.orginalMessageID, action: message.action)
                    }
                } else {
                    // Debug info
                    status.insert(SendStatus.doneWithError)
                    if error?.responseCode == 9001 {
                        // here need let user to show the human check.
                        self.queueManager?.isRequiredHumanCheck = true
                        error?.toNSError.alertSentErrorToast()
                    } else if error?.responseCode == 15198 {
                        error?.toNSError.alertSentErrorToast()
                    } else {
                        error?.toNSError.alertErrorToast()
                    }
                    NSError.alertMessageSentErrorToast()
                    // show message now
                    self.localNotificationService.scheduleMessageSendingFailedNotification(.init(messageID: message.messageID,
                                                                                                 error: "\(LocalString._message_sent_failed_desc):\n\(error!.localizedDescription)",
                                                                                                 timeInterval: 1,
                                                                                                 subtitle: message.title))
                }
                completion?(nil, nil, error?.toNSError)
            }.catch(policy: .allErrors) { (error) in
                status.insert(SendStatus.exceptionCatched)

                guard let err = error as? ResponseError,
                      let responseCode = err.responseCode else {
                    NSError.alertMessageSentError(details: error.localizedDescription)
                    completion?(nil, nil, error as NSError)
                    return
                }
                if responseCode == 9001 {
                    // here need let user to show the human check.
                    self.queueManager?.isRequiredHumanCheck = true
                    NSError.alertMessageSentError(details: err.localizedDescription)
                } else if responseCode == 15198 {
                    NSError.alertMessageSentError(details: err.localizedDescription)
                } else if responseCode == 15004 {
                    // this error means the message has already been sent
                    // so don't need to show this error to user
                    self.localNotificationService.unscheduleMessageSendingFailedNotification(.init(messageID: message.messageID))
                    NSError.alertMessageSentToast()
                    completion?(nil, nil, nil)
                    return
                } else if responseCode == PGPTypeErrorCode.emailAddressFailedValidation.rawValue {
                    // Email address validation failed
                    NSError.alertMessageSentError(details: err.localizedDescription)

                    #if !APP_EXTENSION
                    let toDraftAction = UIAlertAction(title: LocalString._address_invalid_error_to_draft_action_title, style: .default) { (_) in
                        NotificationCenter.default.post(name: .switchView,
                                                        object: DeepLink(String(describing: MailboxViewController.self), sender: Message.Location.draft.rawValue))
                    }
                    LocalString._address_invalid_error_sending.alertViewController(LocalString._address_invalid_error_sending_title, toDraftAction)
                    #endif
                } else if responseCode == 2500 {
                    // The error means "Message has already been sent"
                    // Since the message is sent, this alert is useless to user
                    self.localNotificationService.unscheduleMessageSendingFailedNotification(.init(messageID: message.messageID))
                    completion?(nil, nil, nil)
                    // Draft folder must be single message mode
                    self.ForcefetchDetailForMessage(message) { _, _, _, _ in }
                    return
                } else {
                    NSError.alertMessageSentError(details: err.localizedDescription)
                }

                // show message now
                let errorMsg = responseCode == PGPTypeErrorCode.emailAddressFailedValidation.rawValue ? LocalString._messages_validation_failed_try_again : "\(LocalString._messages_sending_failed_try_again):\n\(err.localizedDescription)"
                self.localNotificationService.scheduleMessageSendingFailedNotification(.init(messageID: message.messageID,
                                                                                             error: errorMsg,
                                                                                             timeInterval: 1,
                                                                                             subtitle: message.title))
                completion?(nil, nil, err as NSError)
            }.finally {
                context.performAndWait {
                    message.isSending = false
                    _ = context.saveUpstreamIfNeeded()
                }
            }
            return
        }
    }

    private func markReplyStatus(_ oriMsgID: String?, action: NSNumber?) -> Promise<Void> {
        guard let originMessageID = oriMsgID,
            let act = action,
            !originMessageID.isEmpty,
            let fetchedMessageController = self.fetchedMessageControllerForID(originMessageID) else {
            return Promise()
        }
        return Promise { seal in
            do {
                try fetchedMessageController.performFetch()
                guard let message: Message = fetchedMessageController.fetchedObjects?.first as? Message,
                    message.managedObjectContext != nil else {
                        seal.fulfill_()
                        return
                }
                let context = self.contextProvider.rootSavingContext
                context.perform {
                    defer {
                        seal.fulfill_()
                    }
                    if let msgToUpdate = try? context.existingObject(with: message.objectID) as? Message {
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
                        _ = context.saveUpstreamIfNeeded()
                    }
                }
            } catch {
                seal.fulfill_()
            }
        }
    }

    // MARK: Notifications

    private func setupNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(MessageDataService.didSignOutNotification(_:)),
                                               name: NSNotification.Name.didSignOut,
                                               object: nil)
        // TODO: add monitoring for didBecomeActive
    }

    @objc fileprivate func didSignOutNotification(_ notification: Notification) {
        _ = cleanUp()
    }

    func queue(_ conversation: Conversation, action: MessageAction) {
        switch action {
        case .saveDraft, .uploadAtt, .uploadPubkey, .deleteAtt, .send, .emptyTrash, .emptySpam:
            fatalError()
        default:
            let task = QueueManager.Task(messageID: conversation.conversationID, action: action, userID: self.userID, dependencyIDs: [], isConversation: true)
            _ = self.queueManager?.addTask(task)
        }
    }

    func queue(_ message: Message, action: MessageAction) {
        if message.objectID.isTemporaryID {
            message.managedObjectContext?.performAndWait {
                do {
                    try message.managedObjectContext?.obtainPermanentIDs(for: [message])
                } catch {
                }
            }
        }
        message.managedObjectContext?.performAndWait {
            self.cachePropertiesForBackground(in: message)
        }
        switch action {
        case .saveDraft, .send:
            let task = QueueManager.Task(messageID: message.messageID, action: action, userID: self.userID, dependencyIDs: [], isConversation: false)
            _ = self.queueManager?.addTask(task)
        default:
            if message.managedObjectContext != nil && !message.messageID.isEmpty {
                let task = QueueManager.Task(messageID: message.messageID, action: action, userID: self.userID, dependencyIDs: [], isConversation: false)
                _ = self.queueManager?.addTask(task)
            }
        }
    }

    func queue(_ action: MessageAction, isConversation: Bool) {
        let task = QueueManager.Task(messageID: "", action: action, userID: self.userID, dependencyIDs: [], isConversation: isConversation)
        _ = self.queueManager?.addTask(task)
    }

    fileprivate func queue(_ att: Attachment, action: MessageAction) {
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
            updatedAction = .deleteAtt(attachmentObjectID: updatedID)
        default:
            break
        }
        let task = QueueManager.Task(messageID: att.message.messageID, action: updatedAction ?? action, userID: self.userID, dependencyIDs: [], isConversation: false)
        _ = self.queueManager?.addTask(task)
    }

    func cleanLocalMessageCache(_ completion: CompletionBlock?) {
        let getLatestEventID = EventLatestIDRequest()
        self.apiService.exec(route: getLatestEventID, responseObject: EventLatestIDResponse()) { (task, response) in
            guard response.error == nil && !response.eventID.isEmpty else {
                completion?(task, nil, response.error?.toNSError)
                return
            }
            self.lastUpdatedStore.clear()
            guard self.viewModeDataSource?.getCurrentViewMode() != nil else {
                return
            }

            let completionBlock: CompletionBlock = { task, dict, error in
                _ = self.labelDataService.fetchV4Labels().then({
                    self.contactDataService.cleanUp()
                }).done({
                    self.contactDataService.fetchContacts { (_, error) in
                        if error == nil {
                            _ = self.lastUpdatedStore.updateEventID(by: self.userID, eventID: response.eventID).ensure {
                                completion?(task, nil, error)
                            }
                        } else {
                            DispatchQueue.main.async {
                                completion?(task, nil, error)
                            }
                        }
                    }
                })
            }

            self.fetchMessages(byLabel: Message.Location.inbox.rawValue, time: 0, forceClean: false, isUnread: false, completion: completionBlock) {
                self.cleanMessage(cleanBadgeAndNotifications: true).then { _ -> Promise<Void> in
                    return self.contactDataService.cleanUp()
                }.cauterize()
            }
        }
    }

    // const (
    //  ok         = 0
    //  notSigned  = 1
    //  noVerifier = 2
    //  failed     = 3
    //  )
    func verifyBody(_ message: Message, verifier: [Data], passphrase: String) -> SignStatus {
        let keys = self.userDataSource!.addressKeys
        guard let passphrase = self.userDataSource?.mailboxPassword else {
            return .failed
        }

        do {
            let time: Int64 = Int64(round(message.time?.timeIntervalSince1970 ?? 0))
            if let verify = self.userDataSource!.newSchema ?
                try message.body.verifyMessage(verifier: verifier,
                                       userKeys: self.userDataSource!.userPrivateKeys,
                                       keys: keys, passphrase: passphrase, time: time) :
                try message.body.verifyMessage(verifier: verifier,
                                               binKeys: keys.binPrivKeysArray,
                                               passphrase: passphrase,
                                               time: time) {
                guard let verification = verify.signatureVerificationError else {
                    return .ok
                }
                return SignStatus(rawValue: verification.status) ?? .notSigned
            }
        } catch {
        }
        return .failed
    }

    func encryptBody(_ message: Message, clearBody: String, mailbox_pwd: String, error: NSErrorPointer?) {
        // TODO: Refactor this method later.
        let addressId = message.addressID ?? .empty
        if addressId.isEmpty {
            return
        }

        do {
            if let key = self.userDataSource?.getAddressKey(address_id: addressId) {
                message.body = try clearBody.encrypt(withKey: key,
                                                     userKeys: self.userDataSource!.userPrivateKeys,
                                                     mailbox_pwd: mailbox_pwd) ?? ""
            } else {// fallback
                let key = self.userDataSource!.getAddressPrivKey(address_id: addressId)
                message.body = try clearBody.encrypt(withPrivKey: key, mailbox_pwd: mailbox_pwd) ?? ""
            }
        } catch {
            message.body = ""
        }
    }

    /// this function need to factor
    func getAddressID(_ message: Message) -> String {
        if let addr = defaultAddress(message) {
            return addr.addressID
        }
        return ""
    }

    /// this function need to factor
    func defaultAddress(_ message: Message) -> Address? {
        let userInfo = self.userDataSource!.userInfo
        if let addressID = message.addressID, !addressID.isEmpty {
            if let add = userInfo.userAddresses.address(byID: addressID),
               add.send == .active {
                return add
            } else {
                if let add = userInfo.userAddresses.defaultSendAddress() {
                    return add
                }
            }
        } else {
            if let addr = userInfo.userAddresses.defaultSendAddress() {
                return addr
            }
        }
        return nil
    }

    /// this function need to factor
    func fromAddress(_ message: Message) -> Address? {
        let userInfo = self.userDataSource!.userInfo
        if let addressID = message.addressID, !addressID.isEmpty {
            if let add = userInfo.userAddresses.address(byID: addressID) {
                return add
            }
        }
        return nil
    }

    func messageWithLocation (recipientList: String,
                              bccList: String,
                              ccList: String,
                              title: String,
                              encryptionPassword: String,
                              passwordHint: String,
                              expirationTimeInterval: TimeInterval,
                              body: String,
                              attachments: [Any]?,
                              mailbox_pwd: String,
                              sendAddress: Address,
                              inManagedObjectContext context: NSManagedObjectContext) -> Message {
        let message = Message(context: context)
        message.messageID = UUID().uuidString
        message.toList = recipientList
        message.bccList = bccList
        message.ccList = ccList
        message.title = title
        message.passwordHint = passwordHint
        message.time = Date()
        message.expirationOffset = Int32(expirationTimeInterval)
        message.messageStatus = 1
        message.setAsDraft()
        message.userID = self.userID
        message.addressID = sendAddress.addressID

        if expirationTimeInterval > 0 {
            message.expirationTime = Date(timeIntervalSinceNow: expirationTimeInterval)
        }

        do {
            self.encryptBody(message, clearBody: body, mailbox_pwd: mailbox_pwd, error: nil)
            if !encryptionPassword.isEmpty {
                if let encryptedBody = try body.encrypt(withPwd: encryptionPassword) {
                    message.passwordEncryptedBody = encryptedBody
                }
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
        } catch {
        }
        return message
    }

    func updateMessage (_ message: Message ,
                        expirationTimeInterval: TimeInterval,
                        body: String,
                        mailbox_pwd: String) {
        if expirationTimeInterval > 0 {
            message.expirationTime = Date(timeIntervalSinceNow: expirationTimeInterval)
        }
        self.encryptBody(message, clearBody: body, mailbox_pwd: mailbox_pwd, error: nil)
    }

}
