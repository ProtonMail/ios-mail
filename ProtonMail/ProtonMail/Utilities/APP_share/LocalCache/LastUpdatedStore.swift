//
//  LastUpdatedStore.swift
//  Proton Mail
//
//
//  Copyright (c) 2019 Proton AG
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
import UIKit

protocol LastUpdatedStoreProtocol {
    func cleanUp(userId: UserID) -> Promise<Void>

    func updateEventID(by userID: UserID, eventID: String) -> Promise<Void>
    func lastEventID(userID: UserID) -> String
    func lastEventUpdateTime(userID: UserID) -> Date?

    func lastUpdate(by labelID: LabelID, userID: UserID, type: ViewMode) -> LabelCountEntity?
    func lastUpdateDefault(by labelID: LabelID, userID: UserID, type: ViewMode) -> LabelCountEntity
    func unreadCount(by labelID: LabelID, userID: UserID, type: ViewMode) -> Int
    func updateUnreadCount(by labelID: LabelID,
                           userID: UserID,
                           unread: Int,
                           total: Int?,
                           type: ViewMode,
                           shouldSave: Bool)
    func removeUpdateTime(by userID: UserID, type: ViewMode)
    func resetCounter(labelID: LabelID, userID: UserID, type: ViewMode?)
    func removeUpdateTimeExceptUnread(by userID: UserID, type: ViewMode)
    func getUnreadCounts(by labelIDs: [LabelID],
                         userID: UserID,
                         type: ViewMode,
                         completion: @escaping ([String: Int]) -> Void)
    func updateLastUpdatedTime(labelID: LabelID,
                               isUnread: Bool,
                               startTime: Date?,
                               endTime: Date?,
                               msgCount: Int,
                               userID: UserID,
                               type: ViewMode)
}

final class LastUpdatedStore: SharedCacheBase, HasLocalStorage, LastUpdatedStoreProtocol, Service {

    let contextProvider: CoreDataContextProviderProtocol

    private var context: NSManagedObjectContext {
        return contextProvider.rootSavingContext
    }

    init(contextProvider: CoreDataContextProviderProtocol) {
        self.contextProvider = contextProvider
        super.init()
    }

    func cleanUp(userId: UserID) -> Promise<Void> {
        return Promise { seal in
            self.context.perform {
                _ = UserEvent.remove(by: userId.rawValue, inManagedObjectContext: self.context)
                _ = LabelUpdate.remove(by: userId.rawValue, inManagedObjectContext: self.context)
                _ = ConversationCount.remove(by: userId.rawValue, inManagedObjectContext: self.context)
                seal.fulfill_()
            }
        }
    }

    static func cleanUpAll() -> Promise<Void> {
        return Promise { seal in
            let coreDataService = sharedServices.get(by: CoreDataService.self)
            let context = coreDataService.operationContext
            context.perform {
                UserEvent.deleteAll(inContext: context)
                LabelUpdate.deleteAll(inContext: context)
                ConversationCount.deleteAll(inContext: context)
                seal.fulfill_()
            }
        }
    }
}

// MARK: - Event ID

extension LastUpdatedStore {
    func updateEventID(by userID: UserID, eventID: String) -> Promise<Void> {
        return Promise { seal in
            context.perform {
                let event = self.eventIDDefault(by: userID)
                event.eventID = eventID
                event.updateTime = Date()
                _ = self.context.saveUpstreamIfNeeded()
                seal.fulfill_()
            }
        }
    }

    private func eventIDDefault(by userID: UserID) -> UserEvent {
        if let update = UserEvent.userEvent(by: userID.rawValue,
                                            inManagedObjectContext: context) {
            return update
        }
        return UserEvent.newUserEvent(userID: userID.rawValue,
                                      inManagedObjectContext: context)
    }

    func lastEventID(userID: UserID) -> String {
        var eventID = ""
        context.performAndWait {
            eventID = eventIDDefault(by: userID).eventID
        }
        return eventID
    }

    func lastEventUpdateTime(userID: UserID) -> Date? {
        var time: Date?
        context.performAndWait {
            time = eventIDDefault(by: userID).updateTime
        }
        return time
    }
}

// MARK: - Conversation/Message Counts

extension LastUpdatedStore {
    func lastUpdate(by labelID: LabelID, userID: UserID, type: ViewMode) -> LabelCountEntity? {
        var result: LabelCountEntity?

        context.performAndWait {
            let labelCount: LabelCount? = lastUpdate(by: labelID, userID: userID, type: type)
            result = labelCount.map { LabelCountEntity(labelCount: $0, viewMode: type) }
        }

        return result
    }

    func lastUpdateDefault(by labelID: LabelID, userID: UserID, type: ViewMode) -> LabelCountEntity {
        let result: LabelCount = lastUpdateDefault(by: labelID, userID: userID, type: type)
        return LabelCountEntity(labelCount: result, viewMode: type)
    }

    func getUnreadCounts(
        by labelIDs: [LabelID],
        userID: UserID,
        type: ViewMode,
        completion: @escaping ([String: Int]) -> Void
    ) {
        context.perform {
            var results: [String: Int] = [:]
            let labelCounts = self.lastUpdates(by: labelIDs, userID: userID, type: type)
            labelCounts.forEach { results[$0.labelID] = Int($0.unread) }

            DispatchQueue.main.async {
                completion(results)
            }
        }
    }

    func unreadCount(by labelID: LabelID, userID: UserID, type: ViewMode) -> Int {
        let update: LabelCountEntity? = self.lastUpdate(by: labelID, userID: userID, type: type)
        let unreadCount = update?.unread

        guard let result = unreadCount else {
            return 0
        }
        guard result >= 0 else {
            return 0
        }
        return result
    }

