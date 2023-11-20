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

import ProtonCoreEventsLoop
import ProtonCoreServices

class MailEventsLoop: EventsLoop {
    typealias Response = EventCheckResponse
    typealias Dependencies = HasLastUpdatedStoreProtocol & HasAPIService

    weak var delegate: CoreLoopDelegate?
    private let dependencies: Dependencies

    let userID: UserID
    var loopID: String {
        userID.rawValue
    }
    var latestEventID: String? {
        get {
            dependencies.lastUpdatedStore.lastEventID(userID: userID)
        }
        set {
            if let value = newValue {
                dependencies.lastUpdatedStore.updateEventID(by: userID, eventID: value)
            }
        }
    }

    init(
        userID: UserID,
        dependencies: Dependencies
    ) {
        self.userID = userID
        self.dependencies = dependencies
    }

    func poll(sinceLatestEventID eventID: String, completion: @escaping (Result<Response, Error>) -> Void) {
        Task {
            SystemLogger.log(message: "Event loop triggered. \neventID: \(eventID) \nuserID: \(userID.rawValue)", category: .eventLoop)
            let request = EventCheckRequest(eventID: eventID)
            let result = await dependencies.apiService.perform(
                request: request,
                response: Response(),
                callCompletionBlockUsing: .immediateExecutor
            )
            if let error = result.1.error {
                completion(.failure(error))
            } else {
                completion(.success(result.1))
            }
        }
    }

    func process(response: Response, completion: @escaping (Result<Void, Error>) -> Void) {
        // TODO: process event api response
        if !response.eventID.isEmpty {
            self.latestEventID = response.eventID
        }
        completion(.success(()))
    }

    func onError(error: EventsLoopError) {
        SystemLogger.log(error: error, category: .eventLoop)
    }
}

extension EventCheckResponse: EventPage {}
