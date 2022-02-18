// Copyright (c) 2022 Proton Technologies AG
//
// This file is part of ProtonMail.
//
// ProtonMail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// ProtonMail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with ProtonMail. If not, see https://www.gnu.org/licenses/.

import XCTest
@testable import ProtonMail
import ProtonCore_TestingToolkit

final class NotificationCenterMock: NotificationCenterProtocol {
    @FuncStub(NotificationCenterMock.removeDeliveredNotifications) var callRemove
    func removeDeliveredNotifications(withIdentifiers identifiers: [String]) {
        callRemove(identifiers)
    }
}

final class BadgeMock: UIApplicationBadgeProtocol {
    @FuncStub(BadgeMock.setBadge) var callSetBadge
    func setBadge(badge: Int) {
        callSetBadge(badge)
    }
}

final class UserSessionMock: UserSessionProvider {
    var primaryUserSessionIdValue: String?
    var primaryUserSessionId: String? {
        get {
            primaryUserSessionIdValue
        }
        set {
            primaryUserSessionIdValue = newValue
        }
    }
}

final class PushUpdaterTests: XCTestCase {
    private var sut: PushUpdater!
    private var ncMock: NotificationCenterMock!
    private var badgeMock: BadgeMock!
    private var userSessionMock: UserSessionMock!
    private var urlSessionMock: URLSessionMock!

    override func setUp() {
        super.setUp()
        ncMock = NotificationCenterMock()
        badgeMock = BadgeMock()
        userSessionMock = UserSessionMock()
        urlSessionMock = URLSessionMock()
        sut = PushUpdater(notificationCenter: ncMock,
                          application: badgeMock,
                          userStatus: userSessionMock,
                          pingBackSession: urlSessionMock)
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
        ncMock = nil
        badgeMock = nil
        userSessionMock = nil
        urlSessionMock = nil
    }

    func testNotProvidingACollapseIdShouldTriggerNothingButCallThePingBackService() {
        let expectation = expectation(description: "Should call ping back service")
        sut.update(with: [:]) { [unowned self] in
            XCTAssert(self.ncMock.callRemove.wasNotCalled)
            XCTAssert(self.badgeMock.callSetBadge.wasNotCalled)
            XCTAssertEqual(self.urlSessionMock.dataTaskCallCount, 1)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 0.5)
    }

    func testProvidingACollapseIdShouldTriggerCleaningNotificationWithTheProvidedId() {
        let expectedId = String.randomString(Int.random(in: 1..<32))
        let expectation = expectation(description: "Should call ping back service")
        sut.update(with: ["collapseID": expectedId]) { [unowned self] in
            XCTAssert(self.ncMock.callRemove.capturedArguments.first!.value.contains(expectedId))
            XCTAssert(self.ncMock.callRemove.wasCalledExactlyOnce)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 0.5)
    }

    func testProvidingACollapseIdWithoutAUIDShouldUpdateNotificationCenterWithoutUpdatingBadge() {
        let expectedId = String.randomString(Int.random(in: 1..<32))
        let expectation = expectation(description: "Should call ping back service")
        sut.update(with: ["collapseID": expectedId]) { [unowned self] in
            XCTAssert(self.ncMock.callRemove.capturedArguments.first!.value.contains(expectedId))
            XCTAssert(self.ncMock.callRemove.wasCalledExactlyOnce)
            XCTAssert(self.badgeMock.callSetBadge.wasNotCalled)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 0.5)
    }

    func testProvidingAUIDWithNoCountShouldUpdateNothing() {
        let expectedUID = String.randomString(Int.random(in: 1..<32))
        userSessionMock.primaryUserSessionId = expectedUID
        let expectation = expectation(description: "Should call ping back service")
        sut.update(with: ["UID": expectedUID]) { [unowned self] in
            XCTAssert(self.ncMock.callRemove.wasNotCalled)
            XCTAssert(self.badgeMock.callSetBadge.wasNotCalled)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 0.5)
    }

