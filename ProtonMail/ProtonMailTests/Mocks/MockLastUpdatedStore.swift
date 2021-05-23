//
//  MockLastUpdatedStore.swift
//  ProtonMailTests
//
//  Copyright (c) 2021 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.

import Foundation
import PromiseKit
import CoreData
import ProtonCore_DataModel
@testable import ProtonMail

class MockLastUpdatedStore: LastUpdatedStoreProtocol {
    var contactsCached: Int = 0
    var msgUnreadData: [String: Int] = [:] //[LabelID: UnreadCount]
    var conversationUnreadData: [String: Int] = [:] //[LabelID: UnreadCount]
    var labelUpdate: [String: LabelUpdate] = [:] //[LabelID: LabelUpdate]
    
    static func clear() {
        
    }
    
    static func cleanUpAll() -> Promise<Void> {
        return Promise<Void>()
    }
    
    func clear() {
        
    }
    
    func cleanUp(userId: String) -> Promise<Void> {
        return Promise<Void>()
    }
    
    func resetUnreadCounts() {
        self.msgUnreadData.removeAll()
        self.conversationUnreadData.removeAll()
    }
    
    func updateEventID(by userID: String, eventID: String) -> Promise<Void> {
        return Promise<Void>()
    }
    
    func lastEventID(userID: String) -> String {
        return ""
    }
    
    func lastEvent(userID: String, context: NSManagedObjectContext) -> UserEvent {
        return UserEvent(context: context)
    }
    
    func lastEventUpdateTime(userID: String) -> Date? {
        return nil
    }
    
    func lastUpdate(by labelID: String, userID: String, context: NSManagedObjectContext, type: UserInfo.ViewMode) -> LabelCount? {
        return self.labelUpdate[labelID]
    }
    
    func lastUpdateDefault(by labelID: String, userID: String, context: NSManagedObjectContext, type: UserInfo.ViewMode) -> LabelCount {
        if let data = self.labelUpdate[labelID] {
            return data
        }
        let newData = LabelUpdate.newLabelUpdate(by: labelID, userID: userID, inManagedObjectContext: context)
        self.labelUpdate[labelID] = newData
        return newData
    }
    
    func unreadCount(by labelID: String, userID: String, type: UserInfo.ViewMode) -> Promise<Int> {
        var count = 0
        switch type {
        case .singleMessage:
            count = self.msgUnreadData[labelID] ?? 0
        case .conversation:
            count = self.conversationUnreadData[labelID] ?? 0
        }
        return Promise.value(count)
    }
    
    func unreadCount(by labelID: String, userID: String, type: UserInfo.ViewMode) -> Int {
        switch type {
        case .singleMessage:
            return self.msgUnreadData[labelID] ?? 0
        case .conversation:
            return self.conversationUnreadData[labelID] ?? 0
        }
    }
    
    func updateUnreadCount(by labelID: String, userID: String, count: Int, type: UserInfo.ViewMode, shouldSave: Bool) {
        switch type {
        case .singleMessage:
            self.msgUnreadData[labelID] = count
        case .conversation:
            self.conversationUnreadData[labelID] = count
        }
    }
    
    func removeUpdateTime(by userID: String, type: UserInfo.ViewMode) {
        
    }
}
