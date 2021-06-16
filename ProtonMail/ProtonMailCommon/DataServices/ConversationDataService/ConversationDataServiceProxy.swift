//
//  ConversationDataService+Actions.swift
//  ProtonMail
//
//
//  Copyright (c) 2020 Proton Technologies AG
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

import CoreData
import Foundation
import ProtonCore_Services

final class ConversationDataServiceProxy: ConversationProvider {
    let apiService: APIService
    let userID: String
    let coreDataService: CoreDataService
    let labelDataService: LabelsDataService
    let lastUpdatedStore: LastUpdatedStoreProtocol
    private(set) weak var eventsService: EventsFetching?
    private weak var viewModeDataSource: ViewModeDataSource?
    private weak var queueManager: QueueManager?
    let conversationDataService: ConversationDataService

    init(api: APIService,
         userID: String,
         coreDataService: CoreDataService,
         labelDataService: LabelsDataService,
         lastUpdatedStore: LastUpdatedStoreProtocol,
         eventsService: EventsFetching,
         viewModeDataSource: ViewModeDataSource?,
         queueManager: QueueManager?) {
        self.apiService = api
        self.userID = userID
        self.coreDataService = coreDataService
        self.labelDataService = labelDataService
        self.lastUpdatedStore = lastUpdatedStore
        self.eventsService = eventsService
        self.viewModeDataSource = viewModeDataSource
        self.queueManager = queueManager
        self.conversationDataService = ConversationDataService(api: apiService,
                                                               userID: userID,
                                                               coreDataService: coreDataService,
                                                               labelDataService: labelDataService,
                                                               lastUpdatedStore: lastUpdatedStore,
                                                               eventsService: eventsService,
                                                               viewModeDataSource: viewModeDataSource,
                                                               queueManager: queueManager)
    }
}

extension ConversationDataServiceProxy {
    func fetchConversationCounts(addressID: String?, completion: ((Result<Void, Error>) -> Void)?) {
        conversationDataService.fetchConversationCounts(addressID: addressID, completion: completion)
    }
    
    func fetchConversations(for labelID: String, before timestamp: Int, unreadOnly: Bool, shouldReset: Bool, completion: ((Result<Void, Error>) -> Void)?) {
        conversationDataService.fetchConversations(for: labelID, before: timestamp, unreadOnly: unreadOnly, shouldReset: shouldReset, completion: completion)
    }
    
    func fetchConversations(with conversationIDs: [String], completion: ((Result<Void, Error>) -> Void)?) {
        guard !conversationIDs.isEmpty else {
            completion?(.failure(ConversationError.emptyConversationIDS))
            return
        }
        conversationDataService.fetchConversations(with: conversationIDs, completion: completion)
    }
    
    func fetchConversation(with conversationID: String, includeBodyOf messageID: String?, completion: ((Result<Void, Error>) -> Void)?) {
        conversationDataService.fetchConversation(with: conversationID, includeBodyOf: messageID, completion: completion)
    }
    
    func deleteConversations(with conversationIDs: [String], labelID: String, completion: ((Result<Void, Error>) -> Void)?) {
        guard !conversationIDs.isEmpty else {
            completion?(.failure(ConversationError.emptyConversationIDS))
            return
        }
        conversationDataService.deleteConversations(with: conversationIDs, labelID: labelID, completion: completion)
    }
    
    func markAsRead(conversationIDs: [String], completion: ((Result<Void, Error>) -> Void)?) {
        guard !conversationIDs.isEmpty else {
            completion?(.failure(ConversationError.emptyConversationIDS))
            return
        }
        let conversations = fetchLocalConversations(withIDs: NSMutableSet(array: conversationIDs), in: coreDataService.mainContext)
        let managedObjectIds = conversations.map{ $0.objectID.uriRepresentation().absoluteString }
        self.queue(.read, isConversation: true, data1: "", data2: "", otherData: managedObjectIds)
        mark(conversations: conversations, in: coreDataService.operationContext, as: false, labelID: nil)
    }
    
