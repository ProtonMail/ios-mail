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
import XCTest
@testable import ProtonMail

class NewUseCaseTests: XCTestCase {
    var sut: NewUseCase<Bool, Void>!

    override func setUp() {
        super.setUp()
        sut = RunsInMainThreadUseCase()
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
    }

    func testExecute_whenExecutionThreadIsNotSpecified_executionIsNotOnMainThread() {
        let expectation = expectation(description: "")
        sut.execute(params: Void()) { result in
            let isExecutionOnMain = try! result.get()
            XCTAssertFalse(isExecutionOnMain)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2.0)
    }

    func testExecute_whenExecutionThreadIsSetToMain_executionIsOnMainThread() {
        let expectation = expectation(description: "")
        sut.executeOn(.main).execute(params: Void()) { result in
            let isExecutionOnMain = try! result.get()
            XCTAssertTrue(isExecutionOnMain)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2.0)
    }

    func testExecute_whenCallbackThreadIsNotSpecified_callbackIsNotOnMainThread() {
        let expectation = expectation(description: "")
        sut.execute(params: Void()) { result in
            XCTAssertFalse(Thread.current.isMainThread)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2.0)
    }

    func testExecute_whenCallbackThreadIsSetToMain_callbackIsOnMainThread() {
        let expectation = expectation(description: "")
        sut.callbackOn(.main).execute(params: Void()) { result in
            XCTAssertTrue(Thread.current.isMainThread)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2.0)
    }
}

private class RunsInMainThreadUseCase: NewUseCase<Bool, Void> {

    override func executionBlock(params: Void, callback: @escaping Callback) {
        let result = Thread.current.isMainThread
        callback(.success(result))
    }
}
