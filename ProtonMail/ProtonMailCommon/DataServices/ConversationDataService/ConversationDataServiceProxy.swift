//
//  ConversationDataServiceProxy.swift
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

import CoreData
import Foundation
import ProtonCore_Services

final class ConversationDataServiceProxy: ConversationProvider {
    let apiService: APIService
    let userID: UserID
    let contextProvider: CoreDataContextProviderProtocol
    private weak var queueManager: QueueManager?
    let conversationDataService: ConversationDataService
    private lazy var localConversationUpdater = LocalConversationUpdater(userID: userID.rawValue)

    init(api: APIService,
         userID: UserID,
         contextProvider: CoreDataContextProviderProtocol,
         lastUpdatedStore: LastUpdatedStoreProtocol,
         eventsService: EventsFetching,
         undoActionManager: UndoActionManagerProtocol,
         queueManager: QueueManager?) {
        self.apiService = api
        self.userID = userID
        self.contextProvider = contextProvider
        self.queueManager = queueManager
        self.conversationDataService = ConversationDataService(api: apiService,
                                                               userID: userID,
                                                               contextProvider: contextProvider,
                                                               lastUpdatedStore: lastUpdatedStore,
                                                               eventsService: eventsService,
                                                               undoActionManager: undoActionManager)
    }
}

private extension ConversationDataServiceProxy {
    func updateContextLabels(for conversationIDs: [ConversationID], on context: NSManagedObjectContext) {
        let conversations = fetchLocalConversations(withIDs: NSMutableSet(array: conversationIDs.map(\.rawValue)),
                                                    in: context)
        conversations.forEach { conversation in
            (conversation.labels as? Set<ContextLabel>)?
                .forEach {
                    context.refresh(conversation, mergeChanges: true)
                    context.refresh($0, mergeChanges: true)
                }
        }
    }
}

extension ConversationDataServiceProxy {
    func fetchConversationCounts(addressID: String?, completion: ((Result<Void, Error>) -> Void)?) {
        conversationDataService.fetchConversationCounts(addressID: addressID, completion: completion)
    }

    func fetchConversations(for labelID: LabelID,
                            before timestamp: Int,
                            unreadOnly: Bool,
                            shouldReset: Bool,
                            completion: ((Result<Void, Error>) -> Void)?) {
        conversationDataService.fetchConversations(for: labelID,
                                                   before: timestamp,
                                                   unreadOnly: unreadOnly,
                                                   shouldReset: shouldReset,
                                                   completion: completion)
    }

    func fetchConversations(with conversationIDs: [ConversationID], completion: ((Result<Void, Error>) -> Void)?) {
        guard !conversationIDs.isEmpty else {
            completion?(.failure(ConversationError.emptyConversationIDS))
            return
        }
        conversationDataService.fetchConversations(with: conversationIDs, completion: completion)
    }

    func fetchConversation(with conversationID: ConversationID,
                           includeBodyOf messageID: MessageID?,
                           callOrigin: String?,
                           completion: ((Result<Conversation, Error>) -> Void)?) {
        conversationDataService.fetchConversation(with: conversationID,
                                                  includeBodyOf: messageID,
                                                  callOrigin: callOrigin,
                                                  completion: completion)
    }

    func deleteConversations(with conversationIDs: [ConversationID],
                             labelID: LabelID,
                             completion: ((Result<Void, Error>) -> Void)?) {
        guard !conversationIDs.isEmpty else {
            completion?(.failure(ConversationError.emptyConversationIDS))
            return
        }
        self.queue(.delete(currentLabelID: labelID.rawValue, itemIDs: conversationIDs.map(\.rawValue)),
                   isConversation: true)
        localConversationUpdater.delete(conversationIDs: conversationIDs,
                                        in: contextProvider.rootSavingContext) { [weak self] result in
            guard let self = self else { return }
            self.updateContextLabels(for: conversationIDs, on: self.contextProvider.mainContext)
            completion?(result)
        }
    }

    func markAsRead(conversationIDs: [ConversationID], labelID: LabelID, completion: ((Result<Void, Error>) -> Void)?) {
        guard !conversationIDs.isEmpty else {
            completion?(.failure(ConversationError.emptyConversationIDS))
            return
        }
        self.queue(.read(itemIDs: conversationIDs.map(\.rawValue), objectIDs: []), isConversation: true)
        localConversationUpdater.mark(conversationIDs: conversationIDs,
                                      in: contextProvider.rootSavingContext,
                                      asUnread: false,
                                      labelID: labelID) { [weak self] result in
            guard let self = self else { return }
            self.updateContextLabels(for: conversationIDs, on: self.contextProvider.mainContext)
            completion?(result)
        }
    }

