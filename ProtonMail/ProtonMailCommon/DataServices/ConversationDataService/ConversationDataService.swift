//
//  ConversationDataService.swift
//  ProtonMail
//
//
//  Copyright (c) 2021 Proton Technologies AG
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

enum ReadState {
    case unread
    case read
}

enum ConversationError: Error {
    case emptyConversationIDS
}

protocol ConversationProvider: AnyObject {
    // MARK: - Collection fetching
    func fetchConversationCounts(addressID: String?, completion: ((Result<Void, Error>) -> Void)?)
    func fetchConversations(for labelID: String,
                            before timestamp: Int,
                            unreadOnly: Bool,
                            shouldReset: Bool,
                            completion: ((Result<Void, Error>) -> Void)?)
    func fetchConversations(with conversationIDs: [String], completion: ((Result<Void, Error>) -> Void)?)
    // MARK: - Single item fetching
    func fetchConversation(with conversationID: String, includeBodyOf messageID: String?, completion: ((Result<Void, Error>) -> Void)?)
    // MARK: - Operations
    func deleteConversations(with conversationIDs: [String], labelID: String, completion: ((Result<Void, Error>) -> Void)?)
    func markAsRead(conversationIDs: [String], completion: ((Result<Void, Error>) -> Void)?)
    func markAsUnread(conversationIDs: [String], labelID: String, completion: ((Result<Void, Error>) -> Void)?)
    func label(conversationIDs: [String], as labelID: String, completion: ((Result<Void, Error>) -> Void)?)
    func unlabel(conversationIDs: [String], as labelID: String, completion: ((Result<Void, Error>) -> Void)?)
    func move(conversationIDs: [String],
              from previousFolderLabel: String,
              to nextFolderLabel: String,
              completion: ((Result<Void, Error>) -> Void)?)
    // MARK: - Clean up
    func cleanAll()
    // MARK: - Local for legacy reasons
    func fetchLocalConversations(withIDs selected: NSMutableSet, in context: NSManagedObjectContext) -> [Conversation]
}

final class ConversationDataService: Service, ConversationProvider {
    let apiService: APIService
    let userID: String
    let coreDataService: CoreDataService
    let labelDataService: LabelsDataService
    let lastUpdatedStore: LastUpdatedStoreProtocol
    private(set) weak var eventsService: EventsFetching?
    private weak var viewModeDataSource: ViewModeDataSource?
    private weak var queueManager: QueueManager?

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
    }
}

// MARK: - Clean up
extension ConversationDataService {
    func cleanAll() {
        let context = coreDataService.rootSavingContext
        context.performAndWait {
            let conversationFetch = NSFetchRequest<NSFetchRequestResult>(entityName: Conversation.Attributes.entityName)
            conversationFetch.predicate = NSPredicate(format: "%K == %@", Conversation.Attributes.userID, self.userID)
            if let conversations = try? context.fetch(conversationFetch) as? [NSManagedObject] {
                conversations.forEach{ context.delete($0) }
            }

            let contextLabelFetch = NSFetchRequest<NSFetchRequestResult>(entityName: ContextLabel.Attributes.entityName)
            contextLabelFetch.predicate = NSPredicate(format: "%K == %@", ContextLabel.Attributes.userID, self.userID)
            if let contextlabels = try? context.fetch(contextLabelFetch) as? [NSManagedObject] {
                contextlabels.forEach{ context.delete($0) }
            }

            if let error = context.saveUpstreamIfNeeded() {
                PMLog.D("error: \(error)")
            }
        }
    }
}

extension ConversationDataService {
    func fetchLocalConversations(withIDs selected: NSMutableSet, in context: NSManagedObjectContext) -> [Conversation] {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: Conversation.Attributes.entityName)
        fetchRequest.predicate = NSPredicate(format: "%K in %@", Conversation.Attributes.conversationID, selected)
        do {
            if let conversations = try context.fetch(fetchRequest) as? [Conversation] {
                return conversations
            }
        } catch let ex as NSError {
            PMLog.D("fetch error: \(ex)")
        }
        return []
    }
}
