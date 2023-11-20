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

@testable import ProtonMail
import XCTest
import ProtonCoreTestingToolkit

final class MailEventsPeriodicSchedulerTests: XCTestCase {
    private var sut: MailEventsPeriodicScheduler!
    private var testContainer: TestContainer!
    private var testUsers: [UserManager] = []
    private var apiMocks: [UserID: APIServiceMock] = [:]
    private var eventIDMap: [UserID: String] = [:]
    private var newEventIDMap: [UserID: String] = [:]

    override func setUp() {
        super.setUp()
        testContainer = .init()
        sut = testContainer.mailEventsPeriodicScheduler
    }

    override func tearDown() {
        super.tearDown()
        sut.reset()
        sut = nil
        testContainer = nil
        testUsers.removeAll()
        apiMocks.removeAll()
        eventIDMap.removeAll()
        newEventIDMap.removeAll()
    }

    func testEnableSpecialLoop_withOneUser_eventApiWillBeTriggered() throws {
        try createTestUser()

        sut.enableSpecialLoop(forSpecialLoopID: testUsers[0].userID.rawValue)
        sut.start()

        waitForExpectations(timeout: 1)
        wait(self.apiMocks[self.testUsers[0].userID]?.requestJSONStub.wasCalledExactlyOnce == true)
    }

    func testEnableSpecialLoop_withMultipleUser_eventApisWillBeTriggered() throws {
        for _ in 0..<5 {
            try createTestUser()
        }

        for user in testUsers {
            sut.enableSpecialLoop(forSpecialLoopID: user.userID.rawValue)
        }
        sut.start()

        waitForExpectations(timeout: 1)
        for item in apiMocks {
            XCTAssertTrue(item.value.requestJSONStub.wasCalledExactlyOnce)
        }

        for item in newEventIDMap {
            wait(self.testContainer.lastUpdatedStore.lastEventID(userID: item.key) == item.value)
        }
    }

    private func createTestUser() throws {
        let api = APIServiceMock()
        let user = try UserManager.prepareUser(apiMock: api, globalContainer: testContainer)
        testUsers.append(user)
        testContainer.usersManager.add(newUser: user)

        let eventID = String.randomString(20)
        eventIDMap[user.userID] = eventID
        apiMocks[user.userID] = api
        testContainer.lastUpdatedStore.updateEventID(by: user.userID, eventID: eventID)
        wait(self.testContainer.lastUpdatedStore.lastEventID(userID: user.userID) == eventID)

        let newEventID = String.randomString(20)
        newEventIDMap[user.userID] = newEventID
        let e = expectation(description: "Closure is called")
        api.requestJSONStub.bodyIs { _, method, path, _, _, _, _, _, _, _, _, completion in
            XCTAssertEqual(path, "/core/v4/events/\(eventID)?ConversationCounts=1&MessageCounts=1")
            XCTAssertEqual(method, .get)
            completion(nil, .success(["EventID": newEventID]))
            e.fulfill()
        }
    }
}
