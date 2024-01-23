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
import UIKit

final class SnapshotPublisher<T: NSFetchRequestResult>: NSObject, NSFetchedResultsControllerDelegate where T: Hashable {
    private let fetchedResultsController: NSFetchedResultsController<T>
    private let didChangedContentSubject = PassthroughSubject<NSDiffableDataSourceSnapshotReference, Never>()

    var contentDidChange: AnyPublisher<NSDiffableDataSourceSnapshotReference, Never> {
        didChangedContentSubject.eraseToAnyPublisher()
    }

    init(
        entityName: String,
        predicate: NSPredicate,
        sortDescriptors: [NSSortDescriptor],
        sectionNameKeyPath: String? = nil,
        contextProvider: CoreDataContextProviderProtocol
    ) {
        self.fetchedResultsController = contextProvider.createFetchedResultsController(
            entityName: entityName,
            predicate: predicate,
            sortDescriptors: sortDescriptors,
            fetchBatchSize: 0,
            sectionNameKeyPath: sectionNameKeyPath
        )
        super.init()
    }

    func start() {
        fetchedResultsController.delegate = self

        fetchedResultsController.managedObjectContext.performAndWait {
            do {
                try fetchedResultsController.performFetch()
            } catch {
                PMAssertionFailure(error)
            }
        }
    }

    func controller(
        _ controller: NSFetchedResultsController<NSFetchRequestResult>,
        didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference
    ) {
        handleSnapshotMapping(
            controller: controller,
            didChangeContentWith: snapshot as NSDiffableDataSourceSnapshot<String, NSManagedObjectID>
        )
    }

    private func handleSnapshotMapping(
        controller: NSFetchedResultsController<NSFetchRequestResult>,
        didChangeContentWith snapshot: NSDiffableDataSourceSnapshot<String, NSManagedObjectID>
    ) {
        let snapshot = snapshot as NSDiffableDataSourceSnapshot<String, NSManagedObjectID>
        var newSnapShot = NSDiffableDataSourceSnapshot<String, T>()

        let sections = snapshot.sectionIdentifiers
        newSnapShot.appendSections(sections)
        for section in sections {
            let rows = snapshot.itemIdentifiers(inSection: section).compactMap { objectID in
                try? controller.managedObjectContext.existingObject(with: objectID) as? T
            }
            newSnapShot.appendItems(rows, toSection: section)
        }
        didChangedContentSubject.send(newSnapShot as NSDiffableDataSourceSnapshotReference)
    }
}
