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

@testable import ProtonMail
import XCTest

final class LastUpdatedStoreTests: XCTestCase {

    var sut: LastUpdatedStore!
    var contextProviderMock: MockCoreDataContextProvider!
    let labelID: LabelID = "label1"
    let userID: UserID = "user1"

    override func setUp() {
        super.setUp()
        contextProviderMock = MockCoreDataContextProvider()
        sut = LastUpdatedStore(contextProvider: contextProviderMock)
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
        contextProviderMock = nil
    }

    func testLastUpdateDefault_fetchLabelHasNoDataInCache_singleMessage_returnNewlyCreatedDataWithDefaultValue() {
        let result = sut.lastUpdateDefault(by: labelID, userID: userID, type: .singleMessage)

        XCTAssertEqual(result.start, Date.distantPast)
        XCTAssertEqual(result.end, Date.distantPast)
        XCTAssertEqual(result.update, Date.distantPast)
        XCTAssertEqual(result.total, 0)
        XCTAssertEqual(result.unread, 0)
    }

    func testLastUpdateDefault_fetchLabelHasDataInCache_singleMessage_returnDataIntTheCache() {
        let startDate = Date()
        let endDate = Date().addingTimeInterval(-10)
        let updateDate = Date()
        let total = 1000
        let unread = 500
        prepareLabelUpdateTestData(labelID: labelID, start: startDate, end: endDate, update: updateDate, total: total, unread: unread, userID: userID)

        let result = sut.lastUpdateDefault(by: labelID, userID: userID, type: .singleMessage)

        XCTAssertEqual(result.start, startDate)
        XCTAssertEqual(result.end, endDate)
        XCTAssertEqual(result.update, updateDate)
        XCTAssertEqual(result.total, total)
        XCTAssertEqual(result.unread, unread)
    }

    func testLastUpdate_fetchLabelHasNoDataInCache_singleMessage_returnNil() {
        XCTAssertNil(sut.lastUpdate(by: labelID, userID: userID, type: .singleMessage))
    }

    func testLastUpdate_fetchLabelHasDataInCache_singleMessage_returnDataIntTheCache() throws {
        let startDate = Date()
        let endDate = Date().addingTimeInterval(-10)
        let updateDate = Date()
        let total = 1000
        let unread = 500
        prepareLabelUpdateTestData(labelID: labelID, start: startDate, end: endDate, update: updateDate, total: total, unread: unread, userID: userID)

        let result = try XCTUnwrap(sut.lastUpdate(by: labelID, userID: userID, type: .singleMessage))

        XCTAssertEqual(result.start, startDate)
        XCTAssertEqual(result.end, endDate)
        XCTAssertEqual(result.update, updateDate)
        XCTAssertEqual(result.total, total)
        XCTAssertEqual(result.unread, unread)
    }

    // MARK: - updateLastUpdatedTime tests

    func testUpdateLastUpdatedTime_withNoDataInCache_singleMessage_updateReadCount_dataIsCreatedInCache() throws {
        let startDate = Date()
        let endDate = Date().addingTimeInterval(-10)
        let count = 99
        sut.updateLastUpdatedTime(labelID: labelID,
                                  isUnread: false,
                                  startTime: startDate,
                                  endTime: endDate,
                                  msgCount: count,
                                  userID: userID, type: .singleMessage)

        let data = try XCTUnwrap(sut.lastUpdate(by: labelID, userID: userID, type: .singleMessage))
        XCTAssertEqual(data.start, startDate)
        XCTAssertEqual(data.total, count)
        XCTAssertEqual(data.end, endDate)
        XCTAssertNotNil(data.update)
        XCTAssertNil(data.unreadStart)
        XCTAssertNil(data.unreadEnd)
        XCTAssertNil(data.unreadUpdate)
    }

    func testUpdateLastUpdatedTime_singleMessage_withEarlierEndDate_endDateIsUpdated() throws {
        let startDate = Date()
        let endDate = Date().addingTimeInterval(-10)
        let earlierEndDate = endDate.addingTimeInterval(-1000)
        let count = 99
        prepareLabelUpdateTestData(labelID: labelID, start: startDate, end: endDate, update: Date(), total: count, unread: 0, userID: userID)

        sut.updateLastUpdatedTime(labelID: labelID,
                                  isUnread: false,
                                  startTime: startDate,
                                  endTime: earlierEndDate,
                                  msgCount: count,
                                  userID: userID, type: .singleMessage)

        let data = try XCTUnwrap(sut.lastUpdate(by: labelID, userID: userID, type: .singleMessage))
        XCTAssertEqual(data.start, startDate)
        XCTAssertEqual(data.total, count)
        XCTAssertEqual(data.end, earlierEndDate)
        XCTAssertNotNil(data.update)
        XCTAssertNil(data.unreadStart)
        XCTAssertNil(data.unreadEnd)
        XCTAssertNil(data.unreadUpdate)
    }

