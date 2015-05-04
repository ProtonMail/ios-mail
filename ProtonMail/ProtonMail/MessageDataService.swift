//
//  MessageDataService.swift
//  ProtonMail
//
//
// Copyright 2015 ArcTouch, Inc.
// All rights reserved.
//
// This file, its contents, concepts, methods, behavior, and operation
// (collectively the "Software") are protected by trade secret, patent,
// and copyright laws. The use of the Software is governed by a license
// agreement. Disclosure of the Software to third parties, in any form,
// in whole or in part, is expressly prohibited except as authorized by
// the license agreement.
//

import CoreData
import Foundation

let sharedMessageDataService = MessageDataService()

class MessageDataService {
    typealias CompletionBlock = APIService.CompletionBlock
    typealias ReadBlock = (() -> Void)
    
    struct Key {
        static let read = "read"
        static let total = "total"
        static let unread = "unread"
    }
        
    private let firstPage = 1
    private let incrementalUpdateQueue = dispatch_queue_create("ch.protonmail.incrementalUpdateQueue", DISPATCH_QUEUE_SERIAL)
    private let lastUpdatedMaximumTimeInterval: NSTimeInterval = 24 /*hours*/ * 3600
    private let lastUpdatedStore = LastUpdatedStore()
    private let maximumCachedMessageCount = 500
    
    private var managedObjectContext: NSManagedObjectContext? {
        return sharedCoreDataService.mainManagedObjectContext
    }
    
    private var readQueue: [ReadBlock] = []
    private let writeQueue = MessageQueue(queueName: "writeQueue")
    
