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
import ProtonCoreDataModel
import UIKit

// sourcery: mock
protocol LastUpdatedStoreProtocol {
    func cleanUp(userId: UserID)

    func updateEventID(by userID: UserID, eventID: String)
    func lastEventID(userID: UserID) -> String
    func lastEventUpdateTime(userID: UserID) -> Date?

    func lastUpdate(by labelID: LabelID, userID: UserID, type: ViewMode) -> LabelCountEntity?
    func unreadCount(by labelID: LabelID, userID: UserID, type: ViewMode) -> Int
    func updateUnreadCount(by labelID: LabelID,
                           userID: UserID,
                           unread: Int,
                           total: Int?,
                           type: ViewMode,
                           shouldSave: Bool)
    func batchUpdateUnreadCounts(counts: [CountData], userID: UserID, type: ViewMode) throws
    func removeUpdateTime(by userID: UserID)
    func resetCounter(labelID: LabelID, userID: UserID)
    func removeUpdateTimeExceptUnread(by userID: UserID)
    func getUnreadCounts(by labelIDs: [LabelID], userID: UserID, type: ViewMode) -> [String: Int]
    func updateLastUpdatedTime(labelID: LabelID,
                               isUnread: Bool,
                               startTime: Date,
                               endTime: Date?,
                               msgCount: Int,
                               userID: UserID,
                               type: ViewMode)
}

final class LastUpdatedStore: LastUpdatedStoreProtocol {

    let contextProvider: CoreDataContextProviderProtocol

    init(contextProvider: CoreDataContextProviderProtocol) {
        self.contextProvider = contextProvider
    }

    func cleanUp(userId: UserID) {
            self.contextProvider.performOnRootSavingContext { context in
                _ = UserEvent.remove(by: userId.rawValue, inManagedObjectContext: context)
                _ = LabelUpdate.remove(by: userId.rawValue, inManagedObjectContext: context)
                _ = ConversationCount.remove(by: userId.rawValue, inManagedObjectContext: context)
            }
    }
}

// MARK: - Event ID

extension LastUpdatedStore {
    func updateEventID(by userID: UserID, eventID: String) {
            contextProvider.performAndWaitOnRootSavingContext { context in
                let event = self.eventIDDefault(by: userID, in: context)
                event.eventID = eventID
                event.updateTime = Date()
                _ = context.saveUpstreamIfNeeded()
            }
    }

    private func eventIDDefault(by userID: UserID, in context: NSManagedObjectContext) -> UserEvent {
        if let update = UserEvent.userEvent(by: userID.rawValue,
                                            inManagedObjectContext: context) {
            return update
        }
        return UserEvent.newUserEvent(userID: userID.rawValue,
                                      inManagedObjectContext: context)
    }

    func lastEventID(userID: UserID) -> String {
        findLastEvent(userID: userID, andGetProperty: \.eventID, defaultValue: "")
    }

    func lastEventUpdateTime(userID: UserID) -> Date? {
        findLastEvent(userID: userID, andGetProperty: \.updateTime, defaultValue: nil)
    }

    private func findLastEvent<T>(userID: UserID, andGetProperty keyPath: KeyPath<UserEvent, T>, defaultValue: T) -> T {
        contextProvider.read { context in
            UserEvent.userEvent(by: userID.rawValue, inManagedObjectContext: context)?[keyPath: keyPath] ?? defaultValue
        }
    }
}

// MARK: - Conversation/Message Counts

extension LastUpdatedStore {
    func lastUpdate(by labelID: LabelID, userID: UserID, type: ViewMode) -> LabelCountEntity? {
        contextProvider.read { context in
            let labelCount: LabelCount?

            switch type {
            case .singleMessage:
                labelCount = LabelUpdate.lastUpdate(
                    by: labelID.rawValue,
                    userID: userID.rawValue,
                    inManagedObjectContext: context
                )
            case .conversation:
                labelCount = ConversationCount.lastContextUpdate(
                    by: labelID.rawValue,
                    userID: userID.rawValue,
                    inManagedObjectContext: context
                )
            }

            return labelCount.map { LabelCountEntity(labelCount: $0) }
        }
    }