    func testUpdateLastUpdatedTime_singleMessage_withLaterEndDate_endDateIsNotUpdated() throws {
        let startDate = Date()
        let endDate = Date().addingTimeInterval(-10)
        let laterEndDate = endDate.addingTimeInterval(1000)
        let count = 99
        prepareLabelUpdateTestData(labelID: labelID, start: startDate, end: endDate, update: Date(), total: count, unread: 0, userID: userID)

        sut.updateLastUpdatedTime(labelID: labelID,
                                  isUnread: false,
                                  startTime: startDate,
                                  endTime: laterEndDate,
                                  msgCount: count,
                                  userID: userID, type: .singleMessage)

        let data = try XCTUnwrap(sut.lastUpdate(by: labelID, userID: userID, type: .singleMessage))
        XCTAssertEqual(data.start, startDate)
        XCTAssertEqual(data.total, count)
        XCTAssertEqual(data.end, endDate)
        XCTAssertNotNil(data.update)
        XCTAssertNil(data.unreadStart)
        XCTAssertNil(data.unreadEnd)
        XCTAssertNil(data.unreadUpdate)
    }

    func testUpdateLastUpdatedTime_singleMessage_withDifferentStartDate_startDateIsNotUpdated() throws {
        let startDate = Date()
        let endDate = Date().addingTimeInterval(-10)
        let count = 99
        prepareLabelUpdateTestData(labelID: labelID, start: startDate, end: endDate, update: Date(), total: count, unread: 0, userID: userID)

        let anotherStartDate = startDate.addingTimeInterval(400)
        sut.updateLastUpdatedTime(labelID: labelID,
                                  isUnread: false,
                                  startTime: anotherStartDate,
                                  endTime: endDate,
                                  msgCount: count,
                                  userID: userID, type: .singleMessage)

        let data = try XCTUnwrap(sut.lastUpdate(by: labelID, userID: userID, type: .singleMessage))
        XCTAssertEqual(data.start, startDate)
        XCTAssertEqual(data.total, count)
        XCTAssertEqual(data.end, endDate)
        XCTAssertNotNil(data.update)
        XCTAssertNil(data.unreadStart)
        XCTAssertNil(data.unreadEnd)
        XCTAssertNil(data.unreadUpdate)
    }

    // MARK: - updateLastUpdatedTime unread tests

    func testUpdateLastUpdatedTime_withNoDataInCache_singleMessage_updateUnreadCount_dataIsCreatedInCache() throws {
        let startDate = Date()
        let endDate = Date().addingTimeInterval(-10)
        let count = 99
        sut.updateLastUpdatedTime(labelID: labelID,
                                  isUnread: true,
                                  startTime: startDate,
                                  endTime: endDate,
                                  msgCount: count,
                                  userID: userID, type: .singleMessage)

        let data = try XCTUnwrap(sut.lastUpdate(by: labelID, userID: userID, type: .singleMessage))
        XCTAssertEqual(data.unreadStart, startDate)
        XCTAssertEqual(data.unreadEnd, endDate)
        XCTAssertNotNil(data.unreadUpdate)
        XCTAssertEqual(data.total, 0)
        XCTAssertEqual(data.start, Date.distantPast)
        XCTAssertEqual(data.end, Date.distantPast)
        XCTAssertEqual(data.update, Date.distantPast)
    }

    func testUpdateLastUpdatedTime_singleMessage_unread_withEarlierEndDate_endDateIsUpdated() throws {
        let startDate = Date()
        let endDate = Date().addingTimeInterval(-10)
        let earlierEndDate = endDate.addingTimeInterval(-1000)
        let count = 99
        prepareLabelUpdateUnreadTestData(labelID: labelID, start: startDate, end: endDate, update: Date(), total: count, unread: 0, userID: userID)

        sut.updateLastUpdatedTime(labelID: labelID,
                                  isUnread: true,
                                  startTime: startDate,
                                  endTime: earlierEndDate,
                                  msgCount: count,
                                  userID: userID, type: .singleMessage)

        let data = try XCTUnwrap(sut.lastUpdate(by: labelID, userID: userID, type: .singleMessage))
        XCTAssertEqual(data.unreadStart, startDate)
        XCTAssertEqual(data.unreadEnd, earlierEndDate)
        XCTAssertNotNil(data.unreadUpdate)
        XCTAssertEqual(data.total, count)
        XCTAssertNil(data.start)
        XCTAssertNil(data.end)
        XCTAssertNil(data.update)
    }

    func testUpdateLastUpdatedTime_singleMessage_unread_withLaterEndDate_endDateIsNotUpdated() throws {
        let startDate = Date()
        let endDate = Date().addingTimeInterval(-10)
        let laterEndDate = endDate.addingTimeInterval(1000)
        let count = 99
        prepareLabelUpdateUnreadTestData(labelID: labelID, start: startDate, end: endDate, update: Date(), total: count, unread: 0, userID: userID)

        sut.updateLastUpdatedTime(labelID: labelID,
                                  isUnread: true,
                                  startTime: startDate,
                                  endTime: laterEndDate,
                                  msgCount: count,
                                  userID: userID, type: .singleMessage)

        let data = try XCTUnwrap(sut.lastUpdate(by: labelID, userID: userID, type: .singleMessage))

        XCTAssertEqual(data.unreadStart, startDate)
        XCTAssertEqual(data.unreadEnd, endDate)
        XCTAssertNotNil(data.unreadUpdate)
        XCTAssertEqual(data.total, count)
        XCTAssertNil(data.start)
        XCTAssertNil(data.end)
        XCTAssertNil(data.update)
    }

