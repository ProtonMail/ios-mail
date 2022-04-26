//
//  EventsService.swift
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
import Groot
import PromiseKit
import ProtonCore_Services
import ProtonCore_DataModel
import EllipticCurveKeyPair
import ProtonMailAnalytics

enum EventsFetchingStatus {
    case idle
    case started
    case running
}

protocol EventsFetching: EventsServiceProtocol, Service {
    var status: EventsFetchingStatus { get }
    func start()
    func pause()
    func resume()
    func stop()
    func call()

    func begin(subscriber: EventsConsumer)

    func fetchEvents(byLabel labelID: LabelID, notificationMessageID: MessageID?, completion: CompletionBlock?)
    func fetchEvents(labelID: LabelID)
    func processEvents(counts: [[String: Any]]?)
    func processEvents(conversationCounts: [[String: Any]]?)
    func processEvents(mailSettings: [String: Any]?)
    func processEvents(space usedSpace: Int64?)
}

protocol EventsConsumer: AnyObject {
    func shouldCallFetchEvents()
}

enum EventError: Error {
    case notRunning
}

/// This is the protocol being worked on during the refactor. It will end up being the only one for EventsService.
protocol EventsServiceProtocol: AnyObject {
    func fetchLatestEventID(completion: ((EventLatestIDResponse) -> Void)?)
    func processEvents(counts: [[String: Any]]?)
    func processEvents(conversationCounts: [[String: Any]]?)
}

final class EventsService: Service, EventsFetching {
    private static let defaultPollingInterval: TimeInterval = 30
    private let incrementalUpdateQueue = DispatchQueue(label: "ch.protonmail.incrementalUpdateQueue", attributes: [])
    private typealias EventsObservation = (() -> Void?)?
    private(set) var status: EventsFetchingStatus = .idle
    private var subscribers: [EventsObservation] = []
    private var timer: Timer?
    private let coreDataService: CoreDataService
    private lazy var lastUpdatedStore = ServiceFactory.default.get(by: LastUpdatedStore.self)
    private weak var userManager: UserManager!
    private lazy var queueManager = ServiceFactory.default.get(by: QueueManager.self)
    private let dependencies: Dependencies

    init(userManager: UserManager, contactCacheStatus: ContactCacheStatusProtocol) {
        self.userManager = userManager
        let coreDataService = ServiceFactory.default.get(by: CoreDataService.self)
        self.coreDataService = coreDataService
        let useCase = FetchMessageMetaData(
            params: .init(userID: userManager.userInfo.userId),
            dependencies: .init(messageDataService: userManager.messageService,
                                contextProvider: coreDataService))
        self.dependencies = .init(fetchMessageMetaData: useCase, contactCacheStatus: contactCacheStatus)
    }

    func start() {
        stop()
        status = .started
        resume()
        timer = Timer.scheduledTimer(withTimeInterval: Self.defaultPollingInterval, repeats: true) { [weak self] _ in
            self?.timerDidFire()
        }
    }

    func pause() {
        if case .idle = status {
            return
        }
        status = .started
    }

    func resume() {
        if case .idle = status {
            return
        }
        status = .running
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        status = .idle
        subscribers.removeAll()
    }

    func call() {
        if case .running = status,
           sharedServices.get(by: QueueManager.self).checkQueueStatus() == .idle {
            subscribers.forEach({ $0?() })
        }
    }

    private func timerDidFire() {
        call()
    }
}

extension EventsService {
    func begin(subscriber: EventsConsumer) {
        let observation = { [weak subscriber] in
            subscriber?.shouldCallFetchEvents()
        }
        subscribers.append(observation)
    }
}

