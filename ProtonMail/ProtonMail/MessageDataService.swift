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

import Foundation
import CoreData

let sharedMessageDataService = MessageDataService()

class MessageDataService {
    typealias CompletionBlock = APIService.CompletionBlock
    typealias CompletionFetchDetail = APIService.CompletionFetchDetail
    typealias ReadBlock = (() -> Void)
    
    var pushNotificationMessageID : String? = nil
    
    struct Key {
        static let read = "read"
        static let total = "total"
        static let unread = "unread"
    }
    
    private let incrementalUpdateQueue = dispatch_queue_create("ch.protonmail.incrementalUpdateQueue", DISPATCH_QUEUE_SERIAL)
    private let lastUpdatedMaximumTimeInterval: NSTimeInterval = 24 /*hours*/ * 3600
    private let maximumCachedMessageCount = 5000
    
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
                PMLog.D("error: \(error)")
                dequeueIfNeeded()
            } else {
                queue(att, action: .uploadAtt)
            }
        }
    }
    
    func deleteAttachment(messageid : String, att: Attachment!)
    {
        let out : [String : AnyObject] = ["MessageID" : messageid, "AttachmentID" : att.attachmentID]
        if let context = sharedCoreDataService.mainManagedObjectContext {
            context.deleteObject(att)
            if let error = context.saveUpstreamIfNeeded() {
                PMLog.D(" error: \(error)")
            }
        }
        sharedMessageQueue.addMessage(out.JSONStringify(false), action: .deleteAtt)
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
                    PMLog.D(" error: \(error)")
                } else {
                    queue(message, action: .send)
                }
            } else {
                //TODO:: handle can't find the message error.
            }
            
        } else {
            error = NSError.protonMailError(code: 500, localizedDescription: NSLocalizedString("No managedObjectContext"), localizedFailureReason: nil, localizedRecoverySuggestion: nil)
        }
        completion?(task: nil, response: nil, error: error)
    }
    
    
    //
    func emptyTrash() {
        if Message.deleteLocation(MessageLocation.trash) {
            queue(.emptyTrash)
        }
    }
    
    func emptySpam() {
        if Message.deleteLocation(MessageLocation.spam) {
            queue(.emptySpam)
        }
    }
    
    // MARK : fetch functions
    
    
    /**
     nonmaly fetching the message from server based on location and time.
     
     :param: location   mailbox location
     :param: MessageID  mesasge id not inuse for now
     :param: Time       the latest update time
     :param: completion aync complete handler
     */
    func fetchMessagesForLocation(location: MessageLocation, MessageID : String, Time: Int, foucsClean: Bool, completion: CompletionBlock?) {
        queue {
            let completionWrapper: CompletionBlock = { task, responseDict, error in
                if let messagesArray = responseDict?["Messages"] as? [Dictionary<String,AnyObject>] {
                    let messcount = responseDict?["Total"] as? Int ?? 0
                    let context = sharedCoreDataService.newMainManagedObjectContext()
                    context.performBlock() {
                        if foucsClean {
                            self.cleanMessage()
                            context.saveUpstreamIfNeeded()
                        }
                        do {
                            if let messages = try GRTJSONSerialization.objectsWithEntityName(Message.Attributes.entityName, fromJSONArray: messagesArray, inContext: context) as? [Message] {
                                for message in messages {
                                    message.messageStatus = 1
                                }
                                if let error = context.saveUpstreamIfNeeded() {
                                    PMLog.D(" error: \(error)")
                                }
                                if let lastMsg = messages.last, let firstMsg = messages.first {
                                    let updateTime = lastUpdatedStore.inboxLastForKey(location)
                                    if (updateTime.isNew) {
                                        updateTime.start = firstMsg.time!
                                        updateTime.total = Int32(messcount)
                                    }
                                    if let time = lastMsg.time {
                                        updateTime.end = time
                                    }
                                    updateTime.update = NSDate()
                                    lastUpdatedStore.updateInboxForKey(location, updateTime: updateTime)
                                }
                                
                                dispatch_async(dispatch_get_main_queue()) {
                                    completion?(task: task, response: responseDict, error: error)
                                }
                            }
                            dispatch_async(dispatch_get_main_queue()) {
                                completion?(task: task, response: responseDict, error: error)
                            }
                        } catch let ex as NSError {
                            PMLog.D("error: \(ex)")
                            dispatch_async(dispatch_get_main_queue()) {
                                completion?(task: task, response: responseDict, error: ex)
                            }
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
    
    func fetchMessagesForLabels(labelID : String, MessageID : String, Time: Int, foucsClean: Bool, completion: CompletionBlock?) {
        queue {
            let completionWrapper: CompletionBlock = { task, responseDict, error in
                // TODO :: need abstract the respons error checking
                if let messagesArray = responseDict?["Messages"] as? [Dictionary<String,AnyObject>] {
                    let messcount = responseDict?["Total"] as? Int ?? 0
                    let context = sharedCoreDataService.newMainManagedObjectContext()
                    context.performBlock() {
                        if foucsClean {
                            self.cleanMessage()
                            context.saveUpstreamIfNeeded()
                        }
                        do {
                            if let messages = try GRTJSONSerialization.objectsWithEntityName(Message.Attributes.entityName, fromJSONArray: messagesArray, inContext: context) as? [Message] {
                                for message in messages {
                                    message.messageStatus = 1
                                }
                                if let error = context.saveUpstreamIfNeeded() {
                                    PMLog.D(" error: \(error)")
                                }
                                if let lastMsg = messages.last, let firstMsg = messages.first {
                                    let updateTime = lastUpdatedStore.labelsLastForKey(labelID)
                                    if (updateTime.isNew) {
                                        updateTime.start = firstMsg.time!
                                        updateTime.total = Int32(messcount)
                                    }
                                    updateTime.end = lastMsg.time!
                                    updateTime.update = NSDate()
                                    
                                    lastUpdatedStore.updateLabelsForKey(labelID, updateTime: updateTime)
                                }
                            }
                            dispatch_async(dispatch_get_main_queue()) {
                                completion?(task: task, response: responseDict, error: error)
                            }
                        } catch let ex as NSError {
                            PMLog.D(" error: \(ex)")
                            dispatch_async(dispatch_get_main_queue()) {
                                completion?(task: task, response: responseDict, error: ex)
                            }
                        }
                    }
                } else {
                    completion?(task: task, response: responseDict, error: NSError.unableToParseResponse(responseDict))
                }
            }
            let request = MessageByLabelRequest(labelID: labelID, endTime: Time);
            sharedAPIService.GET(request, completion: completionWrapper)
        }
    }
    
    
    
    func fetchMessagesForLocationWithEventReset(location: MessageLocation, MessageID : String, Time: Int, completion: CompletionBlock?) {
        queue {
            let getLatestEventID = EventLatestIDRequest<EventLatestIDResponse>()
            getLatestEventID.call() { task, _IDRes, hasIDError in
                if let IDRes = _IDRes where !hasIDError && !IDRes.eventID.isEmpty {
                    let completionWrapper: CompletionBlock = { task, responseDict, error in
                        if error == nil {
                            lastUpdatedStore.clear()
                            lastUpdatedStore.lastEventID = IDRes.eventID
                        }
                        completion?(task: task, response:responseDict, error: error)
                    }
                    self.cleanMessage()
                    sharedContactDataService.cleanUp()
                    self.fetchMessagesForLocation(location, MessageID: MessageID, Time: Time, foucsClean: false, completion: completionWrapper)
                    sharedContactDataService.fetchContacts(nil)
                    sharedLabelsDataService.fetchLabels();
                }  else {
                    completion?(task: task, response:nil, error: nil)
                }
            }
        }
    }
    
    
    private var tempUnreadAddjustCount = 0
    /**
     fetch the new messages use the events log
     
     :param: Time       latest message time
     :param: completion complete handler
     */
    
    func fetchNewMessagesForLocation(location: MessageLocation, Time: Int, notificationMessageID : String?, completion: CompletionBlock?) {
        queue {
            let eventAPI = EventCheckRequest<EventCheckResponse>(eventID: lastUpdatedStore.lastEventID)
            eventAPI.call() { task, _eventsRes, _hasEventsError in
                if let eventsRes = _eventsRes {
                    PMLog.D("\(eventsRes)")
                    if eventsRes.isRefresh || (_hasEventsError && eventsRes.code == 18001) {
                        let getLatestEventID = EventLatestIDRequest<EventLatestIDResponse>()
                        getLatestEventID.call() { task, _IDRes, hasIDError in
                            if let IDRes = _IDRes where !hasIDError && !IDRes.eventID.isEmpty {
                                let completionWrapper: CompletionBlock = { task, responseDict, error in
                                    if error == nil {
                                        lastUpdatedStore.clear()
                                        lastUpdatedStore.lastEventID = IDRes.eventID
                                    }
                                    completion?(task: task, response:responseDict, error: error)
                                }
                                self.cleanMessage()
                                sharedContactDataService.cleanUp()
                                self.fetchMessagesForLocation(location, MessageID: "", Time: 0, foucsClean: false, completion: completionWrapper)
                                sharedContactDataService.fetchContacts(nil)
                                sharedLabelsDataService.fetchLabels();
                            } else {
                                completion?(task: task, response:nil, error: nil)
                            }
                        }
                    }
                    else if eventsRes.messages != nil {
                        self.processIncrementalUpdateMessages(notificationMessageID, messages: eventsRes.messages!, task: task) { task, res, error in
                            if error == nil {
                                lastUpdatedStore.lastEventID = eventsRes.eventID
                                self.processIncrementalUpdateUnread(eventsRes.unreads)
                                self.processIncrementalUpdateTotal(eventsRes.total)
                                self.processIncrementalUpdateUserInfo(eventsRes.userinfo)
                                self.processIncrementalUpdateLabels(eventsRes.labels)
                                self.processIncrementalUpdateContacts(eventsRes.contacts)
                                
                                var outMessages : [AnyObject] = [];
                                for message in eventsRes.messages! {
                                    let msg = MessageEvent(event: message)
                                    if msg.Action == 1 {
                                        outMessages.append(msg)
                                    }
                                }
                                completion?(task: task, response:["Messages": outMessages, "Notices": eventsRes.notices ?? [String]()], error: nil)
                            }
                            else {
                                completion?(task: task, response:nil, error: error)
                            }
                        }
                    }
                    else {
                        if eventsRes.code == 1000 {
                            lastUpdatedStore.lastEventID = eventsRes.eventID
                            self.processIncrementalUpdateUnread(eventsRes.unreads)
                            self.processIncrementalUpdateTotal(eventsRes.total)
                            self.processIncrementalUpdateUserInfo(eventsRes.userinfo)
                            self.processIncrementalUpdateLabels(eventsRes.labels)
                            self.processIncrementalUpdateContacts(eventsRes.contacts)
                        }
                        if _hasEventsError {
                            completion?(task: task, response:nil, error: eventsRes.error)
                        } else {
                            completion?(task: task, response:["Notices": eventsRes.notices ?? [String]()], error: nil)
                        }
                    }
                } else {
                    completion?(task: task, response:nil, error: nil)
                }
            }
        }
    }
    
    func fetchNewMessagesForLabels(labelID: String, Time: Int, notificationMessageID : String?, completion: CompletionBlock?) {
        queue {
            let eventAPI = EventCheckRequest<EventCheckResponse>(eventID: lastUpdatedStore.lastEventID)
            eventAPI.call() { task, response, hasError in
                if response == nil {
                    completion?(task: task, response:nil, error: nil)
                } else if response!.isRefresh || (hasError && response!.code == 18001) {
                    
                    let getLatestEventID = EventLatestIDRequest<EventLatestIDResponse>()
                    getLatestEventID.call() { task, response, hasError in
                        if response != nil && !hasError && !response!.eventID.isEmpty {
                            let completionWrapper: CompletionBlock = { task, responseDict, error in
                                if error == nil {
                                    lastUpdatedStore.clear();
                                    lastUpdatedStore.lastEventID = response!.eventID
                                }
                                completion?(task: task, response:nil, error: error)
                            }
                            self.cleanMessage()
                            sharedContactDataService.cleanUp()
                            self.fetchMessagesForLabels(labelID, MessageID: "", Time: 0, foucsClean: false, completion: completionWrapper)
                            sharedContactDataService.fetchContacts(nil)
                            sharedLabelsDataService.fetchLabels();
                        }
                    }
                    completion?(task: task, response:nil, error: nil)
                }
                else if response!.messages != nil {
                    self.processIncrementalUpdateMessages(notificationMessageID, messages: response!.messages!, task: task) { task, res, error in
                        if error == nil {
                            lastUpdatedStore.lastEventID = response!.eventID
                            completion?(task: task, response:nil, error: nil)
                        }
                        else {
                            completion?(task: task, response:nil, error: error)
                        }
                    }
                    
                    self.processIncrementalUpdateUnread(response!.unreads)
                    self.processIncrementalUpdateTotal(response!.total)
                    self.processIncrementalUpdateUserInfo(response!.userinfo)
                    self.processIncrementalUpdateLabels(response!.labels)
                    self.processIncrementalUpdateContacts(response!.contacts)
                }
                else {
                    if response!.code == 1000 {
                        lastUpdatedStore.lastEventID = response!.eventID
                        self.processIncrementalUpdateUnread(response!.unreads)
                        self.processIncrementalUpdateTotal(response!.total)
                        self.processIncrementalUpdateUserInfo(response!.userinfo)
                        self.processIncrementalUpdateLabels(response!.labels)
                        self.processIncrementalUpdateContacts(response!.contacts)
                    }
                    completion?(task: task, response:nil, error: nil)
                }
            }
        }
    }
    
    func processIncrementalUpdateContacts(contacts: [Dictionary<String,AnyObject>]?) {
        struct IncrementalContactUpdateType {
            static let delete = 0
            static let insert = 1
            static let update = 2
        }
        
        if let contacts = contacts {
            let context = sharedCoreDataService.newMainManagedObjectContext()
            context.performBlock { () -> Void in
                for contact in contacts {
                    let contactObj = ContactEvent(event: contact)
                    switch(contactObj.Action) {
                    case .Some(IncrementalContactUpdateType.delete):
                        if let contactID = contactObj.ID {
                            if let tempContact = Contact.contactForContactID(contactID, inManagedObjectContext: context) {
                                context.deleteObject(tempContact)
                            }
                        }
                    case .Some(IncrementalContactUpdateType.insert), .Some(IncrementalContactUpdateType.update) :
                        do {
                            if let insert_update_contacts = contactObj.contact {
                                try GRTJSONSerialization.objectWithEntityName(Contact.Attributes.entityName, fromJSONDictionary: insert_update_contacts, inContext: context)
                            }
                        } catch let ex as NSError {
                            PMLog.D(" error: \(ex)")
                        }
                    default:
                        PMLog.D(" unknown type in contact: \(contact)")
                    }
                }
                if let error = context.saveUpstreamIfNeeded()  {
                    PMLog.D(" error: \(error)")
                }
            }
        }
    }
    
    func processIncrementalUpdateTotal(totals: Dictionary<String, AnyObject>?) {
        
        if let star = totals?["Starred"] as? Int {
            let updateTime = lastUpdatedStore.inboxLastForKey(MessageLocation.starred)
            updateTime.total = Int32(star)
            lastUpdatedStore.updateInboxForKey(MessageLocation.starred, updateTime: updateTime)
        }
        
        if let locations = totals?["Locations"] as? [Dictionary<String,AnyObject>] {
            for location:[String : AnyObject] in locations {
                if let l = location["Location"] as? Int {
                    if let c = location["Count"] as? Int {
                        if let lo = MessageLocation(rawValue: l) {
                            let updateTime = lastUpdatedStore.inboxLastForKey(lo)
                            updateTime.total = Int32(c)
                            lastUpdatedStore.updateInboxForKey(lo, updateTime: updateTime)
                        }
                    }
                }
            }
        }
    }
    
    func processIncrementalUpdateUserInfo(userinfo: Dictionary<String, AnyObject>?) {
        if let userData = userinfo {
            let userInfo = UserInfo( response: userData )
            sharedUserDataService.updateUserInfoFromEventLog(userInfo);
        }
    }
    
    func processIncrementalUpdateLabels(labels: [Dictionary<String, AnyObject>]?) {
        
        struct IncrementalUpdateType {
            static let delete = 0
            static let insert = 1
            static let update = 2
        }
        
        if let labels = labels {
            // this serial dispatch queue prevents multiple messages from appearing when an incremental update is triggered while another is in progress
            dispatch_sync(self.incrementalUpdateQueue) {
                let context = sharedCoreDataService.newMainManagedObjectContext()
                context.performBlock { () -> Void in
                    for labelEvent in labels {
                        let label = LabelEvent(event: labelEvent)
                        switch(label.Action) {
                        case .Some(IncrementalUpdateType.delete):
                            if let labelID = label.ID {
                                if let dLabel = Label.labelForLableID(labelID, inManagedObjectContext: context) {
                                    context.deleteObject(dLabel)
                                }
                            }
                        case .Some(IncrementalUpdateType.insert), .Some(IncrementalUpdateType.update):
                            do {
                                if let new_or_update_label = label.label {
                                    try GRTJSONSerialization.objectWithEntityName(Label.Attributes.entityName, fromJSONDictionary: new_or_update_label, inContext: context)
                                }
                            } catch let ex as NSError {
                                PMLog.D(" error: \(ex)")
                            }
                        default:
                            PMLog.D(" unknown type in message: \(label)")
                        }
                    }
                    if let error = context.saveUpstreamIfNeeded(){
                        PMLog.D(" error: \(error)")
                    }
                }
            }
            
        }
    }
    
    func processIncrementalUpdateUnread(unreads: Dictionary<String, AnyObject>?) {
        
        var inboxCount : Int = 0;
        var draftCount : Int = 0;
        var sendCount : Int = 0;
        var spamCount : Int = 0;
        var starCount : Int = 0;
        var trashCount : Int = 0;
        
        
        if let star = unreads?["Starred"] as? Int {
            starCount = star;
        }
        
        if let locations = unreads?["Locations"] as? [Dictionary<String,AnyObject>] {
            lastUpdatedStore.resetUnreadCounts()
            for location:[String : AnyObject] in locations {
                
                if let l = location["Location"] as? Int {
                    if let c = location["Count"] as? Int {
                        if let lo = MessageLocation(rawValue: l) {
                            switch lo {
                            case .inbox:
                                inboxCount = c
                                inboxCount = inboxCount + tempUnreadAddjustCount
                                break;
                            case .draft:
                                draftCount = c
                                break;
                            case .outbox:
                                sendCount = c
                                break;
                            case .spam:
                                spamCount = c
                                break;
                            case .trash:
                                trashCount = c
                                break;
                            default:
                                break;
                            }
                            lastUpdatedStore.updateUnreadCountForKey(lo, count: c ?? 0)
                        }
                    }
                }
            }
            lastUpdatedStore.updateUnreadCountForKey(MessageLocation.starred, count: starCount ?? 0)
            
            //MessageLocation
            var badgeNumber = inboxCount //inboxCount + draftCount + sendCount + spamCount + starCount + trashCount;
            if  badgeNumber < 0 {
                badgeNumber = 0
            }
            UIApplication.sharedApplication().applicationIconBadgeNumber = badgeNumber
            tempUnreadAddjustCount = 0
        }
        
        if let locations = unreads?["Labels"] as? [Dictionary<String,AnyObject>] {
            lastUpdatedStore.resetLabelsUnreadCounts()
            for location:[String : AnyObject] in locations {
                
                if let l = location["LabelID"] as? String {
                    if let c = location["Count"] as? Int {
                        lastUpdatedStore.updateLabelsUnreadCountForKey(l, count: c)
                    }
                }
            }
        }
        PMLog.D("\(inboxCount + draftCount + sendCount + spamCount + starCount + trashCount)")
    }
    
    func cleanLocalMessageCache(completion: CompletionBlock?) {
        let getLatestEventID = EventLatestIDRequest<EventLatestIDResponse>()
        getLatestEventID.call() { task, response, hasError in
            if response != nil && !hasError && !response!.eventID.isEmpty {
                let completionWrapper: CompletionBlock = { task, responseDict, error in
                    if error == nil {
                        lastUpdatedStore.clear();
                        lastUpdatedStore.lastEventID = response!.eventID
                        
                    }
                    completion?(task: task, response:nil, error: error)
                }
                
                //if foucsClean {
                self.cleanMessage()
                //}
                sharedLabelsDataService.fetchLabels();
                self.fetchMessagesForLocation(MessageLocation.inbox, MessageID: "", Time: 0, foucsClean: false, completion: completionWrapper)
                
            }
        }
    }
    
    
    /**
     this function to process the event logs
     
     :param: messages   the message event log
     :param: task       NSURL session task
     :param: completion complete call back
     */
    private func processIncrementalUpdateMessages(notificationMessageID: String?, messages: Array<Dictionary<String, AnyObject>>, task: NSURLSessionDataTask!, completion: CompletionBlock?) {
        struct IncrementalUpdateType {
            static let delete = 0
            static let insert = 1
            static let update1 = 2
            static let update2 = 3
        }
        
        // this serial dispatch queue prevents multiple messages from appearing when an incremental update is triggered while another is in progress
        dispatch_sync(self.incrementalUpdateQueue) {
            let context = sharedCoreDataService.newMainManagedObjectContext()
            context.performBlock { () -> Void in
                var error: NSError?
                var messagesNoCache : [Message] = [];
                for message in messages {
                    let msg = MessageEvent(event: message)
                    switch(msg.Action) {
                    case .Some(IncrementalUpdateType.delete):
                        if let messageID = msg.ID {
                            if let message = Message.messageForMessageID(messageID, inManagedObjectContext: context) {
                                let labelObjs = message.mutableSetValueForKey("labels")
                                labelObjs.removeAllObjects()
                                message.setValue(labelObjs, forKey: "labels")
                                context.deleteObject(message)
                            }
                        }
                    case .Some(IncrementalUpdateType.insert), .Some(IncrementalUpdateType.update1), .Some(IncrementalUpdateType.update2):
                        if IncrementalUpdateType.insert == msg.Action {
                            if let cachedMessage = Message.messageForMessageID(msg.ID, inManagedObjectContext: context) {
                                if cachedMessage.location != MessageLocation.draft && cachedMessage.location != MessageLocation.outbox {
                                    self.tempUnreadAddjustCount = cachedMessage.isRead ? -1 : 0
                                    continue
                                }
                            }
                            if let notify_msg_id = notificationMessageID {
                                if notify_msg_id == msg.ID {
                                    msg.message?.removeValueForKey("IsRead")
                                }
                            }
                            msg.message?["messageStatus"] = 1
                        }
                        
                        if let lo = msg.message?["Location"] as? Int {
                            if lo == 1 {
                                if let exsitMes = Message.messageForMessageID(msg.ID , inManagedObjectContext: context) {
                                    if exsitMes.messageStatus == 1 {
                                        continue;
                                    }
                                }
                            }
                        }
                        do {
                            if let messageObject = try GRTJSONSerialization.objectWithEntityName(Message.Attributes.entityName, fromJSONDictionary: msg.message ?? Dictionary<String, AnyObject>(), inContext: context) as? Message {
                                // apply the label changes
                                if let deleted = msg.message?["LabelIDsRemoved"] as? NSArray {
                                    for delete in deleted {
                                        if let label = Label.labelForLableID(delete as! String, inManagedObjectContext: context) {
                                            let labelObjs = messageObject.mutableSetValueForKey("labels")
                                            if labelObjs.count > 0 {
                                                labelObjs.removeObject(label)
                                                messageObject.setValue(labelObjs, forKey: "labels")
                                            }
                                        }
                                    }
                                }
                                
                                if let added = msg.message?["LabelIDsAdded"] as? NSArray {
                                    for add in added {
                                        if let label = Label.labelForLableID(add as! String, inManagedObjectContext: context) {
                                            let labelObjs = messageObject.mutableSetValueForKey("labels")
                                            labelObjs.addObject(label)
                                            messageObject.setValue(labelObjs, forKey: "labels")
                                        }
                                    }
                                }
                                
                                if let labels = msg.message?["LabelIDs"] as? NSArray {
                                    PMLog.D("\(labels)")
                                    //TODO : add later need to know whne it is happending
                                }
                                
                                if messageObject.messageStatus == 0 {
                                    if messageObject.subject.isEmpty {
                                        messagesNoCache.append(messageObject)
                                    } else {
                                        messageObject.messageStatus = 1
                                    }
                                }
                            } else {
                                PMLog.D(" case .Some(IncrementalUpdateType.insert), .Some(IncrementalUpdateType.update1), .Some(IncrementalUpdateType.update2): insert empty")
                            }
                        } catch {
                            PMLog.D(" error: \(error)")
                        }
                    default:
                        PMLog.D(" unknown type in message: \(message)")
                    }
                }
                
                error = context.saveUpstreamIfNeeded()
                
                if error != nil  {
                    PMLog.D(" error: \(error)")
                }
                
                self.fetchMessagesWithIDs(messagesNoCache);
                
                
                dispatch_async(dispatch_get_main_queue()) {
                    completion?(task: task, response:nil, error: error)
                    return
                }
            }
        }
    }
    
    
    func fetchMessagesWithIDs (messages : [Message]) {
        if messages.count > 0 {
            queue {
                let completionWrapper: CompletionBlock = { task, responseDict, error in
                    if let messagesArray = responseDict?["Messages"] as? [Dictionary<String,AnyObject>] {
                        let context = sharedCoreDataService.newMainManagedObjectContext()
                        context.performBlock() {
                            do {
                                if let messages = try GRTJSONSerialization.objectsWithEntityName(Message.Attributes.entityName, fromJSONArray: messagesArray, inContext: context) as? [Message] {
                                    for message in messages {
                                        message.messageStatus = 1
                                    }
                                    if let error = context.saveUpstreamIfNeeded() {
                                        PMLog.D("GRTJSONSerialization.mergeObjectsForEntityName saveUpstreamIfNeeded failed \(error)")
                                    }
                                } else {
                                    PMLog.D("GRTJSONSerialization.mergeObjectsForEntityName failed \(error)")
                                }
                            } catch {
                                PMLog.D("fetchMessagesWithIDs failed \(error)")
                            }
                        }
                    } else {
                        PMLog.D("fetchMessagesWithIDs can't get the response Messages")
                    }
                }
                
                let request = MessageFetchByIDsRequest(messages: messages)
                sharedAPIService.GET(request, completion: completionWrapper)
            }
        }
    }
    
    
    // old functions
    
    /// downloadTask returns the download task for use with UIProgressView+AFNetworking
    func fetchAttachmentForAttachment(attachment: Attachment, downloadTask: ((NSURLSessionDownloadTask) -> Void)?, completion:((NSURLResponse?, NSURL?, NSError?) -> Void)?) {
        if let localURL = attachment.localURL {
            completion?(nil, localURL, nil)
            return
        }
        
        // TODO: check for existing download tasks and return that task rather than start a new download
        queue { () -> Void in
            if attachment.managedObjectContext != nil {
                sharedAPIService.attachmentForAttachmentID(attachment.attachmentID, destinationDirectoryURL: NSFileManager.defaultManager().attachmentDirectory, downloadTask: downloadTask, completion: { task, fileURL, error in
                    var error = error
                    if let context = attachment.managedObjectContext {
                        if let fileURL = fileURL {
                            attachment.localURL = fileURL
                            attachment.fileData = NSData(contentsOfURL: fileURL)
                            error = context.saveUpstreamIfNeeded()
                            if error != nil  {
                                PMLog.D(" error: \(error)")
                            }
                        }
                    }
                    completion?(task, fileURL, error)
                })
            } else {
                PMLog.D("The attachment not exist") //TODO:: need add log here
                completion?(nil, nil, nil)
            }
        }
    }
    
    func ForcefetchDetailForMessage(message: Message, completion: CompletionFetchDetail) {
        queue {
            let completionWrapper: CompletionBlock = { task, response, error in
                let context = sharedCoreDataService.newMainManagedObjectContext()
                context.performBlock() {
                    var error: NSError?
                    if response != nil {
                        //TODO need check the respons code
                        if var msg: Dictionary<String,AnyObject> = response?["Message"] as? Dictionary<String,AnyObject> {
                            msg.removeValueForKey("Location")
                            msg.removeValueForKey("Starred")
                            msg.removeValueForKey("test")
                            do {
                                try GRTJSONSerialization.objectWithEntityName(Message.Attributes.entityName, fromJSONDictionary: msg, inContext: message.managedObjectContext!)
                                message.isDetailDownloaded = true
                                message.messageStatus = 1
                                message.needsUpdate = true
                                message.isRead = true
                                message.managedObjectContext?.saveUpstreamIfNeeded()
                                error = context.saveUpstreamIfNeeded()
                                dispatch_async(dispatch_get_main_queue()) {
                                    completion(task: task, response: response, message: message, error: error)
                                }
                            } catch let ex as NSError {
                                dispatch_async(dispatch_get_main_queue()) {
                                    completion(task: task, response: response, message: message, error: ex)
                                }
                            }
                        } else {
                            dispatch_async(dispatch_get_main_queue()) {
                                completion(task: task, response: response, message:nil, error: NSError.badResponse())
                            }
                        }
                    } else {
                        error = NSError.unableToParseResponse(response)
                        dispatch_async(dispatch_get_main_queue()) {
                            completion(task: task, response: response, message:nil, error: error)
                        }
                    }
                    if error != nil  {
                        PMLog.D(" error: \(error)")
                    }
                }
            }
            sharedAPIService.messageDetail(messageID: message.messageID, completion: completionWrapper)
        }
    }
    
    func fetchMessageDetailForMessage(message: Message, completion: CompletionFetchDetail) {
        if !message.isDetailDownloaded {
            queue {
                let completionWrapper: CompletionBlock = { task, response, error in
                    if let context = message.managedObjectContext {
                        context.performBlock() {
                            if response != nil {
                                //TODO need check the respons code
                                PMLog.D("\(response)")
                                if var msg: Dictionary<String,AnyObject> = response?["Message"] as? Dictionary<String,AnyObject> {
                                    msg.removeValueForKey("Location")
                                    msg.removeValueForKey("Starred")
                                    msg.removeValueForKey("test")
                                    do {
                                        if let message_n = try GRTJSONSerialization.objectWithEntityName(Message.Attributes.entityName, fromJSONDictionary: msg, inContext: context) as? Message {
                                            message_n.messageStatus = 1
                                            message_n.isDetailDownloaded = true
                                            message_n.needsUpdate = true
                                            message_n.isRead = true
                                            message_n.managedObjectContext?.saveUpstreamIfNeeded()
                                            let tmpError = context.saveUpstreamIfNeeded()
                                            dispatch_async(dispatch_get_main_queue()) {
                                                completion(task: task, response: response, message: message_n, error: tmpError)
                                            }
                                        } else {
                                            dispatch_async(dispatch_get_main_queue()) {
                                                completion(task: task, response: response, message:nil, error: error)
                                            }
                                        }
                                    } catch let ex as NSError {
                                        dispatch_async(dispatch_get_main_queue()) {
                                            completion(task: task, response: response, message: nil, error: ex)
                                        }
                                        
                                    }
                                } else {
                                    dispatch_async(dispatch_get_main_queue()) {
                                        completion(task: task, response: response, message:nil, error: error)
                                    }
                                    
                                }
                            } else {
                                dispatch_async(dispatch_get_main_queue()) {
                                    completion(task: task, response: response, message:nil, error: error)
                                }
                            }
                        }
                    } else {
                        dispatch_async(dispatch_get_main_queue()) {
                            completion(task: task, response: response, message:nil, error: NSError.badResponse()) // the message have been deleted
                        }
                    }
                }
                sharedAPIService.messageDetail(messageID: message.messageID, completion: completionWrapper)
            }
        } else {
            completion(task: nil, response: nil, message:nil, error: nil)
        }
    }
    
    
    func fetchNotificationMessageDetail(messageID: String, completion: CompletionFetchDetail) {
        queue {
            let completionWrapper: CompletionBlock = { task, response, error in
                let context = sharedCoreDataService.newMainManagedObjectContext()
                context.performBlock() {
                    if response != nil {
                        //TODO need check the respons code
                        if var msg: Dictionary<String,AnyObject> = response?["Message"] as? Dictionary<String,AnyObject> {
                            msg.removeValueForKey("Location")
                            msg.removeValueForKey("Starred")
                            msg.removeValueForKey("test")
                            do {
                                if let message_out = try GRTJSONSerialization.objectWithEntityName(Message.Attributes.entityName, fromJSONDictionary: msg, inContext: context) as? Message {
                                    message_out.messageStatus = 1
                                    message_out.isDetailDownloaded = true
                                    message_out.needsUpdate = true
                                    message_out.isRead = true
                                    message_out.managedObjectContext?.saveUpstreamIfNeeded()
                                    let tmpError = context.saveUpstreamIfNeeded()
                                    dispatch_async(dispatch_get_main_queue()) {
                                        completion(task: task, response: response, message: message_out, error: tmpError)
                                    }
                                }
                            } catch let ex as NSError {
                                dispatch_async(dispatch_get_main_queue()) {
                                    completion(task: task, response: response, message: nil, error: ex)
                                }
                            }
                        } else {
                            dispatch_async(dispatch_get_main_queue()) {
                                completion(task: task, response: response, message:nil, error: NSError.badResponse())
                            }
                        }
                    } else {
                        dispatch_async(dispatch_get_main_queue()) {
                            completion(task: task, response: response, message:nil, error: error)
                        }
                    }
                }
            }
            
            if let context = sharedCoreDataService.mainManagedObjectContext {
                if let message = Message.messageForMessageID(messageID, inManagedObjectContext: context) {
                    if message.isDetailDownloaded {
                        completion(task: nil, response: nil, message: message, error: nil)
                    } else {
                        sharedAPIService.messageDetail(messageID: messageID, completion: completionWrapper)
                    }
                } else {
                    sharedAPIService.messageDetail(messageID: messageID, completion: completionWrapper)
                }
            } else {
                sharedAPIService.messageDetail(messageID: messageID, completion: completionWrapper)
            }
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
                fetchRequest.predicate = NSPredicate(format: "(%K == true) AND (%K > 0)", Message.Attributes.isStarred, Message.Attributes.messageStatus)
            } else if location == .inbox {
                fetchRequest.predicate = NSPredicate(format: "((%K == %i) OR (%K == 1)) AND (%K > 0)" , Message.Attributes.locationNumber, location.rawValue, Message.Attributes.messageType, Message.Attributes.messageStatus)
            } else {
                fetchRequest.predicate = NSPredicate(format: "(%K == %i) AND (%K > 0)" , Message.Attributes.locationNumber, location.rawValue, Message.Attributes.messageStatus)
            }
            
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: Message.Attributes.time, ascending: false)]
            return NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: moc, sectionNameKeyPath: nil, cacheName: nil)
        }
        
        return nil
    }
    
    func fetchedResultsControllerForLabels(label: Label) -> NSFetchedResultsController? {
        if let moc = managedObjectContext {
            let fetchRequest = NSFetchRequest(entityName: Message.Attributes.entityName)
            fetchRequest.predicate = NSPredicate(format: "(ANY labels.labelID =[cd] %@) AND (%K > 0)", label.labelID, Message.Attributes.messageStatus)
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
     clean up function for clean up the local cache this will be called when:
     
     1. logout.
     2. use cache version bad.
     3. when session expired.
     
     */
    func launchCleanUpIfNeeded() {
        if !sharedUserDataService.isUserCredentialStored || !userCachedStatus.isCacheOk() || !userCachedStatus.isAuthCacheOk() {
            cleanUp()
            userCachedStatus.resetCache()
            
            if (!userCachedStatus.isAuthCacheOk()) {
                sharedUserDataService.clean()
                userCachedStatus.resetAuthCache()
            }
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
        sharedLabelsDataService.cleanUp()
        
        UIApplication.sharedApplication().applicationIconBadgeNumber = 0
    }
    
    private func cleanMessage() {
        if let context = managedObjectContext {
            Message.deleteAll(inContext: context)
        }
        UIApplication.sharedApplication().applicationIconBadgeNumber = 0
    }
    
    func search(query: String, page: Int, completion: (([Message]?, NSError?) -> Void)?) {
        queue {
            let completionWrapper: CompletionBlock = {task, response, error in
                if error != nil {
                    completion?(nil, error)
                }
                
                if let context = sharedCoreDataService.mainManagedObjectContext {
                    if let messagesArray = response?["Messages"] as? [Dictionary<String,AnyObject>] {
                        context.performBlock() {
                            do {
                                if let messages = try GRTJSONSerialization.objectsWithEntityName(Message.Attributes.entityName, fromJSONArray: messagesArray, inContext: context) as? [Message] {
                                    for message in messages {
                                        message.messageStatus = 1
                                    }
                                    if let error = context.saveUpstreamIfNeeded() {
                                        PMLog.D(" error: \(error)")
                                    }
                                    dispatch_async(dispatch_get_main_queue()) {
                                        if error != nil  {
                                            PMLog.D(" error: \(error)")
                                            completion?(nil, error)
                                        } else {
                                            completion?(messages, error)
                                        }
                                    }
                                } else {
                                    completion?(nil, error)
                                }
                            } catch let ex as NSError {
                                PMLog.D(" error: \(ex)")
                                if let completion = completion {
                                    dispatch_async(dispatch_get_main_queue()) {
                                        completion(nil, ex)
                                    }
                                }
                            }
                        }
                    } else {
                        completion?(nil, NSError.unableToParseResponse(response))
                    }
                }
            }
            sharedAPIService.messageSearch(query, page: page, completion: completionWrapper)
        }
    }
    
    func saveDraft(message : Message!) {
        if let context = message.managedObjectContext {
            if let error = context.saveUpstreamIfNeeded() {
                PMLog.D(" error: \(error)")
            } else {
                queue(message, action: .saveDraft)
            }
        }
    }
    
    func deleteDraft (message : Message!)
    {
        if let context = sharedCoreDataService.mainManagedObjectContext {
            if let error = context.saveUpstreamIfNeeded() {
                PMLog.D(" error: \(error)")
            } else {
                queue(message, action: .delete)
            }
        }
    }
    
    func purgeOldMessages() {
        // need fetch status bad messages
        if let context = sharedCoreDataService.mainManagedObjectContext {
            let fetchRequest = NSFetchRequest(entityName: Message.Attributes.entityName)
            fetchRequest.predicate = NSPredicate(format: "%K == 0", Message.Attributes.messageStatus)
            do {
                
                if let badMessages = try context.executeFetchRequest(fetchRequest) as? [Message] {
                    self.fetchMessagesWithIDs(badMessages);
                }
            } catch let ex as NSError {
                ex.uploadFabricAnswer("purgeOldMessages")
                PMLog.D("error : \(ex)")
            }
        }
        
        //clean old messags
        //        if let context = sharedCoreDataService.mainManagedObjectContext {
        //            let cutoffTimeInterval: NSTimeInterval = 3 * 86400 // days converted to seconds
        //            let fetchRequest = NSFetchRequest(entityName: Message.Attributes.entityName)
        //
        //            var error: NSError?
        //            let count = context.countForFetchRequest(fetchRequest, error: &error)
        //
        //            if error != nil {
        //                PMLog.D(" error: \(error)")
        //            } else if count > maximumCachedMessageCount {
        //                 TODO:: disable this need add later
        //                                fetchRequest.predicate = NSPredicate(format: "%K != %@ AND %K < %@", Message.Attributes.locationNumber, MessageLocation.outbox.rawValue, Message.Attributes.time, NSDate(timeIntervalSinceNow: -cutoffTimeInterval))
        //
        //                                if let oldMessages = context.executeFetchRequest(fetchRequest, error: &error) as? [Message] {
        //                                    for message in oldMessages {
        //                                        context.deleteObject(message)
        //                                    }
        //
        //                                    PMLog.D(" \(oldMessages.count) old messages purged.")
        //
        //                                    if let error = context.saveUpstreamIfNeeded() {
        //                                        PMLog.D(" error: \(error)")
        //                                    }
        //                                } else {
        //                                    PMLog.D(" error: \(error)")
        //                                }
        //            } else {
        //                PMLog.D(" cached message count: \(count)")
        //            }
        //        }
    }
    
    // MARK: - Private methods
    private func generatMessagePackage<T : ApiResponse> (message: Message!, keys : [String : AnyObject]?, atts : [Attachment], encrptOutside : Bool) -> MessageSendRequest<T>! {
        
        let outRequest : MessageSendRequest = MessageSendRequest<T>(messageID: message.messageID, expirationTime: message.expirationOffset, messagePackage: nil, clearBody: "", attPackages: nil)
        
        do {
            var tempAtts : [TempAttachment]! = []
            for att in atts {
                if att.managedObjectContext != nil {
                    if let sessionKey = try att.getSessionKey() {
                        tempAtts.append(TempAttachment(id: att.attachmentID, key: sessionKey))
                    }
                }
            }
            
            var out : [MessagePackage] = []
            var needsPlainText : Bool = false
            
            if let body = try message.decryptBody() {
                if let keys = keys {
                    for (key, v) in keys{
                        if key == "Code" {
                            continue
                        }
                        let publicKey = v as! String
                        let isOutsideUser = publicKey.isEmpty
                        
                        if isOutsideUser {
                            if encrptOutside {
                                let encryptedBody = try body.encryptWithPassphrase(message.password)
                                //create outside encrypt packet
                                let token = String.randomString(32) as String
                                let based64Token = token.encodeBase64() as String
                                let encryptedToken = try based64Token.encryptWithPassphrase(message.password)
                                
                                // encrypt keys use public key
                                var attPack : [AttachmentKeyPackage] = []
                                for att in tempAtts {
                                    let newKeyPack = try att.Key?.getSymmetricSessionKeyPackage(message.password)?.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0)) ?? ""
                                    let attPacket = AttachmentKeyPackage(attID: att.ID, attKey: newKeyPack)
                                    attPack.append(attPacket)
                                }
                                
                                let pack = MessagePackage(address: key, type: 2,  body: encryptedBody, attPackets:attPack, token: based64Token, encToken: encryptedToken, passwordHint: message.passwordHint)
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
                                let newKeyPack = try att.Key?.getPublicSessionKeyPackage(publicKey)?.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0)) ?? ""
                                let attPacket = AttachmentKeyPackage(attID: att.ID, attKey: newKeyPack)
                                attPack.append(attPacket)
                            }
                            //create inside packet
                            if let encryptedBody = try body.encryptMessageWithSingleKey(publicKey) {
                                let pack = MessagePackage(address: key, type: 1, body: encryptedBody, attPackets: attPack)
                                out.append(pack)
                            }
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
                        let newKeyPack = att.Key?.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0)) ?? ""
                        let attPacket = AttachmentKeyPackage(attID: att.ID, attKey: newKeyPack, Algo: "aes256")
                        attPack.append(attPacket)
                    }
                    outRequest.attPackets = attPack
                }
            }
        } catch let ex as NSError {
            PMLog.D(" unable to decrypt \(message.body) with error: \(ex)")
        }
        
        return outRequest
    }
    
    
    
    // MARK : old functions
    
    private func attachmentsForMessage(message: Message) -> [Attachment] {
        return message.attachments.allObjects as! [Attachment]
    }
    
    private func messageBodyForMessage(message: Message, response: [String : AnyObject]?) throws -> [String : String] {
        var messageBody: [String : String] = ["self" : message.body]
        do {
            if let keys = response?["keys"] as? [[String : String]] {
                if let body = try message.decryptBody() {
                    // encrypt body with each public key
                    for publicKeys in keys {
                        for (email, publicKey) in publicKeys {
                            if let encryptedBody = try body.encryptMessageWithSingleKey(publicKey) {
                                messageBody[email] = encryptedBody
                            }
                        }
                    }
                    messageBody["outsiders"] = (message.checkIsEncrypted() == true ? message.passwordEncryptedBody : body)
                }
            } else {
                PMLog.D(" unable to parse response: \(response)")
            }
        } catch let ex as NSError {
            PMLog.D(" unable to decrypt \(message.body) with error: \(ex)")
            
        }
        return messageBody
    }
    
    private func saveDraftWithMessageID(messageID: String, writeQueueUUID: NSUUID, completion: CompletionBlock?) {
        if let context = managedObjectContext {
            if let objectID = sharedCoreDataService.managedObjectIDForURIRepresentation(messageID) {
                do {
                    if let message = try context.existingObjectWithID(objectID) as? Message {
                        let completionWrapper: CompletionBlock = { task, response, error in
                            PMLog.D("SendAttachmentDebug == finish save draft!")
                            if let mess = response {
                                if let messageID = mess["ID"] as? String {
                                    //if message context is invalid let app crash which is fine
                                    message.messageID = messageID
                                    message.isDetailDownloaded = true
                                    
                                    var hasTemp = false;
                                    let attachments = message.mutableSetValueForKey("attachments")
                                    for att in attachments {
                                        if let att = att as? Attachment {
                                            if att.isTemp {
                                                hasTemp = true;
                                                context.deleteObject(att)
                                            }
                                        }
                                    }
                                    
                                    if let error = message.managedObjectContext?.saveUpstreamIfNeeded() {
                                        PMLog.D(" error: \(error)")
                                    }
                                    
                                    if hasTemp {
                                        do {
                                            try GRTJSONSerialization.objectWithEntityName(Message.Attributes.entityName, fromJSONDictionary: mess, inContext: context)
                                            if let save_error = context.saveUpstreamIfNeeded() {
                                                PMLog.D(" error: \(save_error)")
                                            }
                                        } catch let exc as NSError {
                                            completion?(task: task, response: response, error: exc)
                                            return
                                        }
                                    }
                                    completion?(task: task, response: response, error: error)
                                    return
                                } else {//error
                                    completion?(task: task, response: response, error: error)
                                    return
                                }
                            } else {//error
                                completion?(task: task, response: response, error: error)
                                return
                            }
                        }
                        
                        PMLog.D("SendAttachmentDebug == start save draft!")
                        if message.isDetailDownloaded && message.messageID != "0" {
                            let api = MessageUpdateDraftRequest<MessageResponse>(message: message);
                            api.call({ (task, response, hasError) -> Void in
                                if hasError {
                                    completionWrapper(task: task, response: nil, error: response?.error)
                                } else {
                                    completionWrapper(task: task, response: response?.message, error: nil)
                                }
                            })
                        } else {
                            let api = MessageDraftRequest<MessageResponse>(message: message)
                            api.call({ (task, response, hasError) -> Void in
                                if hasError {
                                    completionWrapper(task: task, response: nil, error: response?.error)
                                } else {
                                    completionWrapper(task: task, response: response?.message, error: nil)
                                }
                            })
                        }
                        return;
                    }
                } catch let ex as NSError {
                    completion?(task: nil, response: nil, error: ex)
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
            if let objectID = sharedCoreDataService.managedObjectIDForURIRepresentation(addressID) {
                
                var msgObject : NSManagedObject?
                do {
                    msgObject = try context.existingObjectWithID(objectID)
                } catch {
                    msgObject = nil
                }
                
                if let attachment = msgObject as? Attachment {
                    var params = [
                        "Filename":attachment.fileName,
                        "MIMEType" : attachment.mimeType,
                        ]
                    
                    var default_address_id = sharedUserDataService.userAddresses.getDefaultAddress()?.address_id ?? ""
                    //TODO::here need to fix sometime message is not valid'
                    if attachment.message.managedObjectContext == nil {
                        params["MessageID"] =  ""
                    } else {
                        params["MessageID"] =  attachment.message.messageID ?? ""
                        default_address_id = attachment.message.getAddressID
                    }
                    
                    //
                    let encrypt_data = attachment.encryptAttachment(default_address_id)
                    //TODO:: here need check is encryptdata is nil and return the error to user.
                    let keyPacket = encrypt_data?.keyPackage
                    let dataPacket = encrypt_data?.dataPackage
                    
                    let completionWrapper: CompletionBlock = { task, response, error in
                        PMLog.D("SendAttachmentDebug == finish upload att!")
                        if error == nil {
                            if let messageID = response?["AttachmentID"] as? String {
                                attachment.attachmentID = messageID
                                attachment.keyPacket = keyPacket?.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0)) ?? ""
                                if let error = context.saveUpstreamIfNeeded() {
                                    PMLog.D(" error: \(error)")
                                }
                            }
                        }
                        completion?(task: task, response: response, error: error)
                    }
                    PMLog.D("SendAttachmentDebug == start upload att!")
                    sharedAPIService.upload( AppConstants.BaseURLString + AppConstants.BaseAPIPath + "/attachments/upload", parameters: params, keyPackets: keyPacket, dataPacket: dataPacket, completion: completionWrapper)
                    
                    return
                }
            }
        }
        
        // nothing to send, dequeue request
        sharedMessageQueue.remove(elementID: writeQueueUUID)
        self.dequeueIfNeeded()
        
        completion?(task: nil, response: nil, error: NSError.badParameter(addressID))
    }
    
    private func deleteAttachmentWithAttachmentID (deleteObject: String, writeQueueUUID: NSUUID, completion: CompletionBlock?) {
        if let _ = managedObjectContext {
            let api = AttachmentDeleteRequest(body: deleteObject);
            api.call({ (task, response, hasError) -> Void in
                completion?(task: task, response: nil, error: nil)
            })
            return
        }
        
        // nothing to send, dequeue request
        sharedMessageQueue.remove(elementID: writeQueueUUID)
        self.dequeueIfNeeded()
        completion?(task: nil, response: nil, error: NSError.badParameter(deleteObject))
    }
    
    private func emptyMessageWithLocation (location: String, writeQueueUUID: NSUUID, completion: CompletionBlock?) {
        if let _ = managedObjectContext {
            let api = MessageEmptyRequest(location: location);
            api.call({ (task, response, hasError) -> Void in
                completion?(task: task, response: nil, error: nil)
            })
            return
        }
        
        // nothing to send, dequeue request
        sharedMessageQueue.remove(elementID: writeQueueUUID)
        self.dequeueIfNeeded()
        completion?(task: nil, response: nil, error: NSError.badParameter("\(location)"))
    }
    
    
    private func sendMessageID(messageID: String, writeQueueUUID: NSUUID, completion: CompletionBlock?) {
        let errorBlock: CompletionBlock = { task, response, error in
            // nothing to send, dequeue request
            sharedMessageQueue.remove(elementID: writeQueueUUID)
            completion?(task: task, response: response, error: error)
        }
        
        if let context = managedObjectContext {
            if let objectID = sharedCoreDataService.managedObjectIDForURIRepresentation(messageID) {
                var msgObject : NSManagedObject?
                do {
                    msgObject = try context.existingObjectWithID(objectID)
                } catch {
                    msgObject = nil
                }
                if let message = msgObject as? Message {
                    PMLog.D("SendAttachmentDebug == start get key!")
                    sharedAPIService.userPublicKeysForEmails(message.allEmailAddresses, completion: { (task, response, error) -> Void in
                        PMLog.D("SendAttachmentDebug == finish get key!")
                        
                        if error != nil && error!.code == APIErrorCode.badParameter {
                            errorBlock(task: task, response: response, error: error)
                            return
                        }
                        
                        if message.managedObjectContext == nil {
                            NSError.alertLocalCacheErrorToast()
                            let err =  NSError.badDraft()
                            err.uploadFabricAnswer(CacheErrorTitle)
                            errorBlock(task: task, response: nil, error:err)
                            return ;
                        }
                        
                        // is encrypt outside
                        let isEncryptOutside = !message.password.isEmpty
                        
                        // get attachment
                        let attachments = self.attachmentsForMessage(message)
                        
                        // create package for internal
                        let sendMessage = self.generatMessagePackage(message, keys: response, atts:attachments, encrptOutside: isEncryptOutside)
                        
                        let reskeys = response;
                        
                        // parse the response for keys
                        _ = try? self.messageBodyForMessage(message, response: response)
                        
                        let completionWrapper: CompletionBlock = { task, response, error in
                            PMLog.D("SendAttachmentDebug == finish send email!")
                            // remove successful send from Core Data
                            if error == nil {
                                //context.deleteObject(message)MOBA-378
                                if (message.location == MessageLocation.draft) {
                                    var isOutsideUser = false
                                    if let keys = reskeys {
                                        for (key, v) in keys{
                                            if key == "Code" {
                                                continue
                                            }
                                            if let publicKey = v as? String {
                                                if publicKey.isEmpty {
                                                    isOutsideUser = true;
                                                    break;
                                                }
                                            }
                                        }
                                    }
                                    
                                    if isEncryptOutside {
                                        if isOutsideUser {
                                            message.isEncrypted = EncryptTypes.OutEnc.rawValue;
                                        } else {
                                            message.isEncrypted = EncryptTypes.Internal.rawValue;
                                        }
                                    } else {
                                        if isOutsideUser {
                                            message.isEncrypted = EncryptTypes.OutPlain.rawValue;
                                        } else {
                                            message.isEncrypted = EncryptTypes.Internal.rawValue;
                                        }
                                    }
                                    
                                    if attachments.count > 0 {
                                        message.hasAttachments = true;
                                    }
                                    
                                    message.needsUpdate = false;
                                    message.isRead = true
                                    lastUpdatedStore.ReadMailboxMessage(message.location)
                                    message.location = MessageLocation.outbox
                                }
                                NSError.alertMessageSentToast()
                                if let error = context.saveUpstreamIfNeeded() {
                                    PMLog.D(" error: \(error)")
                                } else {
                                    self.markReplyStatus(message.orginalMessageID, action: message.action)
                                }
                            }
                            else {
                                if error?.code == 15198 {
                                    error?.alertSentErrorToast()
                                } else {
                                    //error?.alertErrorToast()
                                }
                                //NSError.alertMessageSentErrorToast()
                                error?.uploadFabricAnswer(SendingErrorTitle)
                            }
                            completion?(task: task, response: response, error: error)
                            return
                        }
                        PMLog.D("SendAttachmentDebug == start send email!")
                        sendMessage!.call({ (task, response, hasError) -> Void in
                            if hasError {
                                completionWrapper(task: task, response: nil, error: response?.error)
                            } else {
                                completionWrapper(task: task, response: nil, error: nil)
                            }
                        })
                    })
                    
                    return
                }
            }
        }
        
        errorBlock(task: nil, response: nil, error: NSError.badParameter(messageID))
    }
    
    private func markReplyStatus(oriMsgID : String?, action : NSNumber?) {
        if let _ = managedObjectContext {
            if let originMessageID = oriMsgID {
                if let act = action {
                    if !originMessageID.isEmpty {
                        if let fetchedMessageController = sharedMessageDataService.fetchedMessageControllerForID(originMessageID) {
                            do {
                                try fetchedMessageController.performFetch()
                                if let message : Message = fetchedMessageController.fetchedObjects?.first as? Message  {
                                    //{0|1|2} // Optional, reply = 0, reply all = 1, forward = 2
                                    if act == 0 {
                                        message.isReplied = true;
                                    } else if act == 1 {
                                        message.isRepliedAll = true;
                                    } else if act == 2{
                                        message.isForwarded = true;
                                    } else {
                                        //ignore
                                    }
                                    if let error = message.managedObjectContext!.saveUpstreamIfNeeded() {
                                        PMLog.D(" error: \(error)")
                                    }
                                }
                            } catch {
                                PMLog.D(" error: \(error)")
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: Notifications
    
    private func setupNotifications() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(MessageDataService.didSignOutNotification(_:)), name: NotificationDefined.didSignOut, object: nil)
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
                        Message.deleteMessage(messageID)
                    }
                }
                sharedMessageQueue.remove(elementID: elementID)
                self.dequeueIfNeeded()
            } else {
                PMLog.D(" error: \(error)")
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
                            if error?.code == -1001 {
                                NSNotificationCenter.defaultCenter().postNotification(NSNotification(name: kReachabilityChangedNotification, object: 0, userInfo: nil))
                            } else {
                                NSNotificationCenter.defaultCenter().postNotification(NSNotification(name: kReachabilityChangedNotification, object: 1, userInfo: nil))
                            }
                            isInternetIssue = true
                        }
                    }
                }
                
                if (statusCode == 404)
                {
                    if  let (_, object) = sharedMessageQueue.next() {
                        if let element = object as? [String : String] {
                            let count = element["count"]
                            PMLog.D("message queue count : \(count)")
                            sharedMessageQueue.remove(elementID: elementID)
                        }
                    }
                }
                
                //need add try times and check internet status
                if statusCode == 500 && !isInternetIssue {
                    if  let (uuid, object) = sharedMessageQueue.next() {
                        if let element = object as? [String : String] {
                            let count = element["count"]
                            PMLog.D("message queue count : \(count)")
                            sharedFailedQueue.add(uuid, object: element)
                            sharedMessageQueue.remove(elementID: elementID)
                        }
                    }
                }
                
                if statusCode == 200 && error?.code > 1000 {
                    //show error
                    sharedMessageQueue.remove(elementID: elementID)
                    error?.uploadFabricAnswer(QueueErrorTitle)
                }
                
                if statusCode != 200 && statusCode != 404 && statusCode != 500 && !isInternetIssue {
                    //show error
                    sharedMessageQueue.remove(elementID: elementID)
                    error?.uploadFabricAnswer(QueueErrorTitle)
                }
                
                if !isInternetIssue {
                    self.dequeueIfNeeded()
                } else {
                    if !sharedMessageQueue.isBlocked && self.readQueue.count > 0 {
                        PMLog.D("left redaQueue count : \(self.readQueue.count)")
                        self.readQueue.removeAtIndex(0)()
                        self.dequeueIfNeeded()
                    }
                }
            }
        }
    }
    
    private func dequeueIfNeeded() {
        if let (uuid, messageID, actionString) = sharedMessageQueue.nextMessage() {
            PMLog.D("SendAttachmentDebug == dequeue --- \(actionString)")
            if let action = MessageAction(rawValue: actionString) {
                sharedMessageQueue.isInProgress = true
                switch action {
                case .saveDraft:
                    saveDraftWithMessageID(messageID, writeQueueUUID: uuid, completion: writeQueueCompletionBlockForElementID(uuid, messageID: messageID, actionString: actionString))
                case .send:
                    sendMessageID(messageID, writeQueueUUID: uuid, completion: writeQueueCompletionBlockForElementID(uuid, messageID: messageID, actionString: actionString))
                case .uploadAtt:
                    uploadAttachmentWithAttachmentID(messageID, writeQueueUUID: uuid, completion: writeQueueCompletionBlockForElementID(uuid, messageID: messageID, actionString: actionString))
                case .deleteAtt:
                    deleteAttachmentWithAttachmentID(messageID, writeQueueUUID: uuid, completion: writeQueueCompletionBlockForElementID(uuid, messageID: messageID, actionString: actionString))
                case .emptyTrash:
                    emptyMessageWithLocation("trash", writeQueueUUID: uuid, completion: writeQueueCompletionBlockForElementID(uuid, messageID: messageID, actionString: actionString))
                case .emptySpam:
                    emptyMessageWithLocation("spam", writeQueueUUID: uuid, completion: writeQueueCompletionBlockForElementID(uuid, messageID: messageID, actionString: actionString))
                default:
                    sharedAPIService.PUT(MessageActionRequest<ApiResponse>(action: actionString, ids: [messageID]), completion: writeQueueCompletionBlockForElementID(uuid, messageID: messageID, actionString: actionString))
                }
            } else {
                PMLog.D(" Unsupported action \(actionString), removing from queue.")
                sharedMessageQueue.remove(elementID: uuid)
            }
        } else if !sharedMessageQueue.isBlocked && readQueue.count > 0 { //sharedMessageQueue.count == 0 &&
            readQueue.removeAtIndex(0)()
            dequeueIfNeeded()
        }
    }
    
    private func queue(message: Message, action: MessageAction) {
        if action == .saveDraft || action == .send {
            //TODO:: need to handle the empty instead of !
            sharedMessageQueue.addMessage(message.objectID.URIRepresentation().absoluteString!, action: action)
        } else {
            if message.managedObjectContext != nil && !message.messageID.isEmpty {
                sharedMessageQueue.addMessage(message.messageID, action: action)
            }
        }
        dequeueIfNeeded()
    }
    
    private func queue(action: MessageAction) {
        sharedMessageQueue.addMessage("", action: action)
        dequeueIfNeeded()
    }
    
    private func queue(att: Attachment, action: MessageAction) {
        //TODO:: need to handle the empty instead of !
        sharedMessageQueue.addMessage(att.objectID.URIRepresentation().absoluteString!, action: action)
        dequeueIfNeeded()
    }
    
    private func queue(readBlock: ReadBlock) {
        readQueue.append(readBlock)
        dequeueIfNeeded()
    }
    
    // MARK: Setup
    private func setupMessageMonitoring() {
        sharedMonitorSavesDataService.registerMessage(attribute: Message.Attributes.locationNumber, handler: { message in
            if message.needsUpdate {
                if let action = message.location.moveAction {
                    self.queue(message, action: action)
                } else {
                    PMLog.D(" \(message.messageID) move to \(message.location) was not a user initiated move.")
                }
            }
        })
        
        sharedMonitorSavesDataService.registerMessage(attribute: Message.Attributes.isRead, handler: { message in
            if message.needsUpdate {
                let action: MessageAction = message.isRead ? .read : .unread
                if message.location == .inbox {
                    var count = lastUpdatedStore.unreadCountForKey(.inbox)
                    let offset = message.isRead ? -1 : 1
                    count = count + offset
                    if count < 0 {
                        count = 0
                    }
                    lastUpdatedStore.updateUnreadCountForKey(.inbox, count: count)
                    UIApplication.sharedApplication().applicationIconBadgeNumber = count
                }
                
                self.queue(message, action: action)
            }
        })
        
        sharedMonitorSavesDataService.registerMessage(attribute: Message.Attributes.isStarred, handler: { message in
            if message.needsUpdate {
                let action: MessageAction = message.isStarred ? .star : .unstar
                self.queue(message, action: action)
            }
        })
    }
}

