// Copyright (c) 2021 Proton AG
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

class ConversationUpdateProvider: NSObject, NSFetchedResultsControllerDelegate {
    private let conversationID: ConversationID
    private let contextProvider: CoreDataContextProviderProtocol
    private var conversationDidUpdate: ((ConversationEntity?) -> Void)?

    private lazy var fetchedController: NSFetchedResultsController<Conversation> = {
        let predicate = NSPredicate(
            format: "%K == %@",
            Conversation.Attributes.conversationID.rawValue,
            self.conversationID.rawValue
        )
        let sortDescriptors = [
            NSSortDescriptor(key: #keyPath(Conversation.order), ascending: true)
        ]
        return contextProvider.createFetchedResultsController(
            entityName: Conversation.Attributes.entityName,
            predicate: predicate,
            sortDescriptors: sortDescriptors,
            fetchBatchSize: 0,
            sectionNameKeyPath: nil
        )
    }()

    init(conversationID: ConversationID,
         contextProvider: CoreDataContextProviderProtocol) {
        self.conversationID = conversationID
        self.contextProvider = contextProvider
    }

    func observe(conversationDidUpdate: @escaping (ConversationEntity?) -> Void) {
        self.conversationDidUpdate = conversationDidUpdate
        fetchedController.delegate = self
        fetchedController.managedObjectContext.perform {
            try? self.fetchedController.performFetch()
        }
    }

    func stopObserve() {
        fetchedController.delegate = nil
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        guard let conversation = controller.fetchedObjects?.first as? Conversation else {
            conversationDidUpdate?(nil)
            return
        }
        conversationDidUpdate?(ConversationEntity(conversation))
    }
}
