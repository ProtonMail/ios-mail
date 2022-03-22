//
//  CacheServiceTests+UnreadCounter.swift
//  ProtonMailTests
//
//  Copyright (c) 2021 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import XCTest
@testable import ProtonMail

extension CacheServiceTest {
    func testUpdateCounterSyncOnMessage() {
        let labelIDs: [String] = self.testMessage.getLabelIDs()

        for label in labelIDs {
            loadTestDataOfUnreadCount(defaultUnreadCount: 1, labelID: label)
        }

        sut.updateCounterSync(markUnRead: false, on: self.testMessage, context: testContext)

        for label in labelIDs {
            let msgUnReadCount: Int = lastUpdatedStore.unreadCount(by: label, userID: sut.userID, type: .singleMessage)
            XCTAssertEqual(msgUnReadCount, 0)

            let conversationUnReadCount: Int = lastUpdatedStore.unreadCount(by: label, userID: sut.userID, type: .conversation)
            XCTAssertEqual(conversationUnReadCount, 0)
        }
    }

    func testMinusUnreadOnMessageWithWrongUnreadData() {
        let labelIDs: [String] = self.testMessage.getLabelIDs()

        for label in labelIDs {
            loadTestDataOfUnreadCount(defaultUnreadCount: 0, labelID: label)
        }

        sut.updateCounterSync(markUnRead: false, on: self.testMessage, context: testContext)

        for label in labelIDs {
            let msgUnReadCount: Int = lastUpdatedStore.unreadCount(by: label, userID: sut.userID, type: .singleMessage)
            XCTAssertEqual(msgUnReadCount, 0)

            let conversationUnReadCount: Int = lastUpdatedStore.unreadCount(by: label, userID: sut.userID, type: .conversation)
            XCTAssertEqual(conversationUnReadCount, 0)
        }
    }

    func testPlusUnreadOnOneLabel() {
        loadTestDataOfUnreadCount(defaultUnreadCount: 1, labelID: "0")

        sut.updateCounterSync(plus: true, with: "0", context: testContext)

        let msgCount: Int = lastUpdatedStore.unreadCount(by: "0", userID: sut.userID, type: .singleMessage)
        XCTAssertEqual(msgCount, 2)

        let conversationCount: Int = lastUpdatedStore.unreadCount(by: "0", userID: sut.userID, type: .conversation)
        XCTAssertEqual(conversationCount, 2)
    }

    func testMinusUnreadOnOneLabel() {
        loadTestDataOfUnreadCount(defaultUnreadCount: 1, labelID: "0")

        sut.updateCounterSync(plus: false, with: "0", context: testContext)

        let msgCount: Int = lastUpdatedStore.unreadCount(by: "0", userID: sut.userID, type: .singleMessage)
        XCTAssertEqual(msgCount, 0)

        let conversationCount: Int = lastUpdatedStore.unreadCount(by: "0", userID: sut.userID, type: .conversation)
        XCTAssertEqual(conversationCount, 0)
    }

    func testMinusUnreadOnLabelWithZeroUnread() {
        loadTestDataOfUnreadCount(defaultUnreadCount: 0, labelID: "0")

        sut.updateCounterSync(plus: false, with: "0", context: testContext)

        let msgCount: Int = lastUpdatedStore.unreadCount(by: "0", userID: sut.userID, type: .singleMessage)
        XCTAssertEqual(msgCount, 0)

        let conversationCount: Int = lastUpdatedStore.unreadCount(by: "0", userID: sut.userID, type: .conversation)
        XCTAssertEqual(conversationCount, 0)
    }

    func testDeleteSoftDeleteOnAttachment() {
        let attID = "attID"
        let attachment = Attachment(context: testContext)
        attachment.attachmentID = attID
        attachment.fileName = "filename"
        attachment.mimeType = "image"
        attachment.fileData = nil
        attachment.fileSize = 1
        attachment.isTemp = false
        attachment.keyPacket = ""
        attachment.localURL = nil
        attachment.message = testMessage
        _ = testContext.saveUpstreamIfNeeded()

        let expect = expectation(description: "attachment delete completion")
        sut.delete(attachment: attachment) {
            expect.fulfill()
        }
        wait(for: [expect], timeout: 1)

        let att = Attachment.attachment(for: attID, inManagedObjectContext: testContext)
        do {
            let unwarpAtt = try XCTUnwrap(att)
            XCTAssertTrue(unwarpAtt.isSoftDeleted)
        } catch {
            XCTFail()
        }
    }

