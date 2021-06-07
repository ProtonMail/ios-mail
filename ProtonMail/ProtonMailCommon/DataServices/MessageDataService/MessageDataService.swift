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
import AwaitKit
import PromiseKit
import ProtonCore_DataModel
import ProtonCore_Networking
import ProtonCore_Services

/// Message data service
class MessageDataService : Service, HasLocalStorage {
    
    ///Message fetch details
    internal typealias CompletionFetchDetail = (_ task: URLSessionDataTask?,
                                                _ response: [String : Any]?,
                                                _ message:Message.ObjectIDContainer?,
                                                _ error: NSError?) -> Void
    
    typealias ReadBlock = (() -> Void)
    
    //TODO:: those 3 var need to double check to clean up
    var pushNotificationMessageID : String? = nil
    
    let apiService : APIService
    let userID : String
    weak var userDataSource : UserDataSource?
    let labelDataService: LabelsDataService
    let contactDataService: ContactDataService
    let localNotificationService: LocalNotificationService
    let coreDataService: CoreDataService
    let lastUpdatedStore: LastUpdatedStoreProtocol
    let cacheService: CacheService
    
    weak var viewModeDataSource: ViewModeDataSource?
    
    weak var queueManager: QueueManager?
    weak var parent: UserManager?
        
    init(api: APIService, userID: String, labelDataService: LabelsDataService, contactDataService: ContactDataService, localNotificationService: LocalNotificationService, queueManager: QueueManager?, coreDataService: CoreDataService, lastUpdatedStore: LastUpdatedStoreProtocol, user: UserManager, cacheService: CacheService) {
        self.apiService = api
        self.userID = userID
        self.labelDataService = labelDataService
        self.contactDataService = contactDataService
        self.localNotificationService = localNotificationService
        self.coreDataService = coreDataService
        self.lastUpdatedStore = lastUpdatedStore
        self.parent = user
        self.cacheService = cacheService
        
        setupNotifications()
        self.queueManager = queueManager
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func createLabel(name: String, color: String, isFolder: Bool) -> Bool {
        self.queue(.createLabel, isConversation: false, data1: name, data2: color, otherData: isFolder)
        return true
    }
    
    func update(label: Label, name: String, color: String) -> Bool {
        guard let context = label.managedObjectContext else {
            return false
        }
        var hasError = false
        context.performAndWait {
            label.name = name
            label.color = color
            
            let error = context.saveUpstreamIfNeeded()
            if let error = error {
                PMLog.D(" error: \(error)")
                hasError = true
            }
        }
        
        if hasError { return false }
        
        self.queue(.updateLabel, isConversation: false, data1: label.labelID, data2: name, otherData: color)
        return true
    }
    
    func delete(labels: [Label]) -> Bool {
        guard !labels.isEmpty,
              let context = labels.first?.managedObjectContext else {
            return false
        }
        let ids = labels.map { $0.labelID }
        var hasError = false
        context.performAndWait {
            labels.forEach(context.delete)
            
            let error = context.saveUpstreamIfNeeded()
            if let error = error {
                PMLog.D(" error: \(error)")
                hasError = true
            }
        }
        
        if hasError { return false }
        ids.forEach { id in
            self.queue(.deleteLabel, isConversation: false, data1: id, data2: "", otherData: nil)
        }
        
        return true
    }

    // MAKR : upload attachment
    
    /// MARK -- Refactored functions
    
    ///  nonmaly fetching the message from server based on label and time. //TODO:: change to promise
    ///
    /// - Parameters:
    ///   - labelID: labelid, location id, forlder id
    ///   - time: the latest update time
    ///   - forceClean: force clean the exsition messages first
    ///   - completion: aync complete handler
    func fetchMessages(byLabel labelID : String, time: Int, forceClean: Bool, isUnread: Bool, completion: CompletionBlock?) {
        self.queueManager?.queue {
            let completionWrapper: CompletionBlock = { task, responseDict, error in
                if error != nil {
                    completion?(task, responseDict, error)
                } else if let response = responseDict {
                    self.cacheService.parseMessagesResponse(labelID: labelID, isUnread: isUnread, response: response) { (errorFromParsing) in
                        if let err = errorFromParsing {
                            DispatchQueue.main.async {
                                completion?(task, responseDict, err as NSError)
                            }
                        } else {
                            // fetch inbox count
                            if labelID == Message.Location.inbox.rawValue {
                                let counterRoute = MessageCount()
                                self.apiService.exec(route: counterRoute) { (response: MessageCountResponse) in
                                    if response.error == nil {
                                        self.parent?.eventsService.processEvents(counts: response.counts)
                                    }
                                }
                            }
                            DispatchQueue.main.async {
                                completion?(task, responseDict, errorFromParsing as NSError?)
                            }
                        }
                    }
                } else {
                    completion?(task, responseDict, NSError.unableToParseResponse(responseDict))
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
    ///   - completion: async complete handler
    func fetchMessagesWithReset(byLabel labelID: String,
                                time: Int,
                                cleanContact: Bool = true,
                                completion: CompletionBlock?) {
        self.queueManager?.queue {
            let getLatestEventID = EventLatestIDRequest()
            self.apiService.exec(route: getLatestEventID) { [weak self] (task, IDRes: EventLatestIDResponse) in
                guard !IDRes.eventID.isEmpty,
                      let self = self else {
                    completion?(task, nil, nil)
                    return
                }
                
                let completionWrapper: CompletionBlock = { task, responseDict, error in
                    guard error == nil else {
                        completion?(task, responseDict, error)
                        return
                    }
                    self.lastUpdatedStore.clear()
                    _ = self.lastUpdatedStore.updateEventID(by: self.userID, eventID: IDRes.eventID).ensure {
                        completion?(task, responseDict, error)
                    }
                }
                
                self.cleanMessage().then { (_) -> Promise<Void> in
                    self.lastUpdatedStore.removeUpdateTime(by: self.userID,
                                                           type: .singleMessage)
                    self.lastUpdatedStore.removeUpdateTime(by: self.userID,
                                                           type: .conversation)
                    if cleanContact {
                        return self.contactDataService.cleanUp()
                    } else {
                        return Promise<Void>()
                    }
                }.ensure {
                    self.fetchMessages(byLabel: labelID, time: time, forceClean: false, isUnread: false, completion: completionWrapper)
                    if cleanContact {
                        self.contactDataService.fetchContacts(completion: nil)
                    }
                    self.labelDataService.fetchV4Labels().cauterize()
                }.cauterize()
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
            self.apiService.exec(route: eventAPI) { (response: EventCheckResponse) in
                guard response.responseCode == 1000 else {
                    return
                }
                self.parent?.eventsService.processEvents(mailSettings: response.mailSettings)
            }
        }
    }
    
    
    /// upload attachment to server
    ///
    /// - Parameter att: Attachment
    func upload( att : Attachment) {
        self.queue(att, action: .uploadAtt)
    }
    
    /// upload attachment to server
    ///
    /// - Parameter att: Attachment
    func upload( pubKey : Attachment) {
        self.queue(pubKey, action: .uploadPubkey)
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
            
            let objetcID = att.objectID.uriRepresentation().absoluteString
            let task = QueueManager.newTask()
            task.messageID = att.message.messageID
            task.actionString = MessageAction.deleteAtt.rawValue
            task.userID = self.userID
            task.otherData = objetcID
            _ = self.queueManager?.addTask(task)
            self.cacheService.delete(attachment: att) {
                seal.fulfill_()
            }
        }
    }
    
    typealias base64AttachmentDataComplete = (_ based64String : String) -> Void
    func base64AttachmentData(att: Attachment, _ complete : @escaping base64AttachmentDataComplete) {
        guard let user = self.userDataSource else {
            complete("")
            return
        }
        let context = self.coreDataService.mainContext
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
            self.fetchAttachmentForAttachment(att, downloadTask: { (taskOne : URLSessionDownloadTask) -> Void in }, completion: { [weak self] (_, url, error) -> Void in
                guard let self = self else {
                    complete("")
                    return
                }
                self.coreDataService.enqueue(context: self.coreDataService.mainContext) { context in
                    guard let attachment = try? context.existingObject(with: att.objectID) as? Attachment else {
                        complete("")
                        return
                    }
                    if attachment.localURL == nil {
                        attachment.localURL = url
                    }
                    complete( attachment.base64DecryptAttachment(userInfo: user.userInfo, passphrase: user.mailboxPassword) )
                    if error != nil {
                        PMLog.D("\(String(describing: error))")
                    }
                }
            })
        } 
    }

    
    
    // MARK : Send message
    func send(inQueue message : Message!, completion: CompletionBlock?) {
        self.localNotificationService.scheduleMessageSendingFailedNotification(.init(messageID: message.messageID, subtitle: message.title))
        message.managedObjectContext?.performAndWait {
            message.isSending = true
            _ = message.managedObjectContext?.saveUpstreamIfNeeded()
        }
        self.queue(message, action: .send)
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
                self.apiService.exec(route: counterApi) { (task, response: MessageCountResponse) in
                    guard response.error == nil else {
                        completion?()
                        return
                    }
                    self.parent?.eventsService.processEvents(counts: response.counts)
                }
            case .conversation:
                let conversationCountApi = ConversationCountRequest(addressID: nil)
                self.apiService.exec(route: conversationCountApi) { (task, response: ConversationCountResponse) in
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
    
    
    func messageFromPush() -> Message? {
        guard let msgID = self.pushNotificationMessageID else {
            return nil
        }
        let context = self.coreDataService.mainContext
        guard let message = Message.messageForMessageID(msgID, inManagedObjectContext: context) else {
            return nil
        }
        return message
    }
    
    
    ///TODO::fixme - double check it  // this way is a little bit hacky. future we will prebuild the send message body
    func injectTransientValuesIntoMessages() {
        let ids = queueManager?.queuedMessageIds() ?? []
        let context = self.coreDataService.operationContext
        self.coreDataService.enqueue(context: context) { (context) in
            ids.forEach { messageID in
                guard let objectID = self.coreDataService.managedObjectIDForURIRepresentation(messageID),
                    let managedObject = try? context.existingObject(with: objectID) else
                {
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
        if self.cacheService.deleteMessage(by: labelID) {
            queue(.empty, isConversation: false, data1: labelID)
        }
    }

    func updateEO(of message: Message, expirationTime: TimeInterval, pwd: String, pwdHint: String, completion: (() -> Void)?) {
        self.cacheService.updateExpirationOffset(of: message, expirationTime: expirationTime, pwd: pwd, pwdHint: pwdHint, completion: completion)
    }
    
    let reportTitle = "FetchMetadata"
    /// fetch message meta data with message obj
    ///
    /// - Parameter messages: Message
    private func fetchMetadata(with messageIDs : [String]) {
        if messageIDs.count > 0 {
            self.queueManager?.queue {
                let completionWrapper: CompletionBlock = { task, responseDict, error in
                    if var messagesArray = responseDict?["Messages"] as? [[String : Any]] {
                        for (index, _) in messagesArray.enumerated() {
                            messagesArray[index]["UserID"] = self.userID
                        }
                        let context = self.coreDataService.operationContext
                        self.coreDataService.enqueue(context: context) { (context) in
                            do {
                                if let messages = try GRTJSONSerialization.objects(withEntityName: Message.Attributes.entityName, fromJSONArray: messagesArray, in: context) as? [Message] {
                                    for message in messages {
                                        message.messageStatus = 1
                                    }
                                    if let error = context.saveUpstreamIfNeeded() {
                                        PMLog.D("GRTJSONSerialization.mergeObjectsForEntityName saveUpstreamIfNeeded failed \(error)")
                                        Analytics.shared.error(message: .fetchMetadata,
                                                               error: error,
                                                               extra: [Analytics.Reason.status: "save"],
                                                               user: self.parent)
                                    }
                                } else {
                                    Analytics.shared.error(message: .fetchMetadata,
                                                           error: "insert empty",
                                                           user: self.parent)
                                    PMLog.D("GRTJSONSerialization.mergeObjectsForEntityName failed \(String(describing: error))")
                                }
                            } catch let err as NSError {
                                Analytics.shared.error(message: .fetchMetadata,
                                                       error: err,
                                                       extra: ["status": "try catch"],
                                                       user: self.parent)
                                PMLog.D("fetchMessagesWithIDs failed \(err)")
                            }
                        }
                    } else {
                        
                        var details = ""
                        if let err = error {
                            details = err.description
                        }
                        Analytics.shared.error(message: .fetchMetadata,
                                               error: "Can't get the response Messages -- " + details,
                                               user: self.parent)
                        PMLog.D("fetchMessagesWithIDs can't get the response Messages")
                    }
                }
                
                let request = FetchMessagesByID(msgIDs: messageIDs)
                self.apiService.GET(request, completion: completionWrapper)
            }
        }
    }
    
    
    // old functions
    var isFirstTimeSaveAttData : Bool = false
    
    /// downloadTask returns the download task for use with UIProgressView+AFNetworking
    func fetchAttachmentForAttachment(_ attachment: Attachment,
                                      customAuthCredential: AuthCredential? = nil,
                                      downloadTask: ((URLSessionDownloadTask) -> Void)?,
                                      completion:((URLResponse?, URL?, NSError?) -> Void)?)
    {
        if attachment.downloaded, let localURL = attachment.localURL {
            completion?(nil, localURL as URL, nil)
            return
        }
        
        // TODO: check for existing download tasks and return that task rather than start a new download
        self.queueManager?.queue { () -> Void in
            if attachment.managedObjectContext != nil {
                self.apiService.downloadAttachment(byID: attachment.attachmentID,
                                                   destinationDirectoryURL: FileManager.default.attachmentDirectory,
                                                   customAuthCredential: customAuthCredential,
                                                   downloadTask: downloadTask,
                                                   completion: { task, fileURL, error in
                                                    var error = error
                                                    self.coreDataService.enqueue(context: self.coreDataService.rootSavingContext) { (context) in
                                                        if let fileURL = fileURL, let attachmentToUpdate = try? context.existingObject(with: attachment.objectID) as? Attachment {
                                                            attachmentToUpdate.localURL = fileURL
                                                            if #available(iOS 12, *) {
                                                                if !self.isFirstTimeSaveAttData {
                                                                    attachmentToUpdate.fileData = try? Data(contentsOf: fileURL)
                                                                }
                                                            } else {
                                                                attachmentToUpdate.fileData = try? Data(contentsOf: fileURL)
                                                            }
                                                            error = context.saveUpstreamIfNeeded()
                                                            if error != nil  {
                                                                PMLog.D(" error: \(String(describing: error))")
                                                            }
                                                        }
                                                        completion?(task, fileURL, error)
                                                    }
                                                   })
            } else {
                PMLog.D("The attachment not exist")
                completion?(nil, nil, nil)
            }
        }
    }
    
    func ForcefetchDetailForMessage(_ message: Message, completion: @escaping CompletionFetchDetail) {
        let msgID = message.messageID
        self.queueManager?.queue {
            let completionWrapper: CompletionBlock = { task, response, error in
                let objectId = message.objectID
                let context = self.coreDataService.operationContext
                self.coreDataService.enqueue(context: context) { (context) in
                    var error: NSError?
                    if let newMessage = context.object(with: objectId) as? Message, response != nil {
                        //TODO need check the respons code
                        if var msg: [String:Any] = response?["Message"] as? [String : Any] {
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
                                
                                let localAttachments = newMessage.attachments.allObjects.compactMap{ $0 as? Attachment}.filter{ !$0.isSoftDeleted }
                                let localAttachmentCount = localAttachments.count
                                
                                //This will remove all attachments that are still not uploaded to BE
                                try GRTJSONSerialization.object(withEntityName: Message.Attributes.entityName, fromJSONDictionary: msg, in: context)
                                
                                //Adds back the attachments that are still uploading
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
                                
                                //Use local attachment count since the not-uploaded attachment is not counted
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
                    if error != nil  {
                        PMLog.D(" error: \(String(describing: error))")
                    }
                }
            }
            self.apiService.messageDetail(messageID: msgID, completion: completionWrapper)
        }
    }
    
    func fetchMessageDetailForMessage(_ message: Message, labelID: String, completion: @escaping CompletionFetchDetail) {
        if !message.isDetailDownloaded {
            let msgID = message.messageID
            self.queueManager?.queue {
                let completionWrapper: CompletionBlock = { task, response, error in
                    let context = self.coreDataService.operationContext
                    let objectId = message.objectID
                    self.coreDataService.enqueue(context: context) { (context) in
                        if response != nil, let message = context.object(with: objectId) as? Message {
                            if var msg: [String : Any] = response?["Message"] as? [String : Any] {
                                msg.removeValue(forKey: "Location")
                                msg.removeValue(forKey: "Starred")
                                msg.removeValue(forKey: "test")
                                msg["UserID"] = self.userID
                                do {
                                    if let message_n = try GRTJSONSerialization.object(withEntityName: Message.Attributes.entityName, fromJSONDictionary: msg, in: context) as? Message {
                                        let unsubscribeMethods = msg["UnsubscribeMethods"] as? [String: Any]
                                        message_n.unsubscribeMethods = unsubscribeMethods?.toString()
                                        message_n.messageStatus = 1
                                        message_n.isDetailDownloaded = true
                                        if let labelID = message.firstValidFolder() {
                                            self.mark(messages: [message], labelID: labelID, unRead: false)
                                        }
                                        if message_n.unRead {
                                            self.cacheService.updateCounterSync(markUnRead: false, on: message, context: context)
                                        }
                                        message_n.unRead = false
                                        
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
                let context = self.coreDataService.operationContext
                self.coreDataService.enqueue(context: context) { (context) in
                    if response != nil {
                        //TODO need check the respons code
                        if var msg: [String : Any] = response?["Message"] as? [String : Any] {
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
            
            let context = self.coreDataService.operationContext
            self.coreDataService.enqueue(context: context) { (context) in
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
    
    
    // MARK : fuctions for only fetch the local cache
    
    /**
     fetch the message by location from local cache
     
     :param: location message location enum
     
     :returns: NSFetchedResultsController
     */
    func fetchedResults(by labelID: String, viewMode: ViewMode, isUnread: Bool = false) -> NSFetchedResultsController<NSFetchRequestResult>? {
        switch viewMode {
        case .singleMessage:
            let moc = self.coreDataService.mainContext
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: Message.Attributes.entityName)
            if isUnread {
                fetchRequest.predicate = NSPredicate(format: "(ANY labels.labelID = %@) AND (%K > %d) AND (%K == %@) AND (%K == %@)",
                                                     labelID, Message.Attributes.messageStatus, 0, Message.Attributes.userID, self.userID, Message.Attributes.unRead, NSNumber(true))
            } else {
                fetchRequest.predicate = NSPredicate(format: "(ANY labels.labelID = %@) AND (%K > %d) AND (%K == %@)",
                                                     labelID, Message.Attributes.messageStatus, 0, Message.Attributes.userID, self.userID)
            }
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(Message.time), ascending: false)]
            fetchRequest.fetchBatchSize = 30
            fetchRequest.includesPropertyValues = true
            return NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: moc, sectionNameKeyPath: nil, cacheName: nil)
        case .conversation:
            let moc = self.coreDataService.mainContext
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: ContextLabel.Attributes.entityName)
            if isUnread {
                fetchRequest.predicate = NSPredicate(format: "(%K == %@) AND (%K == %@) AND (conversation != nil) AND (%K > 0)",
                                                     ContextLabel.Attributes.labelID, labelID, ContextLabel.Attributes.userID, self.userID, ContextLabel.Attributes.unreadCount)
            } else {
                fetchRequest.predicate = NSPredicate(format: "(%K == %@) AND (%K == %@) AND (conversation != nil)",
                                                                ContextLabel.Attributes.labelID, labelID, ContextLabel.Attributes.userID, self.userID)
            }
            fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \ContextLabel.time, ascending: false)]
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
        let moc = self.coreDataService.mainContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: Message.Attributes.entityName)
        fetchRequest.predicate = NSPredicate(format: "%K == %@", Message.Attributes.messageID, messageID)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: Message.Attributes.time, ascending: false)]
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
        return self.cleanMessage().done { (_) in
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
        self.queue(.signout, isConversation: false, data1: "", data2: "", otherData: nil)
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
    
    func cleanMessage(removeAllDraft: Bool = true) -> Promise<Void> {
        return Promise { seal in
            self.coreDataService.enqueue(context: self.coreDataService.operationContext) { (context) in
                if #available(iOS 12, *) {
                    self.isFirstTimeSaveAttData = true
                }
                self.removeMessageFromDB(context: context, removeAllDraft: removeAllDraft)

                let conversationFetch = NSFetchRequest<NSFetchRequestResult>(entityName: Conversation.Attributes.entityName)
                conversationFetch.predicate = NSPredicate(format: "%K == %@", Conversation.Attributes.userID, self.userID)
                if let conversations = try? context.fetch(conversationFetch) as? [NSManagedObject] {
                    conversations.forEach{ context.delete($0) }
                }

                if let error = context.saveUpstreamIfNeeded() {
                    PMLog.D("error: \(error)")
                }

                UIApplication.setBadge(badge: 0)
                seal.fulfill_()
            }
        }
    }
    
    // Remove message from db
    // In some conditions, some of the messages can't be deleted
    private func removeMessageFromDB(context: NSManagedObjectContext, removeAllDraft: Bool = true) {
        let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: Message.Attributes.entityName)
        fetch.predicate = NSPredicate(format: "%K == %@", Message.Attributes.userID, self.userID)
        
        guard let results = try? context.fetch(fetch) as? [NSManagedObject] else {
            return
        }
        
        if removeAllDraft {
            results.forEach{ context.delete($0) }
            return
        }
        
        // The remove is triggered by pull down to refresh
        // So if the messages correspond to some conditions, can't delete it
        let draftID = Message.Location.draft.rawValue
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
            
            if var messagesArray = response?["Messages"] as? [[String : Any]] {
                for (index, _) in messagesArray.enumerated() {
                    messagesArray[index]["UserID"] = self.userID
                }
                let context = self.coreDataService.rootSavingContext
                self.coreDataService.enqueue(context: context) { (context) in
                    do {
                        if let messages = try GRTJSONSerialization.objects(withEntityName: Message.Attributes.entityName, fromJSONArray: messagesArray, in: context) as? [Message] {
                            for message in messages {
                                message.messageStatus = 1
                            }
                            if let error = context.saveUpstreamIfNeeded() {
                                PMLog.D(" error: \(error)")
                            }

                            if error != nil  {
                                PMLog.D(" error: \(String(describing: error))")
                                completion?(nil, error)
                            } else {
                                completion?(messages.map(ObjectBox.init), error)
                            }
                        } else {
                            completion?(nil, error)
                        }
                    } catch let ex as NSError {
                        PMLog.D(" error: \(ex)")
                        if let completion = completion {
                            completion(nil, ex)
                        }
                    }
                }
            }
        }
        let api = SearchMessage(keyword: query, page: page)
        self.apiService.exec(route: api) { (task, response: SearchMessageResponse) in
            if let error = response.error {
                completionWrapper(task, nil, error.toNSError)
            } else {
                completionWrapper(task, response.jsonDic, nil)
            }
        }
    }
    
    func saveDraft(_ message : Message?) {
        if let message = message, let context = message.managedObjectContext {
            context.performAndWait {
                if let error = context.saveUpstreamIfNeeded() {
                    PMLog.D(" error: \(error)")
                }
            }
            self.queue(message, action: .saveDraft)
        }
    }
    
    func purgeOldMessages() { //TODO:: later we need to clean the message with a bad user id
        // need fetch status bad messages
        let context = self.coreDataService.operationContext
        self.coreDataService.enqueue(context: context) { (context) in
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: Message.Attributes.entityName)
            fetchRequest.predicate = NSPredicate(format: "(%K == 0) AND %K == %@", Message.Attributes.messageStatus, Contact.Attributes.userID, self.userID)
            do {
                if let badMessages = try context.fetch(fetchRequest) as? [Message] {
                    var badIDs : [String] = []
                    for message in badMessages {
                        badIDs.append(message.messageID)
                    }
                    
                    self.fetchMessageInBatches(messageIDs: badIDs)
                }
            } catch let ex as NSError {
                Analytics.shared.error(message: .purgeOldMessages,
                                       error: ex,
                                       user: self.parent)
                PMLog.D("error : \(ex)")
            }
        }
    }

    func fetchMessageInBatches(messageIDs: [String]) {
        guard !messageIDs.isEmpty else { return }
        //split the api call in case there are too many messages
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

    
    // MARK : old functions
    
    fileprivate func attachmentsForMessage(_ message: Message) -> [Attachment] {
        if let all = message.attachments.allObjects as? [Attachment] {
            return all.filter{ !$0.isSoftDeleted }
        }
        return []
    }
    
    struct SendStatus : OptionSet {
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
    
    func send(byID messageID: String, writeQueueUUID: UUID, UID: String, completion: CompletionBlock?) {
        let errorBlock: CompletionBlock = { task, response, error in
            completion?(task, response, error)
        }
        
        //TODO: needs to refractor
        let context = self.coreDataService.operationContext
        self.coreDataService.enqueue(context: context) { (context) in
            guard let objectID = self.coreDataService.managedObjectIDForURIRepresentation(messageID),
                  let message = context.find(with: objectID) as? Message else
            {
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
                Analytics.shared.error(message: .sendMessageError, error: err)
                errorBlock(nil, nil, err)
                return
            }
            
            //start track status here :
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
            
            var requests : [UserEmailPubKeys] = [UserEmailPubKeys]()
            let emails = message.allEmails
            for email in emails {
                requests.append(UserEmailPubKeys(email: email, authCredential: authCredential))
            }
            
            // is encrypt outside
            let isEO = !message.password.isEmpty
            
            // get attachment
            let attachments = self.attachmentsForMessage(message)
            
            //create builder
            let sendBuilder = SendBuilder()
            
            //build contacts if user setup key pinning
            var contacts : [PreContact] = [PreContact]()
            firstly {
                //fech addresses contact
                userManager.messageService.contactDataService.fetch(byEmails: emails, context: context)
            }.then { (cs) -> Guarantee<[Result<KeysResponse>]> in
                //Debug info
                status.insert(SendStatus.fetchEmailOK)
                // fech email keys from api
                contacts.append(contentsOf: cs)
                return when(resolved: requests.getPromises(api: userManager.apiService))
            }.then { results -> Promise<SendBuilder> in
                //Debug info
                status.insert(SendStatus.getBody)
                //all prebuild errors need pop up from here
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
                //Debug info
                status.insert(SendStatus.updateBuilder)
                guard let key = session.key else {
                    throw RuntimeError.cant_decrypt.error
                }
                sendBuilder.update(bodyData: bodyData, bodySession: key, algo: session.algo)
                sendBuilder.set(pwd: message.password, hit: message.passwordHint)
                //Debug info
                status.insert(SendStatus.processKeyResponse)
                
                for (index, result) in results.enumerated() {
                    switch result {
                    case .fulfilled(let value):
                        let req = requests[index]
                        //check contacts have pub key or not
                        if let contact = contacts.find(email: req.email) {
                            if value.recipientType == 1 {
                                //if type is internal check is key match with contact key
                                //compare the key if doesn't match
                                sendBuilder.add(addr: PreAddress(email: req.email, pubKey: value.firstKey(), pgpKey: contact.firstPgpKey, recipintType: value.recipientType, eo: isEO, mime: false, sign: true, pgpencrypt: false, plainText: contact.plainText))
                            } else {
                                //sendBuilder.add(addr: PreAddress(email: req.email, pubKey: nil, pgpKey: contact.pgpKey, recipintType: value.recipientType, eo: isEO, mime: true))
                                sendBuilder.add(addr: PreAddress(email: req.email, pubKey: nil, pgpKey: contact.firstPgpKey, recipintType: value.recipientType, eo: isEO, mime: contact.mime, sign: contact.sign, pgpencrypt: contact.encrypt, plainText: contact.plainText))
                            }
                        } else {
                            if userInfo.sign == 1 {
                                sendBuilder.add(addr: PreAddress(email: req.email, pubKey: value.firstKey(), pgpKey: nil, recipintType: value.recipientType, eo: isEO, mime: true, sign: true, pgpencrypt: false, plainText: false))
                            } else {
                                sendBuilder.add(addr: PreAddress(email: req.email, pubKey: value.firstKey(), pgpKey: nil, recipintType: value.recipientType, eo: isEO, mime: false, sign: false, pgpencrypt: false, plainText: false))
                            }
                        }
                    case .rejected(let error):
                        throw error
                    }
                }
                //Debug info
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
                    sendBuilder.set(clear: clearbody)
                }
                //Debug info
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
                            sendBuilder.add(att: PreAttachment(id: att.attachmentID,
                                                               session: key,
                                                               algo: sessionPack.algo,
                                                               att: att))
                        }
                    }
                }
                //Debug info
                status.insert(SendStatus.goNext)
                
                return .value(sendBuilder)
            }.then{ (sendbuilder) -> Promise<SendBuilder> in
                //Debug info
                status.insert(SendStatus.checkMime)
                
                if !sendBuilder.hasMime {
                    return .value(sendBuilder)
                }
                //Debug info
                status.insert(SendStatus.buildMime)
                
                //build pgp sending mime body
                return sendBuilder.buildMime(senderKey: addressKey,
                                             passphrase: passphrase,
                                             userKeys: userPrivKeysArray,
                                             keys: addrPrivKeys,
                                             newSchema: newSchema,
                                             msgService: self,
                                             userInfo: userInfo
                )
            }.then{ (sendbuilder) -> Promise<SendBuilder> in
                //Debug info
                status.insert(SendStatus.checkPlainText)
                
                if !sendBuilder.hasPlainText {
                    return .value(sendBuilder)
                }
                //Debug info
                status.insert(SendStatus.buildPlainText)
                
                //build pgp sending mime body
                return sendBuilder.buildPlainText(senderKey: addressKey,
                                                  passphrase: passphrase,
                                                  userKeys: userPrivKeysArray,
                                                  keys: addrPrivKeys,
                                                  newSchema: newSchema)
            } .then { sendbuilder -> Guarantee<[Result<AddressPackageBase>]> in
                //Debug info
                status.insert(SendStatus.initBuilders)
                //build address packages
                return when(resolved: sendbuilder.promises)
            }.then { results -> Promise<SendResponse> in
                //Debug info
                status.insert(SendStatus.encodeBody)
                
                //build api request
                let encodedBody = sendBuilder.bodyDataPacket.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
                var msgs = [AddressPackageBase]()
                for res in results {
                    switch res {
                    case .fulfilled(let value):
                        msgs.append(value)
                    case .rejected(let error):
                        throw error
                    }
                }
                //Debug info
                status.insert(SendStatus.buildSend)
                
                if msgs.count == 0 {
                    Analytics.shared.debug(message: .sendMessageError,
                                           extra: ["SendStatus": status,
                                                   "IsBodyEmpty": message.body == "",
                                                   "HasPlainText": sendBuilder.hasPlainText,
                                                   "HasMIME": sendBuilder.hasMime,
                                                   "HasAtt": attachments.count != 0],
                                           user: userManager)
                }
                
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
                                          plainTextDataPacket : sendBuilder.plainBody, clearPlainTextBody : sendBuilder.clearPlainBodyPackage,
                                          authCredential: authCredential)
                //Debug info
                status.insert(SendStatus.sending)
                return userManager.apiService.run(route: sendApi)
            }.done { (res) in
                //Debug info
                
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
                        } else {
                            assert(false, "Failed to parse response Message")
                        }
                    }
                    
                    if let error = context.saveUpstreamIfNeeded() {
                        PMLog.D(" error: \(error)")
                    } else {
                        _ = self.markReplyStatus(message.orginalMessageID, action: message.action)
                    }
                } else {
                    //Debug info
                    status.insert(SendStatus.doneWithError)
                    if error?.responseCode == 9001 {
                        //here need let user to show the human check.
                        self.queueManager?.isRequiredHumanCheck = true
                        error?.toNSError.alertSentErrorToast()
                    } else if error?.responseCode == 15198 {
                        error?.toNSError.alertSentErrorToast()
                    }  else {
                        error?.toNSError.alertErrorToast()
                    }
                    NSError.alertMessageSentErrorToast()
                    let _err = error?.localizedDescription ?? "Unknow error"
                    Analytics.shared.error(message: .sendMessageError, error: _err, extra: [
                        "status": status.rawValue,
                        "emailCount": emails.count,
                        "attCount": attachments.count
                    ], user: userManager)
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
                PMLog.D(error.localizedDescription)
                if responseCode == 9001 {
                    //here need let user to show the human check.
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
                } else if responseCode == 33101 {
                    //Email address validation failed
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
                    let draftID = Message.Location.draft.rawValue
                    self.fetchMessagesWithReset(byLabel: draftID, time: 0, cleanContact: false, completion: nil)
                    return
                } else {
                    NSError.alertMessageSentError(details: err.localizedDescription)
                }
                
                // show message now
                let errorMsg = responseCode == 33101 ? LocalString._messages_validation_failed_try_again : "\(LocalString._messages_sending_failed_try_again):\n\(err.localizedDescription)"
                self.localNotificationService.scheduleMessageSendingFailedNotification(.init(messageID: message.messageID,
                                                                                             error: errorMsg,
                                                                                             timeInterval: 1,
                                                                                             subtitle: message.title))
                Analytics.shared.error(message: .sendMessageError, error: err, extra: [
                    "status": status.rawValue,
                    "emailCount": emails.count,
                    "attCount": attachments.count
                ], user: userManager)
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
    
    private func markReplyStatus(_ oriMsgID : String?, action : NSNumber?) -> Promise<Void> {
        guard let originMessageID = oriMsgID,
            let act = action,
            !originMessageID.isEmpty,
            let fetchedMessageController = self.fetchedMessageControllerForID(originMessageID) else {
            return Promise()
        }
        return Promise { seal in
            do {
                try fetchedMessageController.performFetch()
                guard let message : Message = fetchedMessageController.fetchedObjects?.first as? Message,
                    message.managedObjectContext != nil else {
                        seal.fulfill_()
                        return
                }
                self.coreDataService.enqueue(context: self.coreDataService.rootSavingContext) { (context) in
                    defer {
                        seal.fulfill_()
                    }
                    if let msgToUpdate = try? context.existingObject(with: message.objectID) as? Message {
                        //{0|1|2} // Optional, reply = 0, reply all = 1, forward = 2
                        if act == 0 {
                            msgToUpdate.replied = true
                        } else if act == 1 {
                            msgToUpdate.repliedAll = true
                        } else if act == 2{
                            msgToUpdate.forwarded = true
                        } else {
                            //ignore
                        }
                        if let error = context.saveUpstreamIfNeeded() {
                            PMLog.D(" error: \(error)")
                        }
                    }
                }
            } catch {
                PMLog.D(" error: \(error)")
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
    
    func queue(_ conversation: Conversation, action: MessageAction, data1: String = "", data2: String = "", otherData: Any? = nil) {
        switch action {
        case .saveDraft, .uploadAtt, .uploadPubkey, .deleteAtt, .send, .emptyTrash, .emptySpam:
            fatalError()
        default:
            let task = QueueManager.newTask()
            task.messageID = conversation.conversationID
            task.actionString = action.rawValue
            task.data1 = data1
            task.data2 = data2
            task.userID = self.userID
            task.otherData = otherData
            _ = self.queueManager?.addTask(task)
        }
    }
    
    func queue(_ message: Message, action: MessageAction, data1: String = "", data2: String = "") {
        if message.objectID.isTemporaryID {
            message.managedObjectContext?.performAndWait {
                do {
                    try message.managedObjectContext?.obtainPermanentIDs(for: [message])
                } catch {
                    PMLog.D("error: \(error)")
                }
            }
        }

        self.cachePropertiesForBackground(in: message)
        if action == .saveDraft || action == .send {
            let task = QueueManager.newTask()
            task.messageID = message.messageID
            task.actionString = action.rawValue
            task.data1 = data1
            task.data2 = data2
            task.userID = self.userID
            task.otherData = message.objectID.uriRepresentation().absoluteString
            _ = self.queueManager?.addTask(task)
        } else {
            if message.managedObjectContext != nil && !message.messageID.isEmpty {
                let task = QueueManager.newTask()
                task.messageID = message.messageID
                task.actionString = action.rawValue
                task.data1 = data1
                task.data2 = data2
                task.userID = self.userID
                _ = self.queueManager?.addTask(task)
            }
        }
    }
    
    func queue(_ action: MessageAction, isConversation: Bool, data1: String = "", data2: String = "", otherData: Any? = nil) {
        let task = QueueManager.newTask()
        task.messageID = ""
        task.actionString = action.rawValue
        task.data1 = data1
        task.data2 = data2
        task.userID = self.userID
        task.otherData = otherData
        task.isConversation = isConversation
        _ = self.queueManager?.addTask(task)
    }
    
    fileprivate func queue(_ att: Attachment, action: MessageAction, data1: String = "", data2: String = "") {
        if att.objectID.isTemporaryID {
            att.managedObjectContext?.performAndWait {
                try? att.managedObjectContext?.obtainPermanentIDs(for: [att])
            }
        }
        
        self.cachePropertiesForBackground(in: att.message)
        let task = QueueManager.newTask()
        task.messageID = att.message.messageID
        task.actionString = action.rawValue
        task.data1 = data1
        task.data2 = data2
        task.otherData = att.objectID.uriRepresentation().absoluteString
        task.userID = self.userID
        _ = self.queueManager?.addTask(task)
    }
    
    func cleanLocalMessageCache(_ completion: CompletionBlock?) {
        let getLatestEventID = EventLatestIDRequest()
        self.apiService.exec(route: getLatestEventID) { (task, response : EventLatestIDResponse) in
            guard response.error == nil && !response.eventID.isEmpty else {
                completion?(task, nil, response.error?.toNSError)
                return
            }
            self.cleanMessage().then { _ -> Promise<Void> in
                return self.contactDataService.cleanUp()
            }.ensure {
                self.lastUpdatedStore.clear()
                guard let viewMode = self.viewModeDataSource?.getCurrentViewMode() else {
                    return
                }
                
                let completionBlock: CompletionBlock = { task, dict, error in
                    _ = self.labelDataService.fetchV4Labels().done { (_) in
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
                    }
                }
                
                switch viewMode {
                case .singleMessage:
                    self.fetchMessages(byLabel: Message.Location.inbox.rawValue, time: 0, forceClean: false, isUnread: false, completion: completionBlock)
                case .conversation:
                    // ConversationDataService.cleanAll() should be called instead
                    break
                }
            }.cauterize()
        }
    }
    
    //const (
    //  ok         = 0
    //  notSigned  = 1
    //  noVerifier = 2
    //  failed     = 3
    //  )
    func verifyBody(_ message: Message, verifier : [Data], passphrase: String) -> SignStatus {
        let keys = self.userDataSource!.addressKeys
        guard let passphrase = self.userDataSource?.mailboxPassword else {
            return .failed
        }
        
        do {
            let time : Int64 = Int64(round(message.time?.timeIntervalSince1970 ?? 0))
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
            PMLog.D("error: \(error.localizedDescription)")
        }
        return .failed
    }
    
    func encryptBody(_ message: Message, clearBody: String, mailbox_pwd: String, error: NSErrorPointer?) {
        let address_id = self.getAddressID(message)
        if address_id.isEmpty {
            return
        }
        
        do {
            if let key = self.userDataSource?.getAddressKey(address_id: address_id) {
                message.body = try clearBody.encrypt(withKey: key,
                                                     userKeys: self.userDataSource!.userPrivateKeys,
                                                     mailbox_pwd: mailbox_pwd) ?? ""
            } else {//fallback
                let key = self.userDataSource!.getAddressPrivKey(address_id: address_id)
                message.body = try clearBody.encrypt(withPrivKey: key, mailbox_pwd: mailbox_pwd) ?? ""
            }
        } catch let error {//TODO:: error handling
            PMLog.D(any: error.localizedDescription)
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
            if let add = userInfo.userAddresses.address(byID: addressID), add.send.rawValue == 1 {
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
            PMLog.D("error: \(error)")
        }
        return message
    }
    
    func updateMessage (_ message: Message ,
                        expirationTimeInterval: TimeInterval,
                        body: String,
                        attachments: [Any]?,
                        mailbox_pwd: String) {
        if expirationTimeInterval > 0 {
            message.expirationTime = Date(timeIntervalSinceNow: expirationTimeInterval)
        }
        self.encryptBody(message, clearBody: body, mailbox_pwd: mailbox_pwd, error: nil)
    }
    
}