    func getUnreadCounts(by labelIDs: [LabelID], userID: UserID, type: ViewMode) -> [String: Int] {
        contextProvider.read { context in
            lastUpdates(by: labelIDs, userID: userID, type: type, in: context).reduce(into: [:]) { acc, labelCount in
                acc[labelCount.labelID] = Int(labelCount.unread)
            }
        }
    }

    func unreadCount(by labelID: LabelID, userID: UserID, type: ViewMode) -> Int {
        let unreadCount = lastUpdate(by: labelID, userID: userID, type: type)?.unread ?? 0
        return max(unreadCount, 0)
    }

    func updateUnreadCount(
        by labelID: LabelID,
        userID: UserID,
        unread: Int,
        total: Int?,
        type: ViewMode,
        shouldSave: Bool
    ) {
        contextProvider.performAndWaitOnRootSavingContext { context in
            let update: LabelCount = self.lastUpdateDefault(by: labelID, userID: userID, type: type, in: context)
            update.unread = Int32(unread)
            if let total = total {
                update.total = Int32(total)
            }

            if shouldSave {
                _ = context.saveUpstreamIfNeeded()
            }
        }
    }

    func batchUpdateUnreadCounts(counts: [CountData], userID: UserID, type: ViewMode) throws {
        try contextProvider.performAndWaitOnRootSavingContext { context in
            for count in counts {
                let update = self.lastUpdateDefault(by: count.labelID, userID: userID, type: type, in: context)
                update.unread = Int32(count.unread)
                update.total = Int32(count.total)
            }

            if let error = context.saveUpstreamIfNeeded() {
                throw error
            }
        }
    }

    /// Reset counter value to zero
    /// - Parameters:
    ///   - type: Optional, nil will reset conversation and message counter
    func resetCounter(labelID: LabelID, userID: UserID) {
        contextProvider.performAndWaitOnRootSavingContext { context in
            let conversationCount: LabelCount = self.lastUpdateDefault(
                by: labelID,
                userID: userID,
                type: .conversation,
                in: context
            )
            let messageCount: LabelCount = self.lastUpdateDefault(by: labelID, userID: userID, type: .singleMessage, in: context)
            let counts: [LabelCount] = [conversationCount, messageCount]
            counts.forEach { count in
                count.total = 0
                count.unread = 0
                count.unreadStart = nil
                count.unreadEnd = nil
                count.unreadUpdate = nil
            }
            _ = context.saveUpstreamIfNeeded()
        }
    }

    // remove all updates for a user
    func removeUpdateTime(by userID: UserID) {
        contextProvider.performAndWaitOnRootSavingContext { context in
            _ = LabelUpdate.remove(by: userID.rawValue, inManagedObjectContext: context)
            _ = ConversationCount.remove(by: userID.rawValue, inManagedObjectContext: context)
        }
    }

    func removeUpdateTimeExceptUnread(by userID: UserID) {
        contextProvider.performAndWaitOnRootSavingContext { context in
            let labelUpdates = LabelUpdate.lastUpdates(userID: userID.rawValue, inManagedObjectContext: context)
            let conversationCounts = ConversationCount.getConversationCounts(
                userID: userID.rawValue,
                inManagedObjectContext: context
            )
            let labelCounts: [LabelCount] = labelUpdates + conversationCounts
            labelCounts.forEach { $0.resetDataExceptUnread() }

            _ = context.saveUpstreamIfNeeded()
        }
    }

    func updateLastUpdatedTime(
        labelID: LabelID,
        isUnread: Bool,
        startTime: Date,
        endTime: Date?,
        msgCount: Int,
        userID: UserID,
        type: ViewMode
    ) {
        contextProvider.performAndWaitOnRootSavingContext { context in
            let updateTime: LabelCount = self.lastUpdateDefault(
                by: labelID,
                userID: userID,
                type: type,
                in: context
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

            if let error = context.saveUpstreamIfNeeded() {
                assertionFailure("\(error)")
            }
        }
    }
}

// CoreData operations
extension LastUpdatedStore {
    private func lastUpdates(by labelIDs: [LabelID], userID: UserID, type: ViewMode, in context: NSManagedObjectContext) -> [LabelCount] {
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

    private func lastUpdateDefault(by labelID: LabelID, userID: UserID, type: ViewMode, in context: NSManagedObjectContext) -> LabelCount {
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
