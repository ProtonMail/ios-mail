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
    var userID: String = "sdifosnvdnoids"

    override func setUp() {
        super.setUp()
        notificationHandlerMock = MockNotificationHandler()
        sut = LocalNotificationService(userID: self.userID, notificationHandler: self.notificationHandlerMock)
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
        notificationHandlerMock = nil
    }

    func testShowSessionRevokeNotification() throws {
        sut.showSessionRevokeNotification(email: "test@test.com")

        XCTAssertTrue(notificationHandlerMock.callAdd.wasCalledExactlyOnce)
        let argument = try XCTUnwrap(notificationHandlerMock.callAdd.lastArguments)
        let content = argument.first.content
        XCTAssertEqual(content.title, String(format: LocalString._token_revoke_noti_title, "test@test.com"))
        XCTAssertEqual(content.body, LocalString._token_revoke_noti_body)
        XCTAssertEqual(content.userInfo["category"] as? String, LocalNotificationService.Categories.sessionRevoked.rawValue)
        XCTAssertEqual(content.userInfo["localNotification"] as? Bool, true)
    }

    func testScheduleMessageSendingFailedNotification() throws {
        let detail = LocalNotificationService.MessageSendingDetails(messageID: String.randomString(20), subtitle: String.randomString(20))
        sut.scheduleMessageSendingFailedNotification(detail)

        XCTAssertTrue(notificationHandlerMock.callAdd.wasCalledExactlyOnce)
        let argument = try XCTUnwrap(notificationHandlerMock.callAdd.lastArguments)
        let content = argument.first.content
        XCTAssertEqual(content.title, "⚠️ " + LocalString._message_not_sent_title)
        XCTAssertEqual(content.subtitle, detail.subtitle)
        XCTAssertEqual(content.body, detail.error)
        XCTAssertEqual(content.categoryIdentifier, LocalNotificationService.Categories.failedToSend.rawValue)
        XCTAssertEqual(content.userInfo["message_id"] as? String, detail.messageID)
        XCTAssertEqual(content.userInfo["category"] as? String, LocalNotificationService.Categories.failedToSend.rawValue)
        XCTAssertEqual(content.userInfo["localNotification"] as? Bool, true)

        let trigger = try XCTUnwrap(argument.first.trigger as? UNTimeIntervalNotificationTrigger)
        XCTAssertFalse(trigger.repeats)
        XCTAssertEqual(trigger.timeInterval, detail.timeInterval)
    }

    func testUnscheduleMessageSendingFailedNotification() throws {
        let detail = LocalNotificationService.MessageSendingDetails(messageID: String.randomString(20), subtitle: String.randomString(20))
        sut.unscheduleMessageSendingFailedNotification(detail)

        XCTAssertTrue(notificationHandlerMock.callRemovePendingNoti.wasCalledExactlyOnce)

        let argument = try XCTUnwrap(notificationHandlerMock.callRemovePendingNoti.lastArguments)
        XCTAssertEqual(argument.a1, [detail.messageID])
    }

    func testRescheduleMessage() {
        let id = UUID().uuidString
        let content = UNNotificationContent()
        let detail = LocalNotificationService.MessageSendingDetails(messageID: String.randomString(20), subtitle: String.randomString(20))
        notificationHandlerMock.callGetPendingReqs.bodyIs { _, callBack in
            let request = UNNotificationRequest(identifier: id, content: content, trigger: nil)
            callBack([request])
        }
        let expectation1 = expectation(description: "Closure is called")

        sut.rescheduleMessage(oldID: id, details: detail) {
            XCTAssertTrue(self.notificationHandlerMock.callGetPendingReqs.wasCalledExactlyOnce)
            XCTAssertTrue(self.notificationHandlerMock.callRemovePendingNoti.wasCalledExactlyOnce)
            XCTAssertTrue(self.notificationHandlerMock.callAdd.wasCalledExactlyOnce)
            do {
                let argument1 = try XCTUnwrap(self.notificationHandlerMock.callRemovePendingNoti.lastArguments)
                XCTAssertEqual(argument1.a1, [id])

                let argument2 = try XCTUnwrap(self.notificationHandlerMock.callAdd.lastArguments)
                let content = argument2.first.content
                XCTAssertEqual(content.title, "⚠️ " + LocalString._message_not_sent_title)
                XCTAssertEqual(content.subtitle, detail.subtitle)
                XCTAssertEqual(content.body, detail.error)
                XCTAssertEqual(content.categoryIdentifier, LocalNotificationService.Categories.failedToSend.rawValue)
                XCTAssertEqual(content.userInfo["message_id"] as? String, detail.messageID)
                XCTAssertEqual(content.userInfo["category"] as? String, LocalNotificationService.Categories.failedToSend.rawValue)

                let trigger = try XCTUnwrap(argument2.first.trigger as? UNTimeIntervalNotificationTrigger)
                XCTAssertFalse(trigger.repeats)
                XCTAssertEqual(trigger.timeInterval, detail.timeInterval)
            } catch {

            }
            expectation1.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testCleanUp() {
        let content = UNMutableNotificationContent()
        content.userInfo = ["user_id": self.userID]
        let id = UUID().uuidString
        let request = UNNotificationRequest(identifier: id, content: content, trigger: nil)
        notificationHandlerMock.callGetPendingReqs.bodyIs { _, callBack in
            callBack([request])
        }
        notificationHandlerMock.callGetDelivered.bodyIs { _, callBack in
            callBack([])
        }
        let expectation1 = expectation(description: "Closure is called")

        sut.cleanUp {
            XCTAssertTrue(self.notificationHandlerMock.callGetPendingReqs.wasCalledExactlyOnce)
            XCTAssertTrue(self.notificationHandlerMock.callRemovePendingNoti.wasCalledExactlyOnce)
            XCTAssertTrue(self.notificationHandlerMock.callGetDelivered.wasCalledExactlyOnce)
            XCTAssertTrue(self.notificationHandlerMock.callRemoveDelivered.wasCalledExactlyOnce)
            expectation1.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }
}