    func testUpdateLastUpdatedTime_singleMessage_unread_withDifferentStartDate_startDateIsNotUpdated() throws {
        let startDate = Date()
        let endDate = Date().addingTimeInterval(-10)
        let count = 99
        prepareLabelUpdateUnreadTestData(labelID: labelID, start: startDate, end: endDate, update: Date(), total: count, unread: 0, userID: userID)

        let anotherStartDate = startDate.addingTimeInterval(400)
        sut.updateLastUpdatedTime(labelID: labelID,
                                  isUnread: true,
                                  startTime: anotherStartDate,
                                  endTime: endDate,
                                  msgCount: count,
                                  userID: userID, type: .singleMessage)

        let data = try XCTUnwrap(sut.lastUpdate(by: labelID, userID: userID, type: .singleMessage))

        XCTAssertEqual(data.unreadStart, startDate)
        XCTAssertEqual(data.unreadEnd, endDate)
        XCTAssertNotNil(data.unreadUpdate)
        XCTAssertEqual(data.total, count)
        XCTAssertNil(data.start)
        XCTAssertNil(data.end)
        XCTAssertNil(data.update)
    }

    // MARK: - unread count

    func testUnreadCount_singleMessage_noCacheData_getZero() {
        XCTAssertEqual(sut.unreadCount(by: labelID, userID: userID, type: .singleMessage), 0)
    }

    func testUnreadCount_singleMessage_getCorrectValue() {
        let unread = Int.random(in: 0...Int(Int32.max))
        prepareLabelUpdateTestData(labelID: labelID, start: Date(), end: Date(), update: Date(), total: Int.random(in: 0...100), unread: unread, userID: userID)

        XCTAssertEqual(sut.unreadCount(by: labelID, userID: userID, type: .singleMessage), unread)
    }

    func testUnreadCount_singleMessage_hasNegativeValue_getZero() {
        let unread = Int.random(in: Int(Int32.min)...0)
        prepareLabelUpdateTestData(labelID: labelID, start: Date(), end: Date(), update: Date(), total: Int.random(in: 0...100), unread: unread, userID: userID)

        XCTAssertEqual(sut.unreadCount(by: labelID, userID: userID, type: .singleMessage), 0)
    }

    func testUpdateUnreadCount_singleMessage_noDataInCache_createAndUpdateTheData() throws {
        let unread = 30
        let total = 50
        sut.updateUnreadCount(by: labelID, userID: userID, unread: unread, total: total, type: .singleMessage, shouldSave: true)

        let result = try XCTUnwrap(sut.lastUpdate(by: labelID, userID: userID, type: .singleMessage))
        XCTAssertEqual(result.unread, 30)
        XCTAssertEqual(result.total, total)
        XCTAssertTrue(result.isNew)
        XCTAssertTrue(result.isUnreadNew)
    }

    func testUpdateUnreadCount_singleMessage_updateDataInCache() throws {
        prepareLabelUpdateTestData(labelID: labelID, start: Date(), end: Date(), update: Date(), total: 0, unread: 0, userID: userID)

        let initialResult = try XCTUnwrap(sut.lastUpdate(by: labelID, userID: userID, type: .singleMessage))
        XCTAssertEqual(initialResult.unread, 0)
        XCTAssertEqual(initialResult.total, 0)

        let unread = 10
        let total = 100
        sut.updateUnreadCount(by: labelID, userID: userID, unread: unread, total: total, type: .singleMessage, shouldSave: true)

        let result = try XCTUnwrap(sut.lastUpdate(by: labelID, userID: userID, type: .singleMessage))
        XCTAssertEqual(result.unread, unread)
        XCTAssertEqual(result.total, total)
    }

