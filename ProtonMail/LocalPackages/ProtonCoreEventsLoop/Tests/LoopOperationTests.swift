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
import XCTest

class LoopOperationTests: XCTestCase {

    private var sut: LoopOperation<LoopSpy>!
    private var loopSpy: LoopSpy!

    override func setUp() {
        super.setUp()

        loopSpy = LoopSpy()
        sut = LoopOperation(
            loop: loopSpy,
            onDidReceiveMorePages: {},
            createOperationQueue: { OperationQueue() }
        )
    }

    override func tearDown() {
        sut = nil
        loopSpy = nil

        super.tearDown()
    }

    /// Added because of a crash in the case when operation was started, just after cancelled, deallocated, but
    /// a response was returned from a backend and self was captured with `unknown` reference inside the completion block
    func testWhenUseWeakSelfInPollCompletion_DoesNotCrash() {
        let expectation = XCTestExpectation(description: "poll_was_called")

        loopSpy.pollCalled = {
            expectation.fulfill()
        }

        sut.start()

        wait(for: [expectation], timeout: .defaultTimeout)

        sut = nil

        XCTAssertNil(sut)

        loopSpy.pollCompletion?(.success(.testPage))
    }

    /// Added because of a crash in the case when operation was started, just after cancelled, deallocated, but
    /// a response was returned from a backend and self was captured with `unknown` reference inside the completion block
    func testWhenUseWeakSelfInProcessCompletion_DoesNotCrash() {
        let pollExpectation = XCTestExpectation(description: "poll_was_called")

        loopSpy.pollCalled = {
            pollExpectation.fulfill()
        }

        sut.start()

        wait(for: [pollExpectation], timeout: .defaultTimeout)

        loopSpy.pollCompletion?(.success(.testPage))

        let processExpectation = XCTestExpectation(description: "process_was_called")

        loopSpy.processCalled = {
            processExpectation.fulfill()
        }

        wait(for: [processExpectation], timeout: .defaultTimeout)

        sut = nil

        XCTAssertNil(sut)

        loopSpy.processCompletion?(.success(()))
    }

}

private class LoopSpy: EventsLoop {

    var pollCalled: (() -> Void)?
    var processCalled: (() -> Void)?
    private(set) var pollCompletion: ((Result<TestEventPage, Error>) -> Void)?
    private(set) var processCompletion: ((Result<Void, Error>) -> Void)?

    // MARK: - EventsLoop

    let loopID = UUID().uuidString
    var latestEventID: String? = "latest_event_id"

    func poll(sinceLatestEventID eventID: String, completion: @escaping (Result<TestEventPage, Error>) -> Void) {
        pollCompletion = completion
        pollCalled?()
    }

    func process(response: TestEventPage, completion: @escaping (Result<Void, Error>) -> Void) {
        processCompletion = completion
        processCalled?()
    }

    func onError(error: EventsLoopError) {}

}

private extension TestEventPage {
    static let testPage = Self(eventID: "", refresh: 0, more: 0)
}
