//
//  MockLastUpdatedStore.swift
//  Proton MailTests
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

import Foundation
import PromiseKit
import CoreData
import ProtonCore_DataModel
@testable import ProtonMail

class MockLastUpdatedStore: LastUpdatedStoreProtocol {
    var contactsCached: Int = 0
    var msgUnreadData: [String: Int] = [:] //[LabelID: UnreadCount]
    var conversationUnreadData: [String: Int] = [:] //[LabelID: UnreadCount]
    var msgLabelUpdate: [String: LabelUpdate] = [:] //[LabelID: LabelUpdate]
    var conversationLabelUpdate: [String: ConversationCount] = [:] //[LabelID: ConversationCount]

    var testContext: NSManagedObjectContext?

    private(set) var clearWasCalled: Bool = false
    private(set) var updateEventIDWasCalled: Bool = false
    private(set) var removeUpdateTimeExceptUnreadForMessagesWasCalled: Bool = false
    private(set) var removeUpdateTimeExceptUnreadForConversationsWasCalled: Bool = false

    static func clear() {

    }
    
    static func cleanUpAll() -> Promise<Void> {
        return Promise<Void>()
    }
    
    func clear() {
        clearWasCalled = true
    }
    
    func cleanUp(userId: String) -> Promise<Void> {
        return Promise<Void>()
    }
    
    func resetUnreadCounts() {
        self.msgUnreadData.removeAll()
        self.conversationUnreadData.removeAll()
    }
    
    func updateEventID(by userID: String, eventID: String) -> Promise<Void> {
        updateEventIDWasCalled = true
        return Promise<Void>()
    }
    
    func lastEventID(userID: String) -> String {
        return ""
    }
    
    func lastEventUpdateTime(userID: String) -> Date? {
        return nil
    }
    
    func lastUpdate(by labelID: String, userID: String, context: NSManagedObjectContext, type: ViewMode) -> LabelCount? {
        switch type {
        case .singleMessage:
            return self.msgLabelUpdate[labelID]
        case .conversation:
            return self.conversationLabelUpdate[labelID]
        }
    }
    
    func lastUpdateDefault(by labelID: String, userID: String, context: NSManagedObjectContext, type: ViewMode) -> LabelCount {
        switch type {
        case .singleMessage:
            if let data = self.msgLabelUpdate[labelID] {
                return data
            } else {
                let newData = LabelUpdate.newLabelUpdate(by: labelID, userID: userID, inManagedObjectContext: context)
                self.msgLabelUpdate[labelID] = newData
                return newData
            }
        case .conversation:
            if let data = self.conversationLabelUpdate[labelID] {
                return data
            } else {
                let newData = ConversationCount.newConversationCount(by: labelID, userID: userID, inManagedObjectContext: context)
                self.conversationLabelUpdate[labelID] = newData
                return newData
            }
        }
    }
    
    func unreadCount(by labelID: String, userID: String, type: ViewMode) -> Int {
        switch type {
        case .singleMessage:
            return Int(self.msgLabelUpdate[labelID]?.unread ?? 0)
        case .conversation:
            return Int(self.conversationLabelUpdate[labelID]?.unread ?? 0)
        }
    }
    
    func updateUnreadCount(by labelID: String, userID: String, unread: Int, total: Int?, type: ViewMode, shouldSave: Bool) {
        switch type {
        case .singleMessage:
            if let data = self.msgLabelUpdate[labelID] {
                data.unread = Int32(unread)
            } else {
                let newData = LabelUpdate.newLabelUpdate(by: labelID, userID: userID, inManagedObjectContext: testContext!)
                newData.unread = Int32(unread)
                self.msgLabelUpdate[labelID] = newData
            }
        case .conversation:
            if let data = self.conversationLabelUpdate[labelID] {
                data.unread = Int32(unread)
            } else {
                let newData = ConversationCount.newConversationCount(by: labelID, userID: userID, inManagedObjectContext: testContext!)
                newData.unread = Int32(unread)
                self.conversationLabelUpdate[labelID] = newData
            }
        }
    }
    
    func removeUpdateTime(by userID: String, type: ViewMode) {
        
    }

    func resetCounter(labelID: String, userID: String, type: ViewMode?) {
        
    }

    func removeUpdateTimeExceptUnread(by userID: String, type: ViewMode) {
        switch type {
        case .singleMessage:
            removeUpdateTimeExceptUnreadForMessagesWasCalled = true
        case .conversation:
            removeUpdateTimeExceptUnreadForConversationsWasCalled = true
        }
    }

    func lastUpdates(by labelIDs: [String], userID: String, context: NSManagedObjectContext, type: ViewMode) -> [LabelCount] {
        return []
    }

    func getUnreadCounts(by labelID: [String], userID: String, type: ViewMode, completion: @escaping ([String: Int]) -> Void) {
        completion([:])
    }
}
