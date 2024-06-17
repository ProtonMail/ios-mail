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
@testable import ProtonMail

class MockCoreDataContextProvider: CoreDataContextProviderProtocol {
    private let container = MockCoreDataStore.testPersistentContainer
    let coreDataService: CoreDataService

    var viewContext: NSManagedObjectContext {
        container.viewContext
    }

    private let serialQueue: OperationQueue = {
        let persistentContainerQueue = OperationQueue()
        persistentContainerQueue.maxConcurrentOperationCount = 1
        return persistentContainerQueue
    }()

    init() {
        coreDataService = CoreDataService(container: container)
    }

    var mainContext: NSManagedObjectContext {
        viewContext
    }

    private var rootSavingContext: NSManagedObjectContext {
        /*
         The unit tests run on the main thread, unless they are `async`.

         To prevent the ConcurrencyDebug flag from triggering a crash we should either:
         - not access `rootSavingContext` on the main thread
         - wrap every access to every Core Data object in `rootSavingContext.performAndWait`

         For now it's the first approach.
         */
        mainContext
    }

    func enqueueOnRootSavingContext(block: (NSManagedObjectContext) -> Void) {
        let context = rootSavingContext

        context.performAndWait {
            block(context)
        }
    }

    func managedObjectIDForURIRepresentation(_ urlString: String) -> NSManagedObjectID? {
        if let url = URL(string: urlString), url.scheme == "x-coredata" {
            let psc = container.persistentStoreCoordinator
            return psc.managedObjectID(forURIRepresentation: url)
        }
        return nil
    }

    func performOnRootSavingContext(block: @escaping (_ context: NSManagedObjectContext) -> Void) {
        let context = rootSavingContext

        context.perform {
            block(context)
        }
    }

    func performAndWaitOnRootSavingContext(block: @escaping (_ context: NSManagedObjectContext) -> Void) {
        let context = rootSavingContext

        context.performAndWait {
            block(context)
        }
    }

    func performAndWaitOnRootSavingContext<T>(block: (_ context: NSManagedObjectContext) throws -> T) throws -> T {
        let context = rootSavingContext

        return try context.performAndWait {
            try block(context)
        }
    }

    func read<T>(block: (NSManagedObjectContext) throws -> T) rethrows -> T {
        let context = rootSavingContext

        return try context.performAndWait {
            try block(context)
        }
    }

    func write<T>(block: @escaping (NSManagedObjectContext) throws -> T) throws -> T {
        return try rootSavingContext.performAndWait {
            let result = try block(rootSavingContext)
            try self.rootSavingContext.save()
            return result
        }
    }

    func writeAsync<T>(block: @escaping @Sendable (NSManagedObjectContext) throws -> T) async throws -> T {
        let context = rootSavingContext

        return try await context.perform {
            let result = try block(context)

            if context.hasChanges {
                try context.save()
            }

            return result
        }
    }

    func deleteAllData() async {
        await coreDataService.deleteAllData()
    }

    func createFetchedResultsController<T>(
        entityName: String,
        predicate: NSPredicate?,
        sortDescriptors: [NSSortDescriptor],
        fetchBatchSize: Int,
        sectionNameKeyPath: String?
    ) -> NSFetchedResultsController<T> {
        let fetchRequest: NSFetchRequest<T> = NSFetchRequest(entityName: entityName)
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = sortDescriptors
        fetchRequest.fetchBatchSize = fetchBatchSize
        return NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: rootSavingContext,
            sectionNameKeyPath: sectionNameKeyPath,
            cacheName: nil
        )
    }
}
