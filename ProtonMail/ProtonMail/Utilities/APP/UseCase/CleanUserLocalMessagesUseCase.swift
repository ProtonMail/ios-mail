// Copyright (c) 2023 Proton AG
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

typealias CleanUserLocalMessagesUseCase = UseCase<Void, CleanUserLocalMessages.Params>
final class CleanUserLocalMessages: CleanUserLocalMessagesUseCase {
    typealias Dependencies = AnyObject
    & HasAPIService
    & HasFetchMessages
    & HasMessageDataService
    & HasLabelsDataService
    & HasContactDataService
    & HasLastUpdatedStoreProtocol
    & HasUserDefaults

    private unowned let dependencies: Dependencies

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    override func executionBlock(params: Params, callback: @escaping UseCase<Void, Params>.Callback) {
        let request = EventLatestIDRequest()
        dependencies.apiService.perform(request: request, response: EventLatestIDResponse()) { _, response in
            guard response.error == nil, !response.eventID.isEmpty else {
                callback(.failure(response.error ?? Error.eventIdEmpty))
                return
            }
            self.dependencies.userDefaults[.areContactsCached] = 0

            self.dependencies.fetchMessages.execute(
                params: .init(
                    labelID: Message.Location.inbox.labelID,
                    endTime: 0,
                    isUnread: false,
                    onMessagesRequestSuccess: {
                        self.dependencies.messageService.cleanMessage(cleanBadgeAndNotifications: true)
                        self.dependencies.contactService.cleanUp()
                    }
                )
            ) { _ in
                self.onFetchComplete(userId: params.userId, eventId: response.eventID, callback: callback)
            }
        }
    }

    private func onFetchComplete(userId: UserID, eventId: String, callback: @escaping UseCase<Void, Params>.Callback) {
        dependencies.labelService.fetchV4Labels { _ in
            self.dependencies.contactService.cleanUp()
            self.dependencies.contactService.fetchContacts { error in
                if let error = error {
                    callback(.failure(error))
                    return
                }
                self.dependencies.lastUpdatedStore.updateEventID(by: userId, eventID: eventId)
                callback(.success(()))
            }
        }
    }
}

extension CleanUserLocalMessages {

    enum Error: String, LocalizedError {
        case eventIdEmpty = "eventId is empty"

        var errorDescription: String? {
            "CleanUserLocalMessages.Error: \(rawValue)"
        }
    }

    struct Params {
        let userId: UserID
    }
}
