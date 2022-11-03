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
import Foundation

#if !APP_EXTENSION
import LifetimeTracker
#endif

class CoreDataService: Service, CoreDataContextProviderProtocol {
    static let shared = CoreDataService(container: CoreDataStore.shared.defaultContainer)

    private let container: NSPersistentContainer
    let rootSavingContext: NSManagedObjectContext
    let mainContext: NSManagedObjectContext
    static var shouldIgnoreContactUpdateInMainContext = false

    private let serialQueue: OperationQueue = {
        let persistentContainerQueue = OperationQueue()
        persistentContainerQueue.maxConcurrentOperationCount = 1
        return persistentContainerQueue
    }()

    init(container: NSPersistentContainer) {
        self.container = container
        self.rootSavingContext = CoreDataService.createRootSavingContext(container.persistentStoreCoordinator)
        self.mainContext = CoreDataService.createMainContext(self.rootSavingContext)
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

    func makeComposerMainContext() -> NSManagedObjectContext {
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.parent = self.rootSavingContext

        NotificationCenter.default.addObserver(forName: .NSManagedObjectContextDidSave, object: self.rootSavingContext, queue: nil) { [weak context] (noti) in
            guard let _ = noti.object as? NSManagedObjectContext,
                  let context = context else {
                return
            }
            let mergeChanges = { () -> Void in
                if let updatedObjects = (noti.userInfo?[NSUpdatedObjectsKey] as? Set<NSManagedObject>) {
                    for object in updatedObjects {
                        context.object(with: object.objectID).willAccessValue(forKey: nil)
                    }
                }
                context.mergeChanges(fromContextDidSave: noti)
            }
            context.perform(mergeChanges)
        }

        return context
    }

    func makeNewBackgroundContext() -> NSManagedObjectContext {
        return container.newBackgroundContext()
    }

    // MARK: - methods
    func managedObjectIDForURIRepresentation(_ urlString: String) -> NSManagedObjectID? {
        if let url = URL(string: urlString), url.scheme == "x-coredata" {
            let psc = self.container.persistentStoreCoordinator
            return psc.managedObjectID(forURIRepresentation: url)
        }
        return nil
    }

    func enqueue(context: NSManagedObjectContext,
                 block: @escaping (_ context: NSManagedObjectContext) -> Void) {
        self.serialQueue.addOperation {
            context.performAndWait {
                block(context)
            }
        }
    }

    /// Executes the block synchronously and immediately - without a serial queue.
    func read<T>(block: (NSManagedObjectContext) -> T) -> T {
        var output: T!

        let context = container.newBackgroundContext()
        context.automaticallyMergesChangesFromParent = true
        context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump

        context.performAndWait {
            output = block(context)
        }

        if output is NSManagedObject {
            print("Warning: returning NSManagedObjects is deprecated, because it is an Core Data layer leak.")
        }

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

     Ignore the `@escaping` annotation, the method is synchronous.
     */
    func write(block: @escaping (_ context: NSManagedObjectContext) throws -> Void) throws {
        var result: Result<Void, Error>!

        serialQueue.addOperation { [weak self] in
            guard let self = self else { return }

            let context = self.container.newBackgroundContext()
            context.automaticallyMergesChangesFromParent = true
            context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump

            context.performAndWait {
                do {
                    try block(context)

                    if context.hasChanges {
                        try context.save()
                    }

                    result = .success(Void())
                } catch {
                    result = .failure(error)
                }
            }
        }

        serialQueue.waitUntilAllOperationsAreFinished()

        try result.get()
    }

    func enqueueOnRootSavingContext(block: @escaping (_ context: NSManagedObjectContext) -> Void) {
        serialQueue.addOperation { [weak self] in
            guard let self = self else { return }

            let context = self.rootSavingContext

            context.performAndWait {
                block(context)
            }
        }
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
}

#if !APP_EXTENSION
extension CoreDataService: LifetimeTrackable {
    static var lifetimeConfiguration: LifetimeConfiguration {
        .init(maxCount: 1)
    }
}
#endif