    func testUpdateUnreadLastUpdateTime() {
        let startDate = Date(timeIntervalSince1970: 1613816451)
        let endDate = Date(timeIntervalSince1970: 1614162051)
        sut.updateLastUpdatedTime(labelID: "02", isUnread: true, startTime: startDate, endTime: endDate, msgCount: 10, msgType: .singleMessage)

        var dataToCheck = self.lastUpdatedStore.lastUpdate(by: "02", userID: sut.userID, context: testContext, type: .singleMessage)!
        XCTAssertFalse(dataToCheck.isUnreadNew)
        XCTAssertEqual(dataToCheck.unreadStart, startDate)
        XCTAssertEqual(dataToCheck.unreadEnd, endDate)

        let laterEndDate = endDate.addingTimeInterval(10000)
        sut.updateLastUpdatedTime(labelID: "02", isUnread: true, startTime: startDate, endTime: laterEndDate, msgCount: 20, msgType: .singleMessage)

        dataToCheck = self.lastUpdatedStore.lastUpdate(by: "02", userID: sut.userID, context: testContext, type: .singleMessage)!
        XCTAssertFalse(dataToCheck.isUnreadNew)
        XCTAssertEqual(dataToCheck.unreadStart, startDate)
        XCTAssertEqual(dataToCheck.unreadEnd, endDate)

        let earlierEndDate = endDate.addingTimeInterval(-10000)
        sut.updateLastUpdatedTime(labelID: "02", isUnread: true, startTime: startDate, endTime: earlierEndDate, msgCount: 20, msgType: .singleMessage)

        dataToCheck = self.lastUpdatedStore.lastUpdate(by: "02", userID: sut.userID, context: testContext, type: .singleMessage)!
        XCTAssertFalse(dataToCheck.isUnreadNew)
        XCTAssertEqual(dataToCheck.unreadStart, startDate)
        XCTAssertEqual(dataToCheck.unreadEnd, earlierEndDate)
    }

    func testUpdateReadLastUpdateTime() {
        let startDate = Date(timeIntervalSince1970: 1613816451)
        let endDate = Date(timeIntervalSince1970: 1614162051)
        sut.updateLastUpdatedTime(labelID: "02", isUnread: false, startTime: startDate, endTime: endDate, msgCount: 10, msgType: .singleMessage)

        var dataToCheck = self.lastUpdatedStore.lastUpdate(by: "02", userID: sut.userID, context: testContext, type: .singleMessage)!
        XCTAssertFalse(dataToCheck.isNew)
        XCTAssertEqual(dataToCheck.start, startDate)
        XCTAssertEqual(dataToCheck.end, endDate)
        XCTAssertEqual(dataToCheck.total, 10)

        let laterEndDate = endDate.addingTimeInterval(10000)
        sut.updateLastUpdatedTime(labelID: "02", isUnread: false, startTime: startDate, endTime: laterEndDate, msgCount: 20, msgType: .singleMessage)

        dataToCheck = self.lastUpdatedStore.lastUpdate(by: "02", userID: sut.userID, context: testContext, type: .singleMessage)!
        XCTAssertFalse(dataToCheck.isNew)
        XCTAssertEqual(dataToCheck.start, startDate)
        XCTAssertEqual(dataToCheck.end, endDate)

        let earlierEndDate = endDate.addingTimeInterval(-10000)
        sut.updateLastUpdatedTime(labelID: "02", isUnread: false, startTime: startDate, endTime: earlierEndDate, msgCount: 20, msgType: .singleMessage)

        dataToCheck = self.lastUpdatedStore.lastUpdate(by: "02", userID: sut.userID, context: testContext, type: .singleMessage)!
        XCTAssertFalse(dataToCheck.isNew)
        XCTAssertEqual(dataToCheck.start, startDate)
        XCTAssertEqual(dataToCheck.end, earlierEndDate)
    }
}
