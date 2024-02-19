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

import CoreData

final class MessagesAssignedToLabelIDObserver: NSObject, NSFetchedResultsControllerDelegate {
    private let labelID: LabelID
    private let userID: UserID
    private let contextProvider: CoreDataContextProviderProtocol
    private var havingMessageUpdate: ((Bool) -> Void)?
    private var isThereAnyMessageInTheLocation = false {
        didSet {
            if isThereAnyMessageInTheLocation != oldValue {
                havingMessageUpdate?(isThereAnyMessageInTheLocation)
            }
        }
    }

    init(
        labelIDToObserve: LabelID,
        userID: UserID,
        contextProvider: CoreDataContextProviderProtocol
    ) {
        self.labelID = labelIDToObserve
        self.userID = userID
        self.contextProvider = contextProvider
    }

    private lazy var messageFetchResultsController: NSFetchedResultsController<Message> = {
        var subPredicates: [NSPredicate] = []
        let labelIDPredicate = NSPredicate(
            format: "ANY labels.labelID = %@",
            labelID.rawValue
        )
        let statusPredicate = NSPredicate(
            format: "%K > %d",
            Message.Attributes.messageStatus,
            0
        )
        let userIDPredicate = NSPredicate(
            format: "%K == %@",
            Message.Attributes.userID,
            userID.rawValue
        )
        let softDeletePredicate = NSPredicate(
            format: "%K == %@",
            Message.Attributes.isSoftDeleted,
            NSNumber(false)
        )
        let predicate = NSCompoundPredicate(
            andPredicateWithSubpredicates: [
                labelIDPredicate,
                statusPredicate,
                userIDPredicate,
                softDeletePredicate
            ]
        )
        let sortDescriptors = [
            NSSortDescriptor(key: #keyPath(Message.time), ascending: false),
            NSSortDescriptor(key: #keyPath(Message.order), ascending: false)
        ]
        return contextProvider.createFetchedResultsController(
            entityName: Message.Attributes.entityName,
            predicate: predicate,
            sortDescriptors: sortDescriptors,
            fetchBatchSize: 5,
            sectionNameKeyPath: nil
        )
    }()

    private lazy var conversationCountFetchResultsController: NSFetchedResultsController<ConversationCount> = {
        let userIDPredicate = NSPredicate(
            format: "%K == %@",
            ConversationCount.Attributes.userID,
            userID.rawValue
        )
        let labelIDPredicate = NSPredicate(
            format: "%K == %@",
            ConversationCount.Attributes.labelID,
            labelID.rawValue
        )
        let predicate = NSCompoundPredicate(
            andPredicateWithSubpredicates: [
                userIDPredicate,
                labelIDPredicate
            ]
        )
        let sortDescriptor = NSSortDescriptor(
            key: ConversationCount.Attributes.userID,
            ascending: true
        )
        return contextProvider.createFetchedResultsController(
            entityName: ConversationCount.Attributes.entityName,
            predicate: predicate,
            sortDescriptors: [sortDescriptor],
            fetchBatchSize: 5,
            sectionNameKeyPath: nil
        )
    }()

    private lazy var messageCountFetchResultsController: NSFetchedResultsController<LabelUpdate> = {
        let userIDPredicate = NSPredicate(
            format: "%K == %@",
            LabelUpdate.Attributes.userID,
            userID.rawValue
        )
        let labelIDPredicate = NSPredicate(
            format: "%K == %@",
            LabelUpdate.Attributes.labelID,
            labelID.rawValue
        )
        let predicate = NSCompoundPredicate(
            andPredicateWithSubpredicates: [userIDPredicate, labelIDPredicate]
        )
        let sortDescriptor = NSSortDescriptor(
            key: LabelUpdate.Attributes.userID,
            ascending: true
        )
        return contextProvider.createFetchedResultsController(
            entityName: LabelUpdate.Attributes.entityName,
            predicate: predicate,
            sortDescriptors: [sortDescriptor],
            fetchBatchSize: 5,
            sectionNameKeyPath: nil
        )
    }()

    func observe(statusUpdate: @escaping (Bool) -> Void) throws -> Bool {
        self.havingMessageUpdate = statusUpdate
        return try contextProvider.write { _ in
            self.messageFetchResultsController.delegate = self
            try? self.messageFetchResultsController.performFetch()

            self.conversationCountFetchResultsController.delegate = self
            try? self.conversationCountFetchResultsController.performFetch()

            self.messageCountFetchResultsController.delegate = self
            try? self.messageCountFetchResultsController.performFetch()

            return self.calculateIsHavingMessage()
        }
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        let newValue = calculateIsHavingMessage()
        self.isThereAnyMessageInTheLocation = newValue
    }

    private func calculateIsHavingMessage() -> Bool {
        let messageCount = messageFetchResultsController.fetchedObjects?.count ?? 0
        let conversationLabelCount = Int( conversationCountFetchResultsController.fetchedObjects?.first?.total ?? 0)
        let messageLabelCount = Int( messageCountFetchResultsController.fetchedObjects?.first?.total ?? 0)

        let isHavingMessage = messageCount > 0 || conversationLabelCount > 0 || messageLabelCount > 0
        return isHavingMessage
    }
}