// MARK: - Events Fetching
extension EventsService {
    /// fetch event logs from server. sync up the cache status to latest
    ///
    /// - Parameters:
    ///   - labelID: Label/location/folder
    ///   - notificationMessageID: the notification message
    ///   - completion: async complete handler
    func fetchEvents(byLabel labelID: LabelID, notificationMessageID: MessageID?, completion: CompletionBlock?) {
        guard status == .running else {
            completion?(nil, nil, EventError.notRunning as NSError)
            return
        }
        self.queueManager.queue {
            let eventAPI = EventCheckRequest(eventID: self.lastUpdatedStore.lastEventID(userID: self.userManager.userID))
            self.userManager.apiService.exec(route: eventAPI, responseObject: EventCheckResponse()) { (task, response) in

                let eventsRes = response
                if eventsRes.refresh.contains(.contacts) {
                    _ = self.userManager.contactService.cleanUp().ensure {
                        self.userManager.contactService.fetchContacts(completion: nil)
                    }
                }

                // Force refresh encrypted search index
                if UserInfo.isEncryptedSearchEnabled {
                    if eventsRes.refresh.contains(.all) || eventsRes.refresh.contains(.mail) {
                        let users: UsersManager = sharedServices.get(by: UsersManager.self)
                        if let userID = users.firstUser?.userInfo.userId {
                            print("ES-REFRESH-ALL: delete index...")
                            // delete search index
                            EncryptedSearchService.shared.deleteSearchIndex(userID: userID) {
                                print("ES-REFRESH-ALL: force rebuild index...")
                                // force rebuild
                                EncryptedSearchService.shared.forceBuildSearchIndex(userID: userID)
                            }
                        }
                    }
                }

                if eventsRes.refresh.contains(.all) || eventsRes.refresh.contains(.mail) || (eventsRes.responseCode == 18001) {
                    let getLatestEventID = EventLatestIDRequest()
                    self.userManager.apiService.exec(route: getLatestEventID, responseObject: EventLatestIDResponse()) { (task, eventIDResponse) in
                        if let err = eventIDResponse.error {
                            completion?(task, nil, err.toNSError)
                            return
                        }

                        let IDRes = eventIDResponse
                        guard !IDRes.eventID.isEmpty else {
                            completion?(task, nil, eventIDResponse.error?.toNSError)
                            return
                        }

                        let completionWrapper: CompletionBlock = { task, responseDict, error in
                            if error == nil {
                                self.dependencies.contactCacheStatus.contactsCached = 0
                                _ = self.lastUpdatedStore.updateEventID(by: self.userManager.userID, eventID: IDRes.eventID).ensure {
                                    completion?(task, responseDict, error)
                                }
                                return
                            }
                            completion?(task, responseDict, error)
                        }
                        self.userManager.conversationService.cleanAll()
                        self.userManager.messageService.cleanMessage(cleanBadgeAndNotifications: false).then {
                            return self.userManager.contactService.cleanUp()
                        }.ensure {
                            switch self.userManager.getCurrentViewMode() {
                            case .conversation:
                                self.userManager.conversationService.fetchConversations(for: labelID, before: 0, unreadOnly: false, shouldReset: false) { result in
                                    switch result {
                                    case .success:
                                        completionWrapper(nil, nil, nil)
                                    case .failure(let error):
                                        completionWrapper(nil, nil, error as NSError)
                                    }
                                }
                            case .singleMessage:
                                self.userManager.messageService.fetchMessages(byLabel: labelID, time: 0, forceClean: false, isUnread: false, completion: completionWrapper)
                            }
                            self.userManager.contactService.fetchContacts(completion: nil)
                            self.userManager.messageService.labelDataService.fetchV4Labels()
                        }.cauterize()
                    }
                } else if let messageEvents = eventsRes.messages {
                    self.processEvents(messages: messageEvents, notificationMessageID: notificationMessageID, task: task) { task, res, error in
                        if error == nil {
                            self.processEvents(conversations: eventsRes.conversations).then { (_) -> Promise<Void> in
                                return self.lastUpdatedStore.updateEventID(by: self.userManager.userID, eventID: eventsRes.eventID)
                            }.then { (_) -> Promise<Void> in
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
                                self.processEvents(conversationCounts: eventsRes.conversationCounts)
                                self.processEvents(space: eventsRes.usedSpace)

                                var outMessages: [Any] = []
                                for message in messageEvents {
                                    let msg = MessageEvent(event: message)
                                    if msg.Action == 1 {
                                        outMessages.append(msg)
                                    }
                                }
                                completion?(task, ["Messages": outMessages, "Notices": eventsRes.notices ?? [String](), "More": eventsRes.more], nil)
                            }.cauterize()
                        } else {
                            completion?(task, nil, error)
                        }
                    }
                } else {
                    if eventsRes.responseCode == 1000 {
                        self.processEvents(conversations: eventsRes.conversations).then { (_) -> Promise<Void> in
                            return self.lastUpdatedStore.updateEventID(by: self.userManager.userID, eventID: eventsRes.eventID)
                        }.then { (_) -> Promise<Void> in
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
                            self.processEvents(conversationCounts: eventsRes.conversationCounts)
                            self.processEvents(space: eventsRes.usedSpace)

                            if eventsRes.error != nil {
                                completion?(task, nil, eventsRes.error?.toNSError)
                            } else {
                                completion?(task, ["Notices": eventsRes.notices ?? [String](), "More": eventsRes.more], nil)
                            }
                        }.cauterize()
                        return
                    }
                    if eventsRes.error != nil {
                        completion?(task, nil, eventsRes.error?.toNSError)
                    } else {
                        completion?(task, ["Notices": eventsRes.notices ?? [String](), "More": eventsRes.more], nil)
                    }
                }

            }
        }
    }

