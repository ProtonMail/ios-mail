//
//  MockLastUpdatedStore.swift
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

import CoreData
import Foundation
import PromiseKit
import ProtonCore_DataModel
@testable import ProtonMail

class MockLastUpdatedStore: LastUpdatedStoreProtocol {
    var contactsCached: Int = 0
    var msgUnreadData: [String: Int] = [:] // [LabelID: UnreadCount]
    var conversationUnreadData: [String: Int] = [:] // [LabelID: UnreadCount]
    var msgLabelUpdate: [LabelID: LabelUpdate] = [:] // [LabelID: LabelUpdate]
    var conversationLabelUpdate: [LabelID: ConversationCount] = [:] // [LabelID: ConversationCount]

    var testContext: NSManagedObjectContext!

    private(set) var updateEventIDWasCalled: Bool = false
    private(set) var removeUpdateTimeExceptUnreadForMessagesWasCalled: Bool = false
    private(set) var removeUpdateTimeExceptUnreadForConversationsWasCalled: Bool = false

    init(context: NSManagedObjectContext? = nil) {
        self.testContext = context
    }

    static func clear() {}

    static func cleanUpAll() -> Promise<Void> {
        return Promise<Void>()
    }

    func cleanUp(userId: UserID) -> Promise<Void> {
        return Promise<Void>()
    }

    func resetUnreadCounts() {
        self.msgUnreadData.removeAll()
        self.conversationUnreadData.removeAll()
    }

    func updateEventID(by userID: UserID, eventID: String) -> Promise<Void> {
        updateEventIDWasCalled = true
        return Promise<Void>()
    }

    func lastEventID(userID: UserID) -> String {
        return ""
    }

    func lastEventUpdateTime(userID: UserID) -> Date? {
        return nil
    }

    func lastUpdate(by labelID: LabelID, userID: UserID, type: ViewMode) -> LabelCountEntity? {
        let labelCount: LabelCount? = lastUpdate(by: labelID, userID: userID, type: type)
        return labelCount.map { LabelCountEntity(labelCount: $0, viewMode: type) }
    }

    func lastUpdate(by labelID: LabelID, userID: UserID, type: ViewMode) -> LabelCount? {
        switch type {
        case .singleMessage:
            return self.msgLabelUpdate[labelID]
        case .conversation:
            return self.conversationLabelUpdate[labelID]
        }
    }

    func lastUpdateDefault(by labelID: LabelID, userID: UserID, type: ViewMode) -> LabelCountEntity {
        switch type {
        case .singleMessage:
            if let data = self.msgLabelUpdate[labelID] {
                return LabelCountEntity(labelCount: data, viewMode: type)
            } else {
                let newData = LabelUpdate.newLabelUpdate(by: labelID.rawValue, userID: userID.rawValue, inManagedObjectContext: testContext)
                self.msgLabelUpdate[labelID] = newData
                return LabelCountEntity(labelCount: newData, viewMode: type)
            }
        case .conversation:
            if let data = self.conversationLabelUpdate[labelID] {
                return LabelCountEntity(labelCount: data, viewMode: type)
            } else {
                let newData = ConversationCount.newConversationCount(by: labelID.rawValue, userID: userID.rawValue, inManagedObjectContext: testContext)
                self.conversationLabelUpdate[labelID] = newData
                return LabelCountEntity(labelCount: newData, viewMode: type)
            }
        }
    }

    func unreadCount(by labelID: LabelID, userID: UserID, type: ViewMode) -> Int {
        switch type {
        case .singleMessage:
            return Int(self.msgLabelUpdate[labelID]?.unread ?? 0)
        case .conversation:
            return Int(self.conversationLabelUpdate[labelID]?.unread ?? 0)
        }
    }

    func updateUnreadCount(by labelID: LabelID, userID: UserID, unread: Int, total: Int?, type: ViewMode, shouldSave: Bool) {
        switch type {
        case .singleMessage:
            if let data = self.msgLabelUpdate[labelID] {
                data.unread = Int32(unread)
            } else {
                let newData = LabelUpdate.newLabelUpdate(by: labelID.rawValue, userID: userID.rawValue, inManagedObjectContext: testContext!)
                newData.unread = Int32(unread)
                self.msgLabelUpdate[labelID] = newData
            }
        case .conversation:
            if let data = self.conversationLabelUpdate[labelID] {
                data.unread = Int32(unread)
            } else {
                let newData = ConversationCount.newConversationCount(by: labelID.rawValue, userID: userID.rawValue, inManagedObjectContext: testContext!)
                newData.unread = Int32(unread)
                self.conversationLabelUpdate[labelID] = newData
            }
        }
    }

    func removeUpdateTime(by userID: UserID, type: ViewMode) {}

    func resetCounter(labelID: LabelID, userID: UserID, type: ViewMode?) {}

    func removeUpdateTimeExceptUnread(by userID: UserID, type: ViewMode) {
        switch type {
        case .singleMessage:
            removeUpdateTimeExceptUnreadForMessagesWasCalled = true
        case .conversation:
            removeUpdateTimeExceptUnreadForConversationsWasCalled = true
        }
    }

    func getUnreadCounts(by labelIDs: [LabelID], userID: UserID, type: ViewMode, completion: @escaping ([String: Int]) -> Void) {
        completion([:])
    }

    func updateLastUpdatedTime(labelID: LabelID, isUnread: Bool, startTime: Date?, endTime: Date?, msgCount: Int, userID: UserID, type: ViewMode) {
        switch type {
        case .singleMessage:
            let data = msgLabelUpdate[labelID] ??
                LabelUpdate.newLabelUpdate(by: labelID.rawValue,
                                           userID: userID.rawValue,
                                           inManagedObjectContext: testContext!)
            if isUnread {
                data.unreadStart = startTime
                data.unreadEnd = endTime
                data.unread = Int32(msgCount)
            } else {
                data.start = startTime
                data.end = endTime
                data.total = Int32(msgCount)
            }

            msgLabelUpdate[labelID] = data
        case .conversation:
            let data = self.conversationLabelUpdate[labelID] ??
                ConversationCount.newConversationCount(by: labelID.rawValue, userID: userID.rawValue, inManagedObjectContext: testContext!)
            if isUnread {
                data.unreadStart = startTime
                data.unreadEnd = endTime
                data.unread = Int32(msgCount)
            } else {
                data.start = startTime
                data.end = endTime
                data.total = Int32(msgCount)
            }
            conversationLabelUpdate[labelID] = data
        }
    }
}