    func testGetUnreadCounts_noDataInCache_singleMessage_returnEmpty() {
        let labelID2: LabelID = "label2"
        let expectation1 = expectation(description: "Closure is called")

        sut.getUnreadCounts(by: [labelID, labelID2], userID: userID, type: .singleMessage) { result in
            XCTAssertTrue(result.isEmpty)
            expectation1.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func testGetUnreadCounts_singleMessage_getCorrectData() {
        let labelID2: LabelID = "label2"
        prepareLabelUpdateTestData(labelID: labelID, start: Date(), end: Date(), update: Date(), total: 100, unread: 30, userID: userID)
        prepareLabelUpdateTestData(labelID: labelID2, start: Date(), end: Date(), update: Date(), total: 10, unread: 5, userID: userID)
        let expectation1 = expectation(description: "Closure is called")

        sut.getUnreadCounts(by: [labelID, labelID2], userID: userID, type: .singleMessage) { result in
            XCTAssertEqual(result.count, 2)
            do {
                let labelUnread = try XCTUnwrap(result[self.labelID.rawValue])
                XCTAssertEqual(labelUnread, 30)

                let label2Unread = try XCTUnwrap(result[labelID2.rawValue])
                XCTAssertEqual(label2Unread, 5)
            } catch {
                XCTFail("Should not throw error")
            }
            expectation1.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    // MARK: reset functions

    func testResetCounter_noType_bothDataAreReset() throws {
        prepareLabelUpdateUnreadTestData(labelID: labelID, start: Date(), end: Date(), update: Date(), total: 100, unread: 100, userID: userID)
        prepareConversationCountUnreadTestData(labelID: labelID, start: Date(), end: Date(), update: Date(), total: 1000, unread: 100, userID: userID)

        sut.resetCounter(labelID: labelID, userID: userID, type: nil)

        let labelCount = try XCTUnwrap(sut.lastUpdate(by: labelID, userID: userID, type: .singleMessage))
        XCTAssertEqual(labelCount.total, 0)
        XCTAssertEqual(labelCount.unread, 0)
        XCTAssertNil(labelCount.unreadStart)
        XCTAssertNil(labelCount.unreadEnd)
        XCTAssertNil(labelCount.unreadUpdate)

        let conversationCount = try XCTUnwrap(sut.lastUpdate(by: labelID, userID: userID, type: .conversation))
        XCTAssertEqual(conversationCount.total, 0)
        XCTAssertEqual(conversationCount.unread, 0)
        XCTAssertNil(conversationCount.unreadStart)
        XCTAssertNil(conversationCount.unreadEnd)
        XCTAssertNil(conversationCount.unreadUpdate)
    }

    func testResetCounter_singleMessage_onlyResetLabelCount() throws {
        prepareLabelUpdateUnreadTestData(labelID: labelID, start: Date(), end: Date(), update: Date(), total: 100, unread: 100, userID: userID)
        prepareConversationCountUnreadTestData(labelID: labelID, start: Date(), end: Date(), update: Date(), total: 1000, unread: 100, userID: userID)

        sut.resetCounter(labelID: labelID, userID: userID, type: .singleMessage)

        let labelCount = try XCTUnwrap(sut.lastUpdate(by: labelID, userID: userID, type: .singleMessage))
        XCTAssertEqual(labelCount.total, 0)
        XCTAssertEqual(labelCount.unread, 0)
        XCTAssertNil(labelCount.unreadStart)
        XCTAssertNil(labelCount.unreadEnd)
        XCTAssertNil(labelCount.unreadUpdate)

        let conversationCount = try XCTUnwrap(sut.lastUpdate(by: labelID, userID: userID, type: .conversation))
        XCTAssertEqual(conversationCount.total, 1000)
        XCTAssertEqual(conversationCount.unread, 100)
        XCTAssertNotNil(conversationCount.unreadStart)
        XCTAssertNotNil(conversationCount.unreadEnd)
        XCTAssertNotNil(conversationCount.unreadUpdate)
    }

    func testResetCounter_conversation_onlyResetConversationCount() throws {
        prepareLabelUpdateUnreadTestData(labelID: labelID, start: Date(), end: Date(), update: Date(), total: 100, unread: 100, userID: userID)
        prepareConversationCountUnreadTestData(labelID: labelID, start: Date(), end: Date(), update: Date(), total: 1000, unread: 100, userID: userID)

        sut.resetCounter(labelID: labelID, userID: userID, type: .conversation)

        let labelCount = try XCTUnwrap(sut.lastUpdate(by: labelID, userID: userID, type: .singleMessage))
        XCTAssertEqual(labelCount.total, 100)
        XCTAssertEqual(labelCount.unread, 100)
        XCTAssertNotNil(labelCount.unreadStart)
        XCTAssertNotNil(labelCount.unreadEnd)
        XCTAssertNotNil(labelCount.unreadUpdate)

        let conversationCount = try XCTUnwrap(sut.lastUpdate(by: labelID, userID: userID, type: .conversation))
        XCTAssertEqual(conversationCount.total, 0)
        XCTAssertEqual(conversationCount.unread, 0)
        XCTAssertNil(conversationCount.unreadStart)
        XCTAssertNil(conversationCount.unreadEnd)
        XCTAssertNil(conversationCount.unreadUpdate)
    }

    // MARK: - remove data

    func testRemoveUpdateTime_singleMessage() {
        prepareLabelUpdateUnreadTestData(labelID: labelID, start: Date(), end: Date(), update: Date(), total: 100, unread: 100, userID: userID)
        prepareConversationCountUnreadTestData(labelID: labelID, start: Date(), end: Date(), update: Date(), total: 1000, unread: 100, userID: userID)

        XCTAssertNotNil(sut.lastUpdate(by: labelID, userID: userID, type: .singleMessage))
        XCTAssertNotNil(sut.lastUpdate(by: labelID, userID: userID, type: .conversation))

        sut.removeUpdateTime(by: userID, type: .singleMessage)

        XCTAssertNil(sut.lastUpdate(by: labelID, userID: userID, type: .singleMessage))
        XCTAssertNotNil(sut.lastUpdate(by: labelID, userID: userID, type: .conversation))
    }

    func testRemoveUpdateTime_conversation() {
        prepareLabelUpdateUnreadTestData(labelID: labelID, start: Date(), end: Date(), update: Date(), total: 100, unread: 100, userID: userID)
        prepareConversationCountUnreadTestData(labelID: labelID, start: Date(), end: Date(), update: Date(), total: 1000, unread: 100, userID: userID)

        XCTAssertNotNil(sut.lastUpdate(by: labelID, userID: userID, type: .singleMessage))
        XCTAssertNotNil(sut.lastUpdate(by: labelID, userID: userID, type: .conversation))

        sut.removeUpdateTime(by: userID, type: .conversation)

        XCTAssertNil(sut.lastUpdate(by: labelID, userID: userID, type: .conversation))
        XCTAssertNotNil(sut.lastUpdate(by: labelID, userID: userID, type: .singleMessage))
    }

    // MARK: - RemoveUpdateTimeExceptUnread

    func testRemoveUpdateTimeExceptUnread_singleMessage() throws {
        prepareLabelUpdateUnreadTestData(labelID: labelID, start: Date(), end: Date(), update: Date(), total: 100, unread: 100, userID: userID)
        prepareConversationCountUnreadTestData(labelID: labelID, start: Date(), end: Date(), update: Date(), total: 1000, unread: 100, userID: userID)

        sut.removeUpdateTimeExceptUnread(by: userID, type: .singleMessage)

        let labelCount = try XCTUnwrap(sut.lastUpdate(by: labelID, userID: userID, type: .singleMessage))
        XCTAssertEqual(labelCount.total, 100)
        XCTAssertEqual(labelCount.unread, 100)
        XCTAssertEqual(labelCount.start, Date.distantPast)
        XCTAssertEqual(labelCount.end, Date.distantPast)
        XCTAssertEqual(labelCount.update, Date.distantPast)
        XCTAssertEqual(labelCount.unreadStart, Date.distantPast)
        XCTAssertEqual(labelCount.unreadEnd, Date.distantPast)
        XCTAssertEqual(labelCount.unreadUpdate, Date.distantPast)

        let conversationCount = try XCTUnwrap(sut.lastUpdate(by: labelID, userID: userID, type: .conversation))
        XCTAssertEqual(conversationCount.total, 1000)
        XCTAssertEqual(conversationCount.unread, 100)
        XCTAssertNotNil(conversationCount.unreadStart)
        XCTAssertNotNil(conversationCount.unreadEnd)
        XCTAssertNotNil(conversationCount.unreadUpdate)
    }

    func testRemoveUpdateTimeExceptUnread_conversation() throws {
        prepareLabelUpdateUnreadTestData(labelID: labelID, start: Date(), end: Date(), update: Date(), total: 100, unread: 100, userID: userID)
        prepareConversationCountUnreadTestData(labelID: labelID, start: Date(), end: Date(), update: Date(), total: 1000, unread: 100, userID: userID)

        sut.removeUpdateTimeExceptUnread(by: userID, type: .conversation)

        let labelCount = try XCTUnwrap(sut.lastUpdate(by: labelID, userID: userID, type: .singleMessage))
        XCTAssertEqual(labelCount.total, 100)
        XCTAssertEqual(labelCount.unread, 100)
        XCTAssertNotNil(labelCount.unreadStart)
        XCTAssertNotNil(labelCount.unreadEnd)
        XCTAssertNotNil(labelCount.unreadUpdate)

        let conversationCount = try XCTUnwrap(sut.lastUpdate(by: labelID, userID: userID, type: .conversation))
        XCTAssertEqual(conversationCount.total, 1000)
        XCTAssertEqual(conversationCount.unread, 100)
        XCTAssertEqual(conversationCount.start, Date.distantPast)
        XCTAssertEqual(conversationCount.end, Date.distantPast)
        XCTAssertEqual(conversationCount.update, Date.distantPast)
        XCTAssertEqual(conversationCount.unreadStart, Date.distantPast)
        XCTAssertEqual(conversationCount.unreadEnd, Date.distantPast)
        XCTAssertEqual(conversationCount.unreadUpdate, Date.distantPast)
    }
}

// MARK: - conversation
extension LastUpdatedStoreTests {
    func testLastUpdateDefault_fetchLabelHasNoDataInCache_conversation_returnNewlyCreatedDataWithDefaultValue() {
        let result = sut.lastUpdateDefault(by: labelID, userID: userID, type: .conversation)

        XCTAssertEqual(result.start, Date.distantPast)
        XCTAssertEqual(result.end, Date.distantPast)
        XCTAssertEqual(result.update, Date.distantPast)
        XCTAssertEqual(result.total, 0)
        XCTAssertEqual(result.unread, 0)
    }

    func testLastUpdateDefault_fetchLabelHasDataInCache_conversation_returnDataIntTheCache() {
        let startDate = Date()
        let endDate = Date().addingTimeInterval(-10)
        let updateDate = Date()
        let total = 909
        let unread = 50
        prepareConversationCountTestData(labelID: labelID, start: startDate, end: endDate, update: updateDate, total: total, unread: unread, userID: userID)

        let result = sut.lastUpdateDefault(by: labelID, userID: userID, type: .conversation)

        XCTAssertEqual(result.start, startDate)
        XCTAssertEqual(result.end, endDate)
        XCTAssertEqual(result.update, updateDate)
        XCTAssertEqual(result.total, total)
        XCTAssertEqual(result.unread, unread)
    }

    func testLastUpdate_fetchLabelHasNoDataInCache_conversation_returnNil() {
        XCTAssertNil(sut.lastUpdate(by: labelID, userID: userID, type: .conversation))
    }

    func testLastUpdate_fetchLabelHasDataInCache_conversation_returnDataIntTheCache() throws {
        let startDate = Date()
        let endDate = Date().addingTimeInterval(-10)
        let updateDate = Date()
        let total = 909
        let unread = 50
        prepareConversationCountTestData(labelID: labelID, start: startDate, end: endDate, update: updateDate, total: total, unread: unread, userID: userID)

        let result = try XCTUnwrap(sut.lastUpdate(by: labelID, userID: userID, type: .conversation))

        XCTAssertEqual(result.start, startDate)
        XCTAssertEqual(result.end, endDate)
        XCTAssertEqual(result.update, updateDate)
        XCTAssertEqual(result.total, total)
        XCTAssertEqual(result.unread, unread)
    }

    // MARK: - updateLastUpdatedTime tests

    func testUpdateLastUpdatedTime_withNoDataInCache_conversation_updateReadCount_dataIsCreatedInCache() throws {
        let startDate = Date()
        let endDate = Date().addingTimeInterval(-10)
        let count = 99
        sut.updateLastUpdatedTime(labelID: labelID,
                                  isUnread: false,
                                  startTime: startDate,
                                  endTime: endDate,
                                  msgCount: count,
                                  userID: userID, type: .conversation)

        let data = try XCTUnwrap(sut.lastUpdate(by: labelID, userID: userID, type: .conversation))
        XCTAssertEqual(data.start, startDate)
        XCTAssertEqual(data.total, count)
        XCTAssertEqual(data.end, endDate)
        XCTAssertNotNil(data.update)
        XCTAssertNil(data.unreadStart)
        XCTAssertNil(data.unreadEnd)
        XCTAssertNil(data.unreadUpdate)
    }

    func testUpdateLastUpdatedTime_conversation_withEarlierEndDate_endDateIsUpdated() throws {
        let startDate = Date()
        let endDate = Date().addingTimeInterval(-10)
        let earlierEndDate = endDate.addingTimeInterval(-1000)
        let count = 99
        prepareConversationCountTestData(labelID: labelID, start: startDate, end: endDate, update: Date(), total: count, unread: 0, userID: userID)

        sut.updateLastUpdatedTime(labelID: labelID,
                                  isUnread: false,
                                  startTime: startDate,
                                  endTime: earlierEndDate,
                                  msgCount: count,
                                  userID: userID, type: .conversation)

        let data = try XCTUnwrap(sut.lastUpdate(by: labelID, userID: userID, type: .conversation))
        XCTAssertEqual(data.start, startDate)
        XCTAssertEqual(data.total, count)
        XCTAssertEqual(data.end, earlierEndDate)
        XCTAssertNotNil(data.update)
        XCTAssertNil(data.unreadStart)
        XCTAssertNil(data.unreadEnd)
        XCTAssertNil(data.unreadUpdate)
    }

    func testUpdateLastUpdatedTime_conversation_withLaterEndDate_endDateIsNotUpdated() throws {
        let startDate = Date()
        let endDate = Date().addingTimeInterval(-10)
        let laterEndDate = endDate.addingTimeInterval(1000)
        let count = 99
        prepareConversationCountTestData(labelID: labelID, start: startDate, end: endDate, update: Date(), total: count, unread: 0, userID: userID)

        sut.updateLastUpdatedTime(labelID: labelID,
                                  isUnread: false,
                                  startTime: startDate,
                                  endTime: laterEndDate,
                                  msgCount: count,
                                  userID: userID, type: .conversation)

        let data = try XCTUnwrap(sut.lastUpdate(by: labelID, userID: userID, type: .conversation))
        XCTAssertEqual(data.start, startDate)
        XCTAssertEqual(data.total, count)
        XCTAssertEqual(data.end, endDate)
        XCTAssertNotNil(data.update)
        XCTAssertNil(data.unreadStart)
        XCTAssertNil(data.unreadEnd)
        XCTAssertNil(data.unreadUpdate)
    }

    func testUpdateLastUpdatedTime_conversation_withDifferentStartDate_startDateIsNotUpdated() throws {
        let startDate = Date()
        let endDate = Date().addingTimeInterval(-10)
        let count = 99
        prepareConversationCountTestData(labelID: labelID, start: startDate, end: endDate, update: Date(), total: count, unread: 0, userID: userID)

        let anotherStartDate = startDate.addingTimeInterval(400)
        sut.updateLastUpdatedTime(labelID: labelID,
                                  isUnread: false,
                                  startTime: anotherStartDate,
                                  endTime: endDate,
                                  msgCount: count,
                                  userID: userID, type: .conversation)

        let data = try XCTUnwrap(sut.lastUpdate(by: labelID, userID: userID, type: .conversation))
        XCTAssertEqual(data.start, startDate)
        XCTAssertEqual(data.total, count)
        XCTAssertEqual(data.end, endDate)
        XCTAssertNotNil(data.update)
        XCTAssertNil(data.unreadStart)
        XCTAssertNil(data.unreadEnd)
        XCTAssertNil(data.unreadUpdate)
    }

    // MARK: - updateLastUpdatedTime unread tests

    func testUpdateLastUpdatedTime_withNoDataInCache_conversation_updateUnreadCount_dataIsCreatedInCache() throws {
        let startDate = Date()
        let endDate = Date().addingTimeInterval(-10)
        let count = 99
        sut.updateLastUpdatedTime(labelID: labelID,
                                  isUnread: true,
                                  startTime: startDate,
                                  endTime: endDate,
                                  msgCount: count,
                                  userID: userID, type: .conversation)

        let data = try XCTUnwrap(sut.lastUpdate(by: labelID, userID: userID, type: .conversation))
        XCTAssertEqual(data.unreadStart, startDate)
        XCTAssertEqual(data.unreadEnd, endDate)
        XCTAssertNotNil(data.unreadUpdate)
        XCTAssertEqual(data.total, 0)
        XCTAssertEqual(data.start, Date.distantPast)
        XCTAssertEqual(data.end, Date.distantPast)
        XCTAssertEqual(data.update, Date.distantPast)
    }

    func testUpdateLastUpdatedTime_conversation_unread_withEarlierEndDate_endDateIsUpdated() throws {
        let startDate = Date()
        let endDate = Date().addingTimeInterval(-10)
        let earlierEndDate = endDate.addingTimeInterval(-1000)
        let count = 99
        prepareConversationCountUnreadTestData(labelID: labelID, start: startDate, end: endDate, update: Date(), total: count, unread: 0, userID: userID)

        sut.updateLastUpdatedTime(labelID: labelID,
                                  isUnread: true,
                                  startTime: startDate,
                                  endTime: earlierEndDate,
                                  msgCount: count,
                                  userID: userID, type: .conversation)

        let data = try XCTUnwrap(sut.lastUpdate(by: labelID, userID: userID, type: .conversation))
        XCTAssertEqual(data.unreadStart, startDate)
        XCTAssertEqual(data.unreadEnd, earlierEndDate)
        XCTAssertNotNil(data.unreadUpdate)
        XCTAssertEqual(data.total, count)
        XCTAssertNil(data.start)
        XCTAssertNil(data.end)
        XCTAssertNil(data.update)
    }

    func testUpdateLastUpdatedTime_conversation_unread_withLaterEndDate_endDateIsNotUpdated() throws {
        let startDate = Date()
        let endDate = Date().addingTimeInterval(-10)
        let laterEndDate = endDate.addingTimeInterval(1000)
        let count = 99
        prepareConversationCountUnreadTestData(labelID: labelID, start: startDate, end: endDate, update: Date(), total: count, unread: 0, userID: userID)

        sut.updateLastUpdatedTime(labelID: labelID,
                                  isUnread: true,
                                  startTime: startDate,
                                  endTime: laterEndDate,
                                  msgCount: count,
                                  userID: userID, type: .conversation)

        let data = try XCTUnwrap(sut.lastUpdate(by: labelID, userID: userID, type: .conversation))

        XCTAssertEqual(data.unreadStart, startDate)
        XCTAssertEqual(data.unreadEnd, endDate)
        XCTAssertNotNil(data.unreadUpdate)
        XCTAssertEqual(data.total, count)
        XCTAssertNil(data.start)
        XCTAssertNil(data.end)
        XCTAssertNil(data.update)
    }

    func testUpdateLastUpdatedTime_conversation_unread_withDifferentStartDate_startDateIsNotUpdated() throws {
        let startDate = Date()
        let endDate = Date().addingTimeInterval(-10)
        let count = 99
        prepareConversationCountUnreadTestData(labelID: labelID, start: startDate, end: endDate, update: Date(), total: count, unread: 0, userID: userID)

        let anotherStartDate = startDate.addingTimeInterval(400)
        sut.updateLastUpdatedTime(labelID: labelID,
                                  isUnread: true,
                                  startTime: anotherStartDate,
                                  endTime: endDate,
                                  msgCount: count,
                                  userID: userID, type: .conversation)

        let data = try XCTUnwrap(sut.lastUpdate(by: labelID, userID: userID, type: .conversation))

        XCTAssertEqual(data.unreadStart, startDate)
        XCTAssertEqual(data.unreadEnd, endDate)
        XCTAssertNotNil(data.unreadUpdate)
        XCTAssertEqual(data.total, count)
        XCTAssertNil(data.start)
        XCTAssertNil(data.end)
        XCTAssertNil(data.update)
    }

    // MARK: - conversation unread count tests

    func testUnreadCount_conversation_noCacheData_getZero() {
        XCTAssertEqual(sut.unreadCount(by: labelID, userID: userID, type: .conversation), 0)
    }

    func testUnreadCount_conversation_getCorrectValue() {
        let unread = Int.random(in: 0...Int(Int32.max))
        prepareConversationCountTestData(labelID: labelID, start: Date(), end: Date(), update: Date(), total: Int.random(in: 0...100), unread: unread, userID: userID)

        XCTAssertEqual(sut.unreadCount(by: labelID, userID: userID, type: .conversation), unread)
    }

    func testUnreadCount_conversation_hasNegativeValue_getZero() {
        let unread = Int.random(in: Int(Int32.min)...0)
        prepareConversationCountTestData(labelID: labelID, start: Date(), end: Date(), update: Date(), total: Int.random(in: 0...100), unread: unread, userID: userID)

        XCTAssertEqual(sut.unreadCount(by: labelID, userID: userID, type: .conversation), 0)
    }

    func testUpdateUnreadCount_conversation_noDataInCache_createAndUpdateTheData() throws {
        let unread = 30
        let total = 50
        sut.updateUnreadCount(by: labelID, userID: userID, unread: unread, total: total, type: .conversation, shouldSave: true)

        let result = try XCTUnwrap(sut.lastUpdate(by: labelID, userID: userID, type: .conversation))
        XCTAssertEqual(result.unread, 30)
        XCTAssertEqual(result.total, total)
        XCTAssertTrue(result.isNew)
        XCTAssertTrue(result.isUnreadNew)
    }

    func testUpdateUnreadCount_conversation_updateDataInCache() throws {
        prepareConversationCountTestData(labelID: labelID, start: Date(), end: Date(), update: Date(), total: 0, unread: 0, userID: userID)

        let initialResult = try XCTUnwrap(sut.lastUpdate(by: labelID, userID: userID, type: .conversation))
        XCTAssertEqual(initialResult.unread, 0)
        XCTAssertEqual(initialResult.total, 0)

        let unread = 10
        let total = 100
        sut.updateUnreadCount(by: labelID, userID: userID, unread: unread, total: total, type: .conversation, shouldSave: true)

        let result = try XCTUnwrap(sut.lastUpdate(by: labelID, userID: userID, type: .conversation))
        XCTAssertEqual(result.unread, unread)
        XCTAssertEqual(result.total, total)
    }

    func testGetUnreadCounts_noDataInCache_conversation_returnEmpty() {
        let labelID2: LabelID = "label2"
        let expectation1 = expectation(description: "Closure is called")
        sut.getUnreadCounts(by: [labelID, labelID2], userID: userID, type: .conversation) { result in
            XCTAssertTrue(result.isEmpty)
            expectation1.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func testGetUnreadCounts_conversation_getCorrectData() {
        let labelID2: LabelID = "label2"
        prepareConversationCountTestData(labelID: labelID, start: Date(), end: Date(), update: Date(), total: 100, unread: 30, userID: userID)
        prepareConversationCountTestData(labelID: labelID2, start: Date(), end: Date(), update: Date(), total: 10, unread: 5, userID: userID)
        let expectation1 = expectation(description: "Closure is called")

        sut.getUnreadCounts(by: [labelID, labelID2], userID: userID, type: .conversation) { result in
            XCTAssertEqual(result.count, 2)
            do {
                let labelUnread = try XCTUnwrap(result[self.labelID.rawValue])
                XCTAssertEqual(labelUnread, 30)

                let label2Unread = try XCTUnwrap(result[labelID2.rawValue])
                XCTAssertEqual(label2Unread, 5)
            } catch {
                XCTFail("Should not throw error")
            }
            expectation1.fulfill()
        }
        waitForExpectations(timeout: 1)
    }
}

private extension LastUpdatedStoreTests {
    func prepareLabelUpdateTestData(
        labelID: LabelID,
        start: Date,
        end: Date,
        update: Date,
        total: Int,
        unread: Int,
        userID: UserID
    ) {
        let data = LabelUpdate(context: contextProviderMock.rootSavingContext)
        data.labelID = labelID.rawValue
        data.start = start
        data.end = end
        data.update = update
        data.total = Int32(total)
        data.unread = Int32(unread)
        data.userID = userID.rawValue
    }

    func prepareLabelUpdateUnreadTestData(
        labelID: LabelID,
        start: Date,
        end: Date,
        update: Date,
        total: Int,
        unread: Int,
        userID: UserID
    ) {
        let data = LabelUpdate(context: contextProviderMock.rootSavingContext)
        data.labelID = labelID.rawValue
        data.unreadStart = start
        data.unreadEnd = end
        data.unreadUpdate = update
        data.total = Int32(total)
        data.unread = Int32(unread)
        data.userID = userID.rawValue
    }

    func prepareConversationCountTestData(
        labelID: LabelID,
        start: Date,
        end: Date,
        update: Date,
        total: Int,
        unread: Int,
        userID: UserID
    ) {
        let data = ConversationCount(context: contextProviderMock.rootSavingContext)
        data.labelID = labelID.rawValue
        data.start = start
        data.end = end
        data.update = update
        data.total = Int32(total)
        data.unread = Int32(unread)
        data.userID = userID.rawValue
    }

    func prepareConversationCountUnreadTestData(
        labelID: LabelID,
        start: Date,
        end: Date,
        update: Date,
        total: Int,
        unread: Int,
        userID: UserID
    ) {
        let data = ConversationCount(context: contextProviderMock.rootSavingContext)
        data.labelID = labelID.rawValue
        data.unreadStart = start
        data.unreadEnd = end
        data.unreadUpdate = update
        data.total = Int32(total)
        data.unread = Int32(unread)
        data.userID = userID.rawValue
    }
}
