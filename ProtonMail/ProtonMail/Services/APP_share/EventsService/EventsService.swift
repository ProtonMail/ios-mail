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

import EllipticCurveKeyPair
import Foundation
import Groot
@preconcurrency import ProtonCoreDataModel
@preconcurrency import ProtonCoreNetworking
import ProtonCoreServices
import ProtonMailAnalytics

enum EventsFetchingStatus {
    case idle
    case started
    case running
}

protocol EventsFetching: EventsServiceProtocol {
    var status: EventsFetchingStatus { get }
    func start()
    func pause()
    func resume()
    func stop()
    func call()

    func begin(subscriber: EventsConsumer)

    func fetchEvents(byLabel labelID: LabelID, notificationMessageID: MessageID?, discardContactsMetadata: Bool, completion: ((Swift.Result<[String: Any], Error>) -> Void)?)
    func fetchEvents(labelID: LabelID)
    func processEvents(mailSettings: [String: Any]?)
    func processEvents(space usedSpace: Int64?)
}

protocol EventsConsumer: AnyObject {
    func shouldCallFetchEvents()
}

enum EventError: Error {
    case notRunning
    case noUser
}

/// This is the protocol being worked on during the refactor. It will end up being the only one for EventsService.
protocol EventsServiceProtocol: AnyObject {
    func processEvents(messageCounts: [[String: Any]]?)
    func processEvents(conversationCounts: [[String: Any]]?)
}

final class EventsService: EventsFetching {
    typealias Dependencies = AnyObject
    & HasCoreDataContextProviderProtocol
    & HasFeatureFlagCache
    & HasFetchMessageMetaData
    & HasIncomingDefaultService
    & HasLastUpdatedStoreProtocol
    & HasNotificationCenter
    & HasQueueManager
    & HasUsersManager
    & HasNotificationCenter
    & HasUserDefaults
    & HasContactDataService
    & HasMailEventsPeriodicScheduler

    // this serial dispatch queue prevents multiple messages from appearing when an incremental update is triggered while another is in progress
    private let incrementalUpdateQueue = DispatchQueue(label: "ch.protonmail.incrementalUpdateQueue", attributes: [])

    private typealias EventsObservation = (() -> Void?)?
    private(set) var status: EventsFetchingStatus = .idle
    private var subscribers: [EventsObservation] = []
    private var timer: Timer?
    private weak var userManager: UserManager?
    private unowned let dependencies: Dependencies

    init(userManager: UserManager, dependencies: Dependencies) {
        self.userManager = userManager
        self.dependencies = dependencies
    }

