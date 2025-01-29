// Copyright (c) 2024 Proton Technologies AG
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

@testable import InboxComposer
@testable import InboxTesting
import XCTest

final class DebouncedTaskTests: XCTestCase {
    private var sut: DebouncedTask!

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: Debounce

    func testDebounce_itShouldDelayTheExecution() {
        let duration: TimeInterval = 10
        let expectation1 = expectation(description: "task is executed")
        let expectation2 = expectation(description: "completion is executed")
        sut = .init(duration: .milliseconds(duration), block: { expectation1.fulfill() }, onBlockCompletion: { expectation2.fulfill() })

        sut.debounce()

        wait(for: [expectation1, expectation2], timeout: duration)
    }

    // MARK: Execute Immediately

    func testExecuteImmediately_itShouldExecuteTheTask() async {
        var result = [Int]()
        sut = .init(duration: .seconds(10), block: { result.append(1) }, onBlockCompletion: {})

        await sut.executeImmediately()
        XCTAssertEqual(result, [1])
    }

    func testExecuteImmediately_itShouldCancelTheDebouncedOpertionToAvoidRunningItTwice() async {
        var result = [Int]()
        let duration = Duration.milliseconds(10)
        sut = .init(duration: duration, block: { result.append(1) }, onBlockCompletion: {})

        await sut.executeImmediately()
        XCTAssertEqual(result, [1])

        try! await Task.sleep(for: duration+duration)
        XCTAssertEqual(result, [1])
    }


    // MARK: Cancel

    func testCancel_itShouldCancelTheTaskExecution() {
        let duration: TimeInterval = 0.1
        let expectation = expectation(description: "task is executed")
        expectation.isInverted = true
        sut = .init(duration: .milliseconds(duration), block: { expectation.fulfill() }, onBlockCompletion: { })
        sut.debounce()

        sut.cancel()

        wait(for: [expectation], timeout: duration)
    }

    func testCancel_itShouldCancelTheTaskCompletion() {
        let duration: TimeInterval = 0.1
        let expectation = expectation(description: "completion is executed")
        expectation.isInverted = true
        sut = .init(duration: .milliseconds(duration), block: { }, onBlockCompletion: { expectation.fulfill() })
        sut.debounce()

        sut.cancel()

        wait(for: [expectation], timeout: duration)
    }

}
