//
//  CoreDataService.swift
//  ProtonMail
//
//
//  The MIT License
//
//  Copyright (c) 2018 Proton Technologies AG
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.


import Foundation
import CoreData

let sharedCoreDataService = CoreDataService(store: CoreDataStore.shared.defaultPersistentStore!)

/// TODO::migrate to NSPersistentContainer in ios 10 or mix when we have time.

/// this class provide the context.
class CoreDataService {
    
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

    
    lazy var testbackgroundManagedObjectContext: NSManagedObjectContext = {
        let managedObjectContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        managedObjectContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        managedObjectContext.persistentStoreCoordinator = self.persistentStore
//        
//        NotificationCenter.default.addObserver(forName: .NSManagedObjectContextDidSave,
//                                               object: managedObjectContext,
//                                               queue: nil) { notification in
//                                                let context = self.mainManagedObjectContext
//                                                context.perform {
//                                                    context.mergeChanges(fromContextDidSave: notification)
//                                                }
        return managedObjectContext
    }()
    
}