    func testProvidingAUIDWithViewModeConversationAndUnreadConversationsShouldSetBadgeToTheRightValue() {
        let expectedUID = String.randomString(Int.random(in: 1..<32))
        let unreadCount = Int.random(in: 0..<100)
        userSessionMock.primaryUserSessionId = expectedUID
        let expectation = expectation(description: "Should call ping back service")
        sut.update(with: ["collapseID": String.randomString(Int.random(in: 1..<32)), "UID": expectedUID, "viewMode": 0, "unreadConversations": unreadCount]) { [unowned self] in
            XCTAssert(self.badgeMock.callSetBadge.wasCalledExactlyOnce)
            XCTAssertEqual(self.badgeMock.callSetBadge.lastArguments?.value, unreadCount)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 0.5)
    }

    func testProvidingAUIDWithViewModeMessagesAndUnreadMessagesShouldSetBadgeToTheRightValue() {
        let expectedUID = String.randomString(Int.random(in: 1..<32))
        let unreadCount = Int.random(in: 0..<100)
        userSessionMock.primaryUserSessionId = expectedUID
        let expectation = expectation(description: "Should call ping back service")
        sut.update(with: ["collapseID": String.randomString(Int.random(in: 1..<32)), "UID": expectedUID, "viewMode": 1, "unreadMessages": unreadCount]) { [unowned self] in
            XCTAssert(self.badgeMock.callSetBadge.wasCalledExactlyOnce)
            XCTAssertEqual(self.badgeMock.callSetBadge.lastArguments?.value, unreadCount)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 0.5)
    }

    func testProvidingAUIDWithViewModeConversationAndUnreadMessagesShouldNotUpdateBadge() {
        let expectedUID = String.randomString(Int.random(in: 1..<32))
        let unreadCount = Int.random(in: 0..<100)
        userSessionMock.primaryUserSessionId = expectedUID
        let expectation = expectation(description: "Should call ping back service")
        sut.update(with: ["UID": expectedUID, "viewMode": 0, "unreadMessages": unreadCount]) { [unowned self] in
            XCTAssert(self.badgeMock.callSetBadge.wasNotCalled)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 0.5)
    }

    func testProvidingAUIDWithViewModeMessagesAndUnreadConversationShouldNotUpdateBadge() {
        let expectedUID = String.randomString(Int.random(in: 1..<32))
        let unreadCount = Int.random(in: 0..<100)
        userSessionMock.primaryUserSessionId = expectedUID
        let expectation = expectation(description: "Should call ping back service")
        sut.update(with: ["UID": expectedUID, "viewMode": 1, "unreadConversations": unreadCount]) { [unowned self] in
            XCTAssert(self.badgeMock.callSetBadge.wasNotCalled)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 0.5)
    }

    func testProvidingDataShouldCallThePingBackService() {
        let expectedId = String.randomString(Int.random(in: 1..<32))
        let expectation = expectation(description: "Should call ping back service")
        sut.update(with: ["collapseID": expectedId]) { [unowned self] in
            XCTAssertEqual(self.urlSessionMock.dataTaskCallCount, 1)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 0.5)
    }

    func testSendPushPingBackParameters() throws {
        let expectedID = String.randomString(Int.random(in: 1..<32))
        let expectedDeviceToken = PushNotificationDecryptor.deviceTokenSaver.get() ?? "unknown"
        let expectation = expectation(description: "Should call ping back service")
        sut.sendPushPingBack(notificationId: expectedID) { [unowned self] in
            let requests = self.urlSessionMock.dataTaskArgsRequest
            XCTAssertEqual(requests.count, 1)
            guard let sentBody = requests[0].httpBody else
            {
                XCTFail("Unable to access request body")
                return
            }
            let body = try! JSONDecoder().decode(NotificationPingBackBody.self, from: sentBody)
            XCTAssertEqual(body.notificationId, "\(expectedID)-background")
            XCTAssertEqual(body.deviceToken, expectedDeviceToken)
            XCTAssertEqual(body.decrypted, true)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 0.5)
    }
}

private final class MockDataTask: URLSessionDataTask {
    var completionHandler: (Data?, URLResponse?, Error?) -> Void
    init(completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) {
        self.completionHandler = completionHandler
    }

    override func resume() {
        delay(0.1) {
            self.completionHandler(nil, nil, nil)
        }
    }
}

private class URLSessionMock: URLSessionProtocol {
    var dataTaskCallCount = 0
    var dataTaskArgsRequest: [URLRequest] = []
    func dataTask(with request: URLRequest,
                  completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
            dataTaskCallCount += 1
            dataTaskArgsRequest.append(request)
            return MockDataTask(completionHandler: completionHandler)
    }
}
