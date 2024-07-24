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

class LocalNotificationServiceTests: XCTestCase {

    var sut: LocalNotificationService!
    var notificationHandlerMock: MockNotificationHandler!
    var userID: UserID = "sdifosnvdnoids"

    private var messageID: MessageID!

    override func setUp() {
        super.setUp()
        notificationHandlerMock = MockNotificationHandler()
        sut = LocalNotificationService(userID: self.userID, notificationHandler: self.notificationHandlerMock)
        messageID = .init(.randomString(20))
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
        notificationHandlerMock = nil
        messageID = nil
    }

    func testShowSessionRevokeNotification() throws {
        sut.showSessionRevokeNotification(email: "test@test.com")

        XCTAssertTrue(notificationHandlerMock.addStub.wasCalledExactlyOnce)
        let argument = try XCTUnwrap(notificationHandlerMock.addStub.lastArguments)
        let content = argument.first.content
        XCTAssertEqual(content.title, String(format: LocalString._token_revoke_noti_title, "test@test.com"))
        XCTAssertEqual(content.body, LocalString._token_revoke_noti_body)
        XCTAssertEqual(content.userInfo["category"] as? String, LocalNotificationService.Categories.sessionRevoked.rawValue)
        XCTAssertEqual(content.userInfo["localNotification"] as? Bool, true)
    }

    func testScheduleMessageSendingFailedNotification() throws {
        let detail = LocalNotificationService.MessageSendingDetails(messageID: messageID, subtitle: String.randomString(20))
        sut.scheduleMessageSendingFailedNotification(detail)

        XCTAssertTrue(notificationHandlerMock.addStub.wasCalledExactlyOnce)
        let argument = try XCTUnwrap(notificationHandlerMock.addStub.lastArguments)
        let content = argument.first.content
        XCTAssertEqual(content.title, "⚠️ " + LocalString._message_not_sent_title)
        XCTAssertEqual(content.subtitle, detail.subtitle)
        XCTAssertEqual(content.body, detail.error)
        XCTAssertEqual(content.categoryIdentifier, LocalNotificationService.Categories.failedToSend.rawValue)
        XCTAssertEqual(content.userInfo["message_id"] as? String, detail.messageID.rawValue)
        XCTAssertEqual(content.userInfo["category"] as? String, LocalNotificationService.Categories.failedToSend.rawValue)
        XCTAssertEqual(content.userInfo["localNotification"] as? Bool, true)

        let trigger = try XCTUnwrap(argument.first.trigger as? UNTimeIntervalNotificationTrigger)
        XCTAssertFalse(trigger.repeats)
        XCTAssertEqual(trigger.timeInterval, detail.timeInterval)
    }

    func testUnscheduleMessageSendingFailedNotification() throws {
        let detail = LocalNotificationService.MessageSendingDetails(messageID: messageID, subtitle: String.randomString(20))
        sut.unscheduleMessageSendingFailedNotification(detail)

        XCTAssertTrue(notificationHandlerMock.removePendingNotificationRequestsStub.wasCalledExactlyOnce)

        let argument = try XCTUnwrap(notificationHandlerMock.removePendingNotificationRequestsStub.lastArguments)
        XCTAssertEqual(argument.a1, [detail.messageID.rawValue])
    }

    func testCleanUp() {
        let content = UNMutableNotificationContent()
        content.userInfo = ["user_id": self.userID]
        let id = UUID().uuidString
        let request = UNNotificationRequest(identifier: id, content: content, trigger: nil)
        notificationHandlerMock.getPendingNotificationRequestsStub.bodyIs { _, callBack in
            callBack([request])
        }
        notificationHandlerMock.getDeliveredNotificationsStub.bodyIs { _, callBack in
            callBack([])
        }
        let expectation1 = expectation(description: "Closure is called")

        sut.cleanUp {
            XCTAssertTrue(self.notificationHandlerMock.getPendingNotificationRequestsStub.wasCalledExactlyOnce)
            XCTAssertTrue(self.notificationHandlerMock.removePendingNotificationRequestsStub.wasCalledExactlyOnce)
            XCTAssertTrue(self.notificationHandlerMock.getDeliveredNotificationsStub.wasCalledExactlyOnce)
            XCTAssertTrue(self.notificationHandlerMock.removeDeliveredNotificationsStub.wasCalledExactlyOnce)
            expectation1.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }
}
