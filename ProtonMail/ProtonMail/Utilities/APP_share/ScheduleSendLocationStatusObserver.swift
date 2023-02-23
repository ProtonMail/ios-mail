// Copyright (c) 2022 Proton Technologies AG
//
// This file is part of ProtonMail.
//
// ProtonMail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// ProtonMail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with ProtonMail. If not, see https://www.gnu.org/licenses/.

import CoreData
import Foundation
import ProtonCore_DataModel

/// This class is used to observe the message count of the location (LabelID == 12).
final class ScheduleSendLocationStatusObserver: NSObject, NSFetchedResultsControllerDelegate {
    private let context: NSManagedObjectContext
    private var havingScheduledSendMessageUpdate: ((Bool) -> Void)?
    private var isHavingScheduledSendMessage = false {
        didSet {
            if isHavingScheduledSendMessage != oldValue {
                havingScheduledSendMessageUpdate?(isHavingScheduledSendMessage)
            }
        }
    }
    private let userID: UserID

    init(
        contextProvider: CoreDataContextProviderProtocol,
        userID: UserID
    ) {
        self.context = contextProvider.mainContext
        self.userID = userID
    }

    private lazy var fetchResultsController: NSFetchedResultsController<Message>? = {
        let fetchRequest = NSFetchRequest<Message>(entityName: Message.Attributes.entityName)
        fetchRequest.predicate = NSPredicate(
            format: "(ANY labels.labelID = %@) AND (%K > %d) AND (%K == %@) AND (%K == %@)",
            Message.Location.scheduled.rawValue,
            Message.Attributes.messageStatus,
            0,
            Message.Attributes.userID,
            userID.rawValue,
            Message.Attributes.isSoftDeleted,
            NSNumber(false)
        )
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: #keyPath(Message.time), ascending: false),
            NSSortDescriptor(key: #keyPath(Message.order), ascending: false)
        ]
        return NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
    }()

    private lazy var conversationCountFetchedController: NSFetchedResultsController<ConversationCount>? = {
        let fetchRequest = NSFetchRequest<ConversationCount>(entityName: ConversationCount.Attributes.entityName)
        fetchRequest.predicate = NSPredicate(
            format: "%K == %@ AND %K == %@",
            ConversationCount.Attributes.userID,
            userID.rawValue,
            ConversationCount.Attributes.labelID,
            Message.Location.scheduled.rawValue
        )
        let sortDescriptor = NSSortDescriptor(key: ConversationCount.Attributes.userID,
                                              ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        return NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
    }()

    private lazy var messageCountController: NSFetchedResultsController<LabelUpdate>? = {
        let fetchRequest = NSFetchRequest<LabelUpdate>(entityName: LabelUpdate.Attributes.entityName)
        fetchRequest.predicate = NSPredicate(
            format: "%K == %@ AND %K == %@",
            LabelUpdate.Attributes.userID,
            userID.rawValue,
            LabelUpdate.Attributes.labelID,
            Message.Location.scheduled.rawValue
        )
        let sortDescriptor = NSSortDescriptor(key: LabelUpdate.Attributes.userID,
                                              ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        return NSFetchedResultsController(fetchRequest: fetchRequest,
                                          managedObjectContext: context,
                                          sectionNameKeyPath: nil,
                                          cacheName: nil)
    }()

    func observe(statusUpdate: @escaping (Bool) -> Void) -> Bool {
        self.havingScheduledSendMessageUpdate = statusUpdate

        fetchResultsController?.delegate = self
        try? fetchResultsController?.performFetch()

        conversationCountFetchedController?.delegate = self
        try? conversationCountFetchedController?.performFetch()

        messageCountController?.delegate = self
        try? messageCountController?.performFetch()

        let isHavingScheduledSendMessage = calculateIsHavingScheduledMessage()

        return isHavingScheduledSendMessage
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        let newValue = calculateIsHavingScheduledMessage()
        isHavingScheduledSendMessage = newValue
    }

    private func calculateIsHavingScheduledMessage() -> Bool {
        let scheduledMsgCount = fetchResultsController?.fetchedObjects?.count ?? 0
        let conversationCount = Int(conversationCountFetchedController?.fetchedObjects?.first?.total ?? 0)
        let messageCount = Int(messageCountController?.fetchedObjects?.first?.total ?? 0)

        let isHavingScheduledSendMessage = scheduledMsgCount > 0 || conversationCount > 0 || messageCount > 0
        return isHavingScheduledSendMessage
    }
}