    func fetchEvents(labelID: LabelID) {
        fetchEvents(
            byLabel: labelID,
            notificationMessageID: nil,
            completion: nil
        )
    }

    func fetchLatestEventID(completion: ((EventLatestIDResponse) -> Void)?) {
        let request = EventLatestIDRequest()
        userManager.apiService.exec(route: request, responseObject: EventLatestIDResponse()) { response in
            completion?(response)
        }
    }
}

// MARK: - Events Processing
extension EventsService {

    /**
     this function to process the event logs
     
     :param: messages   the message event log
     :param: task       NSURL session task
     :param: completion complete call back
     */
    fileprivate func processEvents(messages: [[String : Any]], notificationMessageID: MessageID?, task: URLSessionDataTask!, completion: CompletionBlock?) {
        struct IncrementalUpdateType {
            static let delete = 0
            static let insert = 1
            static let update_draft = 2
            static let update_flags = 3
        }

        // this serial dispatch queue prevents multiple messages from appearing when an incremental update is triggered while another is in progress
        self.incrementalUpdateQueue.sync {
            let context = self.coreDataService.operationContext
            self.coreDataService.enqueue(context: context) { (context) in
                var error: NSError?
                var messagesNoCache : [MessageID] = []
                for message in messages {
                    let msg = MessageEvent(event: message)
                    switch msg.Action {
                    case .some(IncrementalUpdateType.delete):
                        if let messageID = msg.ID {
                            if let message = Message.messageForMessageID(messageID, inManagedObjectContext: context) {
                                if UserInfo.isEncryptedSearchEnabled {
                                    // Delete message from Encrypted Search Index
                                    if userCachedStatus.isEncryptedSearchOn {
                                        let users: UsersManager = sharedServices.get(by: UsersManager.self)
                                        let uid: String? = users.firstUser?.userInfo.userId
                                        if let userID = uid {
                                            EncryptedSearchService.shared.deleteMessageFromSearchIndex(message: message, userID: userID, completionHandler: {})
                                        }
                                    }
                                }

                                let labelObjs = message.mutableSetValue(forKey: "labels")
                                labelObjs.removeAllObjects()
                                message.setValue(labelObjs, forKey: "labels")
                                context.delete(message)
                                // in case
                                error = context.saveUpstreamIfNeeded()
                            }
                        }
                    case .some(IncrementalUpdateType.insert), .some(IncrementalUpdateType.update_draft), .some(IncrementalUpdateType.update_flags):
                        if IncrementalUpdateType.insert == msg.Action {
                            if let cachedMessage = Message.messageForMessageID(msg.ID, inManagedObjectContext: context) {
                                if !cachedMessage.contains(label: .sent) {
                                    continue
                                }
                            }
                            if let notify_msg_id = notificationMessageID?.rawValue {
                                if notify_msg_id == msg.ID {
                                    _ = msg.message?.removeValue(forKey: "Unread")
                                }
                                msg.message?["messageStatus"] = 1
                                msg.message?["UserID"] = self.userManager.userID.rawValue
                            }
                            msg.message?["messageStatus"] = 1
                        }
                        if msg.isDraft,
                           let existing = Helper.getMessageWithMetaData(for: msg.ID, context: context) {
                            Helper.mergeDraft(event: msg, existing: existing)
                            self.applyLabelDeletion(msgEvent: msg, context: context, message: existing)
                            self.applyLabelAddition(msgEvent: msg, context: context, message: existing)
                            _ = context.saveUpstreamIfNeeded()
                            continue
                        }

                        do {
                            if let messageObject = try GRTJSONSerialization.object(withEntityName: Message.Attributes.entityName, fromJSONDictionary: msg.message ?? [String: Any](), in: context) as? Message {
                                self.applyLabelDeletion(msgEvent: msg, context: context, message: messageObject)

                                messageObject.userID = self.userManager.userInfo.userId
                                if msg.Action == IncrementalUpdateType.update_draft {
                                    messageObject.isDetailDownloaded = false
                                }

                                self.applyLabelAddition(msgEvent: msg, context: context, message: messageObject)

                                if (msg.message?["LabelIDs"] as? NSArray) != nil {
                                    messageObject.checkLabels()
                                    // TODO : add later need to know whne it is happending
                                }

                                if messageObject.messageStatus == 0 {
                                    if messageObject.subject.isEmpty {
                                        messagesNoCache.append(MessageID(messageObject.messageID))
                                    } else {
                                        messageObject.messageStatus = 1
                                    }
                                }

                                if messageObject.managedObjectContext == nil {
                                    if let messageid = msg.message?["ID"] as? String {
                                        messagesNoCache.append(MessageID(messageid))
                                    }
                                }
                                
                                if UserInfo.isEncryptedSearchEnabled {
                                    // Insert message into Encrypted Search Index
                                    if userCachedStatus.isEncryptedSearchOn {
                                        let users: UsersManager = sharedServices.get(by: UsersManager.self)
                                        let uid: String? = users.firstUser?.userInfo.userId
                                        if let userID = uid {
                                            if msg.Action == IncrementalUpdateType.insert {
                                                EncryptedSearchService.shared.insertSingleMessageToSearchIndex(message: messageObject, userID: userID) {
                                                    // Update cache if existing
                                                    //let _ = EncryptedSearchCacheService.shared.updateCachedMessage(userID: userID, message: messageObject)
                                                    EncryptedSearchService.shared.refreshCache(userID: userID)
                                                }
                                            } else if msg.Action == IncrementalUpdateType.update_draft {
                                                EncryptedSearchService.shared.deleteMessageFromSearchIndex(message: messageObject, userID: userID) {
                                                    // Wait until delete is done - then insert updated message
                                                    EncryptedSearchService.shared.insertSingleMessageToSearchIndex(message: messageObject, userID: userID) {
                                                        // Update cache if existing
                                                        //let _ = EncryptedSearchCacheService.shared.updateCachedMessage(userID: userID, message: messageObject)
                                                        EncryptedSearchService.shared.refreshCache(userID: userID)
                                                    }
                                                }
                                            } else if msg.Action == IncrementalUpdateType.update_flags {
                                                EncryptedSearchService.shared.deleteMessageFromSearchIndex(message: messageObject, userID: userID) {
                                                    // Wait until delete is done - then insert updated message
                                                    EncryptedSearchService.shared.insertSingleMessageToSearchIndex(message: messageObject, userID: userID) {
                                                        // Update cache if existing
                                                        //let _ = EncryptedSearchCacheService.shared.updateCachedMessage(userID: userID, message: messageObject)
                                                        EncryptedSearchService.shared.refreshCache(userID: userID)
                                                    }
                                                }
                                            }
                                        } else {
                                            print("Error: cannot process event - user unknown!")
                                        }
                                    }
                                }
                            } else {
                                // when GRTJSONSerialization inset returns no thing
                                if let messageid = msg.message?["ID"] as? String {
                                    messagesNoCache.append(MessageID(messageid))
                                }
                            }
                        } catch {
                            // when GRTJSONSerialization insert failed
                            if let messageid = msg.message?["ID"] as? String {
                                messagesNoCache.append(MessageID(messageid))
                            }
                        }
                    default:
                        break

                    }
                    // TODO:: move this to the loop and to catch the error also put it in noCache queue.
                    error = context.saveUpstreamIfNeeded()
                }

                self.dependencies
                    .fetchMessageMetaData
                    .execute(with: messagesNoCache) { _ in }

                DispatchQueue.main.async {
                    completion?(task, nil, error)
                    return
                }
            }
        }
    }

