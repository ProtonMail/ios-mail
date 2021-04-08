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
import PMCommon

/// Message data service
class MessageDataService : Service, HasLocalStorage {
    
    ///Message fetch details
    internal typealias CompletionFetchDetail = (_ task: URLSessionDataTask?,
                                                _ response: [String : Any]?,
                                                _ message:Message.ObjectIDContainer?,
                                                _ error: NSError?) -> Void
    
    typealias ReadBlock = (() -> Void)
    
    //TODO:: those 3 var need to double check to clean up
    private let incrementalUpdateQueue = DispatchQueue(label: "ch.protonmail.incrementalUpdateQueue", attributes: [])
    fileprivate var readQueue: [ReadBlock] = []
    var pushNotificationMessageID : String? = nil
    
    let apiService : APIService
    let userID : String
    weak var userDataSource : UserDataSource?
    private let labelDataService: LabelsDataService
    private let contactDataService: ContactDataService
    private let localNotificationService: LocalNotificationService
    private let coreDataService: CoreDataService
    
    private var managedObjectContext: NSManagedObjectContext {
        return self.coreDataService.backgroundManagedObjectContext
    }

    var backgroundTimeRemaining: (() -> Double)?
    
    //FIXME: need to be refracted
    weak var usersManager: UsersManager?
    
    init(api: APIService, userID: String, labelDataService: LabelsDataService, contactDataService: ContactDataService, localNotificationService: LocalNotificationService, usersManager: UsersManager?, coreDataService: CoreDataService) {
        self.apiService = api
        self.userID = userID
        self.labelDataService = labelDataService
        self.contactDataService = contactDataService
        self.localNotificationService = localNotificationService
        self.coreDataService = coreDataService
        setupNotifications()
        self.usersManager = usersManager
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    /// fetch messages with set of message id
    ///
    /// - Parameter selected: MessageIDs
    /// - Returns: fetched message obj
    func fetchMessages(withIDs selected: NSMutableSet, in context: NSManagedObjectContext) -> [Message] {
        let context = context
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: Message.Attributes.entityName)
        fetchRequest.predicate = NSPredicate(format: "%K in %@", Message.Attributes.messageID, selected)
        do {
            if let messages = try context.fetch(fetchRequest) as? [Message] {
                return messages
            }
        } catch let ex as NSError {
            PMLog.D(" error: \(ex)")
        }
        return [Message]()
    }
    
    /// mark message to unread
    ///
    /// - Parameter message: message
    /// - Returns: true if change to unread and push to the queue
    @discardableResult
    func mark( message: Message, unRead: Bool) -> Bool {
        guard let context = message.managedObjectContext else {
            return false
        }
        self.queue(message, action: unRead ? .unread : .read)
        guard message.unRead != unRead else {
            return false
        }
        var hasError = false
        context.performAndWait {
            message.unRead = unRead
            let error = context.saveUpstreamIfNeeded()
            if let error = error {
                PMLog.D(" error: \(error)")
                hasError = true
            }
        }
        
        if hasError {
            return false
        }
        
        self.updateCounter(markUnRead: unRead, on: message, context: context)
        return true
    }
    
    private func updateCounter(markUnRead: Bool, on message: Message, context: NSManagedObjectContext) {
        let offset = markUnRead ? 1 : -1
        let labelIDs: [String] = message.getLableIDs()
        self.coreDataService.enqueue(context: context) { (context) in
            for lID in labelIDs {
                let unreadCount: Int = lastUpdatedStore.unreadCount(by: lID, userID: self.userID, context: context)
                var count = unreadCount + offset
                if count < 0 {
                    count = 0
                }
                lastUpdatedStore.updateUnreadCount(by: lID, userID: self.userID, count: count, context: context, shouldSave: false)
            }
            if let error = context.saveUpstreamIfNeeded() {
                PMLog.D(error.localizedDescription)
            }
        }
    }
    
    private func updateCounterSync(markUnRead: Bool, on message: Message, context: NSManagedObjectContext) {
        let offset = markUnRead ? 1 : -1
        let labelIDs: [String] = message.getLableIDs()
        for lID in labelIDs {
            let unreadCount: Int = lastUpdatedStore.unreadCount(by: lID, userID: self.userID, context: context)
            var count = unreadCount + offset
            if count < 0 {
                count = 0
            }
            lastUpdatedStore.updateUnreadCount(by: lID, userID: self.userID, count: count, context: context, shouldSave: false)
        }
    }
    
    @discardableResult
    func label(message: Message, label: String, apply: Bool) -> Bool {
        guard let context = message.managedObjectContext else {
            return false
        }

        var hasError = false
        context.performAndWait {
            if apply {
                if message.add(labelID: label) != nil && message.unRead {
                    self.updateCounterSync(plus: true, with: label, context: context)
                }
            } else {
                if message.remove(labelID: label) != nil && message.unRead {
                    self.updateCounterSync(plus: false, with: label, context: context)
                }
            }
            let error = context.saveUpstreamIfNeeded()
            if let error = error {
                PMLog.D(" error: \(error)")
                hasError = true
            }
        }
        
        if hasError {
            return false
        }
        
        self.queue(message, action: apply ? .label : .unlabel, data1: label)
        return true
    }
    
    func updateCounter(plus: Bool, with labelID: String) {
        self.coreDataService.enqueue(context: self.managedObjectContext) { (context) in
            let offset = plus ? 1 : -1
            let unreadCount: Int = lastUpdatedStore.unreadCount(by: labelID, userID: self.userID, context: context)
            var count = unreadCount + offset
            if count < 0 {
                count = 0
            }
            lastUpdatedStore.updateUnreadCount(by: labelID, userID: self.userID, count: count, context: context, shouldSave: false)
            
            if let error = context.saveUpstreamIfNeeded() {
                PMLog.D(error.localizedDescription)
            }
        }
    }
    
    func updateCounterSync(plus: Bool, with labelID: String, context: NSManagedObjectContext) {
        let offset = plus ? 1 : -1
        let unreadCount: Int = lastUpdatedStore.unreadCount(by: labelID, userID: self.userID, context: context)
        var count = unreadCount + offset
        if count < 0 {
            count = 0
        }
        lastUpdatedStore.updateUnreadCount(by: labelID, userID: self.userID, count: count, context: context)
    }

    @discardableResult
    func move(message: Message, from fLabel: String, to tLabel: String, queue: Bool = true) -> Bool {
        guard let context = message.managedObjectContext else {
            return false
        }

        var hasError = false
        context.performAndWait {
            if let lid = message.remove(labelID: fLabel), message.unRead {
                self.updateCounterSync(plus: false, with: lid, context: context)
                if let id = message.selfSent(labelID: lid) {
                    self.updateCounterSync(plus: false, with: id, context: context)
                }
            }
            if let lid = message.add(labelID: tLabel) {
                //if move to trash. clean lables.
                var labelsFound = message.getNormalLableIDs()
                labelsFound.append(Message.Location.starred.rawValue)
                labelsFound.append(Message.Location.allmail.rawValue)
                if lid == Message.Location.trash.rawValue {
                    self.remove(labels: labelsFound, on: message, cleanUnread: true)
                    message.unRead = false
                }
                if lid == Message.Location.spam.rawValue {
                    self.remove(labels: labelsFound, on: message, cleanUnread: false)
                }
                
                if message.unRead {
                    self.updateCounterSync(plus: true, with: lid, context: context)
                    if let id = message.selfSent(labelID: lid) {
                        self.updateCounterSync(plus: true, with: id, context: context)
                    }
                }
            }
            
            let error = context.saveUpstreamIfNeeded()
            if let error = error {
                PMLog.D(" error: \(error)")
                hasError = true
            }
        }
        
        if hasError {
            return false
        }
        
        if queue {
            self.queue(message, action: .folder, data1: fLabel, data2: tLabel)
        }
        return true
    }
    
    private func remove(labels: [String], on message: Message, cleanUnread: Bool) {
        guard let context = message.managedObjectContext else {
            return
        }
        let unread = cleanUnread ? message.unRead : cleanUnread
        for label in labels {
            if let lid = message.remove(labelID: label), unread {
                self.updateCounterSync(plus: false, with: lid, context: context)
                if let id = message.selfSent(labelID: lid) {
                    self.updateCounterSync(plus: false, with: id, context: context)
                }
            }
        }
    }
    
