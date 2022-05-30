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

protocol FetchLatestEventIdUseCase: UseCase {
    func execute(callback: UseCaseResult<EventLatestIDResponse>?)
}

class FetchLatestEventId: FetchLatestEventIdUseCase {
    private let params: Parameters
    private let dependencies: Dependencies

    init(params: Parameters, dependencies: Dependencies) {
        self.params = params
        self.dependencies = dependencies
    }

    func execute(callback: UseCaseResult<EventLatestIDResponse>?) {
        dependencies.eventsService?.fetchLatestEventID { [weak self] latestEvent in
            SystemLogger.logTemporarily(message: "FetchLatestEventId execute...", category: .serviceRefactor)
            if latestEvent.eventID.isEmpty  {
                self?.runOnMainThread { callback?(.success(latestEvent)) }
            } else {
                self?.persistLastEventId(latestEvent: latestEvent, callback: callback)
            }
        }
    }
}

extension FetchLatestEventId {

    private func persistLastEventId(latestEvent: EventLatestIDResponse, callback: UseCaseResult<EventLatestIDResponse>?) {
        dependencies.lastUpdatedStore.clear()
        _ = dependencies.lastUpdatedStore.updateEventID(by: params.userId, eventID: latestEvent.eventID).ensure { [weak self] in
            self?.runOnMainThread { callback?(.success(latestEvent)) }
        }
    }
}

// MARK: Input structs

extension FetchLatestEventId {

    struct Parameters {
        /// Identifier to persist the last event locally for a specific user.
        let userId: String
    }

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
