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

/// TODO::migrate to NSPersistentContainer in ios 10 or mix when we have time.

/// this class provide the context.
class CoreDataService {
    
    //TODO:: fix this in the future. for now we share all data in same persistent store
    static let shared = CoreDataService(store: CoreDataStore.shared.defaultPersistentStore!)
    
    
    ///  store. pass in from outside or use the default
    var persistentStore: NSPersistentStoreCoordinator
    
    init(store: NSPersistentStoreCoordinator) {
        self.persistentStore = store
    }
    
    // MARK: - variables
    lazy var mainManagedObjectContext: NSManagedObjectContext = {
        let managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        managedObjectContext.persistentStoreCoordinator = self.persistentStore
        return managedObjectContext
    }()
    
    /// this case crashes when cleaning cache
    lazy var backgroundManagedObjectContext: NSManagedObjectContext = {
        return mainManagedObjectContext
    }()
    
    func childBackgroundManagedObjectContext(forUseIn thread: Thread) -> NSManagedObjectContext  {
        if Thread.current.isMainThread {
            assert(false, "This object is not supposed to be used on main thread")
        }
        let background = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        background.parent = self.backgroundManagedObjectContext
        return background
    }
    
    func makeReadonlyBackgroundManagedObjectContext() -> NSManagedObjectContext {
        let managedObjectContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = self.persistentStore
        return managedObjectContext
    }

    // MARK: - methods
    func managedObjectIDForURIRepresentation(_ urlString: String) -> NSManagedObjectID? {
        if let url = URL(string: urlString), url.scheme == "x-coredata" {
            return self.persistentStore.managedObjectID(forURIRepresentation: url)
        }
        return nil
    }
    
    func cleanLegacy() {
        //the old code data file
        let url = FileManager.default.applicationSupportDirectoryURL.appendingPathComponent("ProtonMail.sqlite")
        do {
            try FileManager.default.removeItem(at: url)
            PMLog.D("clean ok")
        } catch let error as NSError{
            PMLog.D("\(error)")
        }
    }
    
    /// this do the auto sync
    lazy var testChildContext: NSManagedObjectContext = {
        let managedObjectContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        managedObjectContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        managedObjectContext.parent = self.mainManagedObjectContext
        return managedObjectContext
    }()
    
    lazy var testbackgroundManagedObjectContext: NSManagedObjectContext = {
        let managedObjectContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        managedObjectContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        managedObjectContext.persistentStoreCoordinator = self.persistentStore
        NotificationCenter.default.addObserver(forName: .NSManagedObjectContextDidSave,
                                               object: managedObjectContext,
                                               queue: nil)
        { notification in
            let context = self.mainManagedObjectContext
            context.performAndWait {
                context.mergeChanges(fromContextDidSave: notification)
            }
        }
        return managedObjectContext
    }()
    
}
