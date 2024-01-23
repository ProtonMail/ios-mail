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
import ProtonCoreServices

typealias FetchLatestEventIdUseCase = UseCase<EventLatestIDResponse, Void>

class FetchLatestEventId: FetchLatestEventIdUseCase {
    private let userId: UserID
    private let dependencies: Dependencies

    init(userId: UserID, dependencies: Dependencies) {
        self.userId = userId
        self.dependencies = dependencies
    }

    override func executionBlock(params: Void, callback: @escaping Callback) {
        let request = EventLatestIDRequest()
        dependencies.apiService.perform(
            request: request,
            response: EventLatestIDResponse()
        ) { (_: URLSessionDataTask?, response: EventLatestIDResponse) in
            if response.eventID.isEmpty {
                callback(.success(response))
            } else {
                self.persistLastEventId(latestEvent: response)
                callback(.success(response))
            }
        }
    }
}

extension FetchLatestEventId {

    private func persistLastEventId(latestEvent: EventLatestIDResponse) {
        dependencies.lastUpdatedStore.updateEventID(by: userId, eventID: latestEvent.eventID)
    }
}

// MARK: Input structs

extension FetchLatestEventId {

    struct Dependencies {
        let apiService: APIService
        let lastUpdatedStore: LastUpdatedStoreProtocol
    }
}
