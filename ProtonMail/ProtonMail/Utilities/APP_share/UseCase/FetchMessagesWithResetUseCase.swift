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

typealias FetchMessagesWithResetUseCase = NewUseCase<Void, FetchMessagesWithReset.Params>

final class FetchMessagesWithReset: FetchMessagesWithResetUseCase {
    private let userID: UserID
    private let dependencies: Dependencies

    init(userID: UserID, dependencies: Dependencies) {
        self.userID = userID
        self.dependencies = dependencies
    }

    override func executionBlock(params: FetchMessagesWithReset.Params, callback: @escaping Callback) {
        fetchMessagesIfNeeded(params: params, callback: callback)
    }
}

extension FetchMessagesWithReset {

    private func fetchMessagesIfNeeded(params: Params, callback: @escaping Callback) {
        dependencies.fetchLatestEventId.execute(params: ()) { result in
            let newEvent: Bool = (try? !result.get().eventID.isEmpty) ?? false
            guard newEvent else {
                callback(.success(Void()))
                return
            }
            self.dependencies.labelProvider.fetchV4Labels { _ in
                self.dependencies.fetchMessages.execute(
                    endTime: params.endTime,
                    isUnread: params.fetchOnlyUnreadMessages,
                    callback: { result in
                        if let error = result.error {
                            callback(.failure(error))
                        } else {
                            callback(.success(Void()))
                        }
                    },
                    onMessagesRequestSuccess: {
                        self.removePersistedMessages(
                            cleanContact: params.refetchContacts,
                            removeAllDraft: params.removeAllDrafts
                        )
                    })
            }
        }
    }

    private func removePersistedMessages(cleanContact: Bool, removeAllDraft: Bool) {
        dependencies.localMessageDataService.cleanMessage(
            removeAllDraft: removeAllDraft,
            cleanBadgeAndNotifications: false
        ).then { _ -> Promise<Void> in
            self.dependencies.lastUpdatedStore.removeUpdateTimeExceptUnread(by: self.userID, type: .singleMessage)
            self.dependencies.lastUpdatedStore.removeUpdateTimeExceptUnread(by: self.userID, type: .conversation)
            if cleanContact {
                return self.dependencies.contactProvider.cleanUp()
            } else {
                return Promise<Void>()
            }
        }.ensure {
            if cleanContact {
                self.dependencies.contactProvider.fetchContacts(completion: nil)
            }
        }.cauterize()
    }
}

// MARK: Input structs

extension FetchMessagesWithReset {

    struct Params {
        let endTime: Int
        let fetchOnlyUnreadMessages: Bool
        let refetchContacts: Bool
        let removeAllDrafts: Bool
    }

    struct Dependencies {
        let fetchLatestEventId: FetchLatestEventIdUseCase
        let fetchMessages: FetchMessagesUseCase
        let localMessageDataService: LocalMessageDataServiceProtocol
        let lastUpdatedStore: LastUpdatedStoreProtocol
        let contactProvider: ContactProviderProtocol
        let labelProvider: LabelProviderProtocol

        init(
            fetchLatestEventId: FetchLatestEventIdUseCase,
            fetchMessages: FetchMessagesUseCase,
            localMessageDataService: LocalMessageDataServiceProtocol,
            lastUpdatedStore: LastUpdatedStoreProtocol = sharedServices.get(by: LastUpdatedStore.self),
            contactProvider: ContactProviderProtocol,
            labelProvider: LabelProviderProtocol
        ) {
            self.fetchLatestEventId = fetchLatestEventId
            self.fetchMessages = fetchMessages
            self.localMessageDataService = localMessageDataService
            self.lastUpdatedStore = lastUpdatedStore
            self.contactProvider = contactProvider
            self.labelProvider = labelProvider
        }
    }
}
