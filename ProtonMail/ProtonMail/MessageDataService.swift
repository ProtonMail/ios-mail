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
    typealias CompletionFetchDetail = APIService.CompletionFetchDetail
    typealias ReadBlock = (() -> Void)
    
    struct Key {
        static let read = "read"
        static let total = "total"
        static let unread = "unread"
    }
    
    private let incrementalUpdateQueue = dispatch_queue_create("ch.protonmail.incrementalUpdateQueue", DISPATCH_QUEUE_SERIAL)
    private let lastUpdatedMaximumTimeInterval: NSTimeInterval = 24 /*hours*/ * 3600
    private let maximumCachedMessageCount = 500
    
    private var managedObjectContext: NSManagedObjectContext? {
        return sharedCoreDataService.mainManagedObjectContext
    }
    
    private var readQueue: [ReadBlock] = []
    
    init() {
        setupMessageMonitoring()
        setupNotifications()
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    
    // MAKR : upload attachment
    
    func uploadAttachment(att: Attachment!)
    {
        if let context = sharedCoreDataService.mainManagedObjectContext {
            if let error = context.saveUpstreamIfNeeded() {
                NSLog("\(__FUNCTION__) error: \(error)")
            } else {
                queue(att: att, action: .uploadAtt)
            }
        }
        
        dequeueIfNeeded()
    }
    
    
    
    // MARK : Send message
    
    func send(messageID : String!, completion: CompletionBlock?) {
        var error: NSError?
        if let context = sharedCoreDataService.mainManagedObjectContext {
            if let message = Message.messageForMessageID(messageID, inManagedObjectContext: context) {
                //message.location = .outbox
                error = context.saveUpstreamIfNeeded()
                if error != nil {
                    NSLog("\(__FUNCTION__) error: \(error)")
                } else {
                    queue(message: message, action: .send)
                }
            } else {
                //TODO:: handle can't find the message error.
            }
            
        } else {
            error = NSError.protonMailError(code: 500, localizedDescription: NSLocalizedString("No managedObjectContext"), localizedFailureReason: nil, localizedRecoverySuggestion: nil)
        }
        completion?(task: nil, response: nil, error: error)
    }
    

    
    
    // MARK : fetch functions
    
    
    /**
    nonmaly fetching the message from server based on location and time.
    
    :param: location   mailbox location
    :param: MessageID  mesasge id not inuse for now
    :param: Time       the latest update time
    :param: completion aync complete handler
    */
    func fetchMessagesForLocation(location: MessageLocation, MessageID : String, Time: Int, completion: CompletionBlock?) {
        queue {
            let completionWrapper: CompletionBlock = { task, responseDict, error in
                // TODO :: need abstract the respons error checking
                if let messagesArray = responseDict?["Messages"] as? [Dictionary<String,AnyObject>] {
                    let context = sharedCoreDataService.newMainManagedObjectContext()
                    context.performBlockAndWait() {
                        var error: NSError?
                        var messages = GRTJSONSerialization.mergeObjectsForEntityName(Message.Attributes.entityName, fromJSONArray: messagesArray, inManagedObjectContext: context, error: &error)
                        if error == nil {
                            //                            for message in messages as! [Message] {
                            //                                // PRO-157 - The issue for inbox <--> starred page switch
                            //                                // only change the location if the message is new or not starred
                            //                                // this prevents starred messages from disappearing out of the inbox until the next refresh
                            //                                if message.inserted || location != .starred {
                            //                                    message.locationNumber = location.rawValue
                            //                                }
                            //                            }
                            error = context.saveUpstreamIfNeeded()
                        }
                        if error != nil  {
                            NSLog("\(__FUNCTION__) error: \(error)")
                        }
                        
                        
                        if (messages != nil && messages.last != nil && messages.first != nil) {
                            var updateTime = lastUpdatedStore.inboxLastForKey(location)
                            
                            if (updateTime.isNew) {
                                let mf = messages.first as! Message
                                updateTime.start = mf.time!
                            }
                            let ml = messages.last as! Message
                            updateTime.end = ml.time!
                            updateTime.update = NSDate()
                            lastUpdatedStore.updateInboxForKey(location, updateTime: updateTime)
                        }
                        
                        dispatch_async(dispatch_get_main_queue()) {
                            if MessageID == "0" && Time == 0 {
                                //TODO : fix the last update
                                //self.lastUpdatedStore[location.key] = lastUpdated
                            }
                            completion?(task: task, response: responseDict, error: error)
                        }
                    }
                } else {
                    completion?(task: task, response: responseDict, error: NSError.unableToParseResponse(responseDict))
                }
            }
            
            let request = MessageFetchRequest(location: location, endTime: Time);
            sharedAPIService.GET(request, completion: completionWrapper)
        }
    }
    
    /**
    fetch the new messages use the events log
    
    :param: Time       latest message time
    :param: completion complete handler
    */
    
    func fetchNewMessagesForLocation(location: MessageLocation, Time: Int, completion: CompletionBlock?) {
        queue {
            let eventAPI = EventCheckRequest<EventCheckResponse>(eventID: lastUpdatedStore.lastEventID)
            eventAPI.call() { task, response, hasError in
                
                if response == nil || response!.isRefresh || (hasError && response!.code == 18001) {
                    
                    let getLatestEventID = EventLatestIDRequest<EventLatestIDResponse>()
                    getLatestEventID.call() { task, response, hasError in
                        if response != nil && !hasError && !response!.eventID.isEmpty {
                            lastUpdatedStore.clear();
                            lastUpdatedStore.lastEventID = response!.eventID
                            self.cleanMessage()
                            self.fetchMessagesForLocation(location, MessageID: "", Time: 0, completion: completion)
                        }
                    }
                    completion?(task: task, response:nil, error: nil)
                }
                else if response!.messages != nil {
                    self.processIncrementalUpdateMessages(response!.messages!, task: task) { task, res, error in
                        if error == nil {
                            lastUpdatedStore.lastEventID = response!.eventID
                            completion?(task: task, response:nil, error: nil)
                        }
                        else {
                            completion?(task: task, response:nil, error: error)
                        }
                    }
                }
                else {
                    if response!.code == 1000 {
                        lastUpdatedStore.lastEventID = response!.eventID
                    }
                    completion?(task: task, response:nil, error: nil)
                }
            }
        }
    }
    
    
    /**
    this function to process the event logs
    
    :param: messages   the message event log
    :param: task       NSURL session task
    :param: completion complete call back
    */
    private func processIncrementalUpdateMessages(messages: Array<Dictionary<String, AnyObject>>, task: NSURLSessionDataTask!, completion: CompletionBlock?) {
        struct IncrementalUpdateType {
            static let delete = 0
            static let insert = 1
            static let updateDraft = 2
            static let update = 3
        }
        
        // this serial dispatch queue prevents multiple messages from appearing when an incremental update is triggered while another is in progress
        dispatch_sync(self.incrementalUpdateQueue) {
            let context = sharedCoreDataService.newMainManagedObjectContext()
            
            context.performBlockAndWait { () -> Void in
                var error: NSError?
                
                for message in messages {
                    let msg = MessageEvent(event: message)
                    
                    switch(msg.Action) {
                    case .Some(IncrementalUpdateType.delete):
                        if let messageID = msg.ID {
                            if let message = Message.messageForMessageID(messageID, inManagedObjectContext: context) {
                                context.deleteObject(message)
                            }
                        }
                    case .Some(IncrementalUpdateType.insert), .Some(IncrementalUpdateType.update):
                        if let messageObject = GRTJSONSerialization.mergeObjectForEntityName(Message.Attributes.entityName, fromJSONDictionary: msg.message, inManagedObjectContext: context, error: &error) as? NSManagedObject {
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
                    completion?(task: task, response:nil, error: error)
                    return
                }
            }
        }
    }
    
    
    
    
    
    
    
    
//                if let Jiao = responseDict?["Messages"] as? [Dictionary<String,AnyObject>] {
//                    let context = sharedCoreDataService.newManagedObjectContext()
//                    context.performBlockAndWait() {
//                        var error: NSError?
//                        var messages = GRTJSONSerialization.mergeObjectsForEntityName(Message.Attributes.entityName, fromJSONArray: messagesArray, inManagedObjectContext: context, error: &error)
//                        
//                        if error == nil {
//                            //                            for message in messages as! [Message] {
//                            //                                // PRO-157 - The issue for inbox <--> starred page switch
//                            //                                // only change the location if the message is new or not starred
//                            //                                // this prevents starred messages from disappearing out of the inbox until the next refresh
//                            //                                if message.inserted || location != .starred {
//                            //                                    message.locationNumber = location.rawValue
//                            //                                }
//                            //                            }
//                            error = context.saveUpstreamIfNeeded()
//                        }
//                        if error != nil  {
//                            NSLog("\(__FUNCTION__) error: \(error)")
//                        }
//                        
//                        var updateTime = lastUpdatedStore.inboxLastForKey(location)
//                        for msg in messages {
//                            let m = msg as! Message
//                            if (m.location == location) {
//                                updateTime.start = m.time!
//                                updateTime.update = NSDate()
//                                lastUpdatedStore.updateInboxForKey(location, updateTime: updateTime)
//                                break;
//                            }
//                        }
//                        
//                        dispatch_async(dispatch_get_main_queue()) {
//                            completion?(task: task, response: responseDict, error: error)
//                        }
//                    }
//                } else {
//                    completion?(task: task, response: responseDict, error: NSError.unableToParseResponse(responseDict))
//                }
//                
//            }
//            
//        }
//    }
//    
    
    //        let lastUpdatedCuttoff = NSDate(timeIntervalSinceNow: -lastUpdatedMaximumTimeInterval)
    //
    //        if updateTime.update.compare(lastUpdatedCuttoff) == .OrderedAscending {
    //            // use paging
    //            fetchMessagesForLocation(location, MessageID: "0", Time: 0, completion: completion)
    //            //fetchMessagesForLocation(location, page: firstPage, completion: completion)
    //        } else {
    //            // use incremental
    //            let lastUpdated = NSDate()
    //
    //            let completionWrapper: CompletionBlock = { task, response, error in
    //                if error == nil {
    //                    self.lastUpdatedStore[location.key] = lastUpdated
    //                }
    //
    //                completion?(task: task, response: response, error: error)
    //            }
    //
    //            fetchMessageIncrementalUpdates(lastUpdated: locationLastUpdated, completion: completionWrapper)
    //        }
    //    }
    
//    private func fetchMessageIncrementalUpdates(#lastUpdated: NSDate, completion: CompletionBlock?) {
//        struct ResponseKey {
//            static let code = "code"
//            static let message = "message"
//            static let response = "response"
//        }
//        
//        let validResponse = 1000
//        
//        queue { () -> Void in
//            let completionWrapper: CompletionBlock = { task, response, error in
//                if error != nil {
//                    completion?(task: task, response: nil, error: error)
//                    return
//                }
//                
//                if let code = response?[ResponseKey.code] as? Int {
//                    if code == validResponse {
//                        if let response = response?[ResponseKey.response] as? Dictionary<String, AnyObject> {
//                            if let messages = response[ResponseKey.message] as? Array<Dictionary<String, AnyObject>> {
//                                if messages.isEmpty {
//                                    completion?(task: task, response: nil, error: nil)
//                                } else {
//                                    self.processIncrementalUpdateMessages(messages, task: task, completion: completion)
//                                }
//                                
//                                return
//                            }
//                        }
//                    }
//                }
//                
//                completion?(task: task, response: nil, error: NSError.unableToParseResponse(response))
//            }
//            
//            sharedAPIService.messageCheck(timestamp: lastUpdated.timeIntervalSince1970, completion: completionWrapper)
//        }
//    }
    
    
    

    // old functions
    
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
    
    
//    func fetchMessageCountForInbox() {
//        fetchMessageCountForLocation(.inbox, completion: { (task, response, error) -> Void in
//            if let unreadCount = response?[Key.unread] as? Int {
//                UIApplication.sharedApplication().applicationIconBadgeNumber = unreadCount
//            }
//        })
//    }
    
//    func fetchMessageCountForLocation(location: MessageLocation, completion: CompletionBlock?) {
//        queue { () -> Void in
//            let completionWrapper: CompletionBlock = {task, response, error in
//                let countInfo: Dictionary<String, Int> = [
//                    Key.unread : response?["UnRead"] as? Int ?? 0,
//                    Key.read : response?["Read"] as? Int ?? 0,
//                    Key.total : response?["Total"] as? Int ?? 0]
//                
//                completion?(task: task, response: countInfo, error: error)
//            }
//            
//            sharedAPIService.messageCountForLocation(location.rawValue, completion: completionWrapper)
//        }
//    }
    
    func fetchMessageDetailForMessage(message: Message, completion: CompletionFetchDetail) {
        if !message.isDetailDownloaded {
            queue {
                let completionWrapper: CompletionBlock = { task, response, error in
                    let context = sharedCoreDataService.newMainManagedObjectContext()
                    
                    context.performBlockAndWait() {
                        var error: NSError?
                        
                        if response != nil {
                            //TODO need check the respons code
                            let msg = response?["Message"] as! Dictionary<String,AnyObject>
                            let message_n = GRTJSONSerialization.mergeObjectForEntityName(Message.Attributes.entityName, fromJSONDictionary: msg, inManagedObjectContext: context, error: &error) as! Message
                            if error == nil {
                                message_n.isDetailDownloaded = true
                                message_n.isRead = true
                                error = context.saveUpstreamIfNeeded()
                                dispatch_async(dispatch_get_main_queue()) {
                                    completion(task: task, response: response, message: message_n, error: error)
                                }
                            }
                        } else {
                            error = NSError.unableToParseResponse(response)
                            dispatch_async(dispatch_get_main_queue()) {
                                completion(task: task, response: response, message:nil, error: error)
                            }
                        }
                        if error != nil  {
                            NSLog("\(__FUNCTION__) error: \(error)")
                        }
                    }
                }
                sharedAPIService.messageDetail(messageID: message.messageID, completion: completionWrapper)
            }
        } else {
            completion(task: nil, response: nil, message:nil, error: nil)
        }
    }
    
    
    
    
    
    // MARK : fuctions for only fetch the local cache
    
    /**
    fetch the message by location from local cache
    
    :param: location message location enum
    
    :returns: NSFetchedResultsController
    */
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
    
    /**
    fetch the message from local cache use message id
    
    :param: messageID String
    
    :returns: NSFetchedResultsController
    */
    func fetchedMessageControllerForID(messageID: String) -> NSFetchedResultsController? {
        if let moc = managedObjectContext {
            let fetchRequest = NSFetchRequest(entityName: Message.Attributes.entityName)
            
            
            fetchRequest.predicate = NSPredicate(format: "%K == %@", Message.Attributes.messageID, messageID)
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: Message.Attributes.time, ascending: false)]
            return NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: moc, sectionNameKeyPath: nil, cacheName: nil)
        }
        
        return nil
    }
    
    /**
    delete the message from local cache only use the message id
    
    :param: messageID String
    */
    func deleteMessage(messageID : String) {
        if let context = sharedCoreDataService.mainManagedObjectContext {
            
            if let message = Message.messageForMessageID(messageID, inManagedObjectContext: context) {
                context.deleteObject(message)
            }
            if let error = context.saveUpstreamIfNeeded() {
                NSLog("\(__FUNCTION__) error: \(error)")
                
            }
        }
    }
    
    
    /**
    clean up function for clean up the local cache this will be called when:
    
    1. logout.
    2. use cache version bad.
    3. when session expired.
    
    */
    func launchCleanUpIfNeeded() {
        if !sharedUserDataService.isUserCredentialStored || !userCachedStatus.isCacheOk() {
            cleanUp()
            userCachedStatus.resetCache()
            //need add not clean the important infomation here.
        }
    }
    
    /**
    clean all the local cache data.
    when use this :
    1. logout
    2. local cache version changed
    3. hacked action detacted
    4. use wraped manully.
    */
    private func cleanUp() {
        if let context = managedObjectContext {
            Message.deleteAll(inContext: context)
        }
        //TODO : need check is attachments cleaned .
        
        lastUpdatedStore.clear()
        sharedMessageQueue.clear()
        sharedFailedQueue.clear()
        
        //tempary for clean contact cache
        sharedContactDataService.cleanUp()
        
        UIApplication.sharedApplication().applicationIconBadgeNumber = 0
    }
    
    private func cleanMessage() {
        if let context = managedObjectContext {
            Message.deleteAll(inContext: context)
        }
         UIApplication.sharedApplication().applicationIconBadgeNumber = 0
    }
    
    
    
    
    func search(#query: String, page: Int, managedObjectContext context: NSManagedObjectContext, completion: (([Message]?, NSError?) -> Void)?) {
        queue {
            let completionWrapper: CompletionBlock = {task, response, error in
                if error != nil {
                    completion?(nil, error)
                }
                
                if let messagesArray = response?["Messages"] as? [Dictionary<String,AnyObject>] {
                    
                    context.performBlockAndWait() {
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
    
    func saveDraft(message : Message!) {
        if let context = sharedCoreDataService.mainManagedObjectContext {
            if let error = context.saveUpstreamIfNeeded() {
                NSLog("\(__FUNCTION__) error: \(error)")
            } else {
                queue(message: message, action: .saveDraft)
            }
        }
    }
    
    func deleteDraft (message : Message!)
    {
        if let context = sharedCoreDataService.mainManagedObjectContext {
            if let error = context.saveUpstreamIfNeeded() {
                NSLog("\(__FUNCTION__) error: \(error)")
            } else {
                queue(message: message, action: .delete)
            }
        }
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
    
    private func generatMessagePackage<T : ApiResponse> (message: Message!, keys : [String : AnyObject]?, atts : [Attachment], encrptOutside : Bool) -> MessageSendRequest<T>! {
        
        var tempAtts : [TempAttachment]! = []
        for att in atts {
            
            let sessionKey = att.getSessionKey(nil)
            
            tempAtts.append(TempAttachment(id: att.attachmentID, key: sessionKey!))
        }
        
        var out : [MessagePackage] = []
        var needsPlainText : Bool = false
        let outRequest : MessageSendRequest = MessageSendRequest<T>(messageID: message.messageID, messagePackage: nil, clearBody: "", attPackages: nil)
        
        var error: NSError?
        if let body = message.decryptBody(&error) {
            
            for (key, v) in keys! {
                
                if key == "Code" {
                    continue
                }
                
                let publicKey = v as! String
                let isOutsideUser = publicKey.isEmpty
                let password = "123"
                
                if isOutsideUser {
                    if encrptOutside {
                        
                        let encryptedBody = body.encryptWithPassphrase(message.password, error: &error)
                        //create outside encrypt packet
                        let token = String.randomString(32)
                        let encryptedToken = token.encryptWithPassphrase(message.password, error: &error)
                        
                        
                        // encrypt keys use public key
                        var attPack : [AttachmentKeyPackage] = []
                        for att in tempAtts {
                            //attID:String!, attKey:String!, Algo : String! = ""
                            
//                            let keyAol : NSData = NSData(bytes: [0x09] as [UInt8], length: 1)
//                            var newKeydata = NSMutableData()
//                            newKeydata.appendData(keyAol)
//                            newKeydata.appendData(att.Key)
//                            
//                            let sessionKey : NSData = newKeydata.copy() as! NSData
//                            
//                            
                            let newKeyPack = att.Key.getSymmetricSessionKeyPackage(message.password, error: nil)?.base64EncodedStringWithOptions(nil)
                            let attPacket = AttachmentKeyPackage(attID: att.ID, attKey: newKeyPack)
                            attPack.append(attPacket)
                        }
                        
                        var pack = MessagePackage(address: key, type: 2,  body: encryptedBody, attPackets:attPack, token: token.encodeBase64(), encToken: encryptedToken, passwordHint: message.passwordHint)
                        out.append(pack)
                        
                        // encrypt keys use pwd .
                    }
                    else {
                        needsPlainText = true
                    }
                }
                else {
                    
                    // encrypt keys use public key
                    var attPack : [AttachmentKeyPackage] = []
                    for att in tempAtts {
                        //attID:String!, attKey:String!, Algo : String! = ""
                        let newKeyPack = att.Key.getPublicSessionKeyPackage(publicKey, error: nil)?.base64EncodedStringWithOptions(nil)
                        let attPacket = AttachmentKeyPackage(attID: att.ID, attKey: newKeyPack)
                        attPack.append(attPacket)
                    }
                    
                    //create inside packet
                    if let encryptedBody = body.encryptWithPublicKey(publicKey, error: &error) {
                        var pack = MessagePackage(address: key, type: 1, body: encryptedBody, attPackets: attPack)
                        out.append(pack)
                    } else {
                        NSLog("\(__FUNCTION__) can't encrypt body for \(body) with error: \(error)")
                    }
                }
            }
            
            outRequest.messagePackage = out
            
            if needsPlainText {
                outRequest.clearBody = body
                
                
                //add attachment package
                var attPack : [AttachmentKeyPackage] = []
                for att in tempAtts {
                    //attID:String!, attKey:String!, Algo : String! = ""
                    let newKeyPack = att.Key.base64EncodedStringWithOptions(nil)
                    let attPacket = AttachmentKeyPackage(attID: att.ID, attKey: newKeyPack, Algo: "aes256")
                    attPack.append(attPacket)
                }
                
                outRequest.attPackets = attPack
                
            }
            
        } else {
            NSLog("\(__FUNCTION__) unable to decrypt \(message.body) with error: \(error)")
        }
        
        return outRequest
    }
    
    
    
    // MARK : old functions
    
    
    private func attachmentsForMessage(message: Message) -> [Attachment] {
        return message.attachments.allObjects as! [Attachment]
        //        var attachments: [MessageAPI.Attachment] = []
        //
        //        for messageAttachment in message.attachments.allObjects as! [Attachment] {
        //            if let fileDataBase64Encoded = messageAttachment.fileData?.base64EncodedStringWithOptions(nil) {
        //                let attachment = MessageAPI.Attachment(fileName: messageAttachment.fileName, mimeType: messageAttachment.mimeType, fileData: ["self" : fileDataBase64Encoded], fileSize: messageAttachment.fileSize.integerValue)
        //
        //                attachments.append(attachment)
        //            }
        //        }
        //
        //        return attachments
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

    
    private func saveDraftWithMessageID(messageID: String, writeQueueUUID: NSUUID, completion: CompletionBlock?) {
        if let context = managedObjectContext {
            var error: NSError?
            if let objectID = sharedCoreDataService.managedObjectIDForURIRepresentation(messageID) {
                if let message = context.existingObjectWithID(objectID, error: &error) as? Message {
                    let attachments = self.attachmentsForMessage(message)
                    
                    let completionWrapper: CompletionBlock = { task, response, error in
                        
                        if let mess = response?["Message"] as? Dictionary<String, AnyObject> {
                            if let messageID = mess["ID"] as? String {
                                message.messageID = messageID
                                message.isDetailDownloaded = true
                                if let error = context.saveUpstreamIfNeeded() {
                                    NSLog("\(__FUNCTION__) error: \(error)")
                                }
                            }
                        }
                        completion?(task: task, response: response, error: error)
                    }
                    
                    if message.isDetailDownloaded && message.messageID != "0" {
                       sharedAPIService.PUT(MessageUpdateDraftRequest<ApiResponse>(message:message), completion: completionWrapper)
                    } else {
                       sharedAPIService.POST(MessageDraftRequest<ApiResponse>(message:message), completion: completionWrapper)
                    }
                    return;
                }
            }
        }
        
        // nothing to send, dequeue request
        sharedMessageQueue.remove(elementID: writeQueueUUID)
        self.dequeueIfNeeded()
        
        completion?(task: nil, response: nil, error: NSError.badParameter(messageID))
    }
    
    private func uploadAttachmentWithAttachmentID (addressID: String, writeQueueUUID: NSUUID, completion: CompletionBlock?) {
        if let context = managedObjectContext {
            var error: NSError?
            if let objectID = sharedCoreDataService.managedObjectIDForURIRepresentation(addressID) {
                if let attachment = context.existingObjectWithID(objectID, error: &error) as? Attachment {
                    
                    var params = [
                        "Filename":attachment.fileName,
                        "MessageID" : attachment.message.messageID,
                        "MIMEType" : attachment.mimeType,
                    ]
                    
                    let encrypt_data = attachment.encryptAttachment(nil)
                    let keyPacket = encrypt_data!["self"] as! NSData
                    let dataPacket = encrypt_data!["DataPacket"] as! NSData
                    
                    let completionWrapper: CompletionBlock = { task, response, error in
                        
                        if error == nil {
                            if let messageID = response?["AttachmentID"] as? String {
                                attachment.attachmentID = messageID
                                attachment.keyPacket = keyPacket.base64EncodedStringWithOptions(nil)
                                
                                if let error = context.saveUpstreamIfNeeded() {
                                    NSLog("\(__FUNCTION__) error: \(error)")
                                }
                            }
                        }
                        completion?(task: task, response: response, error: error)
                    }
                    
                    sharedAPIService.upload( AppConstants.BaseURLString + "/attachments/upload", parameters: params, keyPackets: keyPacket, dataPacket: dataPacket, completion: completionWrapper)
                    
                    return
                }
            }
        }
        
        // nothing to send, dequeue request
        sharedMessageQueue.remove(elementID: writeQueueUUID)
        self.dequeueIfNeeded()
        
        completion?(task: nil, response: nil, error: NSError.badParameter(addressID))
    }
    
    private func sendMessageID(messageID: String, writeQueueUUID: NSUUID, completion: CompletionBlock?) {
        let errorBlock: CompletionBlock = { task, response, error in
            // nothing to send, dequeue request
            sharedMessageQueue.remove(elementID: writeQueueUUID)
            self.dequeueIfNeeded()
            completion?(task: task, response: response, error: error)
        }
        
        if let context = managedObjectContext {
            var error: NSError?
            if let objectID = sharedCoreDataService.managedObjectIDForURIRepresentation(messageID) {
                if let message = context.existingObjectWithID(objectID, error: &error) as? Message {
                    let attachments = self.attachmentsForMessage(message)
                    
                    sharedAPIService.userPublicKeysForEmails(message.allEmailAddresses, completion: { (task, response, error) -> Void in
                        if error != nil && error!.code == APIService.ErrorCode.badParameter {
                            errorBlock(task: task, response: response, error: error)
                            return
                        }
                        
                        let isEncryptOutside = !message.password.isEmpty
                        
                        let attachments = self.attachmentsForMessage(message)
                        
                        // create package for internal
                        let sendMessage = self.generatMessagePackage(message, keys: response, atts:attachments, encrptOutside: isEncryptOutside)
                        
                        // parse the response for keys
                        let messageBody = self.messageBodyForMessage(message, response: response)
                        
                        
                        // build the encrypt bodys
                        
                        
                        // build clear output
                        
                        let completionWrapper: CompletionBlock = { task, response, error in
                            // remove successful send from Core Data
                            if error == nil {
                                //TODO : here need to handle the response have the error code
                                context.deleteObject(message)
                                if let error = context.saveUpstreamIfNeeded() {
                                    NSLog("\(__FUNCTION__) error: \(error)")
                                }
                            }
                            completion?(task: task, response: response, error: error)
                            return
                        }
                        
                        sharedAPIService.POST(sendMessage, completion: completionWrapper)
                    })
                    
                    return
                }
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
    private func writeQueueCompletionBlockForElementID(elementID: NSUUID, messageID : String, actionString : String) -> CompletionBlock {
        return { task, response, error in
            sharedMessageQueue.isInProgress = false
            if error == nil {
                if let action = MessageAction(rawValue: actionString) {
                    if action == MessageAction.delete {
                        self.deleteMessage(messageID)
                    }
                }
                sharedMessageQueue.remove(elementID: elementID)
                self.dequeueIfNeeded()
            } else {
                NSLog("\(__FUNCTION__) error: \(error)")
                
                var statusCode = 200;
                var isInternetIssue = false
                if let errorUserInfo = error?.userInfo {
                    if let detail = errorUserInfo["com.alamofire.serialization.response.error.response"] as? NSHTTPURLResponse {
                        statusCode = detail.statusCode
                    }
                    else {
                        //                        if(error?.code == -1001) {
                        //                            // request timed out
                        //                        }
                        if error?.code == -1009 || error?.code == -1004 || error?.code == -1001 { //internet issue
                            isInternetIssue = true
                        }
                    }
                }
                
                if (statusCode == 404)
                {
                    if  let (uuid, object: AnyObject) = sharedMessageQueue.next() {
                        if let element = object as? [String : String] {
                            let count = element["count"]
                            sharedMessageQueue.remove(elementID: elementID)
                        }
                    }
                }
                
                //need add try times and check internet status
                if statusCode == 500 && !isInternetIssue {
                    if  let (uuid, object: AnyObject) = sharedMessageQueue.next() {
                        if let element = object as? [String : String] {
                            let count = element["count"]
                            sharedFailedQueue.add(uuid, object: element)
                            sharedMessageQueue.remove(elementID: elementID)
                        }
                    }
                }
                self.dequeueIfNeeded()
            }
        }
    }
    
    private func dequeueIfNeeded() {
        //return
        if let (uuid, messageID, actionString) = sharedMessageQueue.nextMessage() {
            if let action = MessageAction(rawValue: actionString) {
                sharedMessageQueue.isInProgress = true
                switch action {
                case .saveDraft:
                    saveDraftWithMessageID(messageID, writeQueueUUID: uuid, completion: writeQueueCompletionBlockForElementID(uuid, messageID: messageID, actionString: actionString))
                case .send:
                    sendMessageID(messageID, writeQueueUUID: uuid, completion: writeQueueCompletionBlockForElementID(uuid, messageID: messageID, actionString: actionString))
                case .uploadAtt:
                    uploadAttachmentWithAttachmentID(messageID, writeQueueUUID: uuid, completion: writeQueueCompletionBlockForElementID(uuid, messageID: messageID, actionString: actionString))
                default:
                    sharedAPIService.PUT(MessageActionRequest<ApiResponse>(action: actionString, ids: [messageID]), completion: writeQueueCompletionBlockForElementID(uuid, messageID: messageID, actionString: actionString))
                }
            } else {
                NSLog("\(__FUNCTION__) Unsupported action \(actionString), removing from queue.")
                sharedMessageQueue.remove(elementID: uuid)
            }
        } else if !sharedMessageQueue.isBlocked && readQueue.count > 0 { //sharedMessageQueue.count == 0 &&
            readQueue.removeAtIndex(0)()
            dequeueIfNeeded()
        }
    }
    
    
    
    private func queue(#message: Message, action: MessageAction) {
        if action == .saveDraft || action == .send {
            sharedMessageQueue.addMessage(message.objectID.URIRepresentation().absoluteString!, action: action)
        } else {
            sharedMessageQueue.addMessage(message.messageID, action: action)
        }
        dequeueIfNeeded()
    }
    
    private func queue(#att: Attachment, action: MessageAction) {
        sharedMessageQueue.addMessage(att.objectID.URIRepresentation().absoluteString!, action: action)
        dequeueIfNeeded()
    }
    
    
    private func queue(#readBlock: ReadBlock) {
        readQueue.append(readBlock)
        dequeueIfNeeded()
    }
    
    // MARK: Setup
    private func setupMessageMonitoring() {
        sharedMonitorSavesDataService.registerMessage(attribute: Message.Attributes.locationNumber, handler: { message in
            if message.needsUpdate {
                if let action = message.location.moveAction {
                    self.queue(message: message, action: action)
                } else {
                    NSLog("\(__FUNCTION__) \(message.messageID) move to \(message.location) was not a user initiated move.")
                }
            }
        })
        
        sharedMonitorSavesDataService.registerMessage(attribute: Message.Attributes.isRead, handler: { message in
            if message.needsUpdate {
                let action: MessageAction = message.isRead ? .read : .unread
                self.queue(message: message, action: action)
            }
        })
        
        sharedMonitorSavesDataService.registerMessage(attribute: Message.Attributes.isStarred, handler: { message in
            if message.needsUpdate {
                let action: MessageAction = message.isStarred ? .star : .unstar
                self.queue(message: message, action: action)
            }
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
    func fetchDetailIfNeeded(completion: MessageDataService.CompletionFetchDetail) {
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
