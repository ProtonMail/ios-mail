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

class DataPublisher<T: NSFetchRequestResult>: NSObject, NSFetchedResultsControllerDelegate {
    private let fetchedResultsController: NSFetchedResultsController<T>

    var onContentChanged: (([T]) -> Void)?

    init(
        entityName: String,
        predicate: NSPredicate,
        sortDescriptors: [NSSortDescriptor],
        contextProvider: CoreDataContextProviderProtocol,
        onContentChanged: (([T]) -> Void)?
    ) {
        self.onContentChanged = onContentChanged
        let fetchRequest: NSFetchRequest<T> = NSFetchRequest(entityName: entityName)
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = sortDescriptors
        self.fetchedResultsController = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: contextProvider.mainContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        super.init()
        self.fetchedResultsController.delegate = self
        try? self.fetchedResultsController.performFetch()
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        guard let fetchedDatas = controller.fetchedObjects as? [T] else {
            assertionFailure("NSFetchedResultController is misconfigured.")
            return
        }
        onContentChanged?(fetchedDatas)
    }
}