    func markAsUnread(conversationIDs: [ConversationID],
                      labelID: LabelID,
                      completion: ((Result<Void, Error>) -> Void)?) {
        guard !conversationIDs.isEmpty else {
            completion?(.failure(ConversationError.emptyConversationIDS))
            return
        }
        self.queue(.unread(currentLabelID: labelID.rawValue, itemIDs: conversationIDs.map(\.rawValue), objectIDs: []),
                   isConversation: true)
        localConversationUpdater.mark(conversationIDs: conversationIDs,
                                      in: contextProvider.rootSavingContext,
                                      asUnread: true,
                                      labelID: labelID) { [weak self] result in
            guard let self = self else { return }
            self.updateContextLabels(for: conversationIDs, on: self.contextProvider.mainContext)
            completion?(result)
        }
    }

    func label(conversationIDs: [ConversationID],
               as labelID: LabelID,
               isSwipeAction: Bool,
               completion: ((Result<Void, Error>) -> Void)?) {
        guard !conversationIDs.isEmpty else {
            completion?(.failure(ConversationError.emptyConversationIDS))
            return
        }
        self.queue(.label(currentLabelID: labelID.rawValue,
                          shouldFetch: nil,
                          isSwipeAction: isSwipeAction,
                          itemIDs: conversationIDs.map(\.rawValue),
                          objectIDs: []),
                   isConversation: true)
        localConversationUpdater.editLabels(conversationIDs: conversationIDs,
                                            in: contextProvider.rootSavingContext,
                                            labelToRemove: nil,
                                            labelToAdd: labelID,
                                            isFolder: false) { [weak self] result in
            guard let self = self else { return }
            self.updateContextLabels(for: conversationIDs, on: self.contextProvider.mainContext)
            completion?(result)
        }
    }

    func unlabel(conversationIDs: [ConversationID],
                 as labelID: LabelID,
                 isSwipeAction: Bool,
                 completion: ((Result<Void, Error>) -> Void)?) {
        guard !conversationIDs.isEmpty else {
            completion?(.failure(ConversationError.emptyConversationIDS))
            return
        }
        self.queue(.unlabel(currentLabelID: labelID.rawValue,
                            shouldFetch: nil,
                            isSwipeAction: isSwipeAction,
                            itemIDs: conversationIDs.map(\.rawValue),
                            objectIDs: []),
                   isConversation: true)
        localConversationUpdater.editLabels(conversationIDs: conversationIDs,
                                            in: contextProvider.rootSavingContext,
                                            labelToRemove: labelID,
                                            labelToAdd: nil,
                                            isFolder: false) { [weak self] result in
            guard let self = self else { return }
            self.updateContextLabels(for: conversationIDs, on: self.contextProvider.mainContext)
            completion?(result)
        }
    }

    func move(conversationIDs: [ConversationID],
              from previousFolderLabel: LabelID,
              to nextFolderLabel: LabelID,
              isSwipeAction: Bool,
              completion: ((Result<Void, Error>) -> Void)?) {
        guard !conversationIDs.isEmpty else {
            completion?(.failure(ConversationError.emptyConversationIDS))
            return
        }
        self.queue(.folder(nextLabelID: nextFolderLabel.rawValue,
                           shouldFetch: true,
                           isSwipeAction: isSwipeAction,
                           itemIDs: conversationIDs.map(\.rawValue),
                           objectIDs: []),
                   isConversation: true)
        localConversationUpdater.editLabels(conversationIDs: conversationIDs,
                                            in: contextProvider.rootSavingContext,
                                            labelToRemove: previousFolderLabel,
                                            labelToAdd: nextFolderLabel,
                                            isFolder: true) { [weak self] result in
            guard let self = self else { return }
            self.updateContextLabels(for: conversationIDs, on: self.contextProvider.mainContext)
            completion?(result)
        }
    }

    func cleanAll() {
        conversationDataService.cleanAll()
    }

    func fetchLocalConversations(withIDs selected: NSMutableSet, in context: NSManagedObjectContext) -> [Conversation] {
        conversationDataService.fetchLocalConversations(withIDs: selected, in: context)
    }

    func findConversationIDsToApplyLabels(conversations: [ConversationEntity], labelID: LabelID) -> [ConversationID] {
        conversationDataService.findConversationIDsToApplyLabels(conversations: conversations, labelID: labelID)
    }

    func findConversationIDSToRemoveLabels(conversations: [ConversationEntity],
                                           labelID: LabelID) -> [ConversationID] {
        conversationDataService.findConversationIDSToRemoveLabels(conversations: conversations, labelID: labelID)
    }
}

extension ConversationDataServiceProxy {
    private func queue(_ action: MessageAction, isConversation: Bool) {
        let task = QueueManager.Task(messageID: "",
                                     action: action,
                                     userID: self.userID,
                                     dependencyIDs: [],
                                     isConversation: isConversation)
        _ = self.queueManager?.addTask(task)
    }
}
