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

import Foundation
import CoreData

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

    var operationContext: NSManagedObjectContext {
        return rootSavingContext
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
}
