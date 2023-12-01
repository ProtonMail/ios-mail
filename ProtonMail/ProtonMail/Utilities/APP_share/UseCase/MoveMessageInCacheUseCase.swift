// Copyright (c) 2023 Proton Technologies AG
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

import Foundation
import class CoreData.NSManagedObjectContext

protocol MoveMessageInCacheUseCase {
    func execute(params: MoveMessageInCache.Parameters) throws
}

final class MoveMessageInCache: MoveMessageInCacheUseCase {
    private let dependencies: Dependencies

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    func execute(params: Parameters) throws {
        try dependencies.contextProvider.write(block: { context in
            for (index, message) in params.messagesToBeMoved.enumerated() {
                if message.contains(location: .scheduled) && params.targetLocation == LabelLocation.trash.labelID {
                    // Trash schedule message, should move to draft
                    let target = LabelLocation.draft.labelID
                    let scheduled = LabelLocation.scheduled.labelID
                    let sent = LabelLocation.sent.labelID
                    let labelsToMoveFrom = [scheduled, sent]
                    for fromLabel in labelsToMoveFrom {
                        try self.move(entity: message, from: fromLabel, to: target, in: context)
                    }
                } else {
                    try self.move(entity: message, from: params.from[index], to: params.targetLocation, in: context)
                }
            }
        })
    }

    private func move(
        entity: MessageEntity,
        from location: LabelID,
        to targetLocation: LabelID,
        in context: NSManagedObjectContext
    ) throws {
        guard let message = try context.existingObject(with: entity.objectID.rawValue) as? Message else {
            throw MoveMessageInCacheError.canNotFindMessageInCache
        }

        self.updateUnreadCounterForRemovedLabelIfNeeded(message: message, previousLocation: location)
        self.addNewLabel(to: message, from: location, to: targetLocation)
    }

    private func addNewLabel(to message: Message, from location: LabelID, to targetLocation: LabelID) {
        if let addedLabelID = message.add(labelID: targetLocation.rawValue) {
            switch addedLabelID {
            case Message.Location.trash.rawValue:
                handleMessageBeingMovedToTrash(message: message, fromLocation: location)
            case Message.Location.spam.rawValue:
                handleMessageBeingMovedToSpam(message: message, fromLocation: location)
            default:
                message.add(labelID: Message.Location.almostAllMail.rawValue)
            }
            if message.unRead {
                updateUnreadCountForAddedLabelIfNeeded(
                    addedLabelID: .init(addedLabelID),
                    message: message
                )
            }
        }
    }

    private func handleMessageBeingMovedToTrash(message: Message, fromLocation: LabelID) {
        let labelsToBeRemoved = findLabelsToBeRemovedInSpamAndTrash(message: message, fromLocation: fromLocation)
        labelsToBeRemoved.forEach { label in
            if let removedLabelID = message.remove(labelID: label), message.unRead {
                updateUnreadCounter(plus: false, labelID: .init(removedLabelID))
                if let labelID = message.selfSent(labelID: removedLabelID) {
                    updateUnreadCounter(plus: false, labelID: .init(labelID))
                }
            }
        }
        message.unRead = false
        dependencies.pushUpdater.remove(
            notificationIdentifiers: [message.notificationId]
        )
        message.remove(labelID: Message.Location.almostAllMail.rawValue)
    }

    private func handleMessageBeingMovedToSpam(message: Message, fromLocation: LabelID) {
        let labelsToBeRemoved = findLabelsToBeRemovedInSpamAndTrash(message: message, fromLocation: fromLocation)
        labelsToBeRemoved.forEach { label in
            message.remove(labelID: label)
        }
        message.remove(labelID: Message.Location.almostAllMail.rawValue)
    }

    private func findLabelsToBeRemovedInSpamAndTrash(message: Message, fromLocation: LabelID) -> [String] {
        // find labels to be removed
        var labelsToBeRemoved = message.getNormalLabelIDs()
        labelsToBeRemoved.append(Message.Location.starred.rawValue)

        // If the action is performed in allmail folder, do not remove the allmail label since all the message should has this.
        if fromLocation != Message.Location.allmail.labelID {
            labelsToBeRemoved.append(Message.Location.allmail.rawValue)
        }
        return labelsToBeRemoved
    }

    private func updateUnreadCountForAddedLabelIfNeeded(
        addedLabelID: LabelID,
        message: Message
    ) {
        if message.unRead {
            updateUnreadCounter(plus: true, labelID: addedLabelID)
            if let labelID = message.selfSent(labelID: addedLabelID.rawValue) {
                updateUnreadCounter(plus: true, labelID: .init(labelID))
            }
        }
    }

    private func updateUnreadCounterForRemovedLabelIfNeeded(
        message: Message,
        previousLocation: LabelID
    ) {
        if let removedLabelID = message.remove(labelID: previousLocation.rawValue) {
            updateUnreadCounter(plus: false, labelID: .init(removedLabelID))
            if let labelID = message.selfSent(labelID: previousLocation.rawValue) {
                updateUnreadCounter(plus: false, labelID: .init(labelID))
            }
        }
    }

    private func updateUnreadCounter(plus: Bool, labelID: LabelID) {
        let offset = plus ? 1 : -1
        for viewType in ViewMode.allCases {
            let labelCount = dependencies.lastUpdatedStore.lastUpdate(
                by: labelID,
                userID: dependencies.userID,
                type: viewType
            )
            let unreadCount = Int(labelCount?.unread ?? 0)
            let count = max(unreadCount + offset, 0)
            dependencies.lastUpdatedStore.updateUnreadCount(
                by: labelID,
                userID: dependencies.userID,
                unread: count,
                total: labelCount?.total,
                type: viewType,
                shouldSave: false
            )
        }
    }
}

extension MoveMessageInCache {
    struct Parameters {
        let messagesToBeMoved: [MessageEntity]
        let from: [LabelID]
        let targetLocation: LabelID
    }

    struct Dependencies {
        let contextProvider: CoreDataContextProviderProtocol
        let lastUpdatedStore: LastUpdatedStoreProtocol
        let userID: UserID
        let pushUpdater: PushUpdater
    }

    enum MoveMessageInCacheError: Error {
        case canNotFindMessageInCache
    }
}
