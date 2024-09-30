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

import Combine
@testable import ProtonMail
import ProtonCoreTestingToolkitUnitTestsServices
import XCTest

final class ContactsSyncQueueTests: XCTestCase {
    private var sut: ContactsSyncQueue!
    private var testContainer: TestContainer!
    private let userID = "testUserID"
    private let queueFilePrefix = "contactsQueue"
    private var fileManager: FileManager!
    private var cancellables: Set<AnyCancellable>!

    private let dummyUserID = "dummyUserID"
    private let timeout: TimeInterval = 1

    override func setUp() {
        super.setUp()
        fileManager = FileManager()

        cancellables = Set<AnyCancellable>()

        testContainer = .init()
        let mockUserManager = UserManager(api: APIServiceMock(), userID: dummyUserID, globalContainer: testContainer)
        testContainer.usersManager.add(newUser: mockUserManager)

        sut = ContactsSyncQueue(
            userID: .init(rawValue: userID),
            fileManager: fileManager,
            dependencies: mockUserManager.container
        )
    }

    override func tearDown() {
        try? fileManager.removeItem(at: sut.taskQueueURL)
        fileManager = nil
        testContainer = nil
        cancellables = nil
        sut = nil
        super.tearDown()
    }

    func testSetup_whenNoPersistedData_itShouldPublishZeroProgress() {
        let expectation = self.expectation(description: "progress published")
        expectation.assertForOverFulfill = false

        sut.progressPublisher
            .sink { progress in
                XCTAssertEqual(progress.total, 0)
                expectation.fulfill()
            }
            .store(in: &cancellables)

        sut.setup()
        waitForExpectations(timeout: timeout)
    }

    func testSetup_whenPersistedData_itShouldPublishSomeProgress() {
        let data = try! JSONEncoder().encode([makeTask()])
        try! data.write(to: sut.taskQueueURL)
        XCTAssertTrue(fileManager.fileExists(atPath: sut.taskQueueURL.path))

        let expectation = self.expectation(description: "progress published")
        expectation.assertForOverFulfill = false

        sut.progressPublisher
            .sink { progress in
                if progress.total > 0 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        sut.setup()
        sut.pause() // to avoid the queue executing any task
        waitForExpectations(timeout: timeout)
    }

    func testSetup_itShouldReturnQueueIsPaused() {
        sut.setup()
        XCTAssertTrue(sut.isPaused)
    }

    func testStart_itShouldReturnQueueIsNotPaused() {
        sut.setup()
        sut.start()
        XCTAssertFalse(sut.isPaused)
    }

    func testPause_itShouldReturnQueueIsPaused() {
        sut.setup()
        sut.pause()
        XCTAssertTrue(sut.isPaused)
    }

    func testResume_whenIsPaused_itShouldResumeTheQueue() {
        sut.setup()
        sut.start()
        XCTAssertFalse(sut.isPaused)
        sut.pause()
        XCTAssertTrue(sut.isPaused)
        sut.resume()
        XCTAssertFalse(sut.isPaused)
    }

    func testSaveQueueToDisk_itShouldPersistTheExistingTasksToDisk() {
        sut.setup()

        let expectation = self.expectation(description: "progress published")
        expectation.assertForOverFulfill = false
        sut.progressPublisher
            .sink { progress in
                if progress.total > 0 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        let task = makeTask()
        sut.addTask(task)

        sut.saveQueueToDisk()
        waitForExpectations(timeout: timeout)

        // Check data was persisted

        let data = try! Data(contentsOf: sut.taskQueueURL)
        let persistedTasks = try! JSONDecoder().decode([ContactTask].self, from: data)
        XCTAssertEqual(persistedTasks.first?.taskID, task.taskID)
    }

    func testDeleteQueue_itShouldDeleteTheSystemFile() {
        sut.setup()
        let task = makeTask()
        sut.addTask(task)
        sut.saveQueueToDisk()
        let expectation = self.expectation(description: "progress published")
        expectation.assertForOverFulfill = false
        sut.progressPublisher
            .sink { progress in
                expectation.fulfill()
            }
            .store(in: &cancellables)
        waitForExpectations(timeout: timeout)

        XCTAssertTrue(fileManager.fileExists(atPath: sut.taskQueueURL.path))
        sut.deleteQueue()
        XCTAssertFalse(fileManager.fileExists(atPath: sut.taskQueueURL.path))
    }
}

extension ContactsSyncQueueTests {

    private func makeTask() -> ContactTask {
        ContactTask(taskID: UUID(), command: .create(
            contacts: [
                .init(vCards: [CardData.init(type: .PlainText, data: "", signature: "")])
            ]
        ))
    }
}