    func start() {
        stop()
        status = .started
        resume()
        timer = Timer.scheduledTimer(withTimeInterval: Constants.App.eventsPollingInterval, repeats: true) { [weak self] _ in
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
        if case .running = status, dependencies.queueManager.checkQueueStatus() == .idle {
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
    func fetchEvents(
        byLabel labelID: LabelID,
        notificationMessageID: MessageID?,
        discardContactsMetadata: Bool = EventCheckRequest.isNoMetaDataForContactsEnabled,
        completion: ((Swift.Result<[String: Any], Error>) -> Void)?
    ) {
        if userManager?.isNewEventLoopEnabled == true {
            fetchEventsWithNewApproach(
                byLabel: labelID,
                completion: completion
            )
            return
        }
        dependencies.queueManager.queue {
            guard self.status == .running, let userManager = self.userManager else {
                completion?(.failure(EventError.notRunning))
                return
            }
            
            if self.isOverTimeThreshold(userID: userManager.userID) {
                self.cleanCacheAndRefetchData(userManager: userManager, labelID: labelID, completion: completion)
                return
            }
        
            let eventID = self.dependencies.lastUpdatedStore.lastEventID(userID: userManager.userID)
            SystemLogger.log(message: "Fetching events since \(eventID)", category: .mailboxRefresh)
            let eventAPI = EventCheckRequest(eventID: eventID, discardContactsMetadata: discardContactsMetadata)
            userManager.apiService.perform(request: eventAPI, response: EventCheckResponse()) { _, eventsRes in

                guard eventsRes.responseCode == 1000 else {
                    if let eventError = eventsRes.error {
                        completion?(.failure(eventError.toNSError))
                    } else {
                        completion?(.success(["Notices": eventsRes.notices ?? [String](), "More": eventsRes.more]))
                    }
                    return
                }

                if eventsRes.refreshStatus.contains(.all) {
                    self.cleanCacheAndRefetchData(userManager: userManager, labelID: labelID, completion: completion)
                    return
                }

                if eventsRes.refreshStatus.contains(.contacts) {
                    userManager.contactService.cleanUp()
                    // Although this flag is triggered when all of contacts are deleted
                    // But if user create a new contact right after deletion
                    // The new contact won't be sent, client needs to call API to get it
                    // Call contacts API just in case
                    userManager.contactService.fetchContacts(completion: nil)
                }
        
                self.incrementalUpdateQueue.async {
                    do {
                        let messageEvents = eventsRes.messages ?? []
                        try self.processEvents(messages: messageEvents, notificationMessageID: notificationMessageID)
                        self.processEvents(conversations: eventsRes.conversations)
                        self.processEvents(contactEmails: eventsRes.contactEmails)
                        if discardContactsMetadata {
                            self.processContactEventsWithoutMetadata(eventsRes.contacts)
                        } else {
                            self.processEvents(contacts: eventsRes.contacts)
                        }
                        self.processEvents(labels: eventsRes.labels)
                        self.processEvents(addresses: eventsRes.addresses)
                        self.processEvents(incomingDefaults: eventsRes.incomingDefaults)
                        self.processEvents(user: eventsRes.user)
                        self.processEvents(userSettings: eventsRes.userSettings)
                        self.processEvents(mailSettings: eventsRes.mailSettings)
                        self.processEvents(messageCounts: eventsRes.messageCounts)
                        self.processEvents(conversationCounts: eventsRes.conversationCounts)
                        self.processEvents(space: eventsRes.usedSpace)
                        SystemLogger.log(message: "Fetched events up to \(eventsRes.eventID)", category: .mailboxRefresh)
                        self.dependencies.lastUpdatedStore.updateEventID(by: userManager.userID, eventID: eventsRes.eventID)

                        let outMessages = messageEvents
                            .map { MessageEvent(event: $0) }
                            .filter { $0.Action == 1 }
                        completion?(.success(
                            [
                                "Messages": outMessages,
                                "Notices": eventsRes.notices ?? [String](),
                                "More": eventsRes.more
                            ]
                        ))
                    } catch {
                        completion?(.failure(error))
                    }
                }
            }
        }
    }

    private func fetchEventsWithNewApproach(
        byLabel labelID: LabelID,
        completion: ((Swift.Result<[String: Any], Error>) -> Void)?
    ) {
        guard let user = userManager else {
            completion?(.failure(EventError.noUser))
            return
        }
        if isOverTimeThreshold(userID: user.userID) {
            cleanCacheAndRefetchData(userManager: user, labelID: labelID, completion: completion)
            return
        }
        let eventID = dependencies.lastUpdatedStore.lastEventID(userID: user.userID)
        Task {
            do {
                let response = try await MailEventsLoop.fetchEvent(eventID: eventID, apiService: user.apiService, jsonDecoder: .init())

                let refreshStatus = RefreshStatus(rawValue: response.refresh)
                if refreshStatus == .all {
                    cleanCacheAndRefetchData(userManager: user, labelID: labelID, completion: completion)
                    return
                }

                if refreshStatus == .contacts {
                    user.contactService.cleanUp()
                    // Although this flag is triggered when all of contacts are deleted
                    // But if user create a new contact right after deletion
                    // The new contact won't be sent, client needs to call API to get it
                    // Call contacts API just in case
                    user.contactService.fetchContacts(completion: nil)
                }

                let eventProcessor = EventProcessor(dependencies: user.container)
                eventProcessor.process(response: response) { result in
                    switch result {
                    case .success:
                        completion?(.success([
                            "Notices": response.notices,
                            "More": response.more,
                            "Refresh": response.refresh
                        ]))
                    case .failure(let error):
                        completion?(.failure(error))
                    }
                }
            } catch {
                completion?(.failure(error))
            }
        }
    }

    func fetchEvents(labelID: LabelID) {
        guard let user = userManager, !user.isNewEventLoopEnabled else {
            if let userID = userManager?.userID {
                dependencies.mailEventsPeriodicScheduler.triggerSpecialLoop(forSpecialLoopID: userID.rawValue)
            }
            return
        }
        fetchEvents(
            byLabel: labelID,
            notificationMessageID: nil,
            completion: nil
        )
    }
}

// MARK: - Events Processing
extension EventsService {
    
    private func isOverTimeThreshold(userID: UserID) -> Bool {
        guard
            dependencies.featureFlagCache.isFeatureFlag(.refetchEventsByTime, enabledForUserWithID: userID),
            let lastDate = dependencies.lastUpdatedStore.lastEventUpdateTime(userID: userID)
        else { return false }
        let secondDifference = lastDate.distance(to: Date())
        let hourDifference = secondDifference / 3600.0
        let threshold: Int = dependencies.featureFlagCache.valueOfFeatureFlag(.refetchEventsHourThreshold, for: userID)
        return Double(threshold) < hourDifference
    }
    
    private func cleanCacheAndRefetchData(
        userManager: UserManager,
        labelID: LabelID,
        completion: ((Swift.Result<[String: Any], Error>) -> Void)?
    ) {
        let getLatestEventID = EventLatestIDRequest()
        userManager.apiService.perform(request: getLatestEventID, response: EventLatestIDResponse()) { _, eventIDResponse in
            if let err = eventIDResponse.error {
                completion?(.failure(err.toNSError))
                return
            }
            
            let IDRes = eventIDResponse
            guard !IDRes.eventID.isEmpty else {
                completion?(.failure(eventIDResponse.error?.toNSError ?? .badResponse()))
                return
            }
            
            let completionWrapper: JSONCompletion = { _, result in
                switch result {
                case .failure(let error):
                    completion?(.failure(error))
                case .success(let responseDict):
                    self.dependencies.userDefaults[.areContactsCached] = 0
                    self.dependencies.lastUpdatedStore.updateEventID(by: userManager.userID, eventID: IDRes.eventID)
                    completion?(.success(responseDict))
                }
            }
            userManager.conversationService.cleanAll()
            userManager.messageService.cleanMessage(cleanBadgeAndNotifications: false)
            userManager.contactService.cleanUp()
            switch userManager.conversationStateService.viewMode {
            case .conversation:
                userManager.conversationService.fetchConversations(for: labelID, before: 0, unreadOnly: false, shouldReset: false) { result in
                    switch result {
                    case .success:
                        completionWrapper(nil, .success([:]))
                    case .failure(let error):
                        completionWrapper(nil, .failure(error as NSError))
                    }
                }
            case .singleMessage:
                userManager.messageService.fetchMessages(
                    byLabel: labelID,
                    time: 0,
                    forceClean: false,
                    isUnread: false
                ) { task, response, error in
                    if let error = error {
                        completionWrapper(nil, .failure(error))
                        return
                    }
                    completionWrapper(nil, .success(response ?? [:]))
                }
            }
            userManager.contactService.fetchContacts(completion: nil)
            userManager.messageService.labelDataService.fetchV4Labels()
        }
    }
    
    fileprivate func processEvents(messages: [[String : Any]], notificationMessageID: MessageID?) throws {
        assertProperExecution()

        struct IncrementalUpdateType {
            static let delete = 0
            static let insert = 1
            static let update_draft = 2
            static let update_flags = 3
        }
        var error: NSError?
        dependencies.contextProvider.performAndWaitOnRootSavingContext { [weak userManager] context in
            guard let userManager else {
                return
            }

            var messagesNoCache : [MessageID] = []
            for message in messages {
                let msg = MessageEvent(event: message)
                switch msg.Action {
                case .some(IncrementalUpdateType.delete):
                    if let messageID = msg.ID {
                        if let message = Message.messageForMessageID(messageID, inManagedObjectContext: context) {
                            let labelObjs = message.mutableSetValue(forKey: "labels")
                            labelObjs.removeAllObjects()
                            message.setValue(labelObjs, forKey: "labels")
                            context.delete(message)
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
                            msg.message?["UserID"] = userManager.userID.rawValue
                        }
                        msg.message?["messageStatus"] = 1
                    }
                    if msg.isDraft,
                       let existing = Helper.getMessageWithMetaData(for: msg.ID, context: context) {
                        if !self.isMessageBeingSent(messageID: .init(existing.messageID)) {
                            Helper.mergeDraft(event: msg, existing: existing)
                            self.applyLabelDeletion(msgEvent: msg, context: context, message: existing)
                            self.applyLabelAddition(msgEvent: msg, context: context, message: existing)
                        }
                        continue
                    }

                    do {
                        if let messageObject = try GRTJSONSerialization.object(withEntityName: Message.Attributes.entityName, fromJSONDictionary: msg.message ?? [String: Any](), in: context) as? Message {
                            self.applyLabelDeletion(msgEvent: msg, context: context, message: messageObject)

                            messageObject.userID = userManager.userInfo.userId
                            if msg.Action == IncrementalUpdateType.update_draft {
                                messageObject.isDetailDownloaded = false
                            }

                            self.applyLabelAddition(msgEvent: msg, context: context, message: messageObject)

                            if (msg.message?["LabelIDs"] as? NSArray) != nil {
                                messageObject.checkLabels()
                                // TODO : add later need to know when it is happening
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

                            if msg.Action == IncrementalUpdateType.insert {
                                messageObject.labels.allObjects
                                    .compactMap { $0 as? Label }
                                    .forEach { label in
                                        let msgCount = LabelUpdate.lastUpdate(
                                            by: label.labelID,
                                            userID: userManager.userID.rawValue,
                                            inManagedObjectContext: context
                                        )
                                        msgCount?.unread += 1
                                        msgCount?.total += 1
                                    }

                            }
                        } else {
                            // when GRTJSONSerialization insert returns nothing
                            if let messageid = msg.message?["ID"] as? String {
                                messagesNoCache.append(MessageID(messageid))
                            }
                        }
                    } catch {
                        PMAssertionFailure(error)
                        // when GRTJSONSerialization insert failed
                        if let messageid = msg.message?["ID"] as? String {
                            messagesNoCache.append(MessageID(messageid))
                        }
                    }
                default:
                    break

                }
            }
            error = context.saveUpstreamIfNeeded() ?? error

            self.dependencies
                .fetchMessageMetaData
                .execute(params: .init(messageIDs: messagesNoCache)) { _ in }
        }

        if let error = error {
            throw error
        }
    }

    private func processEvents(conversations: [[String: Any]]?) {
        assertProperExecution()

        struct IncrementalUpdateType {
            static let delete = 0
            static let insert = 1
            static let update_draft = 2
            static let update_flags = 3
        }

        guard let conversationsDict = conversations else {
            return
        }
                dependencies.contextProvider.performAndWaitOnRootSavingContext { [weak userManager] context in
                    guard let userManager else {
                        return
                    }

                    var conversationsNeedRefetch: [String] = []

                    for conDict in conversationsDict {
                        // Parsing conversation event
                        guard let conversationEvent = ConversationEvent(event: conDict) else {
                            PMAssertionFailure("Could not instantiate ConversationEvent")
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
                            }
                        case IncrementalUpdateType.insert: // treat it as same as update
                            if Conversation.conversationForConversationID(conversationEvent.ID, inManagedObjectContext: context) != nil {
                                continue
                            }
                            do {
                                if let conversationObject = try GRTJSONSerialization.object(withEntityName: Conversation.Attributes.entityName, fromJSONDictionary: conversationEvent.conversation, in: context) as? Conversation {
                                    conversationObject.userID = userManager.userInfo.userId
                                    if let labels = conversationObject.labels as? Set<ContextLabel> {
                                        for label in labels {
                                            label.order = conversationObject.order
                                            label.userID = userManager.userID.rawValue
                                            label.conversationID = conversationObject.conversationID

                                            let conversationCount = ConversationCount.lastContextUpdate(
                                                by: label.labelID,
                                                userID: userManager.userID.rawValue,
                                                inManagedObjectContext: context
                                            )
                                            conversationCount?.unread += 1
                                            conversationCount?.total += 1
                                        }
                                    }
                                }
                            } catch {
                                PMAssertionFailure(error)
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
                                conversationData["UserID"] = userManager.userID.rawValue

                                if var labels = conversationData["Labels"] as? [[String: Any]] {
                                    for (index, _) in labels.enumerated() {
                                        labels[index]["UserID"] = userManager.userID.rawValue
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
                            } catch {
                                PMAssertionFailure(error)
                                conversationsNeedRefetch.append(conversationEvent.ID)
                            }
                        default:
                            break
                        }
                    }

                    _ = context.saveUpstreamIfNeeded()

                    let conversationIDs = conversationsNeedRefetch.map {ConversationID($0)}
                    userManager.conversationService.fetchConversations(with: conversationIDs, completion: nil)
                }
    }

    /// Process contacts from event logs
    ///
    /// - Parameter contacts: contact events
    fileprivate func processEvents(contacts: [[String: Any]]?) {
        guard let contacts = contacts else {
            return
        }

            dependencies.contextProvider.performAndWaitOnRootSavingContext { [weak userManager] context in
                guard let userManager else {
                    return
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
                    case .insert, .update:
                        do {
                            if let outContacts = try GRTJSONSerialization.objects(withEntityName: Contact.Attributes.entityName,
                                                                                  fromJSONArray: contactObj.contacts,
                                                                                  in: context) as? [Contact] {
                                let allLocalEmails = (try? context.fetch(NSFetchRequest<Email>(entityName: Email.Attributes.entityName))) ?? []
                                for c in outContacts {
                                    c.isDownloaded = false
                                    c.userID = userManager.userInfo.userId
                                    if let emails = c.emails.allObjects as? [Email] {
                                        emails.forEach { (e) in
                                            allLocalEmails
                                                .filter { localEmail in
                                                    // Same email, same name, and emailID is a UUID, then it was a temporary email that we must delete to avoid duplicates
                                                    localEmail.email == e.email
                                                    && UUID(uuidString: localEmail.emailID) != nil
                                                }
                                                .forEach { context.delete($0) }
                                            e.userID = userManager.userInfo.userId
                                        }
                                    }
                                }
                            }
                        } catch {
                            PMAssertionFailure(error)
                        }
                    default:
                        break
                    }
                }
                _ = context.saveUpstreamIfNeeded()
            }
    }

    /// Enqueues fetch contact detail operations for contact events
    private func processContactEventsWithoutMetadata(_ contacts: [[String: Any]]?) {
        guard  let contacts = contacts else { return }

        let contactObjects = contacts.compactMap { object in
            let contactObj = ContactEvent(event: object)
            switch contactObj.action {
            case .insert, .update, .delete:
                return contactObj
            default:
                PMAssertionFailure("event loop unexpected contact action \(contactObj.action)")
                return nil
            }
        }
        let createdContactIDs: Set<String> = Set(contactObjects.filter { $0.action == .insert }.map(\.ID))
        let updatedContactIDs: Set<String> = Set(contactObjects.filter { $0.action == .update }.map(\.ID))
        let deletedContactIDs: Set<String> = Set(contactObjects.filter { $0.action == .delete }.map(\.ID))

        let existingContactsIDs: Set<String> = Set(
            dependencies.contactService.getContactsByIds(Array(createdContactIDs)).map(\.contactID.rawValue)
        )

        // 1. Manage `delete` events
        dependencies.contextProvider.performAndWaitOnRootSavingContext { context in
            for contactID in deletedContactIDs {
                guard let tempContact = Contact.contactForContactID(contactID, inManagedObjectContext: context) else {
                    return
                }
                context.delete(tempContact)
            }
        }

        // 2. Manage `create` and `update` events
        let contactIDsToFetch = Array(
            createdContactIDs                          // all create events
                .subtracting(existingContactsIDs)      // remove create events for contacts that exist
                .union(updatedContactIDs)              // add update events
                .subtracting(deletedContactIDs)        // remove any event if there is a delete
        )

        guard let userID = userManager?.userID else {
            PMAssertionFailure("processContactEventsWithoutMetadata no userID found")
            return
        }

        // We break in batches to have smaller tasks enqueued, otherwise if the task does 
        // not finish (e.g. app killed) the task would start from the beginning on next launch.
        // If we enqueue one single task with hundreds of requests, the app could struggle
        // to move the misc queue forward in bad connection conditions. In smaller
        // tasks, some will be removed from the queue at a time.

        let batches = contactIDsToFetch.chunked(into: 15)
        for batch in batches {
            let task = QueueManager.Task(
                messageID: "",
                action: .fetchContactDetail(contactIDs: batch),
                userID: userID,
                dependencyIDs: [],
                isConversation: false
            )
            dependencies.queueManager.addTask(task)
            SystemLogger.log(message: "Enqueued .fetchContactDetail with \(batch.count) IDs", category: .queue)
        }
    }

    /// Process contact emails this is like metadata update
    ///
    /// - Parameter contactEmails: contact email events
    fileprivate func processEvents(contactEmails: [[String: Any]]?) {
        guard let emails = contactEmails else {
            return
        }

            dependencies.contextProvider.performAndWaitOnRootSavingContext { [weak userManager] context in
                guard let userManager else {
                    return
                }
                
                for email in emails {
                    let emailObj = EmailEvent(event: email)
                    switch emailObj.action {
                    case .delete:
                        if let emailID = emailObj.ID {
                            if let tempEmail = Email.emailForID(emailID, inManagedObjectContext: context) {
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
                                    c.userID = userManager.userInfo.userId
                                    if let emails = c.emails.allObjects as? [Email] {
                                        emails.forEach { (e) in
                                            e.userID = userManager.userInfo.userId
                                        }
                                    }
                                }
                            }

                        } catch {
                            PMAssertionFailure(error)
                        }
                    default:
                        break
                    }
                }

                _ = context.saveUpstreamIfNeeded()
            }
    }

    /// Process Labels include Folders and Labels.
    ///
    /// - Parameter labels: labels events
    fileprivate func processEvents(labels: [[String: Any]]?) {
        assertProperExecution()

        struct IncrementalUpdateType {
            static let delete = 0
            static let insert = 1
            static let update = 2
        }

        if let labels = labels {
            dependencies.contextProvider.performAndWaitOnRootSavingContext { [weak userManager] context in
                guard let userManager else {
                    return
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
                                new_or_update_label["UserID"] = userManager.userID.rawValue
                                try GRTJSONSerialization.object(withEntityName: Label.Attributes.entityName, fromJSONDictionary: new_or_update_label, in: context)
                            }
                        } catch {
                            PMAssertionFailure(error)
                        }
                    default:
                        break
                    }
                }
                _ = context.saveUpstreamIfNeeded()
            }
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

    private func processEvents(addresses: [[String: Any]]?){
        assertProperExecution()

        guard
            let events = addresses,
            events.isEmpty == false
        else { return }
        for eventDict in events {
            let event = AddressEvent(event: eventDict)
            switch event.action {
            case .delete:
                if let addressID = event.ID {
                    self.userManager?.deleteFromEvents(addressIDRes: addressID)
                }
            case .create, .update:
                guard
                    let addressID = event.ID,
                    let addressInfo = event.address,
                    addressInfo.addresses.count == 1,
                    let parsedAddress = addressInfo.addresses.first,
                    parsedAddress.addressID == addressID,
                    let user = self.userManager
                else { continue }
                user.setFromEvents(addressRes: parsedAddress)
                Task {
                    do {
                        try await user.userService.activeUserKeys(userInfo: user.userInfo, auth: user.authCredential)
                    } catch {
                        PMAssertionFailure(error)
                    }
                }
            default:
                break
            }
            dependencies.notificationCenter.post(name: .addressesStatusAreChanged, object: nil)
        }
        dependencies.notificationCenter.post(name: .addressesStatusAreChanged, object: nil)
    }

    private func processEvents(incomingDefaults: [[String: Any]]?) {
        guard let incomingDefaults else {
            return
        }
                for item in incomingDefaults {
                    let incomingDefaultEvent = IncomingDefaultEvent(event: item)
                    switch incomingDefaultEvent.action {
                    case .create, .update:
                        guard let incomingDefault = incomingDefaultEvent.incomingDefault else {
                            assertionFailure()
                            continue
                        }
                        self.saveIncomingDefault(incomingDefault)
                    case .delete:
                        self.deleteIncomingDefaultByID(item)
                    default:
                        break
                    }
                }
    }

    private func saveIncomingDefault(_ incomingDefault: [String: Any]) {
        do {
            let incomingDefaultDTO = try IncomingDefaultDTO(
                dict: incomingDefault,
                keyDecodingStrategy: .decapitaliseFirstLetter,
                dateDecodingStrategy: .secondsSince1970
            )

            try dependencies.incomingDefaultService.save(dto: incomingDefaultDTO)
        } catch {
            PMAssertionFailure(error)
        }
    }

    private func deleteIncomingDefaultByID(_ incomingDefault: [String: Any]) {
        guard let incomingDefaultId = incomingDefault["ID"] as? String else {
            assertionFailure()
            return
        }
        do {
            try dependencies.incomingDefaultService.hardDelete(query: .id(incomingDefaultId), includeSoftDeleted: true)
        } catch {
            PMAssertionFailure(error)
        }
    }

    /// Process Message count from event logs
    ///
    /// - Parameter counts: message count dict
    func processEvents(messageCounts: [[String: Any]]?) {
        processEvents(counts: messageCounts, viewMode: .singleMessage)
    }

    func processEvents(conversationCounts: [[String: Any]]?) {
        processEvents(counts: conversationCounts, viewMode: .conversation)
    }

    private func processEvents(counts: [[String: Any]]?, viewMode: ViewMode) {
        guard let counts = counts, !counts.isEmpty, let userManager else {
            return
        }

        // parsing manually here to avoid modifying the rest of the class
        // once EventCheckResponse is made Decodable, we'll be able to remove this
        let parsedCounts: [CountData] = counts.compactMap {
            do {
                return try CountData.init(dict: $0)
            } catch {
                PMAssertionFailure(error)
                return nil
            }
        }

        do {
            try dependencies.lastUpdatedStore.batchUpdateUnreadCounts(
                counts: parsedCounts, userID: userManager.userID, type: viewMode
            )
        } catch {
            PMAssertionFailure(error)
        }

        guard let users = userManager.parentManager,
              let primaryUser = users.firstUser,
              primaryUser.userInfo.userId == userManager.userInfo.userId,
              primaryUser.conversationStateService.viewMode == viewMode else { return }

        let unreadCount: Int = dependencies.lastUpdatedStore.unreadCount(by: Message.Location.inbox.labelID, userID: userManager.userID, type: viewMode)
        UIApplication.setBadge(badge: max(0, unreadCount))
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

    private func assertProperExecution() {
        assert(!Thread.isMainThread)
#if DEBUG_ENTERPRISE
        dispatchPrecondition(condition: .onQueue(incrementalUpdateQueue))
#endif
    }

    private func isMessageBeingSent(messageID: MessageID) -> Bool {
        dependencies.queueManager.messageIDsOfTasks { action in
            switch action {
            case .send:
                return true
            default:
                return false
            }
        }.contains(where: { $0 == messageID.rawValue })
    }
}
