// Copyright (c) 2022 Proton AG
//
// This file is part of Proton Mail.
//
// Proton Mail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Mail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Mail. If not, see https://www.gnu.org/licenses/.

import Foundation
import PromiseKit

protocol FetchMessagesWithResetUseCase: UseCase {
    func execute(
        endTime: Int,
        isUnread: Bool,
        cleanContact: Bool,
        removeAllDraft: Bool,
        hasToBeQueued: Bool,
        callback: UseCaseResult<Void>?
    )
}

final class FetchMessagesWithReset: FetchMessagesWithResetUseCase {
    private let params: Parameters
    private let dependencies: Dependencies

    init(params: Parameters, dependencies: Dependencies) {
        self.params = params
        self.dependencies = dependencies
    }

    func execute(
        endTime: Int,
        isUnread: Bool,
        cleanContact: Bool,
        removeAllDraft: Bool,
        hasToBeQueued: Bool,
        callback: UseCaseResult<Void>?
    ) {
        SystemLogger.logTemporarily(message: "FetchMessagesWithReset execute...", category: .serviceRefactor)
        if hasToBeQueued {
            dependencies.queueManager.addBlock { [weak self] in
                self?.fetchMessagesIfNeeded(
                    endTime: endTime,
                    isUnread: isUnread,
                    cleanContact: cleanContact,
                    removeAllDraft: removeAllDraft,
                    callback: callback
                )
            }
        } else {
            fetchMessagesIfNeeded(
                endTime: endTime,
                isUnread: isUnread,
                cleanContact: cleanContact,
                removeAllDraft: removeAllDraft,
                callback: callback
            )
        }
    }
}

extension FetchMessagesWithReset {

    private func fetchMessagesIfNeeded(
        endTime: Int,
        isUnread: Bool,
        cleanContact: Bool,
        removeAllDraft: Bool,
        callback: UseCaseResult<Void>?
    ) {
        dependencies.fetchLatestEventId.execute { result in
            let newEvent: Bool = (try? !result.get().eventID.isEmpty) ?? false
            guard newEvent else {
                self.runOnMainThread { callback?(.success(Void())) }
                return
            }
            self.dependencies.fetchMessages.execute(
                endTime: endTime,
                isUnread: isUnread,
                hasToBeQueued: false,
                callback: { result in
                    if let error = result.error {
                        self.runOnMainThread { callback?(.failure(error)) }
                    } else {
                        self.runOnMainThread { callback?(.success(Void())) }
                    }
                },
                onMessagesRequestSuccess: {
                    self.removePersistedMessages(cleanContact: cleanContact, removeAllDraft: removeAllDraft)
                })
        }
    }

    private func removePersistedMessages(cleanContact: Bool, removeAllDraft: Bool) {
        let userId = params.userId
        dependencies.localMessageDataService.cleanMessage(
            removeAllDraft: removeAllDraft,
            cleanBadgeAndNotifications: false
        ).then { _ -> Promise<Void> in
            self.dependencies.lastUpdatedStore.removeUpdateTimeExceptUnread(by: userId, type: .singleMessage)
            self.dependencies.lastUpdatedStore.removeUpdateTimeExceptUnread(by: userId, type: .conversation)
            if cleanContact {
                return self.dependencies.contactProvider.cleanUp()
            } else {
                return Promise<Void>()
            }
        }.ensure {
            if cleanContact {
                self.dependencies.contactProvider.fetchContacts(fromUI: false, completion: nil)
            }
            self.dependencies.labelProvider.fetchV4Labels().cauterize()
        }.cauterize()
    }
}

// MARK: Input structs

extension FetchMessagesWithReset {

    struct Parameters {
        /// Identifier to persist the last event locally for a specific user.
        let userId: String
    }

    struct Dependencies {
        let fetchLatestEventId: FetchLatestEventIdUseCase
        let fetchMessages: FetchMessagesUseCase
        let localMessageDataService: LocalMessageDataServiceProtocol
        let lastUpdatedStore: LastUpdatedStoreProtocol
        let contactProvider: ContactProviderProtocol
        let labelProvider: LabelProviderProtocol
        let queueManager: QueueManagerProtocol

        init(
            fetchLatestEventId: FetchLatestEventIdUseCase,
            fetchMessages: FetchMessagesUseCase,
            localMessageDataService: LocalMessageDataServiceProtocol,
            lastUpdatedStore: LastUpdatedStoreProtocol = sharedServices.get(by: LastUpdatedStore.self),
            contactProvider: ContactProviderProtocol,
            labelProvider: LabelProviderProtocol,
            queueManager: QueueManagerProtocol = sharedServices.get(by: QueueManager.self)
        ) {
            self.fetchLatestEventId = fetchLatestEventId
            self.fetchMessages = fetchMessages
            self.localMessageDataService = localMessageDataService
            self.lastUpdatedStore = lastUpdatedStore
            self.contactProvider = contactProvider
            self.labelProvider = labelProvider
            self.queueManager = queueManager
        }
    }
}
