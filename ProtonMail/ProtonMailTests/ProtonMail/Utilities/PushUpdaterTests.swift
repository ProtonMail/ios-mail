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
import ProtonCoreTestingToolkitUnitTestsCore

final class BadgeMock: UIApplicationBadgeProtocol {
    @FuncStub(BadgeMock.setBadge) var callSetBadge
    func setBadge(badge: Int) {
        callSetBadge(badge)
    }
}

final class PushUpdaterTests: XCTestCase {
    private var sut: PushUpdater!
    private var ncMock: MockUserNotificationCenterProtocol!
    private var badgeMock: BadgeMock!
    private var userDefaults: UserDefaults!

    override func setUp() {
        super.setUp()
        ncMock = .init()
        badgeMock = BadgeMock()
        userDefaults = TestContainer().userDefaults
        sut = PushUpdater(notificationCenter: ncMock,
                          application: badgeMock,
                          userDefaults: userDefaults)
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
        ncMock = nil
        badgeMock = nil
        userDefaults = nil
    }

    func testNotProvidingACollapseIdShouldTriggerNothing() {
        sut.update(with: [:])
        XCTAssert(self.ncMock.removeDeliveredNotificationsStub.wasNotCalled)
        XCTAssert(self.badgeMock.callSetBadge.wasNotCalled)
    }

    func testProvidingACollapseIdShouldTriggerCleaningNotificationWithTheProvidedId() {
        let expectedId = String.randomString(Int.random(in: 1..<32))
        sut.update(with: ["collapseID": expectedId])
        XCTAssert(self.ncMock.removeDeliveredNotificationsStub.capturedArguments.first!.value.contains(expectedId))
        XCTAssert(self.ncMock.removeDeliveredNotificationsStub.wasCalledExactlyOnce)
    }

    func testProvidingACollapseIdWithoutAUIDShouldUpdateNotificationCenterWithoutUpdatingBadge() {
        let expectedId = String.randomString(Int.random(in: 1..<32))
        sut.update(with: ["collapseID": expectedId])
        XCTAssert(self.ncMock.removeDeliveredNotificationsStub.capturedArguments.first!.value.contains(expectedId))
        XCTAssert(self.ncMock.removeDeliveredNotificationsStub.wasCalledExactlyOnce)
        XCTAssert(self.badgeMock.callSetBadge.wasNotCalled)
    }

    func testProvidingAUIDWithNoCountShouldUpdateNothing() {
        let expectedUID = String.randomString(Int.random(in: 1..<32))
        userDefaults[.primaryUserSessionId] = expectedUID
        sut.update(with: ["UID": expectedUID])
        XCTAssert(self.ncMock.removeDeliveredNotificationsStub.wasNotCalled)
        XCTAssert(self.badgeMock.callSetBadge.wasNotCalled)
    }

    func testProvidingAUIDWithViewModeConversationAndUnreadConversationsShouldSetBadgeToTheRightValue() {
        let expectedUID = String.randomString(Int.random(in: 1..<32))
        let unreadCount = Int.random(in: 0..<100)
        userDefaults[.primaryUserSessionId] = expectedUID
        sut.update(with: ["collapseID": String.randomString(Int.random(in: 1..<32)), "UID": expectedUID, "viewMode": 0, "unreadConversations": unreadCount])
        XCTAssert(self.badgeMock.callSetBadge.wasCalledExactlyOnce)
        XCTAssertEqual(self.badgeMock.callSetBadge.lastArguments?.value, unreadCount)
    }

    func testProvidingAUIDWithViewModeMessagesAndUnreadMessagesShouldSetBadgeToTheRightValue() {
        let expectedUID = String.randomString(Int.random(in: 1..<32))
        let unreadCount = Int.random(in: 0..<100)
        userDefaults[.primaryUserSessionId] = expectedUID
        sut.update(with: ["collapseID": String.randomString(Int.random(in: 1..<32)), "UID": expectedUID, "viewMode": 1, "unreadMessages": unreadCount])
        XCTAssert(self.badgeMock.callSetBadge.wasCalledExactlyOnce)
        XCTAssertEqual(self.badgeMock.callSetBadge.lastArguments?.value, unreadCount)
    }

    func testProvidingAUIDWithViewModeConversationAndUnreadMessagesShouldNotUpdateBadge() {
        let expectedUID = String.randomString(Int.random(in: 1..<32))
        let unreadCount = Int.random(in: 0..<100)
        userDefaults[.primaryUserSessionId] = expectedUID
        sut.update(with: ["UID": expectedUID, "viewMode": 0, "unreadMessages": unreadCount])
        XCTAssert(self.badgeMock.callSetBadge.wasNotCalled)
    }

    func testProvidingAUIDWithViewModeMessagesAndUnreadConversationShouldNotUpdateBadge() {
        let expectedUID = String.randomString(Int.random(in: 1..<32))
        let unreadCount = Int.random(in: 0..<100)
        userDefaults[.primaryUserSessionId] = expectedUID
        sut.update(with: ["UID": expectedUID, "viewMode": 1, "unreadConversations": unreadCount])
        XCTAssert(self.badgeMock.callSetBadge.wasNotCalled)
    }
}
