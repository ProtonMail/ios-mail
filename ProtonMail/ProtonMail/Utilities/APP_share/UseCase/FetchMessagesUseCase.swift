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

/// This use case fetches messages from backend and persists those messages locally.
/// It then requests the number of messages in each label/folder and also persists it locally.
typealias FetchMessagesUseCase = UseCase<Void, FetchMessages.Parameters>

class FetchMessages: FetchMessagesUseCase {
    private let dependencies: Dependencies

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    override func executionBlock(params: Parameters, callback: @escaping UseCase<Void, Parameters>.Callback) {
        dependencies
            .messageDataService
            .fetchMessages(
                labelID: params.labelID,
                endTime: params.endTime,
                fetchUnread: params.isUnread
            ) { [weak self] _, result in
                do {
                    let response = try result.get()
                    params.onMessagesRequestSuccess?()
                    try self?.persistOnLocalStorageMessages(
                        labelID: params.labelID,
                        isUnread: params.isUnread,
                        messagesData: response
                    )
                    callback(.success(()))
                } catch {
                    callback(.failure(error))
                }
            }
    }
}

// MARK: Private methods

extension FetchMessages {

    private func persistOnLocalStorageMessages(labelID: LabelID, isUnread: Bool, messagesData: [String: Any]) throws {
        try dependencies
            .cacheService
            .parseMessagesResponse(
                labelID: labelID,
                isUnread: isUnread,
                response: messagesData,
                idsOfMessagesBeingSent: dependencies.messageDataService.idsOfMessagesBeingSent()
            )

        requestMessagesCount()
    }

    private func requestMessagesCount() {
        dependencies.messageDataService.fetchMessagesCount { [weak self] (response: MessageCountResponse) in
            guard response.error == nil, let counts = response.counts else {
                return
            }
            self?.persistOnLocalStorageMessageCounts(counts: counts)
        }
    }

    private func persistOnLocalStorageMessageCounts(counts: [[String: Any]]) {
        dependencies.eventsService.processEvents(messageCounts: counts)
    }
}

// MARK: Input structs

extension FetchMessages {

    struct Parameters {
        let labelID: LabelID
        /// timestamp to get messages earlier than this value.
        let endTime: Int
        /// whether we want only unread messages or not
        let isUnread: Bool
        /// callback when the messages have been received from backend successfully
        let onMessagesRequestSuccess: (() -> Void)?

        init(labelID: LabelID, endTime: Int, isUnread: Bool, onMessagesRequestSuccess: (() -> Void)? = nil) {
            if labelID == LabelLocation.draft.labelID {
                self.labelID = LabelLocation.hiddenDraft.labelID
            } else if labelID == LabelLocation.sent.labelID {
                self.labelID = LabelLocation.hiddenSent.labelID
            } else {
                self.labelID = labelID
            }

            self.endTime = endTime
            self.isUnread = isUnread
            self.onMessagesRequestSuccess = onMessagesRequestSuccess
        }
    }

    struct Dependencies {
        let messageDataService: MessageDataServiceProtocol
        let cacheService: CacheServiceProtocol
        let eventsService: EventsServiceProtocol
    }
}
