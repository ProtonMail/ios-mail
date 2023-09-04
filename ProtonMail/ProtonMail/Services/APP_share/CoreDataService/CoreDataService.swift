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

class CoreDataService: Service, CoreDataContextProviderProtocol {
    static let shared = CoreDataService(container: CoreDataStore.shared.container)

    static var useNewApproach: Bool {
        let isFeatureFlagOn: Bool = {
            let usersManager = sharedServices.get(by: UsersManager.self)

            guard let activeUser = usersManager.firstUser else {
                return false
            }

            return userCachedStatus.featureFlags(for: activeUser.userID)[.modernizedCoreData]
        }()

        return UIApplication.isDebugOrEnterprise || isFeatureFlagOn
    }

    private let container: NSPersistentContainer
    private let rootSavingContext: NSManagedObjectContext
    private let _mainContext: NSManagedObjectContext
    private let backgroundContext: NSManagedObjectContext
    private static let queueNamePrefix = "ch.protonmail.CoreDataService"
    static var shouldIgnoreContactUpdateInMainContext = false

    var mainContext: NSManagedObjectContext {
        if Self.useNewApproach {
            return container.viewContext
        } else {
            return _mainContext
        }
    }

    private let serialQueue: OperationQueue = {
        let persistentContainerQueue = OperationQueue()
        persistentContainerQueue.name = "\(CoreDataService.queueNamePrefix).writeQueue"
        persistentContainerQueue.maxConcurrentOperationCount = 1
        return persistentContainerQueue
    }()

    init(container: NSPersistentContainer) {
        self.container = container
        self.rootSavingContext = CoreDataService.createRootSavingContext(container.persistentStoreCoordinator)
        self._mainContext = CoreDataService.createMainContext(self.rootSavingContext)
        backgroundContext = container.newBackgroundContext()
        backgroundContext.name = "\(Self.queueNamePrefix).backgroundContext"
        backgroundContext.automaticallyMergesChangesFromParent = true
        backgroundContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump

        #if !APP_EXTENSION
        trackLifetime()
        #endif
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private static func createMainContext(_ parent: NSManagedObjectContext) -> NSManagedObjectContext {
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.parent = parent
        context.mergePolicy = NSRollbackMergePolicy
        context.undoManager = nil
        context.name = "ch.protonmail.MainContext"

        NotificationCenter.default.addObserver(forName: .NSManagedObjectContextWillSave, object: context, queue: nil) { (noti) in
            let context = noti.object as! NSManagedObjectContext
            let insertedObjects = context.insertedObjects
            let numberOfInsertedObjects = insertedObjects.count
            guard numberOfInsertedObjects > 0 else {
                return
            }

            do {
                try context.obtainPermanentIDs(for: Array(insertedObjects))
            } catch {
            }
        }

        NotificationCenter.default.addObserver(forName: .NSManagedObjectContextDidSave, object: parent, queue: nil) { [weak context] (noti) in
            DispatchQueue.main.async {
                guard let _ = noti.object as? NSManagedObjectContext,
                      !shouldIgnoreContactUpdateInMainContext,
                      let context = context else {
                    return
                }
                let mergeChanges = {
                    if let updatedObjects = (noti.userInfo?[NSUpdatedObjectsKey] as? Set<NSManagedObject>) {
                        for object in updatedObjects {
                            context.object(with: object.objectID).willAccessValue(forKey: nil)
                        }
                    }
                    context.mergeChanges(fromContextDidSave: noti)
                }
                context.perform(mergeChanges)
            }

        }

        return context
    }

    private static func createRootSavingContext(_ coordinator: NSPersistentStoreCoordinator) -> NSManagedObjectContext {
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.persistentStoreCoordinator = coordinator
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        context.undoManager = nil
        context.name = "ch.protonmail.RootContext"

        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "com.apple.coredata.ubiquity.importer.didfinishimport"), object: coordinator, queue: nil) { [weak context] (noti) in
            context?.perform {
                if let updatedObjectIDs = (noti.userInfo?[NSUpdatedObjectsKey] as? Set<NSManagedObjectID>) {

                    for objectID in updatedObjectIDs {

                        context?.registeredObject(for: objectID)?.willAccessValue(forKey: nil)
                    }
                }
                context?.mergeChanges(fromContextDidSave: noti)
            }
        }

        NotificationCenter.default.addObserver(forName: .NSManagedObjectContextWillSave, object: context, queue: nil) { (noti) in
            let context = noti.object as! NSManagedObjectContext
            let insertedObjects = context.insertedObjects
            let numberOfInsertedObjects = insertedObjects.count
            guard numberOfInsertedObjects > 0 else {
                return
            }

            do {
                try context.obtainPermanentIDs(for: Array(insertedObjects))
            } catch {
            }
        }
        // setup notification
        return context
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
            SystemLogger.log(
                message: "\(self).\(caller) took too long on the main thread",
                category: .coreData,
                isError: true
            )
        }
    }

    func enqueueOnRootSavingContext(block: @escaping (_ context: NSManagedObjectContext) -> Void) {
        if Self.useNewApproach {
            do {
                try write(block: block)
            } catch {
                PMAssertionFailure(error)
            }
        } else {
            serialQueue.addOperation { [weak self] in
                guard let self = self else { return }
                
                let context = self.rootSavingContext
                
                context.performAndWait {
                    block(context)
                }
            }
        }
    }

    func performOnRootSavingContext(block: @escaping (_ context: NSManagedObjectContext) -> Void) {
        if Self.useNewApproach {
            do {
                try write(block: block)
            } catch {
                PMAssertionFailure(error)
            }
        } else {
            let context = rootSavingContext

            context.perform {
                block(context)
            }
        }
    }

    func performAndWaitOnRootSavingContext(block: @escaping (_ context: NSManagedObjectContext) -> Void) {
        if Self.useNewApproach {
            do {
                try write(block: block)
            } catch {
                PMAssertionFailure(error)
            }
        } else {
            let context = rootSavingContext

            context.performAndWait {
                block(context)
            }
        }
    }

    func performAndWaitOnRootSavingContext<T>(block: @escaping (NSManagedObjectContext) throws -> T) throws -> T {
        var result: Result<T, Error>!

        performAndWaitOnRootSavingContext { context in
            do {
                result = .success(try block(context))
            } catch {
                result = .failure(error)
            }
        }

        return try result.get()
    }

    /// Discards pending changes in the global main context
    func resetMainContextIfNeeded() {
        mainContext.perform {
            if self.mainContext.hasChanges {
                self.mainContext.reset()
            }
        }
    }

    func createFetchedResultsController<T>(
        entityName: String,
        predicate: NSPredicate,
        sortDescriptors: [NSSortDescriptor],
        fetchBatchSize: Int,
        sectionNameKeyPath: String? = nil,
        onMainContext: Bool
    ) -> NSFetchedResultsController<T> {
        let backgroundContext = Self.useNewApproach ? backgroundContext : rootSavingContext
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
