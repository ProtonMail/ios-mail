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

import Combine
import CoreData

class DataPublisher<T: NSFetchRequestResult>: NSObject, NSFetchedResultsControllerDelegate {
    private let fetchedResultsController: NSFetchedResultsController<T>
    private let contentDidChangeSubject = PassthroughSubject<[T], Never>()

    var contentDidChange: AnyPublisher<[T], Never> {
        contentDidChangeSubject.eraseToAnyPublisher()
    }

    init(
        entityName: String,
        predicate: NSPredicate?,
        sortDescriptors: [NSSortDescriptor],
        contextProvider: CoreDataContextProviderProtocol
    ) {
        fetchedResultsController = contextProvider.createFetchedResultsController(
            entityName: entityName,
            predicate: predicate,
            sortDescriptors: sortDescriptors,
            fetchBatchSize: 0,
            sectionNameKeyPath: nil
        )
        super.init()
    }

    func start() {
        fetchedResultsController.delegate = self

        fetchedResultsController.managedObjectContext.perform {
            do {
                try self.fetchedResultsController.performFetch()
                self.publishFetchedObjects()
            } catch {
                PMAssertionFailure(error)
            }
        }
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        publishFetchedObjects()
    }

    private func publishFetchedObjects() {
        guard let fetchedObjects = fetchedResultsController.fetchedObjects else {
            PMAssertionFailure("fetchedObjects accessed before performFetch")
            return
        }
        contentDidChangeSubject.send(fetchedObjects)
    }
}