    func updateUnreadCount(
        by labelID: LabelID,
        userID: UserID,
        unread: Int,
        total: Int?,
        type: ViewMode,
        shouldSave: Bool
    ) {
        context.performAndWait {
            let update: LabelCount = self.lastUpdateDefault(by: labelID, userID: userID, type: type)
            update.unread = Int32(unread)
            if let total = total {
                update.total = Int32(total)
            }

            if shouldSave {
                _ = context.saveUpstreamIfNeeded()
            }
        }
    }

    /// Reset counter value to zero
    /// - Parameters:
    ///   - type: Optional, nil will reset conversation and message counter
    func resetCounter(labelID: LabelID, userID: UserID, type: ViewMode?) {
        context.performAndWait {
            let counts: [LabelCount]
            if let type = type {
                let count: LabelCount = self.lastUpdateDefault(by: labelID, userID: userID, type: type)
                counts = [count]
            } else {
                let conversationCount: LabelCount = self.lastUpdateDefault(
                    by: labelID,
                    userID: userID,
                    type: .conversation
                )
                let messageCount: LabelCount = self.lastUpdateDefault(by: labelID, userID: userID, type: .singleMessage)
                counts = [conversationCount, messageCount]
            }
            counts.forEach { count in
                count.total = 0
                count.unread = 0
                count.unreadStart = nil
                count.unreadEnd = nil
                count.unreadUpdate = nil
            }
            _ = self.context.saveUpstreamIfNeeded()
        }
    }

    // remove all updates for a user
    func removeUpdateTime(by userID: UserID, type: ViewMode) {
        context.performAndWait {
            switch type {
            case .singleMessage:
                _ = LabelUpdate.remove(by: userID.rawValue, inManagedObjectContext: self.context)
            case .conversation:
                _ = ConversationCount.remove(by: userID.rawValue, inManagedObjectContext: self.context)
            }
        }
    }

    func removeUpdateTimeExceptUnread(by userID: UserID, type: ViewMode) {
        context.performAndWait {
            switch type {
            case .singleMessage:
                let data = LabelUpdate.lastUpdates(userID: userID.rawValue, inManagedObjectContext: self.context)
                data.forEach { $0.resetDataExceptUnread() }
            case .conversation:
                let data = ConversationCount.getConversationCounts(
                    userID: userID.rawValue,
                    inManagedObjectContext: self.context
                )
                data.forEach { $0.resetDataExceptUnread() }
            }
            _ = self.context.saveUpstreamIfNeeded()
        }
    }

    func updateLastUpdatedTime(
        labelID: LabelID,
        isUnread: Bool,
        startTime: Date?,
        endTime: Date?,
        msgCount: Int,
        userID: UserID,
        type: ViewMode
    ) {
        context.performAndWait {
            let updateTime: LabelCount = self.lastUpdateDefault(
                by: labelID,
                userID: userID,
                type: type
            )
            if isUnread {
                // Update unread date query time
                if updateTime.isUnreadNew {
                    updateTime.unreadStart = startTime
                }
                if let time = endTime,
                   updateTime.unreadEndTime.compare(time) == .orderedDescending ||
                   updateTime.unreadEndTime == .distantPast {
                    updateTime.unreadEnd = time
                }
                updateTime.unreadUpdate = Date()
            } else {
                if updateTime.isNew {
                    updateTime.start = startTime
                    updateTime.total = Int32(msgCount)
                }
                if let time = endTime,
                   updateTime.endTime.compare(time) == .orderedDescending || updateTime.endTime == .distantPast {
                    updateTime.end = time
                }
                updateTime.update = Date()
            }
            _ = context.saveUpstreamIfNeeded()
        }
    }
}

// CoreData operations
extension LastUpdatedStore {
    private func lastUpdate(by labelID: LabelID, userID: UserID, type: ViewMode) -> LabelCount? {
        switch type {
        case .singleMessage:
            return LabelUpdate.lastUpdate(
                by: labelID.rawValue,
                userID: userID.rawValue,
                inManagedObjectContext: context
            )
        case .conversation:
            return ConversationCount.lastContextUpdate(
                by: labelID.rawValue,
                userID: userID.rawValue,
                inManagedObjectContext: context
            )
        }
    }

    private func lastUpdates(by labelIDs: [LabelID], userID: UserID, type: ViewMode) -> [LabelCount] {
        switch type {
        case .singleMessage:
            return LabelUpdate.fetchLastUpdates(
                by: labelIDs.map(\.rawValue),
                userID: userID.rawValue,
                context: context
            )
        case .conversation:
            return ConversationCount.fetchConversationCounts(
                by: labelIDs.map(\.rawValue),
                userID: userID.rawValue,
                context: context
            )
        }
    }

    private func lastUpdateDefault(by labelID: LabelID, userID: UserID, type: ViewMode) -> LabelCount {
        switch type {
        case .singleMessage:
            if let update = LabelUpdate.lastUpdate(
                by: labelID.rawValue,
                userID: userID.rawValue,
                inManagedObjectContext: context
            ) {
                return update
            } else {
                return LabelUpdate.newLabelUpdate(
                    by: labelID.rawValue,
                    userID: userID.rawValue,
                    inManagedObjectContext: context)
            }
        case .conversation:
            if let update = ConversationCount.lastContextUpdate(
                by: labelID.rawValue,
                userID: userID.rawValue,
                inManagedObjectContext: context
            ) {
                return update
            } else {
                return ConversationCount.newConversationCount(
                    by: labelID.rawValue,
                    userID: userID.rawValue,
                    inManagedObjectContext: context
                )
            }
        }
    }
}