// MARK: - NSFileManager extension

extension NSFileManager {
    var attachmentDirectory: NSURL {
        let attachmentDirectory = applicationSupportDirectoryURL.URLByAppendingPathComponent("attachments", isDirectory: true)
        //TODO:: need to handle the empty instead of !
        if !self.fileExistsAtPath(attachmentDirectory!.absoluteString!) {
            do {
                //TODO:: need to handle the empty instead of !
                try self.createDirectoryAtURL(attachmentDirectory!, withIntermediateDirectories: true, attributes: nil)
            }
            catch let ex as NSError {
                PMLog.D(" error : \(ex).")
            }
        }
        //TODO:: need to handle the empty instead of !
        return attachmentDirectory!
    }
    
    func cleanCachedAtts() {
        let attachmentDirectory = applicationSupportDirectoryURL.URLByAppendingPathComponent("attachments", isDirectory: true)
        //TODO:: need to handle the empty instead of !
        if let path = attachmentDirectory!.path {
            do {
                let filePaths = try self.contentsOfDirectoryAtPath(path)
                for fileName in filePaths {
                    let filePathName = "\(path)/\(fileName)"
                    try self.removeItemAtPath(filePathName)
                }
            }
            catch let ex as NSError {
                PMLog.D(" error : \(ex).")
            }
        }
    }
}

extension NSError {
    class func badDraft() -> NSError {
        return apiServiceError(
            code: APIErrorCode.SendErrorCode.draftBad,
            localizedDescription: NSLocalizedString("Unable to send the email"),
            localizedFailureReason: NSLocalizedString("The draft format incorrectly sending failed!"))
    }
}
