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

typealias FetchMessagesWithResetUseCase = UseCase<Void, FetchMessagesWithReset.Params>

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
                _ = self.cleanContactIfNeeded(cleanContact: params.refetchContacts).done { _ in
                    self.dependencies.fetchMessages
                        .execute(
                            params: .init(
                                labelID: params.labelID,
                                endTime: 0,
                                isUnread: params.fetchOnlyUnreadMessages,
                                onMessagesRequestSuccess: {
                                    self.removePersistedMessages()
                                }
                            )
                        ) { result in
                            callback(result)
                        }
                }
            }
        }
    }

    private func removePersistedMessages() {
        dependencies.localMessageDataService.cleanMessage(
            removeAllDraft: false,
            cleanBadgeAndNotifications: false
        )
            self.dependencies.lastUpdatedStore.removeUpdateTimeExceptUnread(by: self.userID)
    }

    private func cleanContactIfNeeded(cleanContact: Bool) -> Promise<Void> {
        guard cleanContact else { return Promise() }
        return Promise { seal in
            self.dependencies.contactProvider.cleanUp()
                self.dependencies.contactProvider.fetchContacts { _ in
                    seal.fulfill_()
                }
        }
    }
}

// MARK: Input structs

extension FetchMessagesWithReset {

    struct Params {
        let labelID: LabelID
        let fetchOnlyUnreadMessages: Bool
        let refetchContacts: Bool
    }

    struct Dependencies {
        let fetchLatestEventId: FetchLatestEventIdUseCase
        let fetchMessages: FetchMessagesUseCase
        let localMessageDataService: LocalMessageDataServiceProtocol
        let lastUpdatedStore: LastUpdatedStoreProtocol
        let contactProvider: ContactProviderProtocol
        let labelProvider: LabelProviderProtocol
    }
}
