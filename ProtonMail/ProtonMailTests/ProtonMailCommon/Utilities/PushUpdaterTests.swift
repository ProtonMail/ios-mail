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

final class NotificationCenterMock: NotificationCenterProtocol {
    var removedIdentifiers: [String] = []
    var removeDeliveredNotificationsCallCount = 0
    func removeDeliveredNotifications(withIdentifiers identifiers: [String]) {
        removedIdentifiers.append(contentsOf: identifiers)
        removeDeliveredNotificationsCallCount += 1
    }
}

final class BadgeMock: UIApplicationBadgeProtocol {
    var badgeValue: Int?
    var setBadgeCallCount = 0
    func setBadge(badge: Int) {
        badgeValue = badge
        setBadgeCallCount += 1
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

final class PushUpdaterTest: XCTestCase {
    var sut: PushUpdater!
    var ncMock: NotificationCenterMock!
    var badgeMock: BadgeMock!
    var userSessionMock: UserSessionMock!

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
        XCTAssertEqual(ncMock.removeDeliveredNotificationsCallCount, 0)
        XCTAssertEqual(badgeMock.setBadgeCallCount, 0)
    }

    func testProvidingACollapseIdShouldTriggerCleaningNotificationWithTheProvidedId() {
        let expectedId = String.randomString(Int.random(in: 1..<32))
        sut.update(with: ["collapseID": expectedId])
        XCTAssert(ncMock.removedIdentifiers.contains(expectedId))
        XCTAssertEqual(ncMock.removeDeliveredNotificationsCallCount, 1)
    }

    func testProvidingACollapseIdWithoutAUIDShouldUpdateNotificationCenterWithoutUpdatingBadge() {
        let expectedId = String.randomString(Int.random(in: 1..<32))
        sut.update(with: ["collapseID": expectedId])
        XCTAssert(ncMock.removedIdentifiers.contains(expectedId))
        XCTAssertEqual(ncMock.removeDeliveredNotificationsCallCount, 1)
        XCTAssertEqual(badgeMock.setBadgeCallCount, 0)
    }

    func testProvidingAUIDWithNoCountShouldUpdateNothing() {
        let expectedUID = String.randomString(Int.random(in: 1..<32))
        userSessionMock.primaryUserSessionId = expectedUID
        sut.update(with: ["UID": expectedUID])
        XCTAssertEqual(ncMock.removeDeliveredNotificationsCallCount, 0)
        XCTAssertEqual(badgeMock.setBadgeCallCount, 0)
    }

    func testProvidingAUIDWithViewModeConversationAndUnreadConversationsShouldSetBadgeToTheRightValue() {
        let expectedUID = String.randomString(Int.random(in: 1..<32))
        let unreadCount = Int.random(in: 0..<100)
        userSessionMock.primaryUserSessionId = expectedUID
        sut.update(with: ["UID": expectedUID, "viewMode": 0, "unreadConversations": unreadCount])
        XCTAssertEqual(badgeMock.setBadgeCallCount, 1)
        XCTAssertEqual(badgeMock.badgeValue, unreadCount)
    }

    func testProvidingAUIDWithViewModeMessagesAndUnreadMessagesShouldSetBadgeToTheRightValue() {
        let expectedUID = String.randomString(Int.random(in: 1..<32))
        let unreadCount = Int.random(in: 0..<100)
        userSessionMock.primaryUserSessionId = expectedUID
        sut.update(with: ["UID": expectedUID, "viewMode": 1, "unreadMessages": unreadCount])
        XCTAssertEqual(badgeMock.setBadgeCallCount, 1)
        XCTAssertEqual(badgeMock.badgeValue, unreadCount)
    }

    func testProvidingAUIDWithViewModeConversationAndUnreadMessagesShouldNotUpdateBadge() {
        let expectedUID = String.randomString(Int.random(in: 1..<32))
        let unreadCount = Int.random(in: 0..<100)
        userSessionMock.primaryUserSessionId = expectedUID
        sut.update(with: ["UID": expectedUID, "viewMode": 0, "unreadMessages": unreadCount])
        XCTAssertEqual(badgeMock.setBadgeCallCount, 0)
    }

    func testProvidingAUIDWithViewModeMessagesAndUnreadConversationShouldNotUpdateBadge() {
        let expectedUID = String.randomString(Int.random(in: 1..<32))
        let unreadCount = Int.random(in: 0..<100)
        userSessionMock.primaryUserSessionId = expectedUID
        sut.update(with: ["UID": expectedUID, "viewMode": 1, "unreadConversations": unreadCount])
        XCTAssertEqual(badgeMock.setBadgeCallCount, 0)
    }
}
