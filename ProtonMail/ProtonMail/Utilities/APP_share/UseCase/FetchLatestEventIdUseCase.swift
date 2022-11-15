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

typealias FetchLatestEventIdUseCase = NewUseCase<EventLatestIDResponse, Void>

class FetchLatestEventId: FetchLatestEventIdUseCase {
    private let userId: UserID
    private let dependencies: Dependencies

    init(userId: UserID, dependencies: Dependencies) {
        self.userId = userId
        self.dependencies = dependencies
    }

    override func executionBlock(params: Void, callback: @escaping Callback) {
        dependencies.eventsService?.fetchLatestEventID { [weak self] latestEvent in
            if latestEvent.eventID.isEmpty {
                callback(.success(latestEvent))
            } else {
                self?.persistLastEventId(latestEvent: latestEvent, callback: callback)
            }
        }
    }
}

extension FetchLatestEventId {

    private func persistLastEventId(latestEvent: EventLatestIDResponse, callback: @escaping Callback) {
        dependencies
            .lastUpdatedStore
            .updateEventID(by: userId, eventID: latestEvent.eventID)
            .ensure {
                callback(.success(latestEvent))
            }
            .cauterize()
    }
}

// MARK: Input structs

extension FetchLatestEventId {

    struct Dependencies {
        let eventsService: EventsServiceProtocol?
        let lastUpdatedStore: LastUpdatedStoreProtocol

        init(
            eventsService: EventsServiceProtocol?,
            lastUpdatedStore: LastUpdatedStoreProtocol = ServiceFactory.default.get(by: LastUpdatedStore.self)
        ) {
            self.eventsService = eventsService
            self.lastUpdatedStore = lastUpdatedStore
        }
    }
}
