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
import ProtonCoreServices
import ProtonMailAnalytics

final class ConversationDataServiceProxy: ConversationProvider {
    let apiService: APIService
    let userID: UserID
    let contextProvider: CoreDataContextProviderProtocol
    private weak var queueManager: QueueManager?
    let conversationDataService: ConversationDataService
    private let localConversationUpdater: LocalConversationUpdater

    init(api: APIService,
         userID: UserID,
         contextProvider: CoreDataContextProviderProtocol,
         lastUpdatedStore: LastUpdatedStoreProtocol,
         messageDataService: MessageDataServiceProtocol,
         eventsService: EventsFetching,
         undoActionManager: UndoActionManagerProtocol,
         queueManager: QueueManager?,
         userDefaults: UserDefaults,
         localConversationUpdater: LocalConversationUpdater) {
        self.apiService = api
        self.userID = userID
        self.contextProvider = contextProvider
        self.queueManager = queueManager
        self.conversationDataService = ConversationDataService(api: apiService,
                                                               userID: userID,
                                                               contextProvider: contextProvider,
                                                               lastUpdatedStore: lastUpdatedStore,
                                                               messageDataService: messageDataService,
                                                               eventsService: eventsService,
                                                               undoActionManager: undoActionManager,
                                                               userDefaults: userDefaults)
        self.localConversationUpdater = localConversationUpdater
    }
}

private extension ConversationDataServiceProxy {
    // this is a workaround for the fact that just updating the ContextLabel won't trigger MailboxViewController's controllerDidChangeContent
    @available(
        *,
         deprecated,
         message: """
This method is sync and as such it relies on the deprecated `write`. Use `refreshContextLabelsAsync` instead.
"""
    )
    func refreshContextLabels(for conversationIDs: [ConversationID]) {
        do {
            try contextProvider.write { context in
                self.refreshContextLabels(for: conversationIDs, in: context)
            }
        } catch {
            PMAssertionFailure(error)
        }
    }

    // this is a workaround for the fact that just updating the ContextLabel won't trigger MailboxViewController's controllerDidChangeContent
    func refreshContextLabelsAsync(for conversationIDs: [ConversationID]) async {
        do {
            try await contextProvider.writeAsync { context in
                self.refreshContextLabels(for: conversationIDs, in: context)
            }
        } catch {
            PMAssertionFailure(error)
        }
    }

