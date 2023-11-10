//
//  CoreDataService.swift
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
import UIKit

#if !APP_EXTENSION
import LifetimeTracker
#endif

class CoreDataService: CoreDataContextProviderProtocol {
    static let shared = CoreDataService(container: CoreDataStore.shared.container)

    private let container: NSPersistentContainer
    private let backgroundContext: NSManagedObjectContext
    private static let queueNamePrefix = "ch.protonmail.CoreDataService"

    var mainContext: NSManagedObjectContext {
        container.viewContext
    }

    private let serialQueue: OperationQueue = {
        let persistentContainerQueue = OperationQueue()
        persistentContainerQueue.name = "\(CoreDataService.queueNamePrefix).writeQueue"
        persistentContainerQueue.maxConcurrentOperationCount = 1
        return persistentContainerQueue
    }()

    init(container: NSPersistentContainer) {
        self.container = container
        backgroundContext = container.newBackgroundContext()
        backgroundContext.name = "\(Self.queueNamePrefix).backgroundContext"
        backgroundContext.automaticallyMergesChangesFromParent = true
        backgroundContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump

        #if !APP_EXTENSION
        trackLifetime()
        #endif
    }

    // MARK: - methods
    func managedObjectIDForURIRepresentation(_ urlString: String) -> NSManagedObjectID? {
        if let url = URL(string: urlString), url.scheme == "x-coredata" {
            let psc = self.container.persistentStoreCoordinator
            return psc.managedObjectID(forURIRepresentation: url)
        }
        return nil
    }

    /// Executes the block synchronously and immediately - without a serial queue.
    func read<T>(block: (NSManagedObjectContext) -> T) -> T {
        let context: NSManagedObjectContext

        let hasBeenCalledFromTheWriteMethod = OperationQueue.current == serialQueue
        if hasBeenCalledFromTheWriteMethod {
            context = backgroundContext
        } else {
            let newContext = container.newBackgroundContext()
            newContext.automaticallyMergesChangesFromParent = true
            newContext.name = "\(Self.queueNamePrefix).readContext"
            context = newContext
        }

        var output: T!
        let startTime = Date()

        context.performAndWait {
            output = block(context)
        }

        checkForOverlyLongExecutionIfOnMainThread(startTime: startTime)

        return output
    }

    /*
     Executes the block synchronously and immediately - without a serial queue.

     This is the throwing variant of `read`. We might be able to adopt `rethrows` once we drop iOS 14 support.
     */
    func read<T>(block: (NSManagedObjectContext) throws -> T) throws -> T {
        let result = read { (context: NSManagedObjectContext) -> Result<T, Error> in
            do {
                let output = try block(context)
                return .success(output)
            } catch {
                return .failure(error)
            }
        }

        return try result.get()
    }

    /*
     Executes the block synchronously on a serial queue.
     This has the following implications:
     - calling this method will block the current thread
     - the block will only be executed once the previously enqueued blocks are finished
     - any changes written to the context will be saved automatically - no need to call `context.save()`
     - This method mimics `context.performAndWait` in that it can be called from within itself. Doing so will not cause
     a deadlock: the nested call will be executed immediately, without adding it to the queue.

     Ignore the `@escaping` annotation, the method is synchronous.
     */
    func write<T>(block: @escaping (NSManagedObjectContext) throws -> T) throws -> T {
        let hasBeenCalledFromAnotherWriteMethod = OperationQueue.current == serialQueue
        let context = backgroundContext
        var result: Result<T, Error>!

        if hasBeenCalledFromAnotherWriteMethod {
            context.performAndWait {
                do {
                    let output = try block(context)
                    result = .success(output)
                } catch {
                    result = .failure(error)
                }
            }
        } else {
            serialQueue.addOperation {
                context.performAndWait {
                    do {
                        let output = try block(context)

                        if context.hasChanges {
                            try context.save()
                        }

                        result = .success(output)
                    } catch {
                        result = .failure(error)
                    }
                }
            }

            let startTime = Date()

            serialQueue.waitUntilAllOperationsAreFinished()

            checkForOverlyLongExecutionIfOnMainThread(startTime: startTime)
        }

        return try result.get()
    }

    func deleteAllData() async {
        await withCheckedContinuation { continuation in
            serialQueue.addOperation {
                CoreDataStore.deleteDataStore()
                continuation.resume()
            }
        }
    }

    private func checkForOverlyLongExecutionIfOnMainThread(startTime: Date, caller: StaticString = #function) {
        let elapsedTime = Date().timeIntervalSince(startTime)
        if Thread.isMainThread && elapsedTime > 0.2 {
            Analytics.shared.sendError(
                .assertionFailure(
                    message: "\(self).\(caller) took too long on the main thread", 
                    caller: caller, 
                    file: #file,
                    line: #line
                )
            )
        }
    }

    func enqueueOnRootSavingContext(block: @escaping (_ context: NSManagedObjectContext) -> Void) {
        do {
            try write(block: block)
        } catch {
            PMAssertionFailure(error)
        }
    }

    func performOnRootSavingContext(block: @escaping (_ context: NSManagedObjectContext) -> Void) {
        do {
            try write(block: block)
        } catch {
            PMAssertionFailure(error)
        }
    }

    func performAndWaitOnRootSavingContext(block: @escaping (_ context: NSManagedObjectContext) -> Void) {
        do {
            try write(block: block)
        } catch {
            PMAssertionFailure(error)
        }
    }

    func performAndWaitOnRootSavingContext<T>(block: @escaping (NSManagedObjectContext) throws -> T) throws -> T {
        try write(block: block)
    }

    func createFetchedResultsController<T>(
        entityName: String,
        predicate: NSPredicate,
        sortDescriptors: [NSSortDescriptor],
        fetchBatchSize: Int,
        sectionNameKeyPath: String? = nil,
        onMainContext: Bool
    ) -> NSFetchedResultsController<T> {
        let fetchRequest: NSFetchRequest<T> = NSFetchRequest(entityName: entityName)
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = sortDescriptors
        fetchRequest.fetchBatchSize = fetchBatchSize
        return NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: backgroundContext,
            sectionNameKeyPath: sectionNameKeyPath,
            cacheName: nil
        )
    }
}

#if !APP_EXTENSION
extension CoreDataService: LifetimeTrackable {
    static var lifetimeConfiguration: LifetimeConfiguration {
        .init(maxCount: 1)
    }
}
#endif
