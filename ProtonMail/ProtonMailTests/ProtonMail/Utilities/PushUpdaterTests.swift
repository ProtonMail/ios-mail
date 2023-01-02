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

    override func setUp() {
        super.setUp()
        ncMock = NotificationCenterMock()
        badgeMock = BadgeMock()
        userSessionMock = UserSessionMock()
        sut = PushUpdater(notificationCenter: ncMock,
                          application: badgeMock,
                          userStatus: userSessionMock)
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
        ncMock = nil
        badgeMock = nil
        userSessionMock = nil
    }

    func testNotProvidingACollapseIdShouldTriggerNothing() {
        sut.update(with: [:])
        XCTAssert(self.ncMock.callRemove.wasNotCalled)
        XCTAssert(self.badgeMock.callSetBadge.wasNotCalled)
    }

    func testProvidingACollapseIdShouldTriggerCleaningNotificationWithTheProvidedId() {
        let expectedId = String.randomString(Int.random(in: 1..<32))
        sut.update(with: ["collapseID": expectedId])
        XCTAssert(self.ncMock.callRemove.capturedArguments.first!.value.contains(expectedId))
        XCTAssert(self.ncMock.callRemove.wasCalledExactlyOnce)
    }

    func testProvidingACollapseIdWithoutAUIDShouldUpdateNotificationCenterWithoutUpdatingBadge() {
        let expectedId = String.randomString(Int.random(in: 1..<32))
        sut.update(with: ["collapseID": expectedId])
        XCTAssert(self.ncMock.callRemove.capturedArguments.first!.value.contains(expectedId))
        XCTAssert(self.ncMock.callRemove.wasCalledExactlyOnce)
        XCTAssert(self.badgeMock.callSetBadge.wasNotCalled)
    }

    func testProvidingAUIDWithNoCountShouldUpdateNothing() {
        let expectedUID = String.randomString(Int.random(in: 1..<32))
        userSessionMock.primaryUserSessionId = expectedUID
        sut.update(with: ["UID": expectedUID])
        XCTAssert(self.ncMock.callRemove.wasNotCalled)
        XCTAssert(self.badgeMock.callSetBadge.wasNotCalled)
    }

    func testProvidingAUIDWithViewModeConversationAndUnreadConversationsShouldSetBadgeToTheRightValue() {
        let expectedUID = String.randomString(Int.random(in: 1..<32))
        let unreadCount = Int.random(in: 0..<100)
        userSessionMock.primaryUserSessionId = expectedUID
        sut.update(with: ["collapseID": String.randomString(Int.random(in: 1..<32)), "UID": expectedUID, "viewMode": 0, "unreadConversations": unreadCount])
        XCTAssert(self.badgeMock.callSetBadge.wasCalledExactlyOnce)
        XCTAssertEqual(self.badgeMock.callSetBadge.lastArguments?.value, unreadCount)
    }

    func testProvidingAUIDWithViewModeMessagesAndUnreadMessagesShouldSetBadgeToTheRightValue() {
        let expectedUID = String.randomString(Int.random(in: 1..<32))
        let unreadCount = Int.random(in: 0..<100)
        userSessionMock.primaryUserSessionId = expectedUID
        sut.update(with: ["collapseID": String.randomString(Int.random(in: 1..<32)), "UID": expectedUID, "viewMode": 1, "unreadMessages": unreadCount])
        XCTAssert(self.badgeMock.callSetBadge.wasCalledExactlyOnce)
        XCTAssertEqual(self.badgeMock.callSetBadge.lastArguments?.value, unreadCount)
    }

    func testProvidingAUIDWithViewModeConversationAndUnreadMessagesShouldNotUpdateBadge() {
        let expectedUID = String.randomString(Int.random(in: 1..<32))
        let unreadCount = Int.random(in: 0..<100)
        userSessionMock.primaryUserSessionId = expectedUID
        sut.update(with: ["UID": expectedUID, "viewMode": 0, "unreadMessages": unreadCount])
        XCTAssert(self.badgeMock.callSetBadge.wasNotCalled)
    }

    func testProvidingAUIDWithViewModeMessagesAndUnreadConversationShouldNotUpdateBadge() {
        let expectedUID = String.randomString(Int.random(in: 1..<32))
        let unreadCount = Int.random(in: 0..<100)
        userSessionMock.primaryUserSessionId = expectedUID
        sut.update(with: ["UID": expectedUID, "viewMode": 1, "unreadConversations": unreadCount])
        XCTAssert(self.badgeMock.callSetBadge.wasNotCalled)
    }
}