    init() {
        setupMessageMonitoring()
        setupNotifications()
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    /// downloadTask returns the download task for use with UIProgressView+AFNetworking
    func fetchAttachmentForAttachment(attachment: Attachment, downloadTask: ((NSURLSessionDownloadTask) -> Void)?, completion:((NSURLResponse?, NSURL?, NSError?) -> Void)?) {
        if let localURL = attachment.localURL {
            completion?(nil, localURL, nil)
            return
        }
        
        // TODO: check for existing download tasks and return that task rather than start a new download

        queue { () -> Void in
            sharedAPIService.attachmentForAttachmentID(attachment.attachmentID, destinationDirectoryURL: NSFileManager.defaultManager().attachmentDirectory, downloadTask: downloadTask, completion: { task, fileURL, error in
                var error = error
                if let fileURL = fileURL {
                    attachment.localURL = fileURL
                    
                    error = attachment.managedObjectContext?.saveUpstreamIfNeeded()
                    if error != nil  {
                        NSLog("\(__FUNCTION__) error: \(error)")
                    }
                }
                
                completion?(task, fileURL, error)
            })
        }
    }
    
    func fetchLatestMessagesForLocation(location: MessageLocation, completion: CompletionBlock?) {
        let locationLastUpdated = lastUpdatedStore[location.key]
        let lastUpdatedCuttoff = NSDate(timeIntervalSinceNow: -lastUpdatedMaximumTimeInterval)
        
        if locationLastUpdated.compare(lastUpdatedCuttoff) == .OrderedAscending {
            NSLog("\(__FUNCTION__) lastUpdated: \(locationLastUpdated), paging update")
            // use paging
            fetchMessagesForLocation(location, MessageID: "0", Time: 0, completion: completion)
            //fetchMessagesForLocation(location, page: firstPage, completion: completion)
        } else {
            // use incremental
            NSLog("\(__FUNCTION__) lastUpdated: \(locationLastUpdated), incremental update")
            let lastUpdated = NSDate()
            
            let completionWrapper: CompletionBlock = { task, response, error in
                if error == nil {
                    self.lastUpdatedStore[location.key] = lastUpdated
                }
                
                completion?(task: task, response: response, error: error)
            }
            
            fetchMessageIncrementalUpdates(lastUpdated: locationLastUpdated, completion: completionWrapper)
        }
    }
    
    func fetchMessageCountForInbox() {
        fetchMessageCountForLocation(.inbox, completion: { (task, response, error) -> Void in
            if let unreadCount = response?[Key.unread] as? Int {
                UIApplication.sharedApplication().applicationIconBadgeNumber = unreadCount
            }
        })
    }
    
    func fetchMessageCountForLocation(location: MessageLocation, completion: CompletionBlock?) {
        queue { () -> Void in
            let completionWrapper: CompletionBlock = {task, response, error in
                let countInfo: Dictionary<String, Int> = [
                    Key.unread : response?["UnRead"] as? Int ?? 0,
                    Key.read : response?["Read"] as? Int ?? 0,
                    Key.total : response?["Total"] as? Int ?? 0]
                
                completion?(task: task, response: countInfo, error: error)
            }
            
            sharedAPIService.messageCountForLocation(location.rawValue, completion: completionWrapper)
        }
    }
    
    func fetchMessageDetailForMessage(message: Message, completion: CompletionBlock) {
        if !message.isDetailDownloaded {
            queue {
                let completionWrapper: CompletionBlock = { task, response, error in
                    let context = sharedCoreDataService.newManagedObjectContext()
                    
                    context.performBlock() {
                        var error: NSError?
                        
                        if response != nil {
                            let message = GRTJSONSerialization.mergeObjectForEntityName(Message.Attributes.entityName, fromJSONDictionary: response, inManagedObjectContext: context, error: &error) as! Message
                            
                            if error == nil {
                                message.isDetailDownloaded = true
                                
                                error = context.saveUpstreamIfNeeded()
                            }
                        } else {
                            error = NSError.unableToParseResponse(response)
                        }
                        
                        if error != nil  {
                            NSLog("\(__FUNCTION__) error: \(error)")
                        }
                        
                        dispatch_async(dispatch_get_main_queue()) {
                            completion(task: task, response: response, error: error)
                        }
                    }
                }

                sharedAPIService.messageDetail(messageID: message.messageID, completion: completionWrapper)
            }
        } else {
            completion(task: nil, response: nil, error: nil)
        }
    }
    
    func fetchMessagesForLocation(location: MessageLocation, MessageID : String, Time: Int, completion: CompletionBlock?) {
        queue {
            let lastUpdated = NSDate()
            
            let completionWrapper: CompletionBlock = { task, responseDict, error in
                if let messagesArray = responseDict?["Messages"] as? [Dictionary<String,AnyObject>] {
                    let context = sharedCoreDataService.newManagedObjectContext()
                    context.performBlockAndWait() {
                        var error: NSError?
                        var messages = GRTJSONSerialization.mergeObjectsForEntityName(Message.Attributes.entityName, fromJSONArray: messagesArray, inManagedObjectContext: context, error: &error)
                        
                        if error == nil {
                            for message in messages as! [Message] {
                                // PRO-157 - The issue for inbox <--> starred page switch
                                // only change the location if the message is new or not starred
                                // this prevents starred messages from disappearing out of the inbox until the next refresh
                                if message.inserted || location != .starred {
                                    message.locationNumber = location.rawValue
                                }
                            }
                            error = context.saveUpstreamIfNeeded()
                        }
                        if error != nil  {
                            NSLog("\(__FUNCTION__) error: \(error)")
                        }
                        dispatch_async(dispatch_get_main_queue()) {
//                            if page == self.firstPage {
//                                self.lastUpdatedStore[location.key] = lastUpdated
//                            }
                            //self.fetchMessageCountForInbox()
                            completion?(task: task, response: responseDict, error: error)
                        }
                    }
                } else {
                    completion?(task: task, response: responseDict, error: NSError.unableToParseResponse(responseDict))
                }
            }
            sharedAPIService.fetchPageMessageList(location.rawValue, time: Time, messageID: MessageID, completion: completionWrapper)
        }
    }
    
    func fetchedResultsControllerForLocation(location: MessageLocation) -> NSFetchedResultsController? {
        if let moc = managedObjectContext {
            let fetchRequest = NSFetchRequest(entityName: Message.Attributes.entityName)
            
            if location == .starred {
                fetchRequest.predicate = NSPredicate(format: "%K == true", Message.Attributes.isStarred)
            } else {
                fetchRequest.predicate = NSPredicate(format: "%K == %i", Message.Attributes.locationNumber, location.rawValue)
            }
            
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: Message.Attributes.time, ascending: false)]
            return NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: moc, sectionNameKeyPath: nil, cacheName: nil)
        }
     
        return nil
    }
    
    func launchCleanUpIfNeeded() {
        if !sharedUserDataService.isUserCredentialStored {
            cleanUp()
        }
    }
    
    func search(#query: String, page: Int, managedObjectContext context: NSManagedObjectContext, completion: (([Message]?, NSError?) -> Void)?) {
        queue {
            let completionWrapper: CompletionBlock = {task, response, error in
                if error != nil {
                    completion?(nil, error)
                }
                
                if let messagesArray = response?["Messages"] as? [Dictionary<String,AnyObject>] {
                    
                    context.performBlock() {
                        var error: NSError?
                        var messages = GRTJSONSerialization.mergeObjectsForEntityName(Message.Attributes.entityName, fromJSONArray: messagesArray, inManagedObjectContext: context, error: &error) as! [Message]
                                                
                        if let completion = completion {
                            dispatch_async(dispatch_get_main_queue()) {
                                if error != nil  {
                                    NSLog("\(__FUNCTION__) error: \(error)")
                                    completion(nil, error)
                                } else {
                                    completion(messages, error)
                                }
                            }
                        }
                    }
                } else {
                    completion?(nil, NSError.unableToParseResponse(response))
                }
            }
            
            sharedAPIService.messageSearch(query, page: page, completion: completionWrapper)
        }
    }
    
    func saveDraft(#recipientList: String, bccList: String, ccList: String, title: String, encryptionPassword: String, passwordHint: String, expirationTimeInterval: NSTimeInterval, body: String, attachments: [AnyObject]?) {
        if let context = sharedCoreDataService.mainManagedObjectContext {
            let message = messageWithLocation(.draft,
                recipientList: recipientList,
                bccList: bccList,
                ccList: ccList,
                title: title,
                encryptionPassword: encryptionPassword,
                passwordHint: passwordHint,
                expirationTimeInterval: expirationTimeInterval,
                body: body,
                attachments: attachments,
                inManagedObjectContext: context)
            
            if let error = context.saveUpstreamIfNeeded() {
                NSLog("\(__FUNCTION__) error: \(error)")
            } else {
                queue(message: message, action: .saveDraft)
            }
        }
    }
    
    func send(#recipientList: String, bccList: String, ccList: String, title: String, encryptionPassword: String, passwordHint: String, expirationTimeInterval: NSTimeInterval, body: String, attachments: [AnyObject]?, completion: CompletionBlock?) {
        var error: NSError?
        
        if let context = sharedCoreDataService.mainManagedObjectContext {
            let message = messageWithLocation(.outbox,
                recipientList: recipientList,
                bccList: bccList,
                ccList: ccList,
                title: title,
                encryptionPassword: encryptionPassword,
                passwordHint: passwordHint,
                expirationTimeInterval: expirationTimeInterval,
                body: body,
                attachments: attachments,
                inManagedObjectContext: context)
            
            error = context.saveUpstreamIfNeeded()
            
            if error != nil {
                NSLog("\(__FUNCTION__) error: \(error)")
            } else {
                queue(message: message, action: .send)
            }
        } else {
            error = NSError.protonMailError(code: 500, localizedDescription: NSLocalizedString("No managedObjectContext"), localizedFailureReason: nil, localizedRecoverySuggestion: nil)
        }
        
        completion?(task: nil, response: nil, error: error)
    }
    
    func purgeOldMessages() {
        if let context = sharedCoreDataService.mainManagedObjectContext {
            let cutoffTimeInterval: NSTimeInterval = 3 * 86400 // days converted to seconds
            let fetchRequest = NSFetchRequest(entityName: Message.Attributes.entityName)
            
            var error: NSError?
            let count = context.countForFetchRequest(fetchRequest, error: &error)
                
            if error != nil {
                NSLog("\(__FUNCTION__) error: \(error)")
            } else if count > maximumCachedMessageCount {
                fetchRequest.predicate = NSPredicate(format: "%K != %@ AND %K < %@", Message.Attributes.locationNumber, MessageLocation.outbox.rawValue, Message.Attributes.time, NSDate(timeIntervalSinceNow: -cutoffTimeInterval))
                
                if let oldMessages = context.executeFetchRequest(fetchRequest, error: &error) as? [Message] {
                    for message in oldMessages {
                        context.deleteObject(message)
                    }
                    
                    NSLog("\(__FUNCTION__) \(oldMessages.count) old messages purged.")
                    
                    if let error = context.saveUpstreamIfNeeded() {
                        NSLog("\(__FUNCTION__) error: \(error)")
                    }
                } else {
                    NSLog("\(__FUNCTION__) error: \(error)")
                }
            } else {
                NSLog("\(__FUNCTION__) cached message count: \(count)")
            }
        }
    }
    
    // MARK: - Private methods
    
    private func cleanUp() {
        if let context = managedObjectContext {
            Message.deleteAll(inContext: context)
        }
        
        lastUpdatedStore.clear()
        writeQueue.clear()
        
        UIApplication.sharedApplication().applicationIconBadgeNumber = 0
    }
    
    private func fetchMessageIncrementalUpdates(#lastUpdated: NSDate, completion: CompletionBlock?) {
        struct ResponseKey {
            static let code = "code"
            static let message = "message"
            static let response = "response"
        }
        
        let validResponse = 1000
        
        queue { () -> Void in
            let completionWrapper: CompletionBlock = { task, response, error in
                if error != nil {
                    completion?(task: task, response: nil, error: error)
                    return
                }
                
                if let code = response?[ResponseKey.code] as? Int {
                    if code == validResponse {
                        if let response = response?[ResponseKey.response] as? Dictionary<String, AnyObject> {
                            if let messages = response[ResponseKey.message] as? Array<Dictionary<String, AnyObject>> {
                                if messages.isEmpty {
                                    completion?(task: task, response: nil, error: nil)
                                } else {
                                    self.processIncrementalUpdateMessages(messages, task: task, response: response, completion: completion)
                                }
                                
                                return
                            }
                        }
                    }
                }
                
                completion?(task: task, response: nil, error: NSError.unableToParseResponse(response))
            }
            
            sharedAPIService.messageCheck(timestamp: lastUpdated.timeIntervalSince1970, completion: completionWrapper)
        }
    }
    
    private func attachmentsForMessage(message: Message) -> [APIService.Attachment] {
        var attachments: [APIService.Attachment] = []
        
        for messageAttachment in message.attachments.allObjects as! [Attachment] {
            if let fileDataBase64Encoded = messageAttachment.fileData?.base64EncodedStringWithOptions(nil) {
                let attachment = APIService.Attachment(fileName: messageAttachment.fileName, mimeType: messageAttachment.mimeType, fileData: ["self" : fileDataBase64Encoded], fileSize: messageAttachment.fileSize.integerValue)
                
                attachments.append(attachment)
            }
        }
        
        return attachments
    }
    
    private func messageBodyForMessage(message: Message, response: [String : AnyObject]?) -> [String : String] {
        var messageBody: [String : String] = ["self" : message.body]
        
        if let keys = response?["keys"] as? [[String : String]] {
            var error: NSError?
            if let body = message.decryptBody(&error) {
                // encrypt body with each public key
                for publicKeys in keys {
                    for (email, publicKey) in publicKeys {
                        if let encryptedBody = body.encryptWithPublicKey(publicKey, error: &error) {
                            messageBody[email] = encryptedBody
                        } else {
                            NSLog("\(__FUNCTION__) did not add encrypted body for \(email) with error: \(error)")
                        }
                    }
                }
                messageBody["outsiders"] = (message.checkIsEncrypted() == true ? message.passwordEncryptedBody : body)
            } else {
                NSLog("\(__FUNCTION__) unable to decrypt \(message.body) with error: \(error)")
            }
        } else {
            NSLog("\(__FUNCTION__) unable to parse response: \(response)")
        }

        return messageBody
    }
    
    // FIXME: Tried moving to Message extension, but caused a segmentation fault 11 in Xcode 6.1.1
    private func messageWithLocation(
        location: MessageLocation,
        recipientList: String,
        bccList: String,
        ccList: String,
        title: String,
        encryptionPassword: String,
        passwordHint: String,
        expirationTimeInterval: NSTimeInterval,
        body: String,
        attachments: [AnyObject]?,
        inManagedObjectContext context: NSManagedObjectContext) -> Message {
            let message = Message(context: context)
            message.messageID = "0"  //default is 0,  if you already have a draft ID pass here.
            message.location = location
            message.recipientList = recipientList
            message.bccList = bccList
            message.ccList = ccList
            message.title = title
            message.passwordHint = passwordHint
            
            if expirationTimeInterval > 0 {
                message.expirationTime = NSDate(timeIntervalSince1970: expirationTimeInterval)
            }
            
            var error: NSError?
            message.encryptBody(body, error: &error)
            
            if error != nil {
                NSLog("\(__FUNCTION__) error: \(error)")
            }
            
            if !encryptionPassword.isEmpty {
                if let encryptedBody = body.encryptWithPassphrase(encryptionPassword, error: &error) {
                    message.isEncrypted = true
                    message.passwordEncryptedBody = encryptedBody
                } else {
                    NSLog("\(__FUNCTION__) encryption error: \(error)")
                }
            }
            
            if let attachments = attachments {
                for (index, attachment) in enumerate(attachments) {
                    if let image = attachment as? UIImage {
                        if let fileData = UIImagePNGRepresentation(image) {
                            let attachment = Attachment(context: context)
                            attachment.attachmentID = "0"
                            attachment.message = message
                            attachment.fileName = "\(index).png"
                            attachment.mimeType = "image/png"
                            attachment.fileData = fileData
                            attachment.fileSize = fileData.length
                            continue
                        }
                    }
                    
                    let description = attachment.description ?? "unknown"
                    NSLog("\(__FUNCTION__) unsupported attachment type \(description)")
                }
            }
            
            return message
    }
    
    private func processIncrementalUpdateMessages(messages: Array<Dictionary<String, AnyObject>>, task: NSURLSessionDataTask!, response: Dictionary<String,AnyObject>?, completion: CompletionBlock?) {
        struct IncrementalUpdateType {
            static let delete = 1
            static let insert = 0
            static let update = 2
        }
        
        struct ResponseKey {
            static let messageID = "MessageID"
            static let type = "type"
        }
        
        // this serial dispatch queue prevents multiple messages from appearing when an incremental update is triggered while another is in progress
        dispatch_sync(self.incrementalUpdateQueue) {
            let context = sharedCoreDataService.newManagedObjectContext()
            
            context.performBlockAndWait { () -> Void in
                var error: NSError?
                
                for message in messages {
                    switch(message[ResponseKey.type] as? Int) {
                    case .Some(IncrementalUpdateType.delete):
                        if let messageID = message[ResponseKey.messageID] as? String {
                            if let message = Message.messageForMessageID(messageID, inManagedObjectContext: context) {
                                context.deleteObject(message)
                            }
                        }
                    case .Some(IncrementalUpdateType.insert), .Some(IncrementalUpdateType.update):
                        if let messageObject = GRTJSONSerialization.mergeObjectForEntityName(Message.Attributes.entityName, fromJSONDictionary: message, inManagedObjectContext: context, error: &error) as? NSManagedObject {
                        } else {
                            NSLog("\(__FUNCTION__) error: \(error)")
                        }
                    default:
                        NSLog("\(__FUNCTION__) unknown type in message: \(message)")
                    }
                }
                
                error = context.saveUpstreamIfNeeded()
                
                if error != nil  {
                    NSLog("\(__FUNCTION__) error: \(error)")
                }
                
                dispatch_async(dispatch_get_main_queue()) {
                    completion?(task: task, response: response, error: error)
                    self.fetchMessageCountForInbox()
                    return
                }
            }
        }
    }
    
    private func saveDraftWithMessageID(messageID: String, writeQueueUUID: NSUUID, completion: CompletionBlock?) {
        if let context = managedObjectContext {
            var error: NSError?
            if let objectID = sharedCoreDataService.managedObjectIDForURIRepresentation(messageID) {
                if let message = context.existingObjectWithID(objectID, error: &error) as? Message {
                    let attachments = self.attachmentsForMessage(message)
                    
                    let completionWrapper: CompletionBlock = { task, response, error in
                        if let messageID = response?["MessageID"] as? String {
                            message.messageID = messageID
                            
                            if let error = context.saveUpstreamIfNeeded() {
                                NSLog("\(__FUNCTION__) error: \(error)")
                            }
                        }
                        
                        completion?(task: task, response: response, error: error)
                    }
                    
                    sharedAPIService.messageDraft(
                        recipientList: message.recipientList,
                        bccList: message.bccList,
                        ccList: message.ccList,
                        title: message.title,
                        passwordHint: message.passwordHint,
                        expirationDate: message.expirationTime,
                        isEncrypted: message.isEncrypted,
                        body: ["self" : message.body],
                        attachments: attachments,
                        completion: completionWrapper)
                    
                    return
                }
            }
        }
        
        // nothing to send, dequeue request
        self.writeQueue.remove(elementID: writeQueueUUID)
        self.dequeueIfNeeded()
        
        completion?(task: nil, response: nil, error: NSError.badParameter(messageID))
    }
    
    private func sendMessageID(messageID: String, writeQueueUUID: NSUUID, completion: CompletionBlock?) {
        let errorBlock: CompletionBlock = { task, response, error in
            // nothing to send, dequeue request
            self.writeQueue.remove(elementID: writeQueueUUID)
            self.dequeueIfNeeded()
            
            completion?(task: task, response: response, error: error)
        }
        
        if let context = managedObjectContext {
            if let message = Message.messageForMessageID(messageID, inManagedObjectContext: context) {
                sharedAPIService.userPublicKeysForEmails(message.allEmailAddresses, completion: { (task, response, error) -> Void in
                    if error != nil && error!.code == APIService.ErrorCode.badParameter {
                        errorBlock(task: task, response: response, error: error)
                        return
                    }
                    
                    let messageBody = self.messageBodyForMessage(message, response: response)
                    let attachments = self.attachmentsForMessage(message)
                    
                    let completionWrapper: CompletionBlock = { task, response, error in
                        // remove successful send from Core Data
                        if error == nil {
                            context.deleteObject(message)
                            
                            if let error = context.saveUpstreamIfNeeded() {
                                NSLog("\(__FUNCTION__) error: \(error)")
                            }
                        }
                        
                        completion?(task: task, response: response, error: error)
                        return
                    }
                    
                    sharedAPIService.messageCreate(
                        messageID: message.messageID,
                        recipientList: message.recipientList,
                        bccList: message.bccList,
                        ccList: message.ccList,
                        title: message.title,
                        passwordHint: message.passwordHint,
                        expirationDate: message.expirationTime,
                        isEncrypted: message.isEncrypted,
                        body: messageBody,
                        attachments: attachments,
                        completion: completionWrapper)
                })
                
                return
            }
        }
    
        errorBlock(task: nil, response: nil, error: NSError.badParameter(messageID))
    }

    // MARK: Notifications

    private func setupNotifications() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "didSignOutNotification:", name: UserDataService.Notification.didSignOut, object: nil)
        
        // TODO: add monitoring for didBecomeActive
        
    }
    
    @objc private func didSignOutNotification(notification: NSNotification) {
        cleanUp()
    }
    
    // MARK: Queue
    
    private func writeQueueCompletionBlockForElementID(elementID: NSUUID) -> CompletionBlock {
        return { task, response, error in
            self.writeQueue.isInProgress = false
            
            if error == nil {
                self.writeQueue.remove(elementID: elementID)
                self.dequeueIfNeeded()
            } else {
                NSLog("\(__FUNCTION__) error: \(error)")
                
                // TODO: handle error
            }
        }
    }
    
    private func dequeueIfNeeded() {
        if let (uuid, messageID, actionString) = writeQueue.nextMessage() {
            if let action = MessageAction(rawValue: actionString) {
                writeQueue.isInProgress = true
                
                switch action {
                case .saveDraft:
                    saveDraftWithMessageID(messageID, writeQueueUUID: uuid, completion: writeQueueCompletionBlockForElementID(uuid))
                case .send:
                    sendMessageID(messageID, writeQueueUUID: uuid, completion: writeQueueCompletionBlockForElementID(uuid))
                default:
                    sharedAPIService.messageID(messageID, updateWithAction: action, completion: writeQueueCompletionBlockForElementID(uuid))
                }
            } else {
                NSLog("\(__FUNCTION__) Unsupported action \(actionString), removing from queue.")
                writeQueue.remove(elementID: uuid)
            }
        } else if !writeQueue.isBlocked && writeQueue.count == 0 && readQueue.count > 0 {
            readQueue.removeAtIndex(0)()
            dequeueIfNeeded()
        }
    }
        
    private func queue(#message: Message, action: MessageAction) {
        if action == .saveDraft {
            writeQueue.addMessage(message.objectID.URIRepresentation().absoluteString!, action: action)
        } else {
            writeQueue.addMessage(message.messageID, action: action)
        }
        
        dequeueIfNeeded()
    }
    
    private func queue(#readBlock: ReadBlock) {
        readQueue.append(readBlock)
        dequeueIfNeeded()
    }
    
    // MARK: Setup
    private func setupMessageMonitoring() {
        sharedMonitorSavesDataService.registerMessage(attribute: Message.Attributes.locationNumber, handler: { message in
            if let action = message.location.moveAction {
                self.queue(message: message, action: action)
            } else {
                NSLog("\(__FUNCTION__) \(message.messageID) move to \(message.location) was not a user initiated move.")
            }
        })
        
        sharedMonitorSavesDataService.registerMessage(attribute: Message.Attributes.isRead, handler: { message in
            let action: MessageAction = message.isRead ? .read : .unread
            
            self.queue(message: message, action: action)
        })
        
        sharedMonitorSavesDataService.registerMessage(attribute: Message.Attributes.isStarred, handler: { message in
            let action: MessageAction = message.isStarred ? .star : .unstar
            
            self.queue(message: message, action: action)
        })
    }
}


