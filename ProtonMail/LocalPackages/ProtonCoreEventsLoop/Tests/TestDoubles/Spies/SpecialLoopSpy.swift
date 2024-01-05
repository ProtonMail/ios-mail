// Copyright (c) 2022 Proton Technologies AG
//
// This file is part of Proton Technologies AG and ProtonCore.
//
// ProtonCore is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// ProtonCore is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with ProtonCore. If not, see https://www.gnu.org/licenses/.

@testable import ProtonCoreEventsLoop

class SpecialLoopSpy: EventsLoop {

    enum RecordedEvent: Equatable {
        case startedPolling(eventID: String)
        case finishedPolling(eventID: String, requiresClearCache: Bool, hasMorePages: Bool)
        case startedProcessing(eventID: String)
        case finishedProcessing(eventID: String)
        case missingLatestEventIDError
        case requiresClearCacheError
        case networkError(String)
        case pageProcessingError(String)
    }

    init(loopID: String, simulateHasMorePages: Bool) {
        self.loopID = loopID
        self.simulateHasMorePages = simulateHasMorePages
    }

    var stubbedRequiresClearCache: Bool = false
    var stubbedNetworkError: Error?
    var stubbedProcessingError: Error?

    private(set) var recordedEvents: [RecordedEvent] = []

    // MARK: - EventsLoop

    typealias Response = TestEventPage

    func poll(sinceLatestEventID eventID: String, completion: @escaping (Result<Response, Error>) -> Void) {
        recordedEvents.append(.startedPolling(eventID: eventID))

        pollCalls.append((eventID, completion))

        if let error = stubbedNetworkError {
            simulatePollingFailure(error: error)
        } else {
            simulatePollingSuccess()
        }
    }

    func process(response: TestEventPage, completion: (Result<Void, Error>) -> Void) {
        recordedEvents.append(.startedProcessing(eventID: response.eventID))

        if let error = stubbedProcessingError {
            completion(.failure(error))
        } else {
            recordedEvents.append(.finishedProcessing(eventID: response.eventID))
            completion(.success(()))
        }
    }

    func onError(error: EventsLoopError) {
        switch error {
        case .cacheIsOutdated:
            recordedEvents.append(.requiresClearCacheError)
        case .missingLatestEventID:
            recordedEvents.append(.missingLatestEventIDError)
        case .networkError(let error):
            recordedEvents.append(.networkError(error.localizedDescription))
        case .pageProcessingError(let error):
            recordedEvents.append(.pageProcessingError(error.localizedDescription))
        }
    }

    var loopID: String
    var latestEventID: String?

    // MARK: - Private

    private let simulateHasMorePages: Bool
    private var pollCalls: [(sinceLatestEventID: String, completion: (Result<Response, Error>) -> Void)] = []

    private func simulatePollingSuccess() {
        guard let eventID = pollCalls.last?.sinceLatestEventID else {
            fatalError("Can not simulate success before calling poll(sinceLatestEventID:completion:)")
        }

        let hasMorePages = simulateHasMorePages ? pollCalls.count == 1 : false
        let response = Response(
            eventID: "\(eventID)_#\(pollCalls.count)",
            refresh: stubbedRequiresClearCache ? 1 : 0,
            more: hasMorePages ? 1 : 0
        )
        recordedEvents.append(.finishedPolling(
            eventID: response.eventID,
            requiresClearCache: response.requiresClearCache,
            hasMorePages: response.hasMorePages
        ))

        pollCalls.last?.completion(.success(response))
    }

    private func simulatePollingFailure(error: Error) {
        pollCalls.last?.completion(.failure(error))
    }

}