    fileprivate func processEvents(conversations: [[String: Any]]?) -> Promise<Void> {
        struct IncrementalUpdateType {
            static let delete = 0
            static let insert = 1
            static let update_draft = 2
            static let update_flags = 3
        }

        guard let conversationsDict = conversations else {
            return Promise()
        }
        return Promise { seal in
            self.incrementalUpdateQueue.sync {
                let context = self.coreDataService.operationContext
                self.coreDataService.enqueue(context: context) { (context) in
                    defer {
                        seal.fulfill_()
                    }
                    var conversationsNeedRefetch: [String] = []

                    for conDict in conversationsDict {
                        // Parsing conversation event
                        guard let conversationEvent = ConversationEvent(event: conDict) else {
                            continue
                        }
                        switch conversationEvent.action {
                        case IncrementalUpdateType.delete:
                            if let conversation = Conversation.conversationForConversationID(conversationEvent.ID, inManagedObjectContext: context) {
                                let labelObjs = conversation.mutableSetValue(forKey: Conversation.Attributes.labels)
                                labelObjs.allObjects
                                    .compactMap({ $0 as? ContextLabel })
                                    .forEach { $0.messageCount = 0 }
                                labelObjs.removeAllObjects()
                                context.delete(conversation)

                                _ = context.saveUpstreamIfNeeded()
                            }
                        case IncrementalUpdateType.insert: // treat it as same as update
                            if Conversation.conversationForConversationID(conversationEvent.ID, inManagedObjectContext: context) != nil {
                                continue
                            }
                            do {
                                if let conversationObject = try GRTJSONSerialization.object(withEntityName: Conversation.Attributes.entityName, fromJSONDictionary: conversationEvent.conversation, in: context) as? Conversation {
                                    conversationObject.userID = self.userManager.userInfo.userId
                                    if let labels = conversationObject.labels as? Set<ContextLabel> {
                                        for label in labels {
                                            label.order = conversationObject.order
                                        }
                                    }
                                }
                                _ = context.saveUpstreamIfNeeded()
                            } catch {
                                // Refetch after insert failed
                                conversationsNeedRefetch.append(conversationEvent.ID)
                            }
                        case IncrementalUpdateType.update_draft, IncrementalUpdateType.update_flags:
                            do {
                                var conversationData = conversationEvent.conversation

                                // this code is only to track an issue with conversationId being empty
                                // https://jira.protontech.ch/browse/MAILIOS-2489
                                if (conDict["ID"] as? String) == nil || (conDict["ID"] as? String)?.count == 0 {
                                    let originalValue = conversationData["ID"] as? String
                                    let msg = "processEvents conversations (empty will override original convId: \(originalValue ?? "nil")"
                                    Breadcrumbs.shared.add(message: msg, to: .malformedConversationRequest)
                                }

                                conversationData["ID"] = conDict["ID"] as? String

                                if var labels = conversationData["Labels"] as? [[String: Any]] {
                                    for (index, _) in labels.enumerated() {
                                        labels[index]["UserID"] = self.userManager.userID.rawValue
                                        labels[index]["ConversationID"] = conversationData["ID"]
                                    }
                                    conversationData["Labels"] = labels
                                }

                                if let conversationObject = try GRTJSONSerialization.object(withEntityName: Conversation.Attributes.entityName, fromJSONDictionary: conversationData, in: context) as? Conversation {
                                    if let labels = conversationObject.labels as? Set<ContextLabel> {
                                        for label in labels {
                                            label.order = conversationObject.order
                                        }
                                    }
                                    if let messageCount = conversationEvent.conversation["NumMessages"] as? NSNumber, conversationObject.numMessages != messageCount {
                                        conversationsNeedRefetch.append(conversationEvent.ID)
                                    }
                                }
                                _ = context.saveUpstreamIfNeeded()
                            } catch {
                                conversationsNeedRefetch.append(conversationEvent.ID)
                            }
                        default:
                            break
                        }

                        _ = context.saveUpstreamIfNeeded()
                    }

                    let conversationIDs = conversationsNeedRefetch.map {ConversationID($0)}
                    self.userManager.conversationService.fetchConversations(with: conversationIDs, completion: nil)
                }
            }
        }
    }

