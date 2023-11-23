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
import ProtonCoreNetworking
import ProtonCoreServices

class MailEventsLoop: EventsLoop {
    typealias Response = EventAPIResponse
    typealias Dependencies = AnyObject
        & HasAPIService
        & HasEventProcessor
        & HasLastUpdatedStoreProtocol
        & HasUserManager
        & HasUserDefaults

    weak var delegate: CoreLoopDelegate?
    private let dependencies: Dependencies
    private let cacheResetUseCase: CacheResetUseCase

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
        self.cacheResetUseCase = .init(dependencies: dependencies)
    }

    func poll(sinceLatestEventID eventID: String, completion: @escaping (Result<Response, Error>) -> Void) {
        Task {
            SystemLogger.log(message: "Event loop triggered. \neventID: \(eventID) \nuserID: \(userID.rawValue)", category: .eventLoop)
            let request = EventCheckRequest(eventID: eventID)
            do {
                let result: (URLSessionDataTask?, EventAPIResponse) = try await dependencies.apiService.perform(
                    request: request,
                    callCompletionBlockUsing: .immediateExecutor
                )
                completion(.success(result.1))
            } catch {
                completion(.failure(error))
            }
        }
    }

    func process(response: Response, completion: @escaping (Result<Void, Error>) -> Void) {
        dependencies.eventProcessor.process(response: response) { result in
            switch result {
            case .success:
                if !response.eventID.isEmpty {
                    self.latestEventID = response.eventID
                }
                completion(result)
            case .failure:
                completion(result)
            }
        }
    }

    func onError(error: EventsLoopError) {
        switch error {
        case .cacheIsOutdated:
            SystemLogger.log(message: "Cache is outdated.", category: .eventLoop)
            Task {
                do {
                    try await self.cacheResetUseCase.execute(type: .all)
                } catch {
                    SystemLogger.log(error: error, category: .eventLoop)
                }
            }
        default:
            SystemLogger.log(error: error, category: .eventLoop)
        }
    }
}

extension EventCheckResponse: EventPage {}
