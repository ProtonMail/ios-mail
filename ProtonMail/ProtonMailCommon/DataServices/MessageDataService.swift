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
import Groot
import AwaitKit
import PromiseKit
import Crashlytics


/// TODO:: global access need to be refactored
let sharedMessageDataService = MessageDataService()

/// Message data service
class MessageDataService {
    
    //TODO:: those 3 var need to double check to clean up
    private let incrementalUpdateQueue = DispatchQueue(label: "ch.protonmail.incrementalUpdateQueue", attributes: [])
    private let lastUpdatedMaximumTimeInterval: TimeInterval = 24 /*hours*/ * 3600
    private let maximumCachedMessageCount = 5000
    
    typealias CompletionBlock = APIService.CompletionBlock
    typealias CompletionFetchDetail = APIService.CompletionFetchDetail
    typealias ReadBlock = (() -> Void)
    
    fileprivate var readQueue: [ReadBlock] = []
    var pushNotificationMessageID : String? = nil
    
    fileprivate var managedObjectContext: NSManagedObjectContext? {
        return sharedCoreDataService.mainManagedObjectContext
    }

    init() {
        setupMessageMonitoring()
        setupNotifications()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MAKR : upload attachment
    func uploadAttachment(_ att: Attachment!) {
        if let context = sharedCoreDataService.mainManagedObjectContext {
            if let error = context.saveUpstreamIfNeeded() {
                PMLog.D("error: \(error)")
                self.dequeueIfNeeded()
            } else {
                self.queue(att, action: .uploadAtt)
            }
        }
    }
    
    func delete(att: Attachment!) {
        let attachmentID = att.attachmentID
        if let context = sharedCoreDataService.mainManagedObjectContext {
            context.delete(att)
            if let error = context.saveUpstreamIfNeeded() {
                PMLog.D(" error: \(error)")
            }
        }
        let _ = sharedMessageQueue.addMessage(attachmentID, action: .deleteAtt)
        dequeueIfNeeded()
    }
    
    
    // MARK : Send message
    func send(inQueue messageID : String!, completion: CompletionBlock?) {
        var error: NSError?
        if let context = sharedCoreDataService.mainManagedObjectContext {
            if let message = Message.messageForMessageID(messageID, inManagedObjectContext: context) {
                //message.location = .outbox
                error = context.saveUpstreamIfNeeded()
                if error != nil {
                    PMLog.D(" error: \(String(describing: error))")
                } else {
                    self.queue(message, action: .send)
                }
            } else {
                //TODO:: handle can't find the message error.
            }
        } else {
            error = NSError.protonMailError(500, localizedDescription: "No managedObjectContext", localizedFailureReason: nil, localizedRecoverySuggestion: nil)
        }
        completion?(nil, nil, error)
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
    func fetchMessagesForLocation(_ location: MessageLocation, MessageID : String, Time: Int, foucsClean: Bool, completion: CompletionBlock?) {
        queue {
            let completionWrapper: CompletionBlock = { task, responseDict, error in
                if let messagesArray = responseDict?["Messages"] as? [[String : Any]] {
                    PMLog.D("\(messagesArray)")
                    let messcount = responseDict?["Total"] as? Int ?? 0
                    let context = sharedCoreDataService.newMainManagedObjectContext()
                    context.perform() {
                        if foucsClean {
                            self.cleanMessage()
                            let _ = context.saveUpstreamIfNeeded()
                        }
                        do {
                            if let messages = try GRTJSONSerialization.objects(withEntityName: Message.Attributes.entityName, fromJSONArray: messagesArray, in: context) as? [Message] {
                                for message in messages {
                                    if location == .archive {
                                        message.location = location
                                    }
                                    message.messageStatus = 1
                                    message.needsUpdate = false
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
                                    updateTime.update = Date()
                                    lastUpdatedStore.updateInboxForKey(location, updateTime: updateTime)
                                }
                                
                                //fetch inbox count
                                if location == .inbox {
                                    let counterApi = MessageCount()
                                    counterApi.call({ (task, response, hasError) in
                                        if !hasError {
                                            self.processMessageCounts(response?.counts)
                                        }
                                    })
                                }
                                
                                DispatchQueue.main.async {
                                    completion?(task, responseDict, error)
                                }
                            }
                            DispatchQueue.main.async {
                                completion?(task, responseDict, error)
                            }
                        } catch let ex as NSError {
                            PMLog.D("error: \(ex)")
                            DispatchQueue.main.async {
                                completion?(task, responseDict, ex)
                            }
                        }
                    }
                } else {
                    completion?(task, responseDict, NSError.unableToParseResponse(responseDict))
                }
            }
            
            let request = FetchMessages(location: location, endTime: Time);
            sharedAPIService.GET(request, completion: completionWrapper)
        }
    }
    
    func fetchMessagesForLabels(_ labelID : String, MessageID : String, Time: Int, foucsClean: Bool, completion: CompletionBlock?) {
        queue {
            let completionWrapper: CompletionBlock = { task, responseDict, error in
                // TODO :: need abstract the respons error checking
                if let messagesArray = responseDict?["Messages"] as? [[String : Any]] {
                    let messcount = responseDict?["Total"] as? Int ?? 0
                    let context = sharedCoreDataService.newMainManagedObjectContext()
                    context.perform() {
                        if foucsClean {
                            self.cleanMessage()
                            let _ = context.saveUpstreamIfNeeded()
                        }
                        do {
                            if let messages = try GRTJSONSerialization.objects(withEntityName: Message.Attributes.entityName, fromJSONArray: messagesArray, in: context) as? [Message] {
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
                                    updateTime.update = Date()
                                    
                                    lastUpdatedStore.updateLabelsForKey(labelID, updateTime: updateTime)
                                }
                            }
                            DispatchQueue.main.async {
                                completion?(task, responseDict, error)
                            }
                        } catch let ex as NSError {
                            PMLog.D(" error: \(ex)")
                            DispatchQueue.main.async {
                                completion?(task, responseDict, ex)
                            }
                        }
                    }
                } else {
                    completion?(task, responseDict, NSError.unableToParseResponse(responseDict))
                }
            }
            let request = FetchMessagesByLabel(labelID: labelID, endTime: Time)
            sharedAPIService.GET(request, completion: completionWrapper)
        }
    }
    func fetchMessagesForLocationWithEventReset(_ location: MessageLocation, MessageID : String, Time: Int, completion: CompletionBlock?) {
        queue {
            let getLatestEventID = EventLatestIDRequest<EventLatestIDResponse>()
            getLatestEventID.call() { task, _IDRes, hasIDError in
                if let IDRes = _IDRes, !hasIDError && !IDRes.eventID.isEmpty {
                    let completionWrapper: CompletionBlock = { task, responseDict, error in
                        if error == nil {
                            lastUpdatedStore.clear()
                            lastUpdatedStore.lastEventID = IDRes.eventID
                        }
                        completion?(task, responseDict, error)
                    }
                    self.cleanMessage()
                    sharedContactDataService.clean()
                    self.fetchMessagesForLocation(location, MessageID: MessageID, Time: Time, foucsClean: false, completion: completionWrapper)
                    
                    sharedContactDataService.fetchContacts(completion: nil)
                    sharedLabelsDataService.fetchLabels();
                }  else {
                    completion?(task, nil, nil)
                }
            }
        }
    }
    
    
    fileprivate var tempUnreadAddjustCount = 0
    /**
     fetch the new messages use the events log
     
     :param: Time       latest message time
     :param: completion complete handler
     */
    func fetchNewMessagesForLocation(_ location: MessageLocation, notificationMessageID : String?, completion: CompletionBlock?) {
        queue {
            let eventAPI = EventCheckRequest<EventCheckResponse>(eventID: lastUpdatedStore.lastEventID)
            eventAPI.call() { task, _eventsRes, _hasEventsError in
                if let eventsRes = _eventsRes {
                    if eventsRes.refresh.contains(.all) ||  eventsRes.refresh.contains(.mail) || (_hasEventsError && eventsRes.code == 18001) || (_hasEventsError && eventsRes.code == 400) {
                        let getLatestEventID = EventLatestIDRequest<EventLatestIDResponse>()
                        getLatestEventID.call() { task, _IDRes, hasIDError in
                            if let IDRes = _IDRes, !hasIDError && !IDRes.eventID.isEmpty {
                                let completionWrapper: CompletionBlock = { task, responseDict, error in
                                    if error == nil {
                                        lastUpdatedStore.clear()
                                        lastUpdatedStore.lastEventID = IDRes.eventID
                                    }
                                    completion?(task, responseDict, error)
                                }
                                self.cleanMessage()
                                sharedContactDataService.clean()
                                self.fetchMessagesForLocation(location, MessageID: "", Time: 0, foucsClean: false, completion: completionWrapper)
                                sharedContactDataService.fetchContacts(completion: nil)
                                sharedLabelsDataService.fetchLabels();
                            } else {
                                completion?(task, nil, nil)
                            }
                        }
                    } else if eventsRes.refresh.contains(.contacts) {
                        sharedContactDataService.clean()
                        sharedContactDataService.fetchContacts(completion: nil)
                    } else if eventsRes.messages != nil {
                        self.processIncrementalUpdateMessages(notificationMessageID, messages: eventsRes.messages!, task: task) { task, res, error in
                            if error == nil {
                                lastUpdatedStore.lastEventID = eventsRes.eventID
                                self.processMessageCounts(eventsRes.messageCounts)
                                self.processIncrementalUpdateUserInfo(eventsRes.userinfo)
                                self.processIncrementalUpdateLabels(eventsRes.labels)
                                self.processIncrementalUpdateContacts(eventsRes.contacts)
                                self.processIncrementalUpdateContactEmails(eventsRes.contactEmails)
                                
                                var outMessages : [Any] = [];
                                for message in eventsRes.messages! {
                                    let msg = MessageEvent(event: message)
                                    if msg.Action == 1 {
                                        outMessages.append(msg)
                                    }
                                }
                                completion?(task, ["Messages": outMessages, "Notices": eventsRes.notices ?? [String](), "More" : eventsRes.more], nil)
                            }
                            else {
                                completion?(task, nil, error)
                            }
                        }
                    }
                    else {
                        if eventsRes.code == 1000 {
                            lastUpdatedStore.lastEventID = eventsRes.eventID
                            self.processMessageCounts(eventsRes.messageCounts)
                            self.processIncrementalUpdateUserInfo(eventsRes.userinfo)
                            self.processIncrementalUpdateLabels(eventsRes.labels)
                            self.processIncrementalUpdateContacts(eventsRes.contacts)
                            self.processIncrementalUpdateContactEmails(eventsRes.contactEmails)
                        }
                        if _hasEventsError {
                            completion?(task, nil, eventsRes.error)
                        } else {
                            completion?(task, ["Notices": eventsRes.notices ?? [String](), "More" : eventsRes.more], nil)
                        }
                    }
                } else {
                    completion?(task, nil, nil)
                }
            }
        }
    }
    
    func fetchNewMessagesForLabels(_ labelID: String, notificationMessageID : String?, completion: CompletionBlock?) {
        queue {
            let eventAPI = EventCheckRequest<EventCheckResponse>(eventID: lastUpdatedStore.lastEventID)
            eventAPI.call() { task, response, hasError in
                if let eventsRes = response {
                    if eventsRes.refresh.contains(.all) ||  eventsRes.refresh.contains(.mail) || (hasError && eventsRes.code == 18001) {
                        let getLatestEventID = EventLatestIDRequest<EventLatestIDResponse>()
                        getLatestEventID.call() { task, _IDRes, hasIDError in
                            if let IDRes = _IDRes, !hasIDError && !IDRes.eventID.isEmpty {
                                let completionWrapper: CompletionBlock = { task, responseDict, error in
                                    if error == nil {
                                        lastUpdatedStore.clear()
                                        lastUpdatedStore.lastEventID = IDRes.eventID
                                    }
                                    completion?(task, responseDict, error)
                                }
                                self.cleanMessage()
                                sharedContactDataService.clean()
                                self.fetchMessagesForLabels(labelID, MessageID: "", Time: 0, foucsClean: false, completion: completionWrapper)
                                sharedContactDataService.fetchContacts(completion: nil)
                                sharedLabelsDataService.fetchLabels();
                            } else {
                                completion?(task, nil, nil)
                            }
                        }
                    } else if eventsRes.refresh.contains(.contacts) {
                        sharedContactDataService.clean()
                        sharedContactDataService.fetchContacts(completion: nil)
                    } else if eventsRes.messages != nil {
                        self.processIncrementalUpdateMessages(notificationMessageID, messages: eventsRes.messages!, task: task) { task, res, error in
                            if error == nil {
                                lastUpdatedStore.lastEventID = eventsRes.eventID
                                self.processMessageCounts(eventsRes.messageCounts)
                                self.processIncrementalUpdateUserInfo(eventsRes.userinfo)
                                self.processIncrementalUpdateLabels(eventsRes.labels)
                                self.processIncrementalUpdateContacts(eventsRes.contacts)
                                self.processIncrementalUpdateContactEmails(eventsRes.contactEmails)
                                
                                var outMessages : [Any] = [];
                                for message in eventsRes.messages! {
                                    let msg = MessageEvent(event: message)
                                    if msg.Action == 1 {
                                        outMessages.append(msg)
                                    }
                                }
                                completion?(task, ["Messages": outMessages, "Notices": eventsRes.notices ?? [String](), "More" : eventsRes.more], nil)
                            }
                            else {
                                completion?(task, nil, error)
                            }
                        }
                    }
                    else {
                        if eventsRes.code == 1000 {
                            lastUpdatedStore.lastEventID = eventsRes.eventID
                            self.processMessageCounts(eventsRes.messageCounts)
                            self.processIncrementalUpdateUserInfo(eventsRes.userinfo)
                            self.processIncrementalUpdateLabels(eventsRes.labels)
                            self.processIncrementalUpdateContacts(eventsRes.contacts)
                            self.processIncrementalUpdateContactEmails(eventsRes.contactEmails)
                        }
                        if hasError {
                            completion?(task, nil, eventsRes.error)
                        } else {
                            completion?(task, ["Notices": eventsRes.notices ?? [String](), "More" : eventsRes.more], nil)
                        }
                    }
                } else {
                    completion?(task, nil, nil)
                }
            }
        }
    }
    
    func processIncrementalUpdateContacts(_ contacts: [[String : Any]]?) {
        if let contacts = contacts {
            let context = sharedCoreDataService.newMainManagedObjectContext()
            context.perform { () -> Void in
                for contact in contacts {
                    let contactObj = ContactEvent(event: contact)
                    switch(contactObj.action) {
                    case .delete:
                        if let contactID = contactObj.ID {
                            if let tempContact = Contact.contactForContactID(contactID, inManagedObjectContext: context) {
                                context.delete(tempContact)
                            }
                        }
                    case .insert, .update:
                        do {
                            if let outContacts = try GRTJSONSerialization.objects(withEntityName: Contact.Attributes.entityName,
                                                                 fromJSONArray: contactObj.contacts,
                                                                 in: context) as? [Contact] {
                                for c in outContacts {
                                    c.isDownloaded = false
                                }
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
    
    func processIncrementalUpdateContactEmails(_ contactEmails: [[String : Any]]?) {
        guard let emails = contactEmails else {
            return
        }
        
        let context = sharedCoreDataService.newMainManagedObjectContext()
        context.perform { () -> Void in
            for email in emails {
                let emailObj = EmailEvent(event: email)
                switch(emailObj.action) {
                case .delete:
                    if let emailID = emailObj.ID {
                        if let tempEmail = Email.EmailForID(emailID, inManagedObjectContext: context) {
                            context.delete(tempEmail)
                        }
                    }
                case .insert, .update:
                    do {
                        if let outContacts = try GRTJSONSerialization.objects(withEntityName: Contact.Attributes.entityName,
                                                                              fromJSONArray: emailObj.contacts,
                                                                              in: context) as? [Contact] {
                            for c in outContacts {
                                c.isDownloaded = false
                            }
                        }
                        
                    } catch let ex as NSError {
                        PMLog.D(" error: \(ex)")
                    }
                default:
                    PMLog.D(" unknown type in contact: \(email)")
                }
            }
            
            if let error = context.saveUpstreamIfNeeded()  {
                PMLog.D(" error: \(error)")
            }
        }
    }
    
    
    func processIncrementalUpdateTotal(_ totals: [String : Any]?) {
        
        if let star = totals?["Starred"] as? Int {
            let updateTime = lastUpdatedStore.inboxLastForKey(MessageLocation.starred)
            updateTime.total = Int32(star)
            lastUpdatedStore.updateInboxForKey(MessageLocation.starred, updateTime: updateTime)
        }
        
        if let locations = totals?["Locations"] as? [[String : Any]] {
            for location:[String : Any] in locations {
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
    
    func processIncrementalUpdateUserInfo(_ userinfo: [String : Any]?) {
        if let userData = userinfo {
            
            let userInfo = UserInfo( response: userData )
            sharedUserDataService.updateUserInfoFromEventLog(userInfo);
        }
    }
    
    func processIncrementalUpdateLabels(_ labels: [[String : Any]]?) {
        
        struct IncrementalUpdateType {
            static let delete = 0
            static let insert = 1
            static let update = 2
        }
        
        if let labels = labels {
            // this serial dispatch queue prevents multiple messages from appearing when an incremental update is triggered while another is in progress
            self.incrementalUpdateQueue.sync {
                let context = sharedCoreDataService.newMainManagedObjectContext()
                context.perform { () -> Void in
                    for labelEvent in labels {
                        let label = LabelEvent(event: labelEvent)
                        switch(label.Action) {
                        case .some(IncrementalUpdateType.delete):
                            if let labelID = label.ID {
                                if let dLabel = Label.labelForLableID(labelID, inManagedObjectContext: context) {
                                    context.delete(dLabel)
                                }
                            }
                        case .some(IncrementalUpdateType.insert), .some(IncrementalUpdateType.update):
                            do {
                                if let new_or_update_label = label.label {
                                    try GRTJSONSerialization.object(withEntityName: Label.Attributes.entityName, fromJSONDictionary: new_or_update_label, in: context)
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
    
    func processMessageCounts(_ msgCounts: [[String : Any]]?) {
        guard let messageCounts = msgCounts, messageCounts.count > 0 else {
            return
        }
        
        lastUpdatedStore.resetUnreadCounts()
        for count in messageCounts {
            if let labelID = count["LabelID"] as? String {
                guard let unread = count["Unread"] as? Int else {
                    continue
                }
                lastUpdatedStore.updateLabelsUnreadCountForKey(labelID, count: unread)
            }
        }
        
        var badgeNumber = lastUpdatedStore.UnreadCountForKey(.inbox)
        if  badgeNumber < 0 {
            badgeNumber = 0
        }
        UIApplication.setBadge(badge: badgeNumber)
        //UIApplication.shared.applicationIconBadgeNumber = badgeNumber
    }
    
    func cleanLocalMessageCache(_ completion: CompletionBlock?) {
        let getLatestEventID = EventLatestIDRequest<EventLatestIDResponse>()
        getLatestEventID.call() { task, response, hasError in
            if response != nil && !hasError && !response!.eventID.isEmpty {
                let completionWrapper: CompletionBlock = { task, responseDict, error in
                    if error == nil {
                        lastUpdatedStore.clear();
                        lastUpdatedStore.lastEventID = response!.eventID
                    }
                    completion?(task, nil, error)
                }
                
                self.cleanMessage()
                sharedContactDataService.clean()
                sharedLabelsDataService.fetchLabels();
                self.fetchMessagesForLocation(MessageLocation.inbox, MessageID: "", Time: 0, foucsClean: false, completion: completionWrapper)
               
                sharedContactDataService.fetchContacts(completion: nil)
            }
        }
    }
    
    
    /**
     this function to process the event logs
     
     :param: messages   the message event log
     :param: task       NSURL session task
     :param: completion complete call back
     */
    fileprivate func processIncrementalUpdateMessages(_ notificationMessageID: String?, messages: [[String : Any]], task: URLSessionDataTask!, completion: CompletionBlock?) {
        struct IncrementalUpdateType {
            static let delete = 0
            static let insert = 1
            static let update1 = 2
            static let update2 = 3
        }
        
        // this serial dispatch queue prevents multiple messages from appearing when an incremental update is triggered while another is in progress
        self.incrementalUpdateQueue.sync {
            let context = sharedCoreDataService.newMainManagedObjectContext()
            context.perform { () -> Void in
                var error: NSError?
                var messagesNoCache : [Message] = [];
                for message in messages {
                    let msg = MessageEvent(event: message)
                    switch(msg.Action) {
                    case .some(IncrementalUpdateType.delete):
                        if let messageID = msg.ID {
                            if let message = Message.messageForMessageID(messageID, inManagedObjectContext: context) {
                                let labelObjs = message.mutableSetValue(forKey: "labels")
                                labelObjs.removeAllObjects()
                                message.setValue(labelObjs, forKey: "labels")
                                context.delete(message)
                            }
                        }
                    case .some(IncrementalUpdateType.insert), .some(IncrementalUpdateType.update1), .some(IncrementalUpdateType.update2):
                        if IncrementalUpdateType.insert == msg.Action {
                            if let cachedMessage = Message.messageForMessageID(msg.ID, inManagedObjectContext: context) {
                                if cachedMessage.location != MessageLocation.draft && cachedMessage.location != MessageLocation.outbox {
                                    self.tempUnreadAddjustCount = cachedMessage.unRead ? 0 : -1
                                    continue
                                }
                            }
                            if let notify_msg_id = notificationMessageID {
                                if notify_msg_id == msg.ID {
                                    let _ = msg.message?.removeValue(forKey: "Unread")
                                }
                            }
                            msg.message?["messageStatus"] = 1
                        }
                        
                        if let lo = msg.message?["Location"] as? Int {
                            if lo == 1 { //if it is a draft
                                if let exsitMes = Message.messageForMessageID(msg.ID , inManagedObjectContext: context) {
                                    if exsitMes.messageStatus == 1 {
                                        if let subject = msg.message?["Subject"] as? String {
                                            exsitMes.title = subject
                                        }
                                        if let timeValue = msg.message?["Time"] {
                                            if let timeString = timeValue as? NSString {
                                                let time = timeString.doubleValue as TimeInterval
                                                if time != 0 {
                                                    exsitMes.time = time.asDate()
                                                }
                                            } else if let dateNumber = timeValue as? NSNumber {
                                                let time = dateNumber.doubleValue as TimeInterval
                                                if time != 0 {
                                                    exsitMes.time = time.asDate()
                                                }
                                            }
                                        }
                                        continue;
                                    }
                                }
                            }
                        }
                        do {
                            if let messageObject = try GRTJSONSerialization.object(withEntityName: Message.Attributes.entityName, fromJSONDictionary: msg.message ?? [String : Any](), in: context) as? Message {
                                // apply the label changes
                                if let deleted = msg.message?["LabelIDsRemoved"] as? NSArray {
                                    for delete in deleted {
                                        let labelID = delete as! String
                                        if let label = Label.labelForLableID(labelID, inManagedObjectContext: context) {
                                            let labelObjs = messageObject.mutableSetValue(forKey: "labels")
                                            if labelObjs.count > 0 {
                                                labelObjs.remove(label)
                                                messageObject.setValue(labelObjs, forKey: "labels")
                                            }
                                        }
                                        if labelID == "1" {
                                            messageObject.isDetailDownloaded = false
                                        }
                                    }
                                }
                                
                                if let added = msg.message?["LabelIDsAdded"] as? NSArray {
                                    for add in added {
                                        if let label = Label.labelForLableID(add as! String, inManagedObjectContext: context) {
                                            let labelObjs = messageObject.mutableSetValue(forKey: "labels")
                                            labelObjs.add(label)
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
                    PMLog.D(" error: \(String(describing: error))")
                }
                
                self.fetchMessagesWithIDs(messagesNoCache)
                
                DispatchQueue.main.async {
                    completion?(task, nil, error)
                    return
                }
            }
        }
    }
    
    
    func fetchMessagesWithIDs (_ messages : [Message]) {
        if messages.count > 0 {
            queue {
                let completionWrapper: CompletionBlock = { task, responseDict, error in
                    if let messagesArray = responseDict?["Messages"] as? [[String : Any]] {
                        let context = sharedCoreDataService.newMainManagedObjectContext()
                        context.perform() {
                            do {
                                if let messages = try GRTJSONSerialization.objects(withEntityName: Message.Attributes.entityName, fromJSONArray: messagesArray, in: context) as? [Message] {
                                    for message in messages {
                                        message.messageStatus = 1
                                    }
                                    if let error = context.saveUpstreamIfNeeded() {
                                        PMLog.D("GRTJSONSerialization.mergeObjectsForEntityName saveUpstreamIfNeeded failed \(error)")
                                    }
                                } else {
                                    PMLog.D("GRTJSONSerialization.mergeObjectsForEntityName failed \(String(describing: error))")
                                }
                            } catch {
                                PMLog.D("fetchMessagesWithIDs failed \(error)")
                            }
                        }
                    } else {
                        PMLog.D("fetchMessagesWithIDs can't get the response Messages")
                    }
                }
                
                let request = FetchMessagesByID(messages: messages)
                sharedAPIService.GET(request, completion: completionWrapper)
            }
        }
    }
    
    
    // old functions
    
    /// downloadTask returns the download task for use with UIProgressView+AFNetworking
    func fetchAttachmentForAttachment(_ attachment: Attachment, downloadTask: ((URLSessionDownloadTask) -> Void)?, completion:((URLResponse?, URL?, NSError?) -> Void)?) {
        if let localURL = attachment.localURL {
            completion?(nil, localURL as URL, nil)
            return
        }
        
        // TODO: check for existing download tasks and return that task rather than start a new download
        queue { () -> Void in
            if attachment.managedObjectContext != nil {
                sharedAPIService.downloadAttachment(byID: attachment.attachmentID,
                                                    destinationDirectoryURL: FileManager.default.attachmentDirectory,
                                                    downloadTask: downloadTask,
                                                    completion: { task, fileURL, error in
                                                        var error = error
                                                        if let context = attachment.managedObjectContext {
                                                            if let fileURL = fileURL {
                                                                attachment.localURL = fileURL
                                                                attachment.fileData = try? Data(contentsOf: fileURL)
                                                                error = context.saveUpstreamIfNeeded()
                                                                if error != nil  {
                                                                    PMLog.D(" error: \(String(describing: error))")
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
    
    func ForcefetchDetailForMessage(_ message: Message, completion: @escaping CompletionFetchDetail) {
        queue {
            let completionWrapper: CompletionBlock = { task, response, error in
                let context = sharedCoreDataService.newMainManagedObjectContext()
                context.perform() {
                    var error: NSError?
                    if response != nil {
                        //TODO need check the respons code
                        if var msg: [String:Any] = response?["Message"] as? [String : Any] {
                            msg.removeValue(forKey: "Location")
                            msg.removeValue(forKey: "Starred")
                            msg.removeValue(forKey: "test")
                            do {
                                try GRTJSONSerialization.object(withEntityName: Message.Attributes.entityName, fromJSONDictionary: msg, in: message.managedObjectContext!)
                                message.isDetailDownloaded = true
                                message.messageStatus = 1
                                message.needsUpdate = true
                                message.unRead = false
                                let _ = message.managedObjectContext?.saveUpstreamIfNeeded()
                                error = context.saveUpstreamIfNeeded()
                                DispatchQueue.main.async {
                                    completion(task, response, message, error)
                                }
                            } catch let ex as NSError {
                                DispatchQueue.main.async {
                                    completion(task, response, message, ex)
                                }
                            }
                        } else {
                            DispatchQueue.main.async {
                                completion(task, response, nil, NSError.badResponse())
                            }
                        }
                    } else {
                        error = NSError.unableToParseResponse(response)
                        DispatchQueue.main.async {
                            completion(task, response, nil, error)
                        }
                    }
                    if error != nil  {
                        PMLog.D(" error: \(String(describing: error))")
                    }
                }
            }
            sharedAPIService.messageDetail(messageID: message.messageID, completion: completionWrapper)
        }
    }
    
    func fetchMessageDetailForMessage(_ message: Message, completion: @escaping CompletionFetchDetail) {
        if !message.isDetailDownloaded {
            queue {
                let completionWrapper: CompletionBlock = { task, response, error in
                    if let context = message.managedObjectContext {
                        context.perform() {
                            if response != nil {
                                //TODO need check the respons code
                                PMLog.D("\(String(describing: response))")
                                if var msg: [String : Any] = response?["Message"] as? [String : Any] {
                                    msg.removeValue(forKey: "Location")
                                    msg.removeValue(forKey: "Starred")
                                    msg.removeValue(forKey: "test")
                                    do {
                                        if let message_n = try GRTJSONSerialization.object(withEntityName: Message.Attributes.entityName, fromJSONDictionary: msg, in: context) as? Message {
                                            message_n.messageStatus = 1
                                            message_n.isDetailDownloaded = true
                                            message_n.needsUpdate = true
                                            message_n.unRead = false
                                            if let ctx = message_n.managedObjectContext {
                                                if let error = ctx.saveUpstreamIfNeeded() {
                                                    PMLog.D("\(error)")
                                                }
                                            }
                                            let tmpError = context.saveUpstreamIfNeeded()
                                            DispatchQueue.main.async {
                                                completion(task, response, message_n, tmpError)
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
                    } else {
                        DispatchQueue.main.async {
                            completion(task, response, nil, NSError.badResponse()) // the message have been deleted
                        }
                    }
                }
                sharedAPIService.messageDetail(messageID: message.messageID, completion: completionWrapper)
            }
        } else {
            DispatchQueue.main.async {
                completion(nil, nil, message, nil)
            }
        }
    }
    
    
    func fetchNotificationMessageDetail(_ messageID: String, completion: @escaping CompletionFetchDetail) {
        queue {
            let completionWrapper: CompletionBlock = { task, response, error in
                DispatchQueue.main.async {
                    let context = sharedCoreDataService.newMainManagedObjectContext()
                    context.perform() {
                        if response != nil {
                            //TODO need check the respons code
                            if var msg: [String : Any] = response?["Message"] as? [String : Any] {
                                msg.removeValue(forKey: "Location")
                                msg.removeValue(forKey: "Starred")
                                msg.removeValue(forKey: "test")
                                do {
                                    var needOffset = 0
                                    if let msg = Message.messageForMessageID(messageID, inManagedObjectContext: context) {
                                        needOffset = msg.unRead ? -1 : 0
                                    }
                                    if let message_out = try GRTJSONSerialization.object(withEntityName: Message.Attributes.entityName, fromJSONDictionary: msg, in: context) as? Message {
                                        message_out.messageStatus = 1
                                        message_out.isDetailDownloaded = true
                                        message_out.needsUpdate = false
                                        
                                        var count = lastUpdatedStore.UnreadCountForKey(.inbox)
                                        if message_out.unRead == true {
                                            message_out.unRead = false
                                            self.queue(message_out, action: .read)
                                            
                                            count = count + needOffset
                                            if count < 0 {
                                                count = 0
                                            }
                                            lastUpdatedStore.updateUnreadCountForKey(.inbox, count: count)
                                        }
                                        let _ = message_out.managedObjectContext?.saveUpstreamIfNeeded()
                                        let tmpError = context.saveUpstreamIfNeeded()
                                        
                                        UIApplication.setBadge(badge: count)
                                        //UIApplication.shared.applicationIconBadgeNumber = count
                                        DispatchQueue.main.async {
                                            completion(task, response, message_out, tmpError)
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
            }
            
            if let context = sharedCoreDataService.mainManagedObjectContext {
                if let message = Message.messageForMessageID(messageID, inManagedObjectContext: context) {
                    if message.isDetailDownloaded {
                        completion(nil, nil, message, nil)
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
    func fetchedResultsControllerForLocation(_ location: MessageLocation) -> NSFetchedResultsController<NSFetchRequestResult>? {
        if let moc = managedObjectContext {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: Message.Attributes.entityName)
            fetchRequest.predicate = NSPredicate(format: "(ANY labels.labelID =[cd] %@) AND (%K > 0)", "\(location.rawValue)", Message.Attributes.messageStatus)
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: Message.Attributes.time, ascending: false)]
            return NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: moc, sectionNameKeyPath: nil, cacheName: nil)
        }
        return nil
    }
    
    func fetchedResultsControllerForLabels(_ label: Label) -> NSFetchedResultsController<NSFetchRequestResult>? {
        if let moc = managedObjectContext {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: Message.Attributes.entityName)
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
    func fetchedMessageControllerForID(_ messageID: String) -> NSFetchedResultsController<NSFetchRequestResult>? {
        if let moc = managedObjectContext {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: Message.Attributes.entityName)
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
    fileprivate func cleanUp() {
        self.cleanMessage()
        
        lastUpdatedStore.clear()
        sharedMessageQueue.clear()
        sharedFailedQueue.clear()
        
        //tempary for clean contact cache
        sharedContactDataService.clean() //here need move to a general data service manager
        sharedLabelsDataService.cleanUp()
    }
    
    fileprivate func cleanMessage() {
        if let context = managedObjectContext {
            Message.deleteAll(inContext: context) // will cascadely remove appropriate Attacments also
        }
        UIApplication.setBadge(badge: 0)
        //UIApplication.shared.applicationIconBadgeNumber = 0
        
        // good opportunity to remove all temp folders (they should be empty by this moment)
        try? FileManager.default.removeItem(at: FileManager.default.appGroupsTempDirectoryURL)
    }
    
    func search(_ query: String, page: Int, completion: (([Message]?, NSError?) -> Void)?) {
        queue {
            let completionWrapper: CompletionBlock = {task, response, error in
                if error != nil {
                    completion?(nil, error)
                }
                
                if let context = sharedCoreDataService.mainManagedObjectContext {
                    if let messagesArray = response?["Messages"] as? [[String : Any]] {
                        context.perform() {
                            do {
                                if let messages = try GRTJSONSerialization.objects(withEntityName: Message.Attributes.entityName, fromJSONArray: messagesArray, in: context) as? [Message] {
                                    for message in messages {
                                        message.messageStatus = 1
                                    }
                                    if let error = context.saveUpstreamIfNeeded() {
                                        PMLog.D(" error: \(error)")
                                    }
                                    DispatchQueue.main.async {
                                        if error != nil  {
                                            PMLog.D(" error: \(String(describing: error))")
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
                                    DispatchQueue.main.async {
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
    
    func saveDraft(_ message : Message!) {
        if let context = message.managedObjectContext {
            context.performAndWait {
                if let error = context.saveUpstreamIfNeeded() {
                    PMLog.D(" error: \(error)")
                } else {
                    self.queue(message, action: .saveDraft)
                }
            }
        }
    }
    
    func deleteDraft (_ message : Message!) {
        if let context = sharedCoreDataService.mainManagedObjectContext {
            if let error = context.saveUpstreamIfNeeded() {
                PMLog.D(" error: \(error)")
            } else {
                self.queue(message, action: .delete)
            }
        }
    }
    
    func purgeOldMessages() {
        // need fetch status bad messages
        if let context = sharedCoreDataService.mainManagedObjectContext {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: Message.Attributes.entityName)
            fetchRequest.predicate = NSPredicate(format: "%K == 0", Message.Attributes.messageStatus)
            do {
                
                if let badMessages = try context.fetch(fetchRequest) as? [Message] {
                    self.fetchMessagesWithIDs(badMessages);
                }
            } catch let ex as NSError {
                ex.upload(toFabric: "purgeOldMessages")
                PMLog.D("error : \(ex)")
            }
        }
    }
    
    // MARK: - Private methods
    fileprivate func generatMessagePackage<T : ApiResponse> (_ message: Message!, keys : [String : Any]?, atts : [Attachment], encrptOutside : Bool) -> MessageSendRequest<T>! {
        
        let outRequest : MessageSendRequest = MessageSendRequest<T>(messageID: message.messageID, expirationTime: message.expirationOffset, messagePackage: nil, clearBody: "", attPackages: nil)
        
        do {
            var tempAtts : [TempAttachment]! = []
            for att in atts {
                if att.managedObjectContext != nil {
                    if let sessionKey = try att.getSession() {
                        tempAtts.append(TempAttachment(id: att.attachmentID, session: sessionKey))
                    }
                }
            }
            
            var out : [MessagePackage] = []
            var needsPlainText : Bool = false
            
            let privKey = message.defaultAddress?.keys[0].private_key ?? ""
            let pwd = sharedUserDataService.mailboxPassword ?? ""
            
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
                                let encryptedBody = try body.encrypt(withPwd: message.password)
                                //create outside encrypt packet
                                let token = String.randomString(32) as String
                                let based64Token = token.encodeBase64() as String
                                let encryptedToken = try based64Token.encrypt(withPwd: message.password)
                                
                                // encrypt keys use key
                                var attPack : [AttachmentKeyPackage] = []
                                for att in tempAtts {
                                    let newKeyPack = try att.Session?.getSymmetricPacket(withPwd: message.password)?.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0)) ?? ""
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
                            // encrypt keys use key
                            var attPack : [AttachmentKeyPackage] = []
                            for att in tempAtts {
                                //attID:String!, attKey:String!, Algo : String! = ""
                                let newKeyPack = try att.Session?.getKeyPackage(strKey: publicKey)?.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0)) ?? ""
                                let attPacket = AttachmentKeyPackage(attID: att.ID, attKey: newKeyPack)
                                attPack.append(attPacket)
                            }
                            //create inside packet
                            if let encryptedBody = try body.encrypt(withPubKey: publicKey, privateKey: privKey, mailbox_pwd: pwd) {
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
                        let newKeyPack = att.Session?.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0)) ?? ""
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
    
    fileprivate func attachmentsForMessage(_ message: Message) -> [Attachment] {
        if let all = message.attachments.allObjects as? [Attachment] {
            return all
        }
        return []
    }
    
    fileprivate func messageBodyForMessage(_ message: Message, response: [String : Any]?) throws -> [String : String] {
        var messageBody: [String : String] = ["self" : message.body]
        
        let privKey = message.defaultAddress?.keys[0].private_key ?? ""
        let pwd = sharedUserDataService.mailboxPassword ?? ""
        
        do {
            if let keys = response?["keys"] as? [[String : String]] {
                if let body = try message.decryptBody() {
                    // encrypt body with each key
                    for publicKeys in keys {
                        for (email, publicKey) in publicKeys {
                            if let encryptedBody = try body.encrypt(withPubKey: publicKey, privateKey: privKey, mailbox_pwd: pwd) {
                                messageBody[email] = encryptedBody
                            }
                        }
                    }
                    messageBody["outsiders"] = (message.checkIsEncrypted() == true ? message.passwordEncryptedBody : body)
                }
            } else {
                PMLog.D(" unable to parse response: \(String(describing: response))")
            }
        } catch let ex as NSError {
            PMLog.D(" unable to decrypt \(message.body) with error: \(ex)")
            
        }
        return messageBody
    }
    
    fileprivate func draft(save messageID: String, writeQueueUUID: UUID, completion: CompletionBlock?) {
        if let context = managedObjectContext {
            if let objectID = sharedCoreDataService.managedObjectIDForURIRepresentation(messageID) {
                do {
                    if let message = try context.existingObject(with: objectID) as? Message {
                        let completionWrapper: CompletionBlock = { task, response, error in
                            PMLog.D("SendAttachmentDebug == finish save draft!")
                            if let mess = response {
                                if let messageID = mess["ID"] as? String {
                                    message.messageID = messageID
                                    message.isDetailDownloaded = true
                                    
                                    var hasTemp = false;
                                    let attachments = message.mutableSetValue(forKey: "attachments")
                                    for att in attachments {
                                        if let att = att as? Attachment {
                                            if att.isTemp {
                                                hasTemp = true;
                                                context.delete(att)
                                            }
                                            att.keyChanged = false
                                        }
                                    }
                                    
                                    
                                    if let subject = mess["Subject"] as? String {
                                        message.title = subject
                                    }
                                    if let timeValue = mess["Time"] {
                                        if let timeString = timeValue as? NSString {
                                            let time = timeString.doubleValue as TimeInterval
                                            if time != 0 {
                                                message.time = time.asDate()
                                            }
                                        } else if let dateNumber = timeValue as? NSNumber {
                                            let time = dateNumber.doubleValue as TimeInterval
                                            if time != 0 {
                                                message.time = time.asDate()
                                            }
                                        }
                                    }
                                    
                                    
                                    if let error = context.saveUpstreamIfNeeded() {
                                        PMLog.D(" error: \(error)")
                                    }
                                    
                                    if hasTemp {
                                        do {
                                            try GRTJSONSerialization.object(withEntityName: Message.Attributes.entityName, fromJSONDictionary: mess, in: context)
                                            if let save_error = context.saveUpstreamIfNeeded() {
                                                PMLog.D(" error: \(save_error)")
                                            }
                                        } catch let exc as NSError {
                                            completion?(task, response, exc)
                                            return
                                        }
                                    }
                                    completion?(task, response, error)
                                    return
                                } else {//error
                                    completion?(task, response, error)
                                    return
                                }
                            } else {//error
                                completion?(task, response, error)
                                return
                            }
                        }
                        
                        PMLog.D("SendAttachmentDebug == start save draft!")
                        if message.isDetailDownloaded && message.messageID != "0" {
                            let api = UpdateDraft(message: message)
                            api.call({ (task, response, hasError) -> Void in
                                if hasError {
                                    completionWrapper(task, nil, response?.error)
                                } else {
                                    completionWrapper(task, response?.message, nil)
                                }
                            })
                        } else {
                            let api = CreateDraft(message: message)
                            api.call({ (task, response, hasError) -> Void in
                                if hasError {
                                    completionWrapper(task, nil, response?.error)
                                } else {
                                    completionWrapper(task, response?.message, nil)
                                }
                            })
                        }
                        return;
                    }
                } catch let ex as NSError {
                    completion?(nil, nil, ex)
                    return;
                }
            }
        }
        
        // nothing to send, dequeue request
        let _ = sharedMessageQueue.remove(writeQueueUUID)
        self.dequeueIfNeeded()
        completion?(nil, nil, NSError.badParameter(messageID))
    }
    
    
    fileprivate func uploadAttachmentWithAttachmentID (_ addressID: String, writeQueueUUID: UUID, completion: CompletionBlock?) {
        if let context = managedObjectContext {
            if let objectID = sharedCoreDataService.managedObjectIDForURIRepresentation(addressID) {
                
                var msgObject : NSManagedObject?
                do {
                    msgObject = try context.existingObject(with: objectID)
                } catch {
                    msgObject = nil
                }
                
                if let attachment = msgObject as? Attachment {
                    var params = [
                        "Filename":attachment.fileName,
                        "MIMEType" : attachment.mimeType,
                        ]
                    
                    var default_address_id = sharedUserDataService.userAddresses.defaultSendAddress()?.address_id ?? ""
                    //TODO::here need to fix sometime message is not valid'
                    if attachment.message.managedObjectContext == nil {
                        params["MessageID"] =  ""
                    } else {
                        params["MessageID"] =  attachment.message.messageID 
                        default_address_id = attachment.message.getAddressID
                    }
                    
                    let pwd = sharedUserDataService.mailboxPassword ?? ""
                    let encrypt_data = attachment.encrypt(byAddrID: default_address_id, mailbox_pwd: pwd)
                    //TODO:: here need check is encryptdata is nil and return the error to user.
                    let keyPacket = encrypt_data?.keyPacket()
                    let dataPacket = encrypt_data?.dataPacket()
                    let signed = attachment.sign(byAddrID: default_address_id, mailbox_pwd: pwd)
                    let completionWrapper: CompletionBlock = { task, response, error in
                        PMLog.D("SendAttachmentDebug == finish upload att!")
                        if error == nil {
                            if let messageID = response?["AttachmentID"] as? String {
                                attachment.attachmentID = messageID
                                attachment.keyPacket = keyPacket?.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0)) ?? ""
                                
                                // since the encrypted attachment is successfully uploaded, we no longer need it cleartext in db
                                attachment.fileData = nil
                                if let fileUrl = attachment.localURL,
                                    let _ = try? FileManager.default.removeItem(at: fileUrl)
                                {
                                    attachment.localURL = nil
                                }
                                if let error = context.saveUpstreamIfNeeded() {
                                    PMLog.D(" error: \(error)")
                                }
                            }
                        }
                        completion?(task, response, error)
                    }
                    PMLog.D("SendAttachmentDebug == start upload att!")
                    sharedAPIService.upload( byUrl: AppConstants.API_HOST_URL + AppConstants.API_PATH + "/attachments",
                                             parameters: params,
                                             keyPackets: keyPacket,
                                             dataPacket: dataPacket,
                                             signature: signed,
                                             headers: ["x-pm-apiversion":3],
                                             authenticated: true,
                                             completion: completionWrapper)
                    return
                }
            }
        }
        
        // nothing to send, dequeue request
        let _ = sharedMessageQueue.remove(writeQueueUUID)
        self.dequeueIfNeeded()
        
        completion?(nil, nil, NSError.badParameter(addressID))
    }
    
    fileprivate func deleteAttachmentWithAttachmentID (_ deleteObject: String, writeQueueUUID: UUID, completion: CompletionBlock?) {
        if let _ = managedObjectContext {
            let api = DeleteAttachment(attID: deleteObject)
            api.call({ (task, response, hasError) -> Void in
                completion?(task, nil, nil)
            })
            return
        }
        
        // nothing to send, dequeue request
        let _ = sharedMessageQueue.remove(writeQueueUUID)
        self.dequeueIfNeeded()
        
        completion?(nil, nil, NSError.badParameter(deleteObject))
    }
    
    fileprivate func emptyMessageWithLocation (_ location: String, writeQueueUUID: UUID, completion: CompletionBlock?) {
        if let _ = managedObjectContext {
            let api = MessageEmptyRequest(location: location);
            api.call({ (task, response, hasError) -> Void in
                completion?(task, nil, nil)
            })
            return
        }
        
        // nothing to send, dequeue request
        let _ = sharedMessageQueue.remove(writeQueueUUID)
        self.dequeueIfNeeded()
        completion?(nil, nil, NSError.badParameter("\(location)"))
    }
    
    fileprivate func send(byID messageID: String, writeQueueUUID: UUID, completion: CompletionBlock?) {
        let errorBlock: CompletionBlock = { task, response, error in
            // nothing to send, dequeue request
            let _ = sharedMessageQueue.remove(writeQueueUUID)
            completion?(task, response, error)
        }
        
        if let context = managedObjectContext,
            let objectID = sharedCoreDataService.managedObjectIDForURIRepresentation(messageID),
            let message = context.find(with: objectID) as? Message {

            if message.managedObjectContext == nil {
                NSError.alertLocalCacheErrorToast()
                let err = RuntimeError.bad_draft.error
                Crashlytics.sharedInstance().recordError(err)
                errorBlock(nil, nil, err)
                return ;
            }
            
            var requests : [UserEmailPubKeys] = [UserEmailPubKeys]()
            let emails = message.allEmails
            for email in emails {
                requests.append(UserEmailPubKeys(email: email))
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
                sharedContactDataService.fetch(byEmails: emails, context: context)
            }.then { (cs) -> Guarantee<[Result<KeysResponse>]> in
                // fech email keys from api
                contacts.append(contentsOf: cs)
                return when(resolved: requests.promises)
            }.then { results -> Promise<SendBuilder> in
                //all prebuild errors need pop up from here
                guard let bodyData = try message.split()?.dataPacket(),
                        let session = try message.getSessionKey() else {
                    throw RuntimeError.cant_decrypt.error
                }

                sendBuilder.update(bodyData: bodyData, bodySession: session.session())
                sendBuilder.set(pwd: message.password, hit: message.passwordHint)
                for (index, result) in results.enumerated() {
                    switch result {
                    case .fulfilled(let value):
                        let req = requests[index]
                        //check contacts have pub key or not
                        if let contact = contacts.find(email: req.email) { //"zhj44781@gmail.com") {//req.email) {
                            if value.recipientType == 1 {
                                //if type is internal check is key match with contact key
                                //compare the key if doesn't match
                                sendBuilder.add(addr: PreAddress(email: req.email, pubKey: value.firstKey(), pgpKey: contact.firstPgpKey, recipintType: value.recipientType, eo: isEO, mime: false, sign: true, pgpencrypt: false, plainText: contact.plainText))
                            } else {
                                //sendBuilder.add(addr: PreAddress(email: req.email, pubKey: nil, pgpKey: contact.pgpKey, recipintType: value.recipientType, eo: isEO, mime: true))
                                sendBuilder.add(addr: PreAddress(email: req.email, pubKey: nil, pgpKey: contact.firstPgpKey, recipintType: value.recipientType, eo: isEO, mime: contact.mime, sign: contact.sign, pgpencrypt: contact.encrypt, plainText: contact.plainText))
                            }
                        } else {
                            sendBuilder.add(addr: PreAddress(email: req.email, pubKey: value.firstKey(), pgpKey: nil, recipintType: value.recipientType, eo: isEO, mime: false, sign: false, pgpencrypt: false, plainText: false))
                        }
                    case .rejected(let error):
                        throw error
                    }
                }

                if sendBuilder.hasMime || sendBuilder.hasPlainText {
                    guard let clearbody = try message.decryptBody() else {
                        throw RuntimeError.cant_decrypt.error
                    }
                    sendBuilder.set(clear: clearbody)
                }
                
                for att in attachments {
                    if att.managedObjectContext != nil {
                        if let sessionKey = try att.getSession() {
                            sendBuilder.add(att: PreAttachment(id: att.attachmentID, session: sessionKey, att: att))
                        }
                    }
                }
                return .value(sendBuilder)
            }.then{ (sendbuilder) -> Promise<SendBuilder> in
                if !sendBuilder.hasMime {
                    return .value(sendBuilder)
                }
                //build pgp sending mime body
                let addr = message.defaultAddress!.keys.first!
                let privateKey = addr.private_key
                let pubKey = addr.publicKey
                return sendBuilder.buildMime(pubKey: pubKey, privKey: privateKey)
            }.then{ (sendbuilder) -> Promise<SendBuilder> in
                if !sendBuilder.hasPlainText {
                    return .value(sendBuilder)
                }
                //build pgp sending mime body
                let addr = message.defaultAddress!.keys.first!
                let privateKey = addr.private_key
                let pubKey = addr.publicKey
                return sendBuilder.buildPlainText(pubKey: pubKey, privKey: privateKey)
            } .then { sendbuilder -> Guarantee<[Result<AddressPackageBase>]> in
                //build address packages
                return when(resolved: sendbuilder.promises)
            }.then { results -> Promise<ApiResponse> in
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
                
                let sendApi = SendMessage(messageID: message.messageID,
                                          expirationTime: message.expirationOffset,
                                          messagePackage: msgs,
                                          body: encodedBody,
                                          clearBody: sendBuilder.clearBodyPackage, clearAtts: sendBuilder.clearAtts,
                                          mimeDataPacket: sendBuilder.mimeBody, clearMimeBody: sendBuilder.clearMimeBodyPackage,
                                          plainTextDataPacket : sendBuilder.plainBody, clearPlainTextBody : sendBuilder.clearPlainBodyPackage
                )
                
                
                return sendApi.run()
            }.done { (res) in
                let error = res.error
                if error == nil {
                    if (message.location == MessageLocation.draft) {
                        if isEO {
                            if sendBuilder.outSideUser {
                                message.isEncrypted =  NSNumber(value: EncryptTypes.outEnc.rawValue)
                            } else {
                                message.isEncrypted = NSNumber(value: EncryptTypes.inner.rawValue);
                            }
                        } else {
                            if sendBuilder.outSideUser {
                                message.isEncrypted = NSNumber(value: EncryptTypes.outPlain.rawValue);
                            } else {
                                message.isEncrypted = NSNumber(value: EncryptTypes.inner.rawValue);
                            }
                        }
                        
                        if attachments.count > 0 {
                            message.hasAttachments = true;
                            message.numAttachments = NSNumber(value: attachments.count)
                        }
                        //TODO::fix later 1.7
                        message.mimeType = "text/html"
                        message.needsUpdate = false
                        message.unRead = false
                        lastUpdatedStore.ReadMailboxMessage(message.location)
                        message.location = MessageLocation.outbox
                        message.isDetailDownloaded = false
                        message.removeLocationFromLabels(currentlocation: .draft, location: .outbox, keepSent: true)
                    }
                    
                    NSError.alertMessageSentToast()
                    if let error = context.saveUpstreamIfNeeded() {
                        PMLog.D(" error: \(error)")
                    } else {
                        self.markReplyStatus(message.orginalMessageID, action: message.action)
                    }
                }
                else {
                    if error?.code == 9001 {
                        //here need let user to show the human check.
                        sharedMessageQueue.isRequiredHumanCheck = true
                        error?.alertSentErrorToast()
                    } else if error?.code == 15198 {
                        error?.alertSentErrorToast()
                    }  else {
                        error?.alertErrorToast()
                    }
                    NSError.alertMessageSentErrorToast()
                    error?.upload(toFabric: SendingErrorTitle)
                }
                completion?(nil, nil, error)
            }.catch { (error) in
                PMLog.D(error.localizedDescription)
                let err = error as NSError
                NSError.alertMessageSentError(details: error.localizedDescription)
                completion?(nil, nil, err)
            }
            return
        }
        errorBlock(nil, nil, NSError.badParameter(messageID))
    }
    
    //deprecated
    fileprivate func sendMessageID(_ messageID: String, writeQueueUUID: UUID, completion: CompletionBlock?) {
        let errorBlock: CompletionBlock = { task, response, error in
            // nothing to send, dequeue request
            let _ = sharedMessageQueue.remove(writeQueueUUID)
            completion?(task, response, error)
        }
        
        if let context = managedObjectContext,
            let objectID = sharedCoreDataService.managedObjectIDForURIRepresentation(messageID),
            let message = context.find(with: objectID) as? Message {
            PMLog.D("SendAttachmentDebug == start get key!")
            sharedAPIService.userPublicKeysForEmails(message.allEmailAddresses, completion: { (task, response, error) -> Void in
                PMLog.D("SendAttachmentDebug == finish get key!")
                if error != nil && error!.code == APIErrorCode.badParameter {
                    errorBlock(task, response, error)
                    return
                }
                
                if message.managedObjectContext == nil {
                    NSError.alertLocalCacheErrorToast()
                    let err = RuntimeError.bad_draft.error
                    Crashlytics.sharedInstance().recordError(err)
                    errorBlock(task, nil, err)
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
                //_ = try? self.messageBodyForMessage(message, response: response)
                
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
                                    message.isEncrypted =  NSNumber(value: EncryptTypes.outEnc.rawValue)
                                } else {
                                    message.isEncrypted = NSNumber(value: EncryptTypes.inner.rawValue);
                                }
                            } else {
                                if isOutsideUser {
                                    message.isEncrypted = NSNumber(value: EncryptTypes.outPlain.rawValue);
                                } else {
                                    message.isEncrypted = NSNumber(value: EncryptTypes.inner.rawValue);
                                }
                            }
                            
                            if attachments.count > 0 {
                                message.hasAttachments = true;
                                message.numAttachments = NSNumber(value: attachments.count)
                            }
                            //TODO::fix later 1.7
                            message.mimeType = "text/html"
                            
                            message.needsUpdate = false
                            message.unRead = false
                            lastUpdatedStore.ReadMailboxMessage(message.location)
                            message.location = MessageLocation.outbox
                            message.isDetailDownloaded = false
                            message.removeLocationFromLabels(currentlocation: .draft, location: .outbox, keepSent: true)
                        }
                        
                        NSError.alertMessageSentToast()
                        if let error = context.saveUpstreamIfNeeded() {
                            PMLog.D(" error: \(error)")
                        } else {
                            self.markReplyStatus(message.orginalMessageID, action: message.action)
                        }
                    }
                    else {
                        if error?.code == 9001 {
                            //here need let user to show the human check.
                            sharedMessageQueue.isRequiredHumanCheck = true
                            error?.alertSentErrorToast()
                        } else if error?.code == 15198 {
                            error?.alertSentErrorToast()
                        }  else {
                            //error?.alertErrorToast()
                        }
                        //NSError.alertMessageSentErrorToast()
                        error?.upload(toFabric: SendingErrorTitle)
                    }
                    completion?(task, response, error)
                    return
                }
                PMLog.D("SendAttachmentDebug == start send email!")
                sendMessage!.call({ (task, response, hasError) -> Void in
                    if hasError {
                        completionWrapper(task, nil, response?.error)
                    } else {
                        completionWrapper(task, nil, nil)
                    }
                })
            })
            
            return
            //            }
            
        }
        errorBlock(nil, nil, NSError.badParameter(messageID))
    }

    fileprivate func markReplyStatus(_ oriMsgID : String?, action : NSNumber?) {
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
                                    if let context = message.managedObjectContext {
                                        if let error = context.saveUpstreamIfNeeded() {
                                            PMLog.D(" error: \(error)")
                                        }
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
    
    fileprivate func setupNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(MessageDataService.didSignOutNotification(_:)), name: NSNotification.Name(rawValue: NotificationDefined.didSignOut), object: nil)
        // TODO: add monitoring for didBecomeActive
    }
    
    @objc fileprivate func didSignOutNotification(_ notification: Notification) {
        cleanUp()
    }
    
    // MARK: Queue
    fileprivate func writeQueueCompletionBlockForElementID(_ elementID: UUID, messageID : String, actionString : String) -> CompletionBlock {
        return { task, response, error in
            sharedMessageQueue.isInProgress = false
            if error == nil {
                if let action = MessageAction(rawValue: actionString) {
                    if action == MessageAction.delete {
                        Message.deleteMessage(messageID)
                    }
                }
                let _ = sharedMessageQueue.remove(elementID)
                self.dequeueIfNeeded()
            } else {
                PMLog.D(" error: \(String(describing: error))")
                var statusCode = 200;
                var isInternetIssue = false
                if let errorUserInfo = error?.userInfo {
                    if let detail = errorUserInfo["com.alamofire.serialization.response.error.response"] as? HTTPURLResponse {
                        statusCode = detail.statusCode
                    }
                    else {
                        if error?.code == -1009 || error?.code == -1004 || error?.code == -1001 { //internet issue
                            if error?.code == -1001 {
                                NotificationCenter.default.post(Notification(name: NSNotification.Name.reachabilityChanged, object: 0, userInfo: nil))
                            } else {
                                NotificationCenter.default.post(Notification(name: NSNotification.Name.reachabilityChanged, object: 1, userInfo: nil))
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
                            PMLog.D("message queue count : \(String(describing: count))")
                            let _ = sharedMessageQueue.remove(elementID)
                        }
                    }
                }
                
                //need add try times and check internet status
                if statusCode == 500 && !isInternetIssue {
                    if  let (uuid, object) = sharedMessageQueue.next() {
                        if let element = object as? [String : String] {
                            let count = element["count"]
                            PMLog.D("message queue count : \(String(describing: count))")
                            let _ = sharedFailedQueue.add(uuid, object: element as NSCoding)
                            let _ = sharedMessageQueue.remove(elementID)
                        }
                    }
                }
                
                if statusCode == 200 && error?.code == 9001 {
                    
                } else if statusCode == 200 && error?.code > 1000 {
                    //show error
                    let _ = sharedMessageQueue.remove(elementID)
                    //TODO:: pop some errors here
                }
                
                if statusCode != 200 && statusCode != 404 && statusCode != 500 && !isInternetIssue {
                    //show error
                    let _ = sharedMessageQueue.remove(elementID)
                    error?.upload(toFabric: QueueErrorTitle)
                }
                
                if !isInternetIssue {
                    self.dequeueIfNeeded()
                } else {
                    if !sharedMessageQueue.isBlocked && self.readQueue.count > 0 {
                        PMLog.D("left redaQueue count : \(self.readQueue.count)")
                        self.readQueue.remove(at: 0)()
                        self.dequeueIfNeeded()
                    }
                }
            }
        }
    }
    
    var dequieNotify : (() -> Void)?
    
    func backgroundFetch(notify : (() -> Void)?) {
        self.dequeueIfNeeded(notify: notify)
    }
    
    fileprivate func dequeueIfNeeded(notify : (() -> Void)? = nil) {
        
        if notify == nil {
            if sharedMessageQueue.count <= 0 && readQueue.count <= 0 {
                self.dequieNotify?()
                self.dequieNotify = nil
            }
        } else {
            self.dequieNotify = notify
        }
        
        if let (uuid, messageID, actionString) = sharedMessageQueue.nextMessage() {
            PMLog.D("SendAttachmentDebug == dequeue --- \(actionString)")
            if let action = MessageAction(rawValue: actionString) {
                sharedMessageQueue.isInProgress = true
                switch action {
                case .saveDraft:
                    draft(save: messageID, writeQueueUUID: uuid, completion: writeQueueCompletionBlockForElementID(uuid, messageID: messageID, actionString: actionString))
                case .send:
                    send(byID: messageID, writeQueueUUID: uuid, completion: writeQueueCompletionBlockForElementID(uuid, messageID: messageID, actionString: actionString))
                case .uploadAtt:
                    uploadAttachmentWithAttachmentID(messageID, writeQueueUUID: uuid, completion: writeQueueCompletionBlockForElementID(uuid, messageID: messageID, actionString: actionString))
                case .deleteAtt:
                    deleteAttachmentWithAttachmentID(messageID, writeQueueUUID: uuid, completion: writeQueueCompletionBlockForElementID(uuid, messageID: messageID, actionString: actionString))
                case .emptyTrash:
                    emptyMessageWithLocation("trash", writeQueueUUID: uuid, completion: writeQueueCompletionBlockForElementID(uuid, messageID: messageID, actionString: actionString))
                case .emptySpam:
                    emptyMessageWithLocation("spam", writeQueueUUID: uuid, completion: writeQueueCompletionBlockForElementID(uuid, messageID: messageID, actionString: actionString))
                case .read, .unread: //1.9.1
                    sharedAPIService.PUT(MessageActionRequest(action: actionString, ids: [messageID]), completion: writeQueueCompletionBlockForElementID(uuid, messageID: messageID, actionString: actionString))
                default:
                    sharedAPIService.PUT(MessageActionRequest(action: actionString, ids: [messageID]), completion: writeQueueCompletionBlockForElementID(uuid, messageID: messageID, actionString: actionString))
                }
            } else {
                PMLog.D(" Unsupported action \(actionString), removing from queue.")
                let _ = sharedMessageQueue.remove(uuid)
            }
        } else if !sharedMessageQueue.isBlocked && readQueue.count > 0 { //sharedMessageQueue.count == 0 &&
            readQueue.remove(at: 0)()
            dequeueIfNeeded()
        }
    }
    
    
    fileprivate func queue(_ message: Message, action: MessageAction) {
        if action == .saveDraft || action == .send {
            //TODO:: need to handle the empty instead of !
            let _ = sharedMessageQueue.addMessage(message.objectID.uriRepresentation().absoluteString, action: action)
        } else {
            if message.managedObjectContext != nil && !message.messageID.isEmpty {
                let _ = sharedMessageQueue.addMessage(message.messageID, action: action)
            }
        }
        dequeueIfNeeded()
    }
    
    fileprivate func queue(_ action: MessageAction) {
        let _ = sharedMessageQueue.addMessage("", action: action)
        dequeueIfNeeded()
    }
    
    fileprivate func queue(_ att: Attachment, action: MessageAction) {
        let _ = sharedMessageQueue.addMessage(att.objectID.uriRepresentation().absoluteString, action: action)
        dequeueIfNeeded()
    }
    
    fileprivate func queue(_ readBlock: @escaping ReadBlock) {
        readQueue.append(readBlock)
        dequeueIfNeeded()
    }
    
    // MARK: message monitor
    fileprivate func setupMessageMonitoring() {
        sharedMonitorSavesDataService.registerMessage(attribute: Message.Attributes.locationNumber, handler: { message in
            if message.needsUpdate {
                if let action = message.location.moveAction {
                    self.queue(message, action: action)
                } else {
                    PMLog.D(" \(message.messageID) move to \(message.location) was not a user initiated move.")
                }
            }
        })
        
        sharedMonitorSavesDataService.registerMessage(attribute: Message.Attributes.unRead, handler: { message in
            if message.needsUpdate {
                let action: MessageAction = message.unRead ? .unread : .read
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
    
    
    // MARK: process events
}
