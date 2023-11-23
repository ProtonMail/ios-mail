// Copyright (c) 2023 Proton Technologies AG
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

final class CacheResetUseCase {
    enum ResetType {
        case all
        case contact
    }
    typealias Dependencies = AnyObject
        & HasLastUpdatedStoreProtocol
        & HasUserDefaults
        & HasUserManager

    unowned private let dependencies: Dependencies

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    func execute(type: ResetType) async throws {
        switch type {
        case .all:
            try await resetAllCache()
        case .contact:
            dependencies.user.contactService.cleanUp()
            dependencies.user.contactService.fetchContacts(completion: nil)
        }
    }

    private func resetAllCache() async throws {
        let eventID = try await fetchLatestEventID()
        dependencies.user.conversationService.cleanAll()
        dependencies.user.messageService.cleanMessage(cleanBadgeAndNotifications: false)
        dependencies.user.contactService.cleanUp()
        switch dependencies.user.conversationStateService.viewMode {
        case .conversation:
            async let _ = try await withCheckedThrowingContinuation { continuation in
                self.dependencies.user.conversationService.fetchConversations(
                    for: Message.Location.allmail.labelID,
                    before: 0,
                    unreadOnly: false,
                    shouldReset: false
                ) { result in
                    switch result {
                    case .success:
                        continuation.resume()
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
            }
        case .singleMessage:
            async let _ = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                self.dependencies.user.messageService.fetchMessages(
                    byLabel: Message.Location.allmail.labelID,
                    time: 0,
                    forceClean: false,
                    isUnread: false
                ) { _, _, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume()
                    }
                }
            }
        }
        async let _ = await withCheckedContinuation { continuation in
            dependencies.user.contactService.fetchContacts { _ in
                continuation.resume()
            }
        }
        async let _ = try await dependencies.user.messageService.labelDataService.fetchV4Labels()
        dependencies.lastUpdatedStore.updateEventID(by: dependencies.user.userID, eventID: eventID)
    }

    private func fetchLatestEventID() async throws -> String {
        let request = EventLatestIDRequest()
        let result = await dependencies.user.apiService.perform(request: request, response: EventLatestIDResponse())
        let response = result.1
        if response.eventID.isEmpty {
            throw NSError.badResponse()
        } else {
            return response.eventID
        }
    }
}
