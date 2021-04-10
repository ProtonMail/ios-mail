//
//  CoreDataService.swift
//  ProtonMail
//
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.

import Foundation
import CoreData

class CoreDataService: Service {

    static let shared = CoreDataService(container: CoreDataStore.shared.defaultContainer)

    ///  container pass in from outside or use the default
    var container: NSPersistentContainer
    let rootSavingContext: NSManagedObjectContext
    let mainContext: NSManagedObjectContext

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

    static func createMainContext(_ parent: NSManagedObjectContext) -> NSManagedObjectContext {
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
                PMLog.D("Failed to obtain permanent ID(s) for \(numberOfInsertedObjects) inserted object(s). Error:\(error)")
            }
        }

        NotificationCenter.default.addObserver(forName: .NSManagedObjectContextDidSave, object: parent, queue: nil) { [weak context] (noti) in
            guard let _ = noti.object as? NSManagedObjectContext,
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

        return context
    }

    static func createRootSavingContext(_ coordinator: NSPersistentStoreCoordinator) -> NSManagedObjectContext {
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
                PMLog.D("Failed to obtain permanent ID(s) for \(numberOfInsertedObjects) inserted object(s). Error:\(error)")
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

    var operationContext: NSManagedObjectContext {
        return rootSavingContext
    }

    func childBackgroundManagedObjectContext(forUseIn thread: Thread) -> NSManagedObjectContext {
        if Thread.current.isMainThread {
            assert(false, "This object is not supposed to be used on main thread")
        }
        let background = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        background.parent = self.rootSavingContext
        return background
    }

    // MARK: - methods
    func managedObjectIDForURIRepresentation(_ urlString: String) -> NSManagedObjectID? {
        if let url = URL(string: urlString), url.scheme == "x-coredata" {
            let psc = self.container.persistentStoreCoordinator
            return psc.managedObjectID(forURIRepresentation: url)
        }
        return nil
    }

    func cleanLegacy() {
        // the old code data file
        let url = FileManager.default.applicationSupportDirectoryURL.appendingPathComponent("ProtonMail.sqlite")
        do {
            try FileManager.default.removeItem(at: url)
            PMLog.D("clean ok")
        } catch let error as NSError {
            PMLog.D("\(error)")
        }
    }

    func enqueue(context: NSManagedObjectContext? = nil,
                 block: @escaping (_ context: NSManagedObjectContext) -> Void) {
        self.serialQueue.addOperation {
            let context = context ?? self.container.newBackgroundContext()
            context.performAndWait {
                block(context)
            }
        }
    }
}