    @discardableResult
    func delete(message: Message, label: String) -> Bool {
        guard let context = message.managedObjectContext else {
            return false
        }
        var hasError = false
        context.performAndWait {
            self.queue(message, action: .delete, data1: label)
            
            if let lid = message.remove(labelID: label), message.unRead {
                self.updateCounterSync(plus: false, with: lid, context: context)
                if let id = message.selfSent(labelID: lid) {
                    self.updateCounterSync(plus: false, with: id, context: context)
                }
            }
            var labelsFound = message.getNormalLableIDs()
            labelsFound.append(Message.Location.starred.rawValue)
            labelsFound.append(Message.Location.allmail.rawValue)
            self.remove(labels: labelsFound, on: message, cleanUnread: true)
            let labelObjs = message.mutableSetValue(forKey: "labels")
            labelObjs.removeAllObjects()
            message.setValue(labelObjs, forKey: "labels")
            context.delete(message)
            
            let error = context.saveUpstreamIfNeeded()
            if let error = error {
                PMLog.D(" error: \(error)")
                hasError = true
            }
        }
        
        if hasError {
            return false
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
    func fetchMessages(byLable labelID : String, time: Int, forceClean: Bool, completion: CompletionBlock?) {
        queue {
            let completionWrapper: CompletionBlock = { task, responseDict, error in
                if error != nil {
                    completion?(task, responseDict, error)
                } else if var messagesArray = responseDict?["Messages"] as? [[String : Any]] {
                    for (index, _) in messagesArray.enumerated() {
                        let userID = self.userID
                        messagesArray[index]["UserID"] = userID
                    }
                    let messcount = responseDict?["Total"] as? Int ?? 0
                    let context = self.coreDataService.mainManagedObjectContext
                    self.coreDataService.enqueue(context: context) { (context) in
                        do {
                            //Prevent the draft is overriden while sending
                            if labelID == Message.Location.draft.rawValue, let sendingMessageIDs = Message.getIDsofSendingMessage(managedObjectContext: context) {
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
                            
                            if let messages = try GRTJSONSerialization.objects(withEntityName: Message.Attributes.entityName, fromJSONArray: messagesArray, in: context) as? [Message] {
                                for message in messages {
                                    // the matedata set, mark the status
                                    message.messageStatus = 1
                                }
                                if let error = context.saveUpstreamIfNeeded() {
                                    PMLog.D(" error: \(error)")
                                }
                                if let lastMsg = messages.last, let firstMsg = messages.first {
                                    let updateTime = lastUpdatedStore.lastUpdateDefault(by: labelID, userID: self.userID, context: context)
                                    if (updateTime.isNew) {
                                        updateTime.start = firstMsg.time ?? Date()
                                        updateTime.total = Int32(messcount)
                                    }
                                    if let time = lastMsg.time,
                                       (updateTime.endTime.compare(time) == .orderedDescending || updateTime.endTime == .distantPast) {
                                        updateTime.end = time
                                    }
                                    updateTime.update = Date()
                                    
                                    let _ = context.saveUpstreamIfNeeded()
                                    // lastUpdatedStore.updateLabelsForKey(labelID, updateTime: updateTime)
                                }
                                
                                // fetch inbox count
                                if labelID == Message.Location.inbox.rawValue {
                                    let counterRoute = MessageCount()
                                    self.apiService.exec(route: counterRoute) { (response: MessageCountResponse) in
                                        if response.error == nil {
                                            self.processEvents(counts: response.counts)
                                        }
                                    }
                                }
                                DispatchQueue.main.async {
                                    completion?(task, responseDict, error)
                                }
                                return
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
            let request = FetchMessagesByLabel(labelID: labelID, endTime: time)
            self.apiService.GET(request, completion: completionWrapper)
        }
    }
    
    
    /// fetching the message from server based on label and time also reset the events status //TODO:: change to promise
    ///
    /// - Parameters:
    ///   - labelID: labelid, location id, forlder id
    ///   - time: the latest update time
    ///   - completion: async complete handler
    func fetchMessagesWithReset(byLabel labelID: String, time: Int, completion: CompletionBlock?) {
        queue {
            let getLatestEventID = EventLatestIDRequest()
            self.apiService.exec(route: getLatestEventID) { (task, IDRes: EventLatestIDResponse) in
                if !IDRes.eventID.isEmpty {
                    let completionWrapper: CompletionBlock = { task, responseDict, error in
                        if error == nil {
                            lastUpdatedStore.clear()
                            _ = lastUpdatedStore.updateEventID(by: self.userID, eventID: IDRes.eventID, context: self.managedObjectContext).ensure {
                                completion?(task, responseDict, error)
                            }
                            return
                            //lastUpdatedStore.lastEventID = IDRes.eventID
                        }
                        completion?(task, responseDict, error)
                    }
                    
                    self.cleanMessage().then { (_) -> Promise<Void> in
                        lastUpdatedStore.removeUpdateTime(by: self.userID, context: self.managedObjectContext)
                        return self.contactDataService.cleanUp()
                    }.ensure {
                        self.fetchMessages(byLable: labelID, time: time, forceClean: false, completion: completionWrapper)
                        self.contactDataService.fetchContacts(completion: nil)
                        self.labelDataService.fetchLabels()
                    }.cauterize()
                }  else {
                    completion?(task, nil, nil)
                }
            }
        }
    }
    
    
    func isEventIDValid(context: NSManagedObjectContext) -> Bool {
        let eventID = lastUpdatedStore.lastEventID(userID: self.userID, context: context)
        return eventID != "" && eventID != "0"
    }
    
    /// fetch event logs from server. sync up the cache status to latest
    ///
    /// - Parameters:
    ///   - labelID: Label/location/forlder
    ///   - notificationMessageID: the notification message
    ///   - completion: async complete handler
    func fetchEvents(byLable labelID: String, notificationMessageID : String?, context: NSManagedObjectContext, completion: CompletionBlock?) {
        queue {
            let eventAPI = EventCheckRequest(eventID: lastUpdatedStore.lastEventID(userID: self.userID, context: context))
            self.apiService.exec(route: eventAPI) { (task, response: EventCheckResponse) in
                if let error = response.error {
                    if error.code == 18001 {
                        let getLatestEventID = EventLatestIDRequest()
                        self.apiService.exec(route: getLatestEventID) { (task, eventIDResponse: EventLatestIDResponse) in
                            if let err = eventIDResponse.error {
                                completion?(task, nil, err)
                            } else {
                                let IDRes = eventIDResponse
                                if !IDRes.eventID.isEmpty {
                                    let completionWrapper: CompletionBlock = { task, responseDict, error in
                                        if error == nil {
                                            lastUpdatedStore.clear()
                                            _ = lastUpdatedStore.updateEventID(by: self.userID, eventID: IDRes.eventID, context: context).ensure {
                                                completion?(task, responseDict, error)
                                            }
                                            return
                                        }
                                        completion?(task, responseDict, error)
                                    }
                                    self.cleanMessage().then {
                                        return self.contactDataService.cleanUp()
                                    }.ensure {
                                        self.fetchMessages(byLable: labelID, time: 0, forceClean: false, completion: completionWrapper)
                                        self.contactDataService.fetchContacts(completion: nil)
                                        self.labelDataService.fetchLabels()
                                    }.cauterize()
                                } else {
                                    completion?(task, nil, eventIDResponse.error)
                                }
                            }
                        }
                    } else {
                        completion?(task, nil, error)
                    }
                } else {
                    let eventsRes = response

                    if eventsRes.refresh.contains(.contacts) {
                        _ = self.contactDataService.cleanUp().ensure {
                            self.contactDataService.fetchContacts(completion: nil)
                        }
                    }

                    if eventsRes.refresh.contains(.all) || eventsRes.refresh.contains(.mail) || (eventsRes.code == 18001) {
                        let getLatestEventID = EventLatestIDRequest()
                        self.apiService.exec(route: getLatestEventID) { (task, eventIDResponse: EventLatestIDResponse) in
                            if let err = eventIDResponse.error {
                                completion?(task, nil, err)
                            } else {
                                let IDRes = eventIDResponse
                                if !IDRes.eventID.isEmpty {
                                    let completionWrapper: CompletionBlock = { task, responseDict, error in
                                        if error == nil {
                                            lastUpdatedStore.clear()
                                            _ = lastUpdatedStore.updateEventID(by: self.userID, eventID: IDRes.eventID, context: context).ensure {
                                                completion?(task, responseDict, error)
                                            }
                                            return
                                        }
                                        completion?(task, responseDict, error)
                                    }
                                    self.cleanMessage().then {
                                        return self.contactDataService.cleanUp()
                                    }.ensure {
                                        self.fetchMessages(byLable: labelID, time: 0, forceClean: false, completion: completionWrapper)
                                        self.contactDataService.fetchContacts(completion: nil)
                                        self.labelDataService.fetchLabels()
                                    }.cauterize()
                                } else {
                                    completion?(task, nil, eventIDResponse.error)
                                }
                            }
                        }
                    } else if let messageEvents = eventsRes.messages {
                        DispatchQueue.global().async {
                            self.processEvents(messages: messageEvents, notificationMessageID: notificationMessageID, task: task) { task, res, error in
                                if error == nil {
                                    _ = lastUpdatedStore.updateEventID(by: self.userID, eventID: eventsRes.eventID, context: self.coreDataService.mainManagedObjectContext).then { (_) -> Promise<Void> in
                                        if eventsRes.refresh.contains(.contacts) {
                                            return Promise()
                                        } else {
                                            return self.processEvents(contactEmails: eventsRes.contactEmails)
                                        }
                                    }.then { (_) -> Promise<Void> in
                                        if eventsRes.refresh.contains(.contacts) {
                                            return Promise()
                                        } else {
                                            return self.processEvents(contacts: eventsRes.contacts)
                                        }
                                    }.then { (_) -> Promise<Void> in
                                        self.processEvents(labels: eventsRes.labels)
                                    }.then({ (_) -> Promise<Void> in
                                        self.processEvents(addresses: eventsRes.addresses)
                                    })
                                    .ensure {
                                        self.processEvents(user: eventsRes.user)
                                        self.processEvents(userSettings: eventsRes.userSettings)
                                        self.processEvents(mailSettings: eventsRes.mailSettings)
                                        self.processEvents(counts: eventsRes.messageCounts)
                                        self.processEvents(space: eventsRes.usedSpace)
                                        
                                        var outMessages : [Any] = []
                                        for message in messageEvents {
                                            let msg = MessageEvent(event: message)
                                            if msg.Action == 1 {
                                                outMessages.append(msg)
                                            }
                                        }
                                        completion?(task, ["Messages": outMessages, "Notices": eventsRes.notices ?? [String](), "More" : eventsRes.more], nil)
                                    }
                                }
                                else {
                                    completion?(task, nil, error)
                                }
                            }
                        }
                    } else {
                        if eventsRes.code == 1000 {
                            _ = lastUpdatedStore.updateEventID(by: self.userID, eventID: eventsRes.eventID, context: self.coreDataService.mainManagedObjectContext).then { (_) -> Promise<Void> in
                                if eventsRes.refresh.contains(.contacts) {
                                    return Promise()
                                } else {
                                    return self.processEvents(contactEmails: eventsRes.contactEmails)
                                }
                            }.then { (_) -> Promise<Void> in
                                if eventsRes.refresh.contains(.contacts) {
                                    return Promise()
                                } else {
                                    return self.processEvents(contacts: eventsRes.contacts)
                                }
                            }.then { (_) -> Promise<Void> in
                                self.processEvents(labels: eventsRes.labels)
                            }.then({ (_) -> Promise<Void> in
                                self.processEvents(addresses: eventsRes.addresses)
                            })
                            .ensure {
                                self.processEvents(user: eventsRes.user)
                                self.processEvents(userSettings: eventsRes.userSettings)
                                self.processEvents(mailSettings: eventsRes.mailSettings)
                                self.processEvents(counts: eventsRes.messageCounts)
                                self.processEvents(space: eventsRes.usedSpace)
                                
                                if eventsRes.error != nil {
                                    completion?(task, nil, eventsRes.error)
                                } else {
                                    completion?(task, ["Notices": eventsRes.notices ?? [String](), "More" : eventsRes.more], nil)
                                }
                            }
                            return
                        }
                        if eventsRes.error != nil {
                            completion?(task, nil, eventsRes.error)
                        } else {
                            completion?(task, ["Notices": eventsRes.notices ?? [String](), "More" : eventsRes.more], nil)
                        }
                    }
                }
            }
        }
    }

    private func fetchEvents(labelID: String) {
        fetchEvents(
            byLable: labelID,
            notificationMessageID: nil,
            context: coreDataService.mainManagedObjectContext,
            completion: nil
        )
    }
    
    /// Sync mail setting when user in composer
    /// workaround
    func syncMailSetting(labelID: String = "0", context: NSManagedObjectContext) {
        queue {
            let eventAPI = EventCheckRequest(eventID: lastUpdatedStore.lastEventID(userID: self.userID, context: context))
            self.apiService.exec(route: eventAPI) { (response: EventCheckResponse) in
                guard response.code == 1000 else {
                    return
                }
                self.processEvents(mailSettings: response.mailSettings)
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
            let objetcID = att.objectID.uriRepresentation().absoluteString
            let context = att.managedObjectContext
            let _ = sharedMessageQueue.addMessage(objetcID, action: .deleteAtt, userId: self.userID)
            dequeueIfNeeded()
            
            self.coreDataService.enqueue(context: context) { (context) in
                att.isSoftDeleted = true
                if let error = context.saveUpstreamIfNeeded() {
                    PMLog.D(" error: \(error)")
                }
                seal.fulfill_()
            }
        }
    }
    
    typealias base64AttachmentDataComplete = (_ based64String : String) -> Void
    func base64AttachmentData(att: Attachment, _ complete : @escaping base64AttachmentDataComplete) {
        guard let user = self.userDataSource, let context = att.managedObjectContext else {
            complete("")
            return
        }
        
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
            self.fetchAttachmentForAttachment(att, downloadTask: { (taskOne : URLSessionDownloadTask) -> Void in }, completion: { (_, url, error) -> Void in
                context.perform {
                    complete( att.base64DecryptAttachment(userInfo: user.userInfo, passphrase: user.mailboxPassword) )
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

    func updateMessageCount() {
        queue {
            let counterApi = MessageCount()
            self.apiService.exec(route: counterApi) { (response: MessageCountResponse) in
                guard response.error == nil else {return}
                self.processEvents(counts: response.counts)
            }
        }
    }
    
    
    func messageFromPush() -> Message? {
        guard let msgID = self.pushNotificationMessageID else {
            return nil
        }
        let context = self.coreDataService.mainManagedObjectContext
        guard let message = Message.messageForMessageID(msgID, inManagedObjectContext: context) else {
            return nil
        }
        return message
    }
    
    
    ///TODO::fixme - double check it  // this way is a little bit hacky. future we will prebuild the send message body
    func injectTransientValuesIntoMessages() {
        let ids = sharedMessageQueue.queuedMessageIds()
        let context = self.coreDataService.backgroundManagedObjectContext
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
        guard let userMsgService = self.usersManager?.getUser(byUserId: message.userID)?.messageService else {
            return
        }
        message.cachedPassphrase = userMsgService.userDataSource!.mailboxPassword
        message.cachedAuthCredential = userMsgService.userDataSource!.authCredential
        message.cachedUser = userMsgService.userDataSource!.userInfo
        message.cachedAddress = userMsgService.defaultAddress(message) // computed property depending on current user settings
    }
    
    
    //
    func empty(location: Message.Location) {
        self.empty(labelID: location.rawValue)
    }
    
    func empty(labelID: String) {
        if Message.delete(labelID: labelID) {
            queue(.empty, data1: labelID)
        }
    }
    
    let reportTitle = "FetchMetadata"
    /// fetch message meta data with message obj
    ///
    /// - Parameter messages: Message
    private func fetchMetadata(with messageIDs : [String]) {
        if messageIDs.count > 0 {
            queue {
                let completionWrapper: CompletionBlock = { task, responseDict, error in
                    if var messagesArray = responseDict?["Messages"] as? [[String : Any]] {
                        for (index, _) in messagesArray.enumerated() {
                            messagesArray[index]["UserID"] = self.userID
                        }
                        let context = self.coreDataService.mainManagedObjectContext
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
                                                               user: self.usersManager?.getUser(byUserId: self.userID))
                                    }
                                } else {
                                    Analytics.shared.error(message: .fetchMetadata,
                                                           error: "insert empty",
                                                           user: self.usersManager?.getUser(byUserId: self.userID))
                                    PMLog.D("GRTJSONSerialization.mergeObjectsForEntityName failed \(String(describing: error))")
                                }
                            } catch let err as NSError {
                                Analytics.shared.error(message: .fetchMetadata,
                                                       error: err,
                                                       extra: ["status": "try catch"],
                                                       user: self.usersManager?.getUser(byUserId: self.userID))
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
                                               user: self.usersManager?.getUser(byUserId: self.userID))
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
        queue { () -> Void in
            if let context = attachment.managedObjectContext {
                self.apiService.downloadAttachment(byID: attachment.attachmentID,
                                                   destinationDirectoryURL: FileManager.default.attachmentDirectory,
                                                   customAuthCredential: customAuthCredential,
                                                   downloadTask: downloadTask,
                                                   completion: { task, fileURL, error in
                                                    var error = error
                                                    self.coreDataService.enqueue(context: context) { (context) in
                                                        if let fileURL = fileURL {
                                                            attachment.localURL = fileURL
                                                            if #available(iOS 12, *) {
                                                                if !self.isFirstTimeSaveAttData {
                                                                    attachment.fileData = try? Data(contentsOf: fileURL)
                                                                }
                                                            } else {
                                                                attachment.fileData = try? Data(contentsOf: fileURL)
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
        queue {
            let completionWrapper: CompletionBlock = { task, response, error in
                let objectId = message.objectID
                let context = self.coreDataService.mainManagedObjectContext
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
                                self.queue(newMessage, action: .read)
                                if newMessage.unRead {
                                    self.updateCounterSync(markUnRead: false, on: newMessage, context: context)
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
            self.apiService.messageDetail(messageID: message.messageID, completion: completionWrapper)
        }
    }
    
    func fetchMessageDetailForMessage(_ message: Message, completion: @escaping CompletionFetchDetail) {
        if !message.isDetailDownloaded {
            queue {
                let completionWrapper: CompletionBlock = { task, response, error in
                    let context = self.coreDataService.mainManagedObjectContext
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
                                        message_n.messageStatus = 1
                                        message_n.isDetailDownloaded = true
                                        self.queue(message, action: .read)
                                        if message_n.unRead {
                                            self.updateCounterSync(markUnRead: false, on: message, context: context)
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
                self.apiService.messageDetail(messageID: message.messageID, completion: completionWrapper)
            }
        } else {
            self.mark(message: message, unRead: false)
            DispatchQueue.main.async {
                completion(nil, nil, Message.ObjectIDContainer(message), nil)
            }
        }
    }
    
    func fetchNotificationMessageDetail(_ messageID: String, completion: @escaping CompletionFetchDetail) {
        queue {
            let completionWrapper: CompletionBlock = { task, response, error in
                let context = self.coreDataService.mainManagedObjectContext
                self.coreDataService.enqueue(context: context) { (context) in
                    if response != nil {
                        //TODO need check the respons code
                        if var msg: [String : Any] = response?["Message"] as? [String : Any] {
                            msg.removeValue(forKey: "Location")
                            msg.removeValue(forKey: "Starred")
                            msg.removeValue(forKey: "test")
                            msg["UserID"] = self.userID
                            do {
                                if let message_out = try GRTJSONSerialization.object(withEntityName: Message.Attributes.entityName, fromJSONDictionary: msg, in: context) as? Message {
                                    message_out.messageStatus = 1
                                    message_out.isDetailDownloaded = true
                                    self.queue(message_out, action: .read)
                                    if message_out.unRead == true {
                                        message_out.unRead = false
                                        self.updateCounterSync(markUnRead: false, on: message_out, context: context)
                                    }
                                    let tmpError = context.saveUpstreamIfNeeded()
                                    
                                    DispatchQueue.main.async {
                                        completion(task, response, Message.ObjectIDContainer(message_out), tmpError)
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
            
            let context = self.coreDataService.mainManagedObjectContext
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
    func fetchedResults(by labelID: String) -> NSFetchedResultsController<NSFetchRequestResult>? {
        let moc = self.coreDataService.mainManagedObjectContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: Message.Attributes.entityName)
        fetchRequest.predicate = NSPredicate(format: "(ANY labels.labelID = %@) AND (%K > %d) AND (%K == %@)",
                                             labelID, Message.Attributes.messageStatus, 0, Message.Attributes.userID, self.userID)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(Message.time), ascending: false)]
        fetchRequest.fetchBatchSize = 30
        fetchRequest.includesPropertyValues = true
        return NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: moc, sectionNameKeyPath: nil, cacheName: nil)
    }
    
    /**
     fetch the message from local cache use message id
     
     :param: messageID String
     
     :returns: NSFetchedResultsController
     */
    func fetchedMessageControllerForID(_ messageID: String) -> NSFetchedResultsController<NSFetchRequestResult>? {
        let moc = self.coreDataService.mainManagedObjectContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: Message.Attributes.entityName)
        fetchRequest.predicate = NSPredicate(format: "%K == %@", Message.Attributes.messageID, messageID)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: Message.Attributes.time, ascending: false)]
        return NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: moc, sectionNameKeyPath: nil, cacheName: nil)
    }
    
    /**
     clean up function for clean up the local cache this will be called when:
     
     1. logout.
     2. use cache version bad.
     3. when session expired.
     
     */
    func launchCleanUpIfNeeded() {
//        if !sharedUserDataService.isUserCredentialStored || !userCachedStatus.isAuthCacheOk() {
//            cleanUp()
//            if (!userCachedStatus.isAuthCacheOk()) {
//                sharedUserDataService.clean()
//                userCachedStatus.resetAuthCache()
//            }
//            //need add not clean the important infomation here.
//        }
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
            lastUpdatedStore.clear()
            lastUpdatedStore.removeUpdateTime(by: self.userID, context: self.managedObjectContext)
            
            self.removeQueuedMessage(userId: self.userID)
            self.removeFailedQueuedMessage(userId: self.userID)
        }
    }
    
    static func cleanUpAll() -> Promise<Void> {
        return Promise { seal in
            sharedMessageQueue.clear()
            sharedFailedQueue.clear()
            let coreDateService = sharedServices.get(by: CoreDataService.self)
            let context = coreDateService.backgroundManagedObjectContext
            coreDateService.enqueue(context: context) { (context) in
                Message.deleteAll(inContext: context)
                _ = context.saveUpstreamIfNeeded()
                seal.fulfill_()
            }
        }
    }
    
    fileprivate func cleanMessage() -> Promise<Void> {
        return Promise { seal in
            self.coreDataService.enqueue(context: self.coreDataService.mainManagedObjectContext) { (context) in
                if #available(iOS 12, *) {
                    self.isFirstTimeSaveAttData = true
                }
                
                let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: Message.Attributes.entityName)
                fetch.predicate = NSPredicate(format: "%K == %@", Message.Attributes.userID, self.userID)
                let request = NSBatchDeleteRequest(fetchRequest: fetch)
                request.resultType = .resultTypeObjectIDs

                if let result = try? context.execute(request) as? NSBatchDeleteResult,
                   let objectIdArray = result.result as? [NSManagedObjectID] {
                    let changes = [NSDeletedObjectsKey: objectIdArray]
                    NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [context])
                }

                UIApplication.setBadge(badge: 0)
                seal.fulfill_()
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
                let context = self.coreDataService.mainManagedObjectContext
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
                completionWrapper(task, nil, error)
            } else {
                completionWrapper(task, response.jsonDic, nil)
            }
        }
    }
    
    func saveDraft(_ message : Message?) {
        if let message = message, let context = message.managedObjectContext {
            context.perform {
                if let error = context.saveUpstreamIfNeeded() {
                    PMLog.D(" error: \(error)")
                }
            }
            self.queue(message, action: .saveDraft)
        }
    }
    
    func purgeOldMessages() { //TODO:: later we need to clean the message with a bad user id
        // need fetch status bad messages
        let context = self.coreDataService.backgroundManagedObjectContext
        self.coreDataService.enqueue(context: context) { (context) in
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: Message.Attributes.entityName)
            fetchRequest.predicate = NSPredicate(format: "(%K == 0) AND %K == %@", Message.Attributes.messageStatus, Contact.Attributes.userID, self.userID)
            do {
                if let badMessages = try context.fetch(fetchRequest) as? [Message] {
                    var badIDs : [String] = []
                    for message in badMessages {
                        badIDs.append(message.messageID)
                    }
                    
                    var temp: [String] = []
                    for i in 0..<badIDs.count {
                        if temp.count > 10 {
                            self.fetchMetadata(with: temp)
                            temp.removeAll()
                        } else {
                            temp.append(badIDs[i])
                            continue
                        }
                    }
                    if !temp.isEmpty {
                        self.fetchMetadata(with: temp)
                    }
                }
            } catch let ex as NSError {
                Analytics.shared.error(message: .purgeOldMessages,
                                       error: ex,
                                       user: self.usersManager?.getUser(byUserId: self.userID))
                PMLog.D("error : \(ex)")
            }
        }
    }
    
    func cleanOldAttachment() {
        let context = self.coreDataService.backgroundManagedObjectContext
        self.coreDataService.enqueue(context: context) { (context) in
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: Attachment.Attributes.entityName)
            fetchRequest.predicate = NSPredicate(format: "(%K == 1) AND %K == NULL", Attachment.Attributes.isSoftDelete, Attachment.Attributes.message)
            let request = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            do {
                try context.execute(request)
            } catch let ex as NSError {
                Analytics.shared.error(message: .purgeOldMessages,
                                       error: ex,
                                       user: self.usersManager?.getUser(byUserId: self.userID))
                PMLog.D("error : \(ex)")
            }
        }
    }
    
    // MARK : old functions
    
    fileprivate func attachmentsForMessage(_ message: Message) -> [Attachment] {
        if let all = message.attachments.allObjects as? [Attachment] {
            return all.filter{ !$0.isSoftDeleted }
        }
        return []
    }
    
    fileprivate func draft(save messageID: String, writeQueueUUID: UUID, UID: String, completion: CompletionBlock?) {
        let context = self.coreDataService.mainManagedObjectContext
        var isAttachmentKeyChanged = false
        self.coreDataService.enqueue(context: context) { (context) in
            guard let objectID = self.coreDataService.managedObjectIDForURIRepresentation(messageID) else {
                // error: while trying to get objectID
                let _ = sharedMessageQueue.remove(writeQueueUUID)
                self.dequeueIfNeeded()
                completion?(nil, nil, NSError.badParameter(messageID))
                return
            }
            
            guard let userManager = self.usersManager?.getUser(byUserId: UID) else {
                completion?(nil, nil, NSError.userLoggedOut())
                return
            }
            
            do {
                guard let message = try context.existingObject(with: objectID) as? Message else {
                    // error: object is not a Message
                    let _ = sharedMessageQueue.remove(writeQueueUUID)
                    self.dequeueIfNeeded()
                    completion?(nil, nil, NSError.badParameter(messageID))
                    return
                }
                
                let completionWrapper: CompletionBlock = { task, response, error in
                    guard let mess = response else {
                        if let err = error {
                            Analytics.shared.error(message: .saveDraftError, error: err, user: self.usersManager?.firstUser)
                            NSError.alertSavingDraftError(details: err.localizedDescription)
                        }
                        // error: response nil
                        completion?(task, nil, error)
                        return
                    }
                    
                    guard let messageID = mess["ID"] as? String else {
                        // error: not ID field in response
                        completion?(task, nil, error)
                        return
                    }
                    
                    PMLog.D("SendAttachmentDebug == finish save draft!")
                    if message.messageID != messageID {
                        // Cancel scheduled local notification and re-schedule
                        self.localNotificationService
                            .rescheduleMessage(oldID: message.messageID, details: .init(messageID: messageID, subtitle: message.title))
                    }
                    message.messageID = messageID
                    message.isDetailDownloaded = true
                
                    var hasTemp = false
                    let attachments = message.mutableSetValue(forKey: "attachments")
                    for att in attachments {
                        if let att = att as? Attachment {
                            if att.isTemp {
                                hasTemp = true
                                context.delete(att)
                            }
                            // Prevent flag being overide if current call do not change the key
                            if isAttachmentKeyChanged {
                                att.keyChanged = false
                            }
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
                            Analytics.shared.error(message: .grtJSONSerialization, error: exc, user: self.usersManager?.firstUser)
                            completion?(task, response, exc)
                            return
                        }
                    }
                    completion?(task, response, error)
                }
                
                PMLog.D("SendAttachmentDebug == start save draft!")
                
                if let atts = message.attachments.allObjects as? [Attachment] {
                    for att in atts {
                        if att.keyChanged {
                            isAttachmentKeyChanged = true
                        }
                    }
                }
                
                if message.isDetailDownloaded && message.messageID != "0" {
                    let addr = userManager.messageService.fromAddress(message) ?? message.cachedAddress ?? userManager.messageService.defaultAddress(message)
                    let api = UpdateDraft(message: message, fromAddr: addr, authCredential: message.cachedAuthCredential)
                    self.apiService.exec(route: api) { (task, response: UpdateDraftResponse) in
                        context.perform {
                            if let err = response.error {
                                completionWrapper(task, nil, err)
                            } else {
                                completionWrapper(task, response.responseDict, nil)
                            }
                        }
                    }
                    
                } else {
                    let addr = userManager.messageService.fromAddress(message) ?? message.cachedAddress ?? userManager.messageService.defaultAddress(message)
                    let api = CreateDraft(message: message, fromAddr: addr)
                    self.apiService.exec(route: api) { (task, response: UpdateDraftResponse) in
                        context.perform {
                            if let err = response.error {
                                completionWrapper(task, nil, err)
                            } else {
                                completionWrapper(task, response.responseDict, nil)
                            }
                        }
                    }
                }
            } catch let ex as NSError {
                // error: context thrown trying to get Message
                Analytics.shared.error(message: .saveDraftError, error: ex, user: self.usersManager?.firstUser)
                let _ = sharedMessageQueue.remove(writeQueueUUID)
                self.dequeueIfNeeded()
                completion?(nil, nil, ex)
                return
            }
        }
    }
    
    
    private func uploadPubKey(_ managedObjectID: String, writeQueueUUID: UUID, UID: String, completion: CompletionBlock?) {
        let context = self.coreDataService.mainManagedObjectContext
        guard let objectID = self.coreDataService.managedObjectIDForURIRepresentation(managedObjectID),
            let managedObject = try? context.existingObject(with: objectID),
            let _ = managedObject as? Attachment else
        {
            // nothing to send, dequeue request
            let _ = sharedMessageQueue.remove(writeQueueUUID)
            self.dequeueIfNeeded()
            
            completion?(nil, nil, NSError.badParameter(managedObjectID))
            return
        }
        
        self.uploadAttachmentWithAttachmentID(managedObjectID, writeQueueUUID: writeQueueUUID, UID: UID, completion: completion)
        return
    }
    
    private func uploadAttachmentWithAttachmentID (_ managedObjectID: String, writeQueueUUID: UUID, UID: String, completion: CompletionBlock?) {
        
        let context = self.coreDataService.mainManagedObjectContext
        guard let objectID = self.coreDataService.managedObjectIDForURIRepresentation(managedObjectID),
            let managedObject = try? context.existingObject(with: objectID),
            let attachment = managedObject as? Attachment else
        {
            // nothing to send, dequeue request
            let _ = sharedMessageQueue.remove(writeQueueUUID)
            self.dequeueIfNeeded()
        
            completion?(nil, nil, NSError.badParameter(managedObjectID))
            return
        }
        
        guard let userManager = self.usersManager?.getUser(byUserId: UID) else {
            completion?(nil, nil, NSError.userLoggedOut())
            return
        }
        
        var params = [
            "Filename": attachment.fileName,
            "MIMEType": attachment.mimeType,
            "MessageID": attachment.message.messageID
        ]
        
        if attachment.inline() {
            params["ContentID"] = attachment.contentID()
        }
        
        let addressID = attachment.message.cachedAddress?.address_id ?? userManager.messageService.getAddressID(attachment.message)
        guard let key = attachment.message.cachedAddress?.keys.first ?? userManager.getAddressKey(address_id: addressID) else {
            completion?(nil, nil, NSError.encryptionError())
            return
        }
        
//        guard let passphrase = attachment.message.cachedPassphrase ?? self.userDataSource?.mailboxPassword else {
//            completion?(nil, nil, NSError.lockError())
//            return
//        }
        let passphrase = attachment.message.cachedPassphrase ?? userManager.mailboxPassword
        
        autoreleasepool(){
            guard
                let (kP, dP) = attachment.encrypt(byKey: key, mailbox_pwd: passphrase),
                let keyPacket = kP,
                let dataPacket = dP
            else
            {
                completion?(nil, nil, NSError.encryptionError())
                return
            }
            Crypto().freeGolangMem()
            let signed = attachment.sign(byKey: key,
                                         userKeys: attachment.message.cachedUser?.userPrivateKeysArray ?? userManager.userPrivateKeys,
                                         passphrase: passphrase)
            let completionWrapper: CompletionBlock = { task, response, error in
                PMLog.D("SendAttachmentDebug == finish upload att!")
                if error == nil,
                    let attDict = response?["Attachment"] as? [String : Any],
                    let id = attDict["ID"] as? String
                {
                    self.coreDataService.enqueue(context: context) { (context) in
                        attachment.attachmentID = id
                        attachment.keyPacket = keyPacket.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
                        attachment.fileData = nil // encrypted attachment is successfully uploaded -> no longer need it cleartext
                        
                        // proper headers from BE - important for inline attachments
                        if let headerInfoDict = attDict["Headers"] as? Dictionary<String, String> {
                            attachment.headerInfo = "{" + headerInfoDict.compactMap { " \"\($0)\":\"\($1)\" " }.joined(separator: ",") + "}"
                        }
                        
                        if let fileUrl = attachment.localURL,
                            let _ = try? FileManager.default.removeItem(at: fileUrl)
                        {
                            attachment.localURL = nil
                        }
                        
                        if let error = context.saveUpstreamIfNeeded() {
                            PMLog.D(" error: \(error)")
                        }
                        completion?(task, response, error)
                    }
                } else {
                    if let err = error {
                        Analytics.shared.error(message: .uploadAttachmentError, error: err, user: self.usersManager?.firstUser)
                    }
                    completion?(task, response, error)
                }
            }
            
            PMLog.D("SendAttachmentDebug == start upload att!")
            ///sharedAPIService.upload( byPath: Constants.App.API_PATH + "/attachments",
            userManager.apiService.upload( byPath: "/attachments",
                                           parameters: params,
                                           keyPackets: keyPacket,
                                           dataPacket: dataPacket as Data,
                                           signature: signed,
                                           headers: [HTTPHeader.apiVersion: 3],
                                           authenticated: true,
                                           customAuthCredential: attachment.message.cachedAuthCredential,
                                           completion: completionWrapper)
        }
        
    }
    
    private func deleteAttachmentWithAttachmentID (_ deleteObject: String, writeQueueUUID: UUID, UID: String, completion: CompletionBlock?) {
        let context = self.coreDataService.mainManagedObjectContext
        self.coreDataService.enqueue(context: context) { (context) in
            var authCredential: AuthCredential?
            var att: Attachment?
            if let objectID = self.coreDataService.managedObjectIDForURIRepresentation(deleteObject),
                let managedObject = try? context.existingObject(with: objectID),
                let attachment = managedObject as? Attachment
            {
                authCredential = attachment.message.cachedAuthCredential
                att = attachment
            }
            
            guard let userManager = self.usersManager?.getUser(byUserId: UID) else {
                completion?(nil, nil, NSError.userLoggedOut())
                return
            }
            
            //TODO:: fix me authCredential
            let api = DeleteAttachment(attID: att?.attachmentID ?? "0", authCredential: authCredential)
            userManager.apiService.exec(route: api) { (task, response) in
                completion?(task, nil, nil)
            }
        }
    }
    
    private func messageAction(_ managedObjectIds: [String], writeQueueUUID: UUID, action: String, UID: String, completion: CompletionBlock?) {
        let context = self.coreDataService.mainManagedObjectContext
        context.performAndWait {
            let messages = managedObjectIds.compactMap { (id: String) -> Message? in
                if let objectID = self.coreDataService.managedObjectIDForURIRepresentation(id),
                    let managedObject = try? context.existingObject(with: objectID)
                {
                    return managedObject as? Message
                }
                return nil
            }
            
            guard let userManager = self.usersManager?.getUser(byUserId: UID) else {
                completion!(nil, nil, NSError.userLoggedOut())
                return
            }
            
            let messageIds = messages.map { $0.messageID }
            guard messageIds.count > 0 else {
                Analytics.shared.debug(message: .coredataIssue,
                                       extra: [
                                        "API": "Message action",
                                        "ObjectCounts": managedObjectIds.count
                                       ])
                completion!(nil, nil, nil)
                return
            }
            let api = MessageActionRequest(action: action, ids: messageIds)
            userManager.apiService.exec(route: api) { (task, response) in
                completion?(task, nil, nil)
            }
        }
    }
    
    /// delete a message
    ///
    /// - Parameters:
    ///   - messageIDs: must be the real message id. becuase the message is deleted before this triggered
    ///   - writeQueueUUID: queue UID
    ///   - action: action type. should .delete here
    ///   - completion: call back
    private func messageDelete(_ messageIDs: [String], labelID: String, writeQueueUUID: UUID, action: String, UID: String, completion: CompletionBlock?) {
        guard let userManager = self.usersManager?.getUser(byUserId: UID) else {
            completion!(nil, nil, NSError.userLoggedOut())
            return
        }
        
        let api = MessageActionRequest(action: action, ids: messageIDs, labelID: labelID)
        userManager.apiService.exec(route: api) { (task, response) in
            completion?(task, nil, nil)
        }
    }
    
    private func empty(labelId: String, UID: String, completion: CompletionBlock?) {
        if let location = Message.Location(rawValue: labelId) {
            self.empty(at: location, UID: UID, completion: completion)
        } else {
            self.empty(labelID: labelId, completion: completion)
        }
//        completion?(nil, nil, nil)
    }
    
    private func empty(at location: Message.Location, UID: String, completion: CompletionBlock?) {
        //TODO:: check is label valid
        if location != .spam && location != .trash && location != .draft {
            completion?(nil, nil, nil)
            return
        }
        
        guard let userManager = self.usersManager?.getUser(byUserId: UID) else {
            completion?(nil, nil, NSError.userLoggedOut())
            return
        }
        
        let api = EmptyMessage(labelID: location.rawValue)
        userManager.apiService.exec(route: api) { (task, response) in
            completion?(task, nil, nil)
        }
    }
    
    private func empty(labelID: String, completion: CompletionBlock?) {
        let api = EmptyMessage(labelID: labelID)
        self.apiService.exec(route: api) { (task, response) in
            completion?(task, nil, nil)
        }
    }

    private func labelMessage(_ labelID: String, messageID: String, UID: String, completion: CompletionBlock?) {
        guard let userManager = self.usersManager?.getUser(byUserId: UID) else {
            completion!(nil, nil, NSError.userLoggedOut())
            return
        }
        
        let api = ApplyLabelToMessages(labelID: labelID, messages: [messageID])
        userManager.apiService.exec(route: api) { [weak self] (task, response) in
            self?.fetchEvents(labelID: labelID)
            completion?(task, nil, response.error)
        }
    }
    
    private func unLabelMessage(_ labelID: String, messageID: String, UID: String, completion: CompletionBlock?) {
        guard let userManager = self.usersManager?.getUser(byUserId: UID) else {
            completion!(nil, nil, NSError.userLoggedOut())
            return
        }
        
        let api = RemoveLabelFromMessages(labelID: labelID, messages: [messageID])
        userManager.apiService.exec(route: api) { [weak self] (task, response) in
            self?.fetchEvents(labelID: labelID)
            completion?(task, nil, response.error)
        }
    }
    
    //
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
    
    
    private func send(byID messageID: String, writeQueueUUID: UUID, UID: String, completion: CompletionBlock?) {
        let errorBlock: CompletionBlock = { task, response, error in
            // nothing to send, dequeue request
            let _ = sharedMessageQueue.remove(writeQueueUUID)
            completion?(task, response, error)
        }
        
        //TODO: needs to refractor
        let context = self.coreDataService.mainManagedObjectContext
        self.coreDataService.enqueue(context: context) { (context) in
            guard let objectID = self.coreDataService.managedObjectIDForURIRepresentation(messageID),
                  let message = context.find(with: objectID) as? Message else
            {
                errorBlock(nil, nil, NSError.badParameter(messageID))
                return
            }
            
            guard let userManager = self.usersManager?.getUser(byUserId: UID) else {
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
            
            let userPrivKeys = userInfo.userPrivateKeys
            
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
                                           user: self.usersManager?.firstUser)
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
                status.insert(SendStatus.done)
                
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
                    let _err = error?.localizedDescription ?? "Unknow error"
                    Analytics.shared.error(message: .sendMessageError, error: _err, extra: [
                        "status": status.rawValue,
                        "emailCount": emails.count,
                        "attCount": attachments.count
                    ], user: self.usersManager?.getUser(byUserId: self.userID))
                    // show message now
                    self.localNotificationService.scheduleMessageSendingFailedNotification(.init(messageID: message.messageID,
                                                                                                 error: "\(LocalString._message_sent_failed_desc):\n\(error!.localizedDescription)",
                                                                                                 timeInterval: 1,
                                                                                                 subtitle: message.title))
                }
                completion?(nil, nil, error)
            }.catch(policy: .allErrors) { (error) in
                status.insert(SendStatus.exceptionCatched)
                
                let err = error as NSError
                PMLog.D(error.localizedDescription)
                if err.code == 9001 {
                    //here need let user to show the human check.
                    sharedMessageQueue.isRequiredHumanCheck = true
                    NSError.alertMessageSentError(details: err.localizedDescription)
                } else if err.code == 15198 {
                    NSError.alertMessageSentError(details: err.localizedDescription)
                } else if err.code == 15004 {
                    // this error means the message has already been sent
                    // so don't need to show this error to user
                    self.localNotificationService.unscheduleMessageSendingFailedNotification(.init(messageID: message.messageID))
                    NSError.alertMessageSentToast()
                    completion?(nil, nil, nil)
                    return
                } else if err.code == 33101 {
                    //Email address validation failed
                    NSError.alertMessageSentError(details: err.localizedDescription)
                    
                    #if !APP_EXTENSION
                    let toDraftAction = UIAlertAction(title: LocalString._address_invalid_error_to_draft_action_title, style: .default) { (_) in
                        NotificationCenter.default.post(name: .switchView,
                                                        object: DeepLink(MenuCoordinatorNew.Destination.mailbox.rawValue, sender: Message.Location.draft.rawValue))
                    }
                    LocalString._address_invalid_error_sending.alertViewController(LocalString._address_invalid_error_sending_title, toDraftAction)
                    #endif
                } else if err.code == 2500 {
                    // The error means "Message has already been sent"
                    // Since the message is sent, this alert is useless to user
                    self.localNotificationService.unscheduleMessageSendingFailedNotification(.init(messageID: message.messageID))
                    completion?(nil, nil, nil)
                    return
                } else {
                    NSError.alertMessageSentError(details: err.localizedDescription)
                }
                
                // show message now
                let errorMsg = err.code == 33101 ? LocalString._messages_validation_failed_try_again : "\(LocalString._messages_sending_failed_try_again):\n\(err.localizedDescription)"
                self.localNotificationService.scheduleMessageSendingFailedNotification(.init(messageID: message.messageID,
                                                                                             error: errorMsg,
                                                                                             timeInterval: 1,
                                                                                             subtitle: message.title))
                Analytics.shared.error(message: .sendMessageError, error: err, extra: [
                    "status": status.rawValue,
                    "emailCount": emails.count,
                    "attCount": attachments.count
                ], user: self.usersManager?.getUser(byUserId: self.userID))
                completion?(nil, nil, err)
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
                    let context = message.managedObjectContext else {
                        seal.fulfill_()
                        return
                }
                self.coreDataService.enqueue(context: context) { (context) in
                    defer {
                        seal.fulfill_()
                    }
                    //{0|1|2} // Optional, reply = 0, reply all = 1, forward = 2
                    if act == 0 {
                        message.replied = true
                    } else if act == 1 {
                        message.repliedAll = true
                    } else if act == 2{
                        message.forwarded = true
                    } else {
                        //ignore
                    }
                    if let error = context.saveUpstreamIfNeeded() {
                        PMLog.D(" error: \(error)")
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
    
    // MARK: Queue
    private func writeQueueCompletionBlockForElementID(_ elementID: UUID, messageID : String, actionString : String) -> CompletionBlock {
        return { task, response, error in
            sharedMessageQueue.isInProgress = false
            if error == nil {
                if let action = MessageAction(rawValue: actionString) {
                    if action == MessageAction.delete {
                        Message.deleteMessage(messageID)
                    }
                    
                    if action == .send {
                        //after sent, clean the other actions with same messageID from write queue (save and send)
                        sharedMessageQueue.removeDoubleSent(messageID: messageID, actions: [MessageAction.saveDraft.rawValue, MessageAction.send.rawValue])
                    }
                }
                let _ = sharedMessageQueue.remove(elementID)
                self.dequeueIfNeeded()
            } else {
                PMLog.D(" error: \(String(describing: error))")
                if let err = error {
                    Analytics.shared.error(message: .queueError, error: err, user: self.usersManager?.firstUser)
                }
                
                var statusCode = 200
                let errorCode = error?.code ?? 200
                var isInternetIssue = false
                
                if let err = error {
                    let errorUserInfo = err.userInfo
                    
                    if let detail = errorUserInfo["com.alamofire.serialization.response.error.response"] as? HTTPURLResponse {
                        statusCode = detail.statusCode
                    } else {
                        if err.domain == NSURLErrorDomain {
                            switch err.code {
                            case NSURLErrorTimedOut,
                                 NSURLErrorCannotConnectToHost,
                                 NSURLErrorCannotFindHost,
                                 NSURLErrorDNSLookupFailed,
                                 NSURLErrorNotConnectedToInternet,
                                 NSURLErrorSecureConnectionFailed,
                                 NSURLErrorDataNotAllowed,
                                 NSURLErrorCannotFindHost:
                                isInternetIssue = true
                            default:
                                break
                            }
                        } else if err.domain == NSPOSIXErrorDomain && err.code == 100 {
                            //Network protocol error
                            isInternetIssue = true
                        } else {
                            let status = Reachability.forInternetConnection()?.currentReachabilityStatus()
                            switch status {
                            case .NotReachable:
                                isInternetIssue = true
                            default: break
                            }
                        }
                        
                        // Show timeout error banner or not reachable banner in mailbox
                        if errorCode == NSURLErrorTimedOut {
                            NotificationCenter.default.post(Notification(name: NSNotification.Name.reachabilityChanged, object: 0, userInfo: nil))
                        } else if isInternetIssue {
                            NotificationCenter.default.post(Notification(name: NSNotification.Name.reachabilityChanged, object: 1, userInfo: nil))
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
                
                if statusCode == 200 && errorCode == 9001 {
                    
                } else if statusCode == 200 && errorCode > 1000 {
                    let _ = sharedMessageQueue.remove(elementID)
                } else if statusCode == 200 && errorCode < 200 && !isInternetIssue {
                    let _ = sharedMessageQueue.remove(elementID)
                }
                
                if statusCode != 200 && statusCode != 404 && statusCode != 500 && !isInternetIssue {
                    //show error
                    let _ = sharedMessageQueue.remove(elementID)
                    Analytics.shared.error(message: .queueError,
                                           error: error?.localizedDescription ?? "Error is nil",
                                           user: self.usersManager?.getUser(byUserId: self.userID))
                }
                
                if !isInternetIssue && (errorCode != NSError.authCacheLocked().code) {
                    self.dequeueIfNeeded()
                } else if sharedMessageQueue.isBlocked {
                    self.pauseNotify?()
                    self.pauseNotify = nil
                    self.dequieNotify = nil
                    sharedMessageQueue.isBlocked = false
                    
                } else if !sharedMessageQueue.isBlocked && self.readQueue.count > 0 {
                    PMLog.D("left redaQueue count : \(self.readQueue.count)")
                    self.readQueue.remove(at: 0)()
                    self.dequeueIfNeeded()
                }
            }
        }
    }
    
    var dequieNotify : (() -> Void)?
    var pauseNotify: (() -> Void)?
    
    func backgroundFetch(notify : (() -> Void)?) {
        self.dequeueIfNeeded(notify: notify)
    }
    
    func pauseQueueAction(didStop: (() -> Void)?) {
        self.pauseNotify = didStop
        sharedMessageQueue.isBlocked = true
    }
    
    func unBlockQueueAction() {
        sharedMessageQueue.isBlocked = false
    }
    
    private func dequeueIfNeeded(notify : (() -> Void)? = nil) {
        
        if notify == nil {
            if sharedMessageQueue.count <= 0 && readQueue.count <= 0 {
                self.dequieNotify?()
                self.dequieNotify = nil
            }
        } else {
            self.dequieNotify = notify
        }

        if let backgroundRemainTime = self.backgroundTimeRemaining?(), backgroundRemainTime < 5 {
            sharedMessageQueue.isBlocked = true
        }
        
        // for label action: data1 is `to`
        // for forder action: data1 is `from`  data2 is `to`
        if let (uuid, messageID, actionString, data1, data2, userId) = sharedMessageQueue.nextMessage() {
            PMLog.D("SendAttachmentDebug == dequeue --- \(actionString)")
            if let action = MessageAction(rawValue: actionString) {
                sharedMessageQueue.isInProgress = true
                let completeHandler = writeQueueCompletionBlockForElementID(uuid, messageID: messageID, actionString: actionString)
                
                //Check userId, if it is empty then assign current userId (Object queued in old version)
                let UID = userId == "" ? self.userID : userId
                
                switch action {
                case .saveDraft:
                    self.draft(save: messageID, writeQueueUUID: uuid, UID: UID, completion: completeHandler)
                case .uploadAtt:
                    self.uploadAttachmentWithAttachmentID(messageID, writeQueueUUID: uuid, UID: UID, completion: completeHandler)
                case .uploadPubkey:
                    self.uploadPubKey(messageID, writeQueueUUID: uuid, UID: UID, completion: completeHandler)
                case .deleteAtt:
                    self.deleteAttachmentWithAttachmentID(messageID, writeQueueUUID: uuid, UID: UID, completion: completeHandler)
                case .send:
                    self.send(byID: messageID, writeQueueUUID: uuid, UID: UID, completion: completeHandler)
                case .emptyTrash:   // keep this as legacy option for 2-3 releases after 1.11.12
                    self.empty(at: .trash, UID: UID, completion: completeHandler)
                case .emptySpam:    // keep this as legacy option for 2-3 releases after 1.11.12
                    self.empty(at: .spam, UID: UID, completion: completeHandler)
                case .empty:
                    self.empty(labelId: data1, UID: UID, completion: completeHandler)
                case .read, .unread:
                    self.messageAction([messageID], writeQueueUUID: uuid, action: actionString, UID: UID, completion: completeHandler)
                case .delete:
                    self.messageDelete([messageID], labelID: data1, writeQueueUUID: uuid, action: actionString, UID: UID, completion: completeHandler)
                case .label:
                    self.labelMessage(data1, messageID: messageID, UID: UID, completion: completeHandler)
                case .unlabel:
                    self.unLabelMessage(data1, messageID: messageID, UID: UID, completion: completeHandler)
                case .folder:
                    //later use data 1 to handle the failure
                    self.labelMessage(data2, messageID: messageID, UID: UID, completion: completeHandler)
                }
            } else {
                PMLog.D(" Unsupported action \(actionString), removing from queue.")
                let _ = sharedMessageQueue.remove(uuid)
            }
        } else if !sharedMessageQueue.isBlocked && readQueue.count > 0 { //sharedMessageQueue.count == 0 &&
            readQueue.remove(at: 0)()
            dequeueIfNeeded()
        } else if sharedMessageQueue.isBlocked {
            self.pauseNotify?()
            self.pauseNotify = nil
            self.dequieNotify = nil
            sharedMessageQueue.isBlocked = false
        }
    }
    
    func queue(_ message: Message, action: MessageAction, data1: String = "", data2: String = "") {
        self.cachePropertiesForBackground(in: message)
        if action == .saveDraft || action == .send || action == .read || action == .unread {
            let _ = sharedMessageQueue.addMessage(message.objectID.uriRepresentation().absoluteString, action: action, data1: data1, data2: data2, userId: self.userID)
        } else {
            if message.managedObjectContext != nil && !message.messageID.isEmpty {
                let _ = sharedMessageQueue.addMessage(message.messageID, action: action, data1: data1, data2: data2, userId: self.userID)
            }
        }
        dequeueIfNeeded()
    }
    
    fileprivate func queue(_ action: MessageAction, data1: String = "", data2: String = "") {
        let _ = sharedMessageQueue.addMessage("", action: action, data1: data1, data2: data2, userId: self.userID)
        dequeueIfNeeded()
    }
    
    fileprivate func queue(_ att: Attachment, action: MessageAction, data1: String = "", data2: String = "") {
        self.cachePropertiesForBackground(in: att.message)
        let _ = sharedMessageQueue.addMessage(att.objectID.uriRepresentation().absoluteString, action: action, data1: data1, data2: data2, userId: self.userID)
        dequeueIfNeeded()
    }
    
    fileprivate func queue(_ readBlock: @escaping ReadBlock) {
        readQueue.append(readBlock)
        dequeueIfNeeded()
    }
    
    func cleanLocalMessageCache(_ completion: CompletionBlock?) {
        let getLatestEventID = EventLatestIDRequest()
        self.apiService.exec(route: getLatestEventID) { (task, response : EventLatestIDResponse) in
            if !response.eventID.isEmpty {
                self.cleanMessage().then { _ -> Promise<Void> in
                    return self.contactDataService.cleanUp()
                }.ensure {
                    lastUpdatedStore.clear()
                    self.fetchMessages(byLable: Message.Location.inbox.rawValue, time: 0, forceClean: false) { (_, _, _) in
                        self.labelDataService.fetchLabels() {
                            self.contactDataService.fetchContacts { (_, error) in
                                if error == nil {
                                    _ = lastUpdatedStore.updateEventID(by: self.userID, eventID: response.eventID, context: self.managedObjectContext).ensure {
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
                }.cauterize()
            } else {
                completion?(task, nil, response.error)
            }
        }
    }
    
    func isAnyQueuedMessage(userId: String) -> Bool {
        return sharedMessageQueue.isAnyQueuedMessage(userID: userId)
    }
    
    func removeQueuedMessage(userId: String) {
        sharedMessageQueue.removeAllQueuedMessage(userId: userId)
    }
    
    func removeFailedQueuedMessage(userId: String) {
        sharedFailedQueue.removeAllQueuedMessage(userId: userId)
    }
    
    
    // MARK: process events
    
    /**
     this function to process the event logs
     
     :param: messages   the message event log
     :param: task       NSURL session task
     :param: completion complete call back
     */
    private func processEvents(messages: [[String : Any]], notificationMessageID: String?, task: URLSessionDataTask!, completion: CompletionBlock?) {
        struct IncrementalUpdateType {
            static let delete = 0
            static let insert = 1
            static let update1 = 2
            static let update2 = 3
        }
        
        // this serial dispatch queue prevents multiple messages from appearing when an incremental update is triggered while another is in progress
        self.incrementalUpdateQueue.sync {
            let context = self.coreDataService.mainManagedObjectContext
            self.coreDataService.enqueue(context: context) { (context) in
                var error: NSError?
                var messagesNoCache : [String] = []
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
                                //in case
                                error = context.saveUpstreamIfNeeded()
                                if error != nil  {
                                    Analytics.shared.error(message: .grtJSONSerialization,
                                                           error: error!,
                                                           extra: [Analytics.Reason.status: "Delete"],
                                                           user: self.usersManager?.getUser(byUserId: self.userID))
                                    PMLog.D(" error: \(String(describing: error))")
                                }
                            }
                        }
                    case .some(IncrementalUpdateType.insert), .some(IncrementalUpdateType.update1), .some(IncrementalUpdateType.update2):
                        if IncrementalUpdateType.insert == msg.Action {
                            if let cachedMessage = Message.messageForMessageID(msg.ID, inManagedObjectContext: context) {
                                if !cachedMessage.contains(label: .sent) {
                                    continue
                                }
                            }
                            if let notify_msg_id = notificationMessageID {
                                if notify_msg_id == msg.ID {
                                    let _ = msg.message?.removeValue(forKey: "Unread")
                                }
                                msg.message?["messageStatus"] = 1
                                msg.message?["UserID"] = self.userID
                            }
                            msg.message?["messageStatus"] = 1
                        }
                        
                        if let lo = msg.message?["Location"] as? Int {
                            if lo == 1 || lo == 8 { //if it is a draft
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
                                        continue
                                    }
                                }
                            }
                        }
                        
                        if let labelIDs = msg.message?["LabelIDs"] as? NSArray {
                            if labelIDs.contains("1") || labelIDs.contains("8") {
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
                                        continue
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
                                    }
                                }
                                
                                messageObject.userID = self.userID
                                if msg.Action == IncrementalUpdateType.update1 {
                                    messageObject.isDetailDownloaded = false
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
                                    messageObject.checkLabels()
                                    //TODO : add later need to know whne it is happending
                                }
                                
                                if messageObject.messageStatus == 0 {
                                    if messageObject.subject.isEmpty {
                                        messagesNoCache.append(messageObject.messageID)
                                    } else {
                                        messageObject.messageStatus = 1
                                    }
                                }
                                //in case
                                if messageObject.managedObjectContext != nil {
                                    error = context.saveUpstreamIfNeeded()
                                    if error != nil  {
                                        if let messageid = msg.message?["ID"] as? String {
                                            messagesNoCache.append(messageid)
                                        }
                                        Analytics.shared.error(message: .grtJSONSerialization,
                                                               error: error!,
                                                               extra: [Analytics.Reason.status: "GRTJSONSerialization Update"],
                                                               user: self.usersManager?.getUser(byUserId: self.userID))
                                        PMLog.D(" error: \(String(describing: error))")
                                    }
                                } else {
                                    if let messageid = msg.message?["ID"] as? String {
                                        messagesNoCache.append(messageid)
                                    }
                                    Analytics.shared.error(message: .grtJSONSerialization,
                                                           error: "GRTJSONSerialization Insert - context nil",
                                                           user: self.usersManager?.getUser(byUserId: self.userID))
                                }
                            } else {
                                // when GRTJSONSerialization inset returns no thing
                                if let messageid = msg.message?["ID"] as? String {
                                    messagesNoCache.append(messageid)
                                }
                                PMLog.D(" case .Some(IncrementalUpdateType.insert), .Some(IncrementalUpdateType.update1), .Some(IncrementalUpdateType.update2): insert empty")
                                Analytics.shared.error(message: .grtJSONSerialization,
                                                       error: "GRTJSONSerialization Insert - insert empty",
                                                       user: self.usersManager?.getUser(byUserId: self.userID))
                            }
                        } catch let err as NSError {
                            // when GRTJSONSerialization insert failed
                            if let messageid = msg.message?["ID"] as? String {
                                messagesNoCache.append(messageid)
                            }
                            var status = ""
                            switch msg.Action {
                            case IncrementalUpdateType.update1:
                                status = "Update1"
                            case IncrementalUpdateType.update2:
                                status = "Update2"
                            case IncrementalUpdateType.insert:
                                status = "Insert"
                            case IncrementalUpdateType.delete:
                                status = "Delete"
                            default:
                                status = "Other: \(String(describing: msg.Action))"
                                break
                            }
                            Analytics.shared.error(message: .grtJSONSerialization,
                                                   error: err,
                                                   extra: [Analytics.Reason.status: status],
                                                   user: self.usersManager?.getUser(byUserId: self.userID))
                            PMLog.D(" error: \(err)")
                        }
                    default:
                        PMLog.D(" unknown type in message: \(message)")
                        
                    }
                    //TODO:: move this to the loop and to catch the error also put it in noCache queue.
                    error = context.saveUpstreamIfNeeded()
                    if error != nil  {
                        Analytics.shared.error(message: .grtJSONSerialization,
                                               error: error!,
                                               extra: [Analytics.Reason.status: "Save"],
                                               user: self.usersManager?.getUser(byUserId: self.userID))
                        PMLog.D(" error: \(String(describing: error))")
                    }
                }
                self.fetchMetadata(with: messagesNoCache)
                DispatchQueue.main.async {
                    completion?(task, nil, error)
                    return
                }
            }
        }
    }
    
    /// Process contacts from event logs
    ///
    /// - Parameter contacts: contact events
    private func processEvents(contacts: [[String : Any]]?) -> Promise<Void> {
        guard let contacts = contacts else {
            return Promise()
        }
        
        return Promise { seal in
            let context = self.coreDataService.mainManagedObjectContext
            self.coreDataService.enqueue(context: context) { (context) in
                defer {
                    seal.fulfill_()
                }
                for contact in contacts {
                    let contactObj = ContactEvent(event: contact)
                    switch(contactObj.action) {
                    case .delete:
                        if let contactID = contactObj.ID {
                            if let tempContact = Contact.contactForContactID(contactID, inManagedObjectContext: context) {
                                context.delete(tempContact)
                            }
                        }
                        //save it earily
                        if let error = context.saveUpstreamIfNeeded()  {
                            PMLog.D(" error: \(error)")
                        }
                    case .insert, .update:
                        do {
                            if let outContacts = try GRTJSONSerialization.objects(withEntityName: Contact.Attributes.entityName,
                                                                                  fromJSONArray: contactObj.contacts,
                                                                                  in: context) as? [Contact] {
                                for c in outContacts {
                                    c.isDownloaded = false
                                    c.userID = self.userID
                                    if let emails = c.emails.allObjects as? [Email] {
                                        emails.forEach { (e) in
                                            e.userID = self.userID
                                        }
                                    }
                                }
                            }
                        } catch let ex as NSError {
                            PMLog.D(" error: \(ex)")
                        }
                        if let error = context.saveUpstreamIfNeeded() {
                            PMLog.D(" error: \(error)")
                        }
                    default:
                        PMLog.D(" unknown type in contact: \(contact)")
                    }
                }
            }
        }
    }
    
    /// Process contact emails this is like metadata update
    ///
    /// - Parameter contactEmails: contact email events
    private func processEvents(contactEmails: [[String : Any]]?) -> Promise<Void> {
        guard let emails = contactEmails else {
            return Promise()
        }
        
        return Promise { seal in
            let context = self.coreDataService.mainManagedObjectContext
            self.coreDataService.enqueue(context: context) { (context) in
                defer {
                    seal.fulfill_()
                }
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
                                    c.userID = self.userID
                                    if let emails = c.emails.allObjects as? [Email] {
                                        emails.forEach { (e) in
                                            e.userID = self.userID
                                        }
                                    }
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
    }
    
    /// Process Labels include Folders and Labels.
    ///
    /// - Parameter labels: labels events
    private func processEvents(labels: [[String : Any]]?) -> Promise<Void> {
        struct IncrementalUpdateType {
            static let delete = 0
            static let insert = 1
            static let update = 2
        }
        
        
        if let labels = labels {
            return Promise { seal in
                // this serial dispatch queue prevents multiple messages from appearing when an incremental update is triggered while another is in progress
                self.incrementalUpdateQueue.sync {
                    let context = self.coreDataService.mainManagedObjectContext
                    self.coreDataService.enqueue(context: context) { (context) in
                        defer {
                            seal.fulfill_()
                        }
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
                                    if var new_or_update_label = label.label {
                                        new_or_update_label["UserID"] = self.userID
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
        } else {
            return Promise()
        }
    }
    
    /// Process User information
    ///
    /// - Parameter userInfo: User dict
    private func processEvents(user: [String : Any]?) {
        guard let userEvent = user else {
            return
        }
        self.userDataSource?.updateFromEvents(userInfoRes: userEvent)
    }
    private func processEvents(userSettings: [String : Any]?) {
        guard let userSettingEvent = userSettings else {
            return
        }
        self.userDataSource?.updateFromEvents(userSettingsRes: userSettingEvent)
    }
    private func processEvents(mailSettings: [String : Any]?) {
        guard let mailSettingEvent = mailSettings else {
            return
        }
        self.userDataSource?.updateFromEvents(mailSettingsRes: mailSettingEvent)
    }
    
    private func processEvents(addresses: [[String : Any]]?) -> Promise<Void> {
        guard let addrEvents = addresses else {
            return Promise()
        }
        return Promise { seal in
            self.incrementalUpdateQueue.async {
                for addrEvent in addrEvents {
                    let address = AddressEvent(event: addrEvent)
                    switch(address.action) {
                    case .delete:
                        if let addrID = address.ID {
                            self.userDataSource?.deleteFromEvents(addressIDRes: addrID)
                        }
                    case .insert, .update1:
                        guard let addrID = address.ID, let addrDict = address.address else {
                            break
                        }
                        let addrRes = AddressesResponse()
                        addrRes.parseAddr(res: addrDict)
                        
                        guard addrRes.addresses.count == 1, let parsedAddr = addrRes.addresses.first, parsedAddr.address_id == addrID else {
                            break
                        }
                        self.userDataSource?.setFromEvents(addressRes: parsedAddr)
                        guard let user = self.usersManager?.getUser(byUserId: self.userID) else {
                            break
                        }
                        do {
                            try await(user.userService.activeUserKeys(userInfo: user.userinfo, auth: user.authCredential))
                        } catch let error {
                            print(error.localizedDescription)
                        }
                    default:
                        PMLog.D(" unknown type in message: \(address)")
                    }
                }
                seal.fulfill_()
            }
        }
    }
    
    /// Process Message count from event logs
    ///
    /// - Parameter counts: message count dict
    private func processEvents(counts: [[String : Any]]?) {
        guard let messageCounts = counts, messageCounts.count > 0 else {
            return
        }
        
        lastUpdatedStore.resetUnreadCounts()
        self.coreDataService.enqueue(context: self.managedObjectContext) { (context) in
            for count in messageCounts {
                if let labelID = count["LabelID"] as? String {
                    guard let unread = count["Unread"] as? Int else {
                        continue
                    }
                    lastUpdatedStore.updateUnreadCount(by: labelID, userID: self.userID, count: unread, context: context, shouldSave: false)
                }
            }
            
            if let error = context.saveUpstreamIfNeeded() {
                PMLog.D(error.localizedDescription)
            }
            
            let unreadCount: Int = lastUpdatedStore.unreadCount(by: Message.Location.inbox.rawValue, userID: self.userID, context: context)
            var badgeNumber = unreadCount
            if  badgeNumber < 0 {
                badgeNumber = 0
            }
            UIApplication.setBadge(badge: badgeNumber)
        }
    }
    
    
    private func processEvents(space usedSpace : Int64?) {
        guard let usedSpace = usedSpace else {
            return
        }
        self.userDataSource?.update(usedSpace: usedSpace)
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
            return addr.address_id
        }
        return ""
    }
    
    /// this function need to factor
    func defaultAddress(_ message: Message) -> Address? {
        let userInfo = self.userDataSource!.userInfo
        if let addressID = message.addressID, !addressID.isEmpty {
            if let add = userInfo.userAddresses.indexOfAddress(addressID), add.send == 1 {
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
            if let add = userInfo.userAddresses.indexOfAddress(addressID) {
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
        message.isEncrypted = 1
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
                    message.isEncrypted = true
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