    func markAsUnread(conversationIDs: [String], labelID: String, completion: ((Result<Void, Error>) -> Void)?) {
        guard !conversationIDs.isEmpty else {
            completion?(.failure(ConversationError.emptyConversationIDS))
            return
        }
        let conversations = fetchLocalConversations(withIDs: NSMutableSet(array: conversationIDs), in: coreDataService.mainContext)
        let managedObjectIds = conversations.map{ $0.objectID.uriRepresentation().absoluteString }
        self.queue(.unread, isConversation: true, data1: labelID, data2: "", otherData: managedObjectIds)
        mark(conversations: conversations, in: coreDataService.operationContext, as: true, labelID: labelID)
    }
    
    func label(conversationIDs: [String], as labelID: String, completion: ((Result<Void, Error>) -> Void)?) {
        guard !conversationIDs.isEmpty else {
            completion?(.failure(ConversationError.emptyConversationIDS))
            return
        }
        let managedObjectIds = fetchLocalConversations(withIDs: NSMutableSet(array: conversationIDs), in: coreDataService.mainContext).map{ $0.objectID.uriRepresentation().absoluteString }
        self.queue(.label, isConversation: true, data1: labelID, data2: "", otherData: managedObjectIds)
    }
    
    func unlabel(conversationIDs: [String], as labelID: String, completion: ((Result<Void, Error>) -> Void)?) {
        guard !conversationIDs.isEmpty else {
            completion?(.failure(ConversationError.emptyConversationIDS))
            return
        }
        let managedObjectIds = fetchLocalConversations(withIDs: NSMutableSet(array: conversationIDs), in: coreDataService.mainContext).map{ $0.objectID.uriRepresentation().absoluteString }
        self.queue(.unlabel, isConversation: true, data1: labelID, data2: "", otherData: managedObjectIds)
    }
    
    func move(conversationIDs: [String], from previousFolderLabel: String, to nextFolderLabel: String, completion: ((Result<Void, Error>) -> Void)?) {
        guard !conversationIDs.isEmpty else {
            completion?(.failure(ConversationError.emptyConversationIDS))
            return
        }
        let managedObjectIds = fetchLocalConversations(withIDs: NSMutableSet(array: conversationIDs), in: coreDataService.mainContext).map{ $0.objectID.uriRepresentation().absoluteString }
        self.queue(.folder, isConversation: true, data1: previousFolderLabel, data2: nextFolderLabel, otherData: managedObjectIds)
    }
    
    func cleanAll() {
        conversationDataService.cleanAll()
    }
    
    func fetchLocalConversations(withIDs selected: NSMutableSet, in context: NSManagedObjectContext) -> [Conversation] {
        conversationDataService.fetchLocalConversations(withIDs: selected, in: context)
    }
}

extension ConversationDataServiceProxy {
    private func queue(_ action: MessageAction, isConversation: Bool, data1: String = "", data2: String = "", otherData: Any? = nil) {
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

    private func mark(conversations: [Conversation], in context: NSManagedObjectContext, as unread: Bool, labelID: String?) {
        let labelID = labelID ?? ""
        context.performAndWait {
            for conversation in conversations {
                guard let conversation = Conversation.conversationForConversationID(conversation.conversationID, inManagedObjectContext: context) else {
                    continue
                }
                conversation.applyMarksAsChanges(unRead: unread, labelID: labelID)
                
                //Read action
                guard !unread else { continue }
                let msgs = Message.messagesForConversationID(conversation.conversationID, inManagedObjectContext: context)
                msgs?.forEach({ (msg) in
                    guard msg.getLabelIDs().contains(labelID) else {
                        return
                    }
                    msg.unRead = unread
                })
            }
            
            let error = context.saveUpstreamIfNeeded()
            if let error = error {
                PMLog.D(" error: \(error)")
            }
        }
    }
}