    /// Process contacts from event logs
    ///
    /// - Parameter contacts: contact events
    fileprivate func processEvents(contacts: [[String: Any]]?) -> Promise<Void> {
        guard let contacts = contacts else {
            return Promise()
        }

        return Promise { seal in
            let context = self.coreDataService.operationContext
            self.coreDataService.enqueue(context: context) { (context) in
                defer {
                    seal.fulfill_()
                }
                for contact in contacts {
                    let contactObj = ContactEvent(event: contact)
                    switch contactObj.action {
                    case .delete:
                        if let contactID = contactObj.ID {
                            if let tempContact = Contact.contactForContactID(contactID, inManagedObjectContext: context) {
                                context.delete(tempContact)
                            }
                        }
                        // save it earily
                        _ = context.saveUpstreamIfNeeded()
                    case .insert, .update:
                        do {
                            if let outContacts = try GRTJSONSerialization.objects(withEntityName: Contact.Attributes.entityName,
                                                                                  fromJSONArray: contactObj.contacts,
                                                                                  in: context) as? [Contact] {
                                let allLocalEmails = (try? context.fetch(NSFetchRequest<Email>(entityName: Email.Attributes.entityName))) ?? []
                                for c in outContacts {
                                    c.isDownloaded = false
                                    c.userID = self.userManager.userInfo.userId
                                    if let emails = c.emails.allObjects as? [Email] {
                                        emails.forEach { (e) in
                                            allLocalEmails
                                                .filter { localEmail in
                                                    // Same email, same name, and emailID is a UUID, then it was a temporary email that we must delete to avoid duplicates
                                                    localEmail.email == e.email
                                                    && UUID(uuidString: localEmail.emailID) != nil
                                                }
                                                .forEach { context.delete($0) }
                                            e.userID = self.userManager.userInfo.userId
                                        }
                                    }
                                }
                            }
                        } catch {
                        }
                        _ = context.saveUpstreamIfNeeded()
                    default:
                        break
                    }
                }
            }
        }
    }

