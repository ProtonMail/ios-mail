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

import BackgroundTasks
import ProtonCoreDataModel
@testable import ProtonMail
import XCTest

final class BackgroundTaskHelperTests: XCTestCase {
    private let tasks: [BackgroundTaskHelper.Task] = [.eventLoop]
    private var task: BackgroundTaskHelper.Task!
    private var scheduler: MockBGTaskSchedulerProtocol!
    private var keyMakerMock: MockKeyMakerProtocol!
    private var usersMock: MockUsersManagerProtocol!
    private var sut: BackgroundTaskHelper!

    override func setUpWithError() throws {
        scheduler = MockBGTaskSchedulerProtocol()
        task = tasks[Int.random(in: 0 ..< tasks.count)]
        keyMakerMock = .init()
        usersMock = .init()
        sut = .init(dependencies: .init(
            coreKeyMaker: keyMakerMock,
            usersManager: usersMock
        ))
    }

    override func tearDownWithError() throws {
        sut = nil
        scheduler = nil
        task = nil
        usersMock = nil
        keyMakerMock = nil
    }

    func testRegisterBackgroundTask() {
        let e = expectation(description: "Closure is Called")
        scheduler.registerStub.bodyIs { _, _, _, _ in
            e.fulfill()
            return true
        }

        sut.registerBackgroundTask(scheduler: scheduler, task: .eventLoop)

        waitForExpectations(timeout: 1)
        XCTAssertTrue(scheduler.registerStub.wasCalledExactlyOnce)
    }

    func testScheduleBackgroundRefreshIfNeeded_appKeyEnable_shouldNotSubmit() {
        keyMakerMock.isAppKeyEnabledStub.fixture = true

        sut.scheduleBackgroundRefreshIfNeeded(scheduler: scheduler, task: .eventLoop)

        XCTAssertEqual(scheduler.submitStub.wasNotCalled, true)
    }

    func testScheduleBackgroundRefreshIfNeeded_appKeyFalse_noUser_shouldNotSubmit() {
        keyMakerMock.isAppKeyEnabledStub.fixture = false

        sut.scheduleBackgroundRefreshIfNeeded(scheduler: scheduler, task: .eventLoop)

        XCTAssertEqual(scheduler.submitStub.wasNotCalled, true)
    }

    func testSubmit_success() throws {
        let expectation1 = expectation(description: "Data correct")
        scheduler.submitStub.bodyIs { _, request in
            switch self.task {
            case .eventLoop:
                XCTAssert(request is BGAppRefreshTaskRequest)
            case .none:
                XCTFail("Unknown type")
            }
            expectation1.fulfill()
        }
        let isSuccess = BackgroundTaskHelper.submit(scheduler: scheduler, task: task)
        XCTAssertTrue(isSuccess)
        wait(for: [expectation1], timeout: 5)
        XCTAssertEqual(scheduler.submitStub.callCounter, 1)
    }

    func testSubmit_failed() {
        scheduler.submitStub.bodyIs { _, _ in
            throw NSError(domain: "test.com", code: -1)
        }
        let isSuccess = BackgroundTaskHelper.submit(scheduler: scheduler, task: .eventLoop)
        XCTAssertFalse(isSuccess)
        XCTAssertEqual(scheduler.submitStub.callCounter, 1)
    }

    func testRegister() {
        let expectation1 = expectation(description: "Handler is called")
        scheduler.registerStub.bodyIs { _, identifier, _, _ in
            XCTAssertEqual(self.task.identifier, identifier)
            // Can't initialize BGTask, can't test completion
            expectation1.fulfill()
            return true
        }
        XCTAssertTrue(
            BackgroundTaskHelper.register(
                scheduler: scheduler,
                task: task
            ) { _ in }
        )
        wait(for: [expectation1], timeout: 5)
        XCTAssertEqual(scheduler.registerStub.callCounter, 1)
    }
}