// MARK: - Attachment extension

extension Attachment {
    
    func fetchAttachment(downloadTask: ((NSURLSessionDownloadTask) -> Void)?, completion:((NSURLResponse?, NSURL?, NSError?) -> Void)?) {
        sharedMessageDataService.fetchAttachmentForAttachment(self, downloadTask: downloadTask, completion: completion)
    }
}


// MARK: - Message extension

extension Message {
    func fetchDetailIfNeeded(completion: MessageDataService.CompletionBlock) {
        sharedMessageDataService.fetchMessageDetailForMessage(self, completion: completion)
    }
}


// MARK: - NSFileManager extension

extension NSFileManager {
    
    var attachmentDirectory: NSURL {
        let attachmentDirectory = applicationSupportDirectoryURL.URLByAppendingPathComponent("attachments", isDirectory: true)
        
        if !NSFileManager.defaultManager().fileExistsAtPath(attachmentDirectory.absoluteString!) {
            var error: NSError?
            if !NSFileManager.defaultManager().createDirectoryAtURL(attachmentDirectory, withIntermediateDirectories: true, attributes: nil, error: &error) {
                NSLog("\(__FUNCTION__) Could not create \(attachmentDirectory.absoluteString!) with error: \(error)")
            }
        }

        return attachmentDirectory
    }
}
