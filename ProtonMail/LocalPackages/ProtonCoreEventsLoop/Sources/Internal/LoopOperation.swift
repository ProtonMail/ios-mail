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

import Foundation

final class LoopOperation<Loop: EventsLoop>: AsynchronousOperation {

    var loopID: String {
        loop.loopID
    }

    private let loop: Loop
    private let onDidReceiveMorePages: () -> Void
    private let queue: OperationQueue

    init(
        loop: Loop,
        onDidReceiveMorePages: @escaping () -> Void,
        createOperationQueue: @escaping () -> OperationQueue
    ) {
        self.loop = loop
        self.onDidReceiveMorePages = onDidReceiveMorePages
        self.queue = SerialQueueFactory(createOperationQueue: createOperationQueue).makeSerialQueue()
        super.init()
    }

    override func cancel() {
        super.cancel()

        queue.cancelAllOperations()
        queue.isSuspended = true
    }

    override func main() {
        guard let latestEventID = loop.latestEventID else {
            loop.onError(error: .missingLatestEventID)
            state = .finished
            return
        }

        addPollOperation(since: latestEventID)
    }

    private func addPollOperation(since latestEventID: String) {
        let poll = BlockOperation { [weak self] in
            self?.loop.poll(sinceLatestEventID: latestEventID) { result in
                self?.addProcessPollResultOperation(result: result)
            }
        }
        queue.addOperation(poll)
    }

    private func addProcessPollResultOperation(result: Result<Loop.Response, Error>) {
        let processPollResult = BlockOperation { [weak self] in
            switch result {
            case .success(let page) where page.requiresClearCache:
                self?.loop.onError(error: .cacheIsOutdated)
                self?.state = .finished
            case .success(let page) where page.requireClearMailCache:
                self?.loop.onError(error: .mailCacheIsOutdated)
                self?.state = .finished
            case .success(let page) where page.requireClearContactCache:
                self?.loop.onError(error: .contactCacheIsOutdated)
                self?.state = .finished
            case .success(let page):
                self?.addProcessPageOperation(page: page)
            case .failure(let error):
                self?.loop.onError(error: .networkError(error))
                self?.state = .finished
            }
        }
        queue.addOperation(processPollResult)
    }

    private func addProcessPageOperation(page: Loop.Response) {
        let processPage = BlockOperation { [weak self] in
            self?.loop.process(response: page) { completion in
                switch completion {
                case .success:
                    self?.loop.latestEventID = page.eventID

                    if page.hasMorePages {
                        self?.onDidReceiveMorePages()
                    }
                case .failure(let error):
                    self?.loop.onError(error: .pageProcessingError(error))
                }
                self?.state = .finished
            }
        }
        queue.addOperation(processPage)
    }

}
