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
    private let coreDataService: CoreDataService

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

    func makeComposerMainContext() -> NSManagedObjectContext {
        return coreDataService.makeComposerMainContext()
    }

    func enqueue<T>(block: @escaping (NSManagedObjectContext) -> T) -> T {
        var output: T!

        serialQueue.addOperation { [weak self] in
            guard let self = self else { return }

            let context = self.container.newBackgroundContext()

            output = context.performAndWait {
                block(context)
            }
        }

        serialQueue.waitUntilAllOperationsAreFinished()

        return output
    }

    func enqueue<T>(block: @escaping (NSManagedObjectContext) throws -> T) throws -> T {
        let result = enqueue { (context: NSManagedObjectContext) -> Result<T, Error> in
            do {
                let output = try block(context)
                return .success(output)
            } catch {
                return .failure(error)
            }
        }

        return try result.get()
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

    func makeNewBackgroundContext() -> NSManagedObjectContext {
        container.newBackgroundContext()
    }

    func read<T>(block: (NSManagedObjectContext) -> T) -> T {
        rethrowingRead(block: block)
    }

    func read<T>(block: (NSManagedObjectContext) throws -> T) throws -> T {
        try rethrowingRead(block: block)
    }

    private func rethrowingRead<T>(block: (NSManagedObjectContext) throws -> T) rethrows -> T {
        let context = rootSavingContext

        return try context.performAndWait {
            try block(context)
        }
    }
}