    private func refreshContextLabels(for conversationIDs: [ConversationID], in context: NSManagedObjectContext) {
                let conversations = fetchLocalConversations(
                    withIDs: NSMutableSet(array: conversationIDs.map(\.rawValue)),
                    in: context
                )

                conversations.forEach { conversation in
                    (conversation.labels as? Set<ContextLabel>)?
                        .forEach { label in
                            label.willChangeValue(forKey: ContextLabel.Attributes.unreadCount)
                            label.didChangeValue(forKey: ContextLabel.Attributes.unreadCount)
                            context.refresh(label, mergeChanges: true)
                        }
                    context.refresh(conversation, mergeChanges: true)
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
                           completion: @escaping ((Result<Conversation, Error>) -> Void)) {
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
        localConversationUpdater.delete(conversationIDs: conversationIDs) { [weak self] result in
            guard let self = self else { return }
            self.refreshContextLabels(for: conversationIDs)
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
                                      asUnread: false,
                                      labelID: labelID) { [weak self] result in
            guard let self = self else { return }
            self.refreshContextLabels(for: conversationIDs)
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
                                      asUnread: true,
                                      labelID: labelID) { [weak self] result in
            guard let self = self else { return }
            self.refreshContextLabels(for: conversationIDs)
            completion?(result)
        }
    }

    func label(conversationIDs: [ConversationID],
               as labelID: LabelID,
               completion: (@Sendable (Result<Void, Error>) -> Void)?) {
        editLabels(
            conversationIDs: conversationIDs,
            actionToQueue: .label(
                currentLabelID: labelID.rawValue,
                shouldFetch: nil,
                itemIDs: conversationIDs.map(\.rawValue),
                objectIDs: []
            ),
            labelToRemove: nil,
            labelToAdd: labelID,
            isFolder: false,
            completion: completion
        )
    }

    func unlabel(conversationIDs: [ConversationID],
                 as labelID: LabelID,
                 completion: (@Sendable (Result<Void, Error>) -> Void)?) {
        editLabels(
            conversationIDs: conversationIDs,
            actionToQueue: .unlabel(
                currentLabelID: labelID.rawValue,
                shouldFetch: nil,
                itemIDs: conversationIDs.map(\.rawValue),
                objectIDs: []
            ),
            labelToRemove: labelID,
            labelToAdd: nil,
            isFolder: false,
            completion: completion
        )
    }

    func snooze(conversationIDs: [ConversationID], on date: Date, completion: (() -> Void)? = nil) {
        editLabels(
            conversationIDs: conversationIDs,
            actionToQueue: .snooze(conversationIDs: conversationIDs.map(\.rawValue), date: date),
            labelToRemove: Message.Location.inbox.labelID,
            labelToAdd: Message.Location.snooze.labelID,
            isFolder: true
        ) { [weak self] _ in
            self?.setSnoozeTime(to: date, conversationIDs: conversationIDs)
            completion?()
        }
    }

    func unSnooze(conversationID: ConversationID) {
        editLabels(
            conversationIDs: [conversationID],
            actionToQueue: .unsnooze(conversationID: conversationID.rawValue),
            labelToRemove: Message.Location.snooze.labelID,
            labelToAdd: Message.Location.inbox.labelID,
            isFolder: true
        ) { [weak self] _ in
            self?.setSnoozeTime(to: nil, conversationIDs: [conversationID])
        }
    }

    private func editLabels(
        conversationIDs: [ConversationID],
        actionToQueue: MessageAction,
        labelToRemove: LabelID?,
        labelToAdd: LabelID?,
        isFolder: Bool,
        completion: (@Sendable (Result<Void, Error>) -> Void)?
    ) {
        guard !conversationIDs.isEmpty else {
            completion?(.failure(ConversationError.emptyConversationIDS))
            return
        }
        self.queue(actionToQueue, isConversation: true)

        Task.detached {
            let result: Swift.Result<Void, Error>
            do {
                try await self.localConversationUpdater.editLabels(
                    conversationIDs: conversationIDs,
                    labelToRemove: labelToRemove,
                    labelToAdd: labelToAdd,
                    isFolder: isFolder
                )

                await self.refreshContextLabelsAsync(for: conversationIDs)

                result = .success(())
            } catch {
                result = .failure(error)
            }

            if let completion {
                DispatchQueue.main.async {
                    completion(result)
                }
            }
        }
    }

    func move(conversationIDs: [ConversationID],
              from previousFolderLabel: LabelID,
              to nextFolderLabel: LabelID,
              callOrigin: String?,
              completion: (@Sendable (Result<Void, Error>) -> Void)?) {
        guard !conversationIDs.isEmpty else {
            completion?(.failure(ConversationError.emptyConversationIDS))
            return
        }
        if previousFolderLabel == nextFolderLabel {
            completion?(.success(()))
            return
        }

        let uniqueConversationIDs = Array(Set(conversationIDs))
        let filteredConversationIDs = uniqueConversationIDs.filter { !$0.rawValue.isEmpty }
        guard !filteredConversationIDs.isEmpty else {
            reportEmptyConversationID(callOrigin: callOrigin)
            completion?(.failure(ConversationError.emptyConversationIDS))
            return
        }

        editLabels(
            conversationIDs: filteredConversationIDs,
            actionToQueue: .folder(
                nextLabelID: nextFolderLabel.rawValue,
                shouldFetch: true,
                itemIDs: filteredConversationIDs.map(\.rawValue),
                objectIDs: []
            ),
            labelToRemove: previousFolderLabel,
            labelToAdd: nextFolderLabel,
            isFolder: true,
            completion: completion
        )
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
        self.queueManager?.addTask(task)
    }

    private func reportEmptyConversationID(callOrigin: String?) {
        Breadcrumbs.shared.add(message: "call from \(callOrigin ?? "-")", to: .malformedConversationLabelRequest)
        Analytics.shared.sendError(
            .abortedConversationRequest,
            trace: Breadcrumbs.shared.trace(for: .malformedConversationLabelRequest)
        )
    }

    /// - Parameters:
    ///   - date: new snooze date, nil means unsnooze
    private func setSnoozeTime(to date: Date?, conversationIDs: [ConversationID]) {
        try? contextProvider.write { context in
            for conversationID in conversationIDs {
                guard let conversation = Conversation.conversationForConversationID(
                    conversationID.rawValue,
                    inManagedObjectContext: context
                ) else { return }
                let messages = Message.messagesForConversationID(
                    conversationID.rawValue,
                    inManagedObjectContext: context
                )
                conversation.labels
                    .compactMap { $0 as? ContextLabel }
                    .forEach { label in
                        label.snoozeTime = date ?? label.time
                    }
                messages?.forEach({ message in
                    message.snoozeTime = date ?? message.time
                })
            }
        }
    }
}
