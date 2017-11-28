//
//  EventDataService.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 11/28/17.
//  Copyright © 2017 ProtonMail. All rights reserved.
//

import Foundation



class EventDataService {
    typealias FetchEventComplete = APIService.CompletionBlock
    func fetchEvents(completion: FetchEventComplete?) {
        let eventAPI = EventCheckRequest<EventCheckResponse>(eventID: lastUpdatedStore.lastEventID)
        eventAPI.call() { task, _eventsRes, _hasEventsError in
            
            
            
//            if let eventsRes = _eventsRes {
//                if eventsRes.isRefresh || (_hasEventsError && eventsRes.code == 18001) {
//                    let getLatestEventID = EventLatestIDRequest<EventLatestIDResponse>()
//                    getLatestEventID.call() { task, _IDRes, hasIDError in
//                        if let IDRes = _IDRes, !hasIDError && !IDRes.eventID.isEmpty {
//                            let completionWrapper: CompletionBlock = { task, responseDict, error in
//                                if error == nil {
//                                    lastUpdatedStore.clear()
//                                    lastUpdatedStore.lastEventID = IDRes.eventID
//                                }
//                                completion?(task, responseDict, error)
//                            }
//                            self.cleanMessage()
//                            sharedContactDataService.clean()
//                            self.fetchMessagesForLocation(location, MessageID: "", Time: 0, foucsClean: false, completion: completionWrapper)
//                            sharedContactDataService.fetchContacts(completion: nil)
//                            sharedLabelsDataService.fetchLabels();
//                        } else {
//                            completion?(task, nil, nil)
//                        }
//                    }
//                }
//                else if eventsRes.messages != nil {
//                    self.processIncrementalUpdateMessages(notificationMessageID, messages: eventsRes.messages!, task: task) { task, res, error in
//                        if error == nil {
//                            lastUpdatedStore.lastEventID = eventsRes.eventID
//                            self.processMessageCounts(eventsRes.messageCounts)
//                            self.processIncrementalUpdateUserInfo(eventsRes.userinfo)
//                            self.processIncrementalUpdateLabels(eventsRes.labels)
//                            self.processIncrementalUpdateContacts(eventsRes.contacts)
//
//                            var outMessages : [Any] = [];
//                            for message in eventsRes.messages! {
//                                let msg = MessageEvent(event: message)
//                                if msg.Action == 1 {
//                                    outMessages.append(msg)
//                                }
//                            }
//                            completion?(task, ["Messages": outMessages, "Notices": eventsRes.notices ?? [String]()], nil)
//                        }
//                        else {
//                            completion?(task, nil, error)
//                        }
//                    }
//                }
//                else {
//                    if eventsRes.code == 1000 {
//                        lastUpdatedStore.lastEventID = eventsRes.eventID
//                        self.processMessageCounts(eventsRes.messageCounts)
//                        self.processIncrementalUpdateUserInfo(eventsRes.userinfo)
//                        self.processIncrementalUpdateLabels(eventsRes.labels)
//                        self.processIncrementalUpdateContacts(eventsRes.contacts)
//                    }
//                    if _hasEventsError {
//                        completion?(task, nil, eventsRes.error)
//                    } else {
//                        completion?(task, ["Notices": eventsRes.notices ?? [String]()], nil)
//                    }
//                }
//            } else {
//                completion?(task, nil, nil)
//            }
        }
    }
    
    
    /**
     this function to process the event logs
     
     :param: messages   the message event log
     :param: task       NSURL session task
     :param: completion complete call back
     */
    fileprivate func processIncrementalUpdateMessages(_ notificationMessageID: String?, messages: Array<Dictionary<String, Any>>, task: URLSessionDataTask!, completion: CompletionBlock?) {
        struct IncrementalUpdateType {
            static let delete = 0
            static let insert = 1
            static let update1 = 2
            static let update2 = 3
        }
//
//        // this serial dispatch queue prevents multiple messages from appearing when an incremental update is triggered while another is in progress
//        self.incrementalUpdateQueue.sync {
//            let context = sharedCoreDataService.newMainManagedObjectContext()
//            context.perform { () -> Void in
//                var error: NSError?
//                var messagesNoCache : [Message] = [];
//                for message in messages {
//                    let msg = MessageEvent(event: message)
//                    switch(msg.Action) {
//                    case .some(IncrementalUpdateType.delete):
//                        if let messageID = msg.ID {
//                            if let message = Message.messageForMessageID(messageID, inManagedObjectContext: context) {
//                                let labelObjs = message.mutableSetValue(forKey: "labels")
//                                labelObjs.removeAllObjects()
//                                message.setValue(labelObjs, forKey: "labels")
//                                context.delete(message)
//                            }
//                        }
//                    case .some(IncrementalUpdateType.insert), .some(IncrementalUpdateType.update1), .some(IncrementalUpdateType.update2):
//                        if IncrementalUpdateType.insert == msg.Action {
//                            if let cachedMessage = Message.messageForMessageID(msg.ID, inManagedObjectContext: context) {
//                                if cachedMessage.location != MessageLocation.draft && cachedMessage.location != MessageLocation.outbox {
//                                    self.tempUnreadAddjustCount = cachedMessage.isRead ? -1 : 0
//                                    continue
//                                }
//                            }
//                            if let notify_msg_id = notificationMessageID {
//                                if notify_msg_id == msg.ID {
//                                    let _ = msg.message?.removeValue(forKey: "IsRead")
//                                }
//                            }
//                            msg.message?["messageStatus"] = 1
//                        }
//
//                        if let lo = msg.message?["Location"] as? Int {
//                            if lo == 1 { //if it is a draft
//                                if let exsitMes = Message.messageForMessageID(msg.ID , inManagedObjectContext: context) {
//                                    if exsitMes.messageStatus == 1 {
//                                        if let subject = msg.message?["Subject"] as? String {
//                                            exsitMes.title = subject
//                                        }
//                                        if let timeValue = msg.message?["Time"] {
//                                            if let timeString = timeValue as? NSString {
//                                                let time = timeString.doubleValue as TimeInterval
//                                                if time != 0 {
//                                                    exsitMes.time = time.asDate()
//                                                }
//                                            } else if let dateNumber = timeValue as? NSNumber {
//                                                let time = dateNumber.doubleValue as TimeInterval
//                                                if time != 0 {
//                                                    exsitMes.time = time.asDate()
//                                                }
//                                            }
//                                        }
//                                        continue;
//                                    }
//                                }
//                            }
//                        }
//                        do {
//                            if let messageObject = try GRTJSONSerialization.object(withEntityName: Message.Attributes.entityName, fromJSONDictionary: msg.message ?? Dictionary<String, Any>(), in: context) as? Message {
//                                // apply the label changes
//                                if let deleted = msg.message?["LabelIDsRemoved"] as? NSArray {
//                                    for delete in deleted {
//                                        let labelID = delete as! String
//                                        if let label = Label.labelForLableID(labelID, inManagedObjectContext: context) {
//                                            let labelObjs = messageObject.mutableSetValue(forKey: "labels")
//                                            if labelObjs.count > 0 {
//                                                labelObjs.remove(label)
//                                                messageObject.setValue(labelObjs, forKey: "labels")
//                                            }
//                                        }
//                                        if labelID == "1" {
//                                            messageObject.isDetailDownloaded = false
//                                        }
//                                    }
//                                }
//
//                                if let added = msg.message?["LabelIDsAdded"] as? NSArray {
//                                    for add in added {
//                                        if let label = Label.labelForLableID(add as! String, inManagedObjectContext: context) {
//                                            let labelObjs = messageObject.mutableSetValue(forKey: "labels")
//                                            labelObjs.add(label)
//                                            messageObject.setValue(labelObjs, forKey: "labels")
//                                        }
//                                    }
//                                }
//
//                                if let labels = msg.message?["LabelIDs"] as? NSArray {
//                                    PMLog.D("\(labels)")
//                                    //TODO : add later need to know whne it is happending
//                                }
//
//                                if messageObject.messageStatus == 0 {
//                                    if messageObject.subject.isEmpty {
//                                        messagesNoCache.append(messageObject)
//                                    } else {
//                                        messageObject.messageStatus = 1
//                                    }
//                                }
//                            } else {
//                                PMLog.D(" case .Some(IncrementalUpdateType.insert), .Some(IncrementalUpdateType.update1), .Some(IncrementalUpdateType.update2): insert empty")
//                            }
//                        } catch {
//                            PMLog.D(" error: \(error)")
//                        }
//                    default:
//                        PMLog.D(" unknown type in message: \(message)")
//                    }
//                }
//
//                error = context.saveUpstreamIfNeeded()
//
//                if error != nil  {
//                    PMLog.D(" error: \(String(describing: error))")
//                }
//
//                self.fetchMessagesWithIDs(messagesNoCache)
//
//                DispatchQueue.main.async {
//                    completion?(task, nil, error)
//                    return
//                }
//            }
//        }
    }
    
    
    
}
