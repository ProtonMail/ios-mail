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

/// this class provide the context.
class CoreDataService: Service {
    
    //TODO:: fix this in the future. for now we share all data in same persistent store
    static let shared = CoreDataService(container: CoreDataStore.shared.defaultContainer)
    
    
    ///  container pass in from outside or use the default
    var container: NSPersistentContainer
    
    private let serialQueue: OperationQueue = {
        let persistentContainerQueue = OperationQueue()
        persistentContainerQueue.maxConcurrentOperationCount = 1
        return persistentContainerQueue
    }()
    
    init(container: NSPersistentContainer) {
        self.container = container
    }
    
    // MARK: - variables
    lazy var mainManagedObjectContext: NSManagedObjectContext = { [unowned self] in
        return self.container.viewContext
    }()
    
    /// this case crashes when cleaning cache
    lazy var backgroundManagedObjectContext: NSManagedObjectContext = { [unowned self] in
        let context = self.container.newBackgroundContext()
        context.mergePolicy = NSMergePolicy.mergeByPropertyStoreTrump
        return context
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
        return self.container.newBackgroundContext()
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
        //the old code data file
        let url = FileManager.default.applicationSupportDirectoryURL.appendingPathComponent("ProtonMail.sqlite")
        do {
            try FileManager.default.removeItem(at: url)
            PMLog.D("clean ok")
        } catch let error as NSError{
            PMLog.D("\(error)")
        }
    }
    
    func enqueue(context: NSManagedObjectContext? = nil,
                 block: @escaping (_ context: NSManagedObjectContext) -> Void) {
        self.serialQueue.addOperation {
            let context = context ?? self.container.newBackgroundContext()
            context.performAndWait {
                block(context)
//                _ = context.saveUpstreamIfNeeded()
            }
        }
    }
    
    /// this do the auto sync
    lazy var testChildContext: NSManagedObjectContext = { [unowned self] in
        let managedObjectContext = self.container.newBackgroundContext()
        managedObjectContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        managedObjectContext.parent = self.mainManagedObjectContext
        return managedObjectContext
    }()
    
    lazy var testbackgroundManagedObjectContext: NSManagedObjectContext = { [unowned self] in
        return self.container.newBackgroundContext()
    }()
    
}
