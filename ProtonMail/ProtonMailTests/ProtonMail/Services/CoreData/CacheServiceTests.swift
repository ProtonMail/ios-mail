//
//  CacheServiceTests.swift
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
import Groot

class CacheServiceTest: XCTestCase {
    private var globalContainer: GlobalContainer!
    var testMessage: Message!
    var lastUpdatedStore: LastUpdatedStore!
    var sut: CacheService!
    var contextProviderMock: MockCoreDataContextProvider!
    var testContext: NSManagedObjectContext!

    override func setUpWithError() throws {
        contextProviderMock = .init()
        testContext = contextProviderMock.viewContext
        
        let parsedObject = testMessageMetaData.parseObjectAny()!
        testMessage = try GRTJSONSerialization.object(withEntityName: "Message",
                                                      fromJSONDictionary: parsedObject, in: testContext) as? Message
        testMessage.userID = "userID"

        let parsedLabel = testLabelsData.parseJson()!
        _ = try GRTJSONSerialization.objects(withEntityName: Label.Attributes.entityName, fromJSONArray: parsedLabel, in: testContext)
        
        try testContext.save()

        lastUpdatedStore = LastUpdatedStore(contextProvider: contextProviderMock)

        globalContainer = GlobalContainer()
        globalContainer.contextProviderFactory.register { self.contextProviderMock }
        globalContainer.lastUpdatedStoreFactory.register { self.lastUpdatedStore }

        sut = CacheService(userID: "userID", dependencies: globalContainer)
    }
    
    override func tearDown() {
        testMessage = nil
        sut = nil
        globalContainer = nil
        testContext = nil
        lastUpdatedStore = nil
        contextProviderMock = nil
    }
    
    func testRemoveLabel() {
        sut.removeLabel(on: self.testMessage, labels: [Message.Location.inbox.rawValue], cleanUnread: false)
        let newLabels: [String] = self.testMessage.getLabelIDs()
        XCTAssertFalse(newLabels.contains(Message.Location.inbox.rawValue))
    }
    
    func testDeleteMessage() {
        self.testMessage.unRead = true
        loadTestDataOfUnreadCount(defaultUnreadCount: 1, labelID: Message.Location.inbox.labelID)

        let msgID = self.testMessage.messageID
        XCTAssertNotNil(Message.messageForMessageID(msgID, inManagedObjectContext: self.testContext))

        XCTAssertTrue(sut.delete(messages: [MessageEntity(self.testMessage)], label: Message.Location.inbox.labelID))

        XCTAssertNil(Message.messageForMessageID(msgID, inManagedObjectContext: self.testContext))

        let unreadCountOfInboxAfterDelete: Int = lastUpdatedStore.unreadCount(by: Message.Location.inbox.labelID, userID: sut.userID, type: .singleMessage)
        XCTAssertEqual(unreadCountOfInboxAfterDelete, 0)
    }

    func testMessageUpdateEO() {
        let expirationTime = TimeInterval(100.0)
        let pwd = "PWD"
        let pwdHint = "Hint"

        let expect = expectation(description: "Update EO")
        sut.updateExpirationOffset(of: self.testMessage.objectID, expirationTime: expirationTime, pwd: pwd, pwdHint: pwdHint) {
            expect.fulfill()
        }
        wait(for: [expect], timeout: 1)

        XCTAssertEqual(self.testMessage.password, pwd)
        XCTAssertEqual(self.testMessage.passwordHint, pwdHint)
        XCTAssertEqual(self.testMessage.expirationOffset, Int32(expirationTime))
    }
    
    func testMarkReadMessageAsRead() {
        loadTestDataOfUnreadCount(defaultUnreadCount: 0, labelID: Message.Location.inbox.labelID)
        XCTAssertTrue(sut.mark(messageObjectID: testMessage.objectID, labelID: Message.Location.inbox.labelID, unRead: false))
        
        XCTAssertFalse(self.testMessage.unRead)
        let unreadCountOfInbox: Int = lastUpdatedStore.unreadCount(by: Message.Location.inbox.labelID, userID: sut.userID, type: .singleMessage)
        XCTAssertEqual(unreadCountOfInbox, 0)
    }
    
    func testMarkReadMessageAsUnread() {
        loadTestDataOfUnreadCount(defaultUnreadCount: 0, labelID: Message.Location.inbox.labelID)
        XCTAssertTrue(sut.mark(messageObjectID: testMessage.objectID, labelID: Message.Location.inbox.labelID, unRead: true))
        
        XCTAssertTrue(self.testMessage.unRead)
        let unreadCountOfInbox: Int = lastUpdatedStore.unreadCount(by: Message.Location.inbox.labelID, userID: sut.userID, type: .singleMessage)
        XCTAssertEqual(unreadCountOfInbox, 1)
    }
    
    func testMarkUnreadMessageAsRead() {
        self.testMessage.unRead = true
        loadTestDataOfUnreadCount(defaultUnreadCount: 1, labelID: Message.Location.inbox.labelID)
        
        XCTAssertTrue(sut.mark(messageObjectID: testMessage.objectID, labelID: Message.Location.inbox.labelID, unRead: false))
        
        XCTAssertFalse(self.testMessage.unRead)
        let unreadCountOfInbox: Int = lastUpdatedStore.unreadCount(by: Message.Location.inbox.labelID, userID: sut.userID, type: .singleMessage)
        XCTAssertEqual(unreadCountOfInbox, 0)
    }
    
    func testMarkUnreadMessageAsUnread() {
        self.testMessage.unRead = true
        loadTestDataOfUnreadCount(defaultUnreadCount: 1, labelID: Message.Location.inbox.labelID)
        
        XCTAssertTrue(sut.mark(messageObjectID: testMessage.objectID, labelID: Message.Location.inbox.labelID, unRead: true))
        
        XCTAssertTrue(self.testMessage.unRead)
        let unreadCountOfInbox: Int = lastUpdatedStore.unreadCount(by: Message.Location.inbox.labelID, userID: sut.userID, type: .singleMessage)
        XCTAssertEqual(unreadCountOfInbox, 1)
    }
    
    func testLabelAndUnLabelMessage() {
        let labelIDToAdd: LabelID = "dixQoKdS1OPVzHB0nZ5Yp7MDlZM4-nHhvspULoUSdWKFRKhHLOQEmU58ExrwFHJY2cejSP1TrDOyc7mvVcSa6Q=="
        
        XCTAssertTrue(sut.label(messages: [MessageEntity(self.testMessage)], label: labelIDToAdd, apply: true))
        let labels: [String] = self.testMessage.getLabelIDs()
        XCTAssertTrue(labels.contains(labelIDToAdd.rawValue))
        
        XCTAssertTrue(sut.label(messages: [MessageEntity(self.testMessage)], label: labelIDToAdd, apply: false))
        let newLabels: [String] = self.testMessage.getLabelIDs()
        XCTAssertFalse(newLabels.contains(labelIDToAdd.rawValue))
    }
}

extension CacheServiceTest {
    func loadTestDataOfUnreadCount(defaultUnreadCount: Int, labelID: LabelID) {
        lastUpdatedStore.updateUnreadCount(by: labelID, userID: sut.userID, unread: defaultUnreadCount, total: nil, type: .singleMessage, shouldSave: true)
        lastUpdatedStore.updateUnreadCount(by: labelID, userID: sut.userID, unread: defaultUnreadCount, total: nil, type: .conversation, shouldSave: true)
    }
}