    /// Process contact emails this is like metadata update
    ///
    /// - Parameter contactEmails: contact email events
    fileprivate func processEvents(contactEmails: [[String: Any]]?) -> Promise<Void> {
        guard let emails = contactEmails else {
            return Promise()
        }

        return Promise { seal in
            let context = self.coreDataService.operationContext
            self.coreDataService.enqueue(context: context) { (context) in
                defer {
                    seal.fulfill_()
                }
                for email in emails {
                    let emailObj = EmailEvent(event: email)
                    switch emailObj.action {
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
                                    c.userID = self.userManager.userInfo.userId
                                    if let emails = c.emails.allObjects as? [Email] {
                                        emails.forEach { (e) in
                                            e.userID = self.userManager.userInfo.userId
                                        }
                                    }
                                }
                            }

                        } catch {
                        }
                    default:
                        break
                    }
                }

                _ = context.saveUpstreamIfNeeded()
            }
        }
    }

    /// Process Labels include Folders and Labels.
    ///
    /// - Parameter labels: labels events
    fileprivate func processEvents(labels: [[String: Any]]?) -> Promise<Void> {
        struct IncrementalUpdateType {
            static let delete = 0
            static let insert = 1
            static let update = 2
        }

        if let labels = labels {
            return Promise { seal in
                // this serial dispatch queue prevents multiple messages from appearing when an incremental update is triggered while another is in progress
                self.incrementalUpdateQueue.sync {
                    let context = self.coreDataService.operationContext
                    self.coreDataService.enqueue(context: context) { (context) in
                        defer {
                            seal.fulfill_()
                        }
                        for labelEvent in labels {
                            let label = LabelEvent(event: labelEvent)
                            switch label.Action {
                            case .some(IncrementalUpdateType.delete):
                                if let labelID = label.ID {
                                    if let dLabel = Label.labelForLabelID(labelID, inManagedObjectContext: context) {
                                        context.delete(dLabel)
                                    }
                                }
                            case .some(IncrementalUpdateType.insert), .some(IncrementalUpdateType.update):
                                do {
                                    if var new_or_update_label = label.label {
                                        new_or_update_label["UserID"] = self.userManager.userID.rawValue
                                        try GRTJSONSerialization.object(withEntityName: Label.Attributes.entityName, fromJSONDictionary: new_or_update_label, in: context)
                                    }
                                } catch {
                                }
                            default:
                                break
                            }
                        }
                        _ = context.saveUpstreamIfNeeded()
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
    fileprivate func processEvents(user: [String: Any]?) {
        guard let userEvent = user else {
            return
        }
        self.userManager?.updateFromEvents(userInfoRes: userEvent)
    }
    fileprivate func processEvents(userSettings: [String: Any]?) {
        guard let userSettingEvent = userSettings else {
            return
        }
        self.userManager?.updateFromEvents(userSettingsRes: userSettingEvent)
    }
    func processEvents(mailSettings: [String: Any]?) {
        guard let mailSettingEvent = mailSettings else {
            return
        }
        self.userManager?.updateFromEvents(mailSettingsRes: mailSettingEvent)
    }

    fileprivate func processEvents(addresses: [[String: Any]]?) -> Promise<Void> {
        guard let addrEvents = addresses else {
            return Promise()
        }
        return Promise { seal in
            self.incrementalUpdateQueue.async {
                for addrEvent in addrEvents {
                    let address = AddressEvent(event: addrEvent)
                    switch address.action {
                    case .delete:
                        if let addrID = address.ID {
                            self.userManager?.deleteFromEvents(addressIDRes: addrID)
                        }
                    case .insert, .update1:
                        guard let addrID = address.ID, let addrDict = address.address else {
                            break
                        }
                        let addrRes = AddressesResponse()
                        _ = addrRes.parseAddr(res: addrDict)

                        guard addrRes.addresses.count == 1, let parsedAddr = addrRes.addresses.first, parsedAddr.addressID == addrID else {
                            break
                        }
                        self.userManager?.setFromEvents(addressRes: parsedAddr)
                        guard let user = self.userManager else {
                            break
                        }
                        do {
                            try `await`(user.userService.activeUserKeys(userInfo: user.userInfo, auth: user.authCredential))
                        } catch {
                        }
                    default:
                        break
                    }
                }
                seal.fulfill_()
            }
        }
    }

    /// Process Message count from event logs
    ///
    /// - Parameter counts: message count dict
    func processEvents(counts: [[String: Any]]?) {
        guard let messageCounts = counts, messageCounts.count > 0 else {
            return
        }

        self.coreDataService.enqueue(context: self.coreDataService.operationContext) { [weak self] (context) in
            guard let self = self else { return }
            for count in messageCounts {
                if let labelID = count["LabelID"] as? String {
                    guard let unread = count["Unread"] as? Int else {
                        continue
                    }
                    let total = count["Total"] as? Int
                    self.lastUpdatedStore.updateUnreadCount(by: LabelID(labelID), userID: self.userManager.userID, unread: unread, total: total, type: .singleMessage, shouldSave: false)
                    self.updateBadgeIfNeeded(unread: unread, labelID: labelID, type: .singleMessage)
                }
            }

            _ = context.saveUpstreamIfNeeded()

            guard let users = self.userManager.parentManager,
                  let primaryUser = users.firstUser,
                  primaryUser.userInfo.userId == self.userManager.userInfo.userId,
                  primaryUser.getCurrentViewMode() == .singleMessage else { return }

            let unreadCount: Int = self.lastUpdatedStore.unreadCount(by: Message.Location.inbox.labelID, userID: self.userManager.userID, type: .singleMessage)
            UIApplication.setBadge(badge: max(0, unreadCount))
        }
    }

    func processEvents(conversationCounts: [[String: Any]]?) {
        guard let conversationCounts = conversationCounts, conversationCounts.count > 0 else {
            return
        }

        self.coreDataService.enqueue(context: self.coreDataService.operationContext) { (context) in
            for count in conversationCounts {
                if let labelID = count["LabelID"] as? String {
                    guard let unread = count["Unread"] as? Int else {
                        continue
                    }
                    let total = count["Total"] as? Int
                    self.lastUpdatedStore.updateUnreadCount(by: LabelID(labelID), userID: self.userManager.userID, unread: unread, total: total, type: .conversation, shouldSave: false)
                    self.updateBadgeIfNeeded(unread: unread, labelID: labelID, type: .conversation)
                }
            }

            _ = context.saveUpstreamIfNeeded()

            guard let users = self.userManager.parentManager,
                  let primaryUser = users.firstUser,
                  primaryUser.userInfo.userId == self.userManager.userInfo.userId,
                  primaryUser.getCurrentViewMode() == .conversation else { return }

            let unreadCount: Int = self.lastUpdatedStore.unreadCount(by: Message.Location.inbox.labelID, userID: self.userManager.userID, type: .conversation)
            UIApplication.setBadge(badge: max(0, unreadCount))
        }
    }

    func processEvents(space usedSpace: Int64?) {
        guard let usedSpace = usedSpace else {
            return
        }
        self.userManager?.update(usedSpace: usedSpace)
    }

    private func applyLabelDeletion(msgEvent: MessageEvent, context: NSManagedObjectContext, message: Message) {
        // apply the label changes
        if let deleted = msgEvent.message?["LabelIDsRemoved"] as? NSArray {
            for delete in deleted {
                let labelID = delete as! String
                if let label = Label.labelForLabelID(labelID, inManagedObjectContext: context) {
                    let labelObjs = message.mutableSetValue(forKey: "labels")
                    if labelObjs.count > 0 {
                        labelObjs.remove(label)
                        message.setValue(labelObjs, forKey: "labels")
                    }
                }
            }
        }
    }

    private func applyLabelAddition(msgEvent: MessageEvent, context: NSManagedObjectContext, message: Message) {
        if let added = msgEvent.message?["LabelIDsAdded"] as? NSArray {
            for add in added {
                if let label = Label.labelForLabelID(add as! String, inManagedObjectContext: context) {
                    let labelObjs = message.mutableSetValue(forKey: "labels")
                    labelObjs.add(label)
                    message.setValue(labelObjs, forKey: "labels")
                }
            }
        }
    }

    // TODO: moving this to a better place
    private func updateBadgeIfNeeded(unread: Int, labelID: String, type: ViewMode) {
        let users: UsersManager = sharedServices.get(by: UsersManager.self)
        guard let firstUser = users.firstUser else {
            return
        }
        let isPrimary = firstUser.userID == self.userManager.userID
        guard labelID == Message.Location.inbox.rawValue,
              isPrimary,
              type == firstUser.getCurrentViewMode() else { return }
        UIApplication.setBadge(badge: unread)
    }
}

