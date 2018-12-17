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

let sharedCoreDataService = CoreDataService()

class CoreDataService {
    struct ErrorCode {
        static let noManagedObjectContext = 10000
    }
    
    fileprivate lazy var managedObjectModel: NSManagedObjectModel = {
        let modelURL = Bundle.main.url(forResource: "ProtonMail", withExtension: "momd")!
        return NSManagedObjectModel(contentsOf: modelURL)!
    }()
    
    fileprivate lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator! = {
        return self.newPersistentStoreCoordinator(self.managedObjectModel)
    }()
    
    // MARK: - variables
    
    lazy var mainManagedObjectContext: NSManagedObjectContext = {
        let managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        managedObjectContext.persistentStoreCoordinator = self.persistentStoreCoordinator
        
        NotificationCenter.default.addObserver(forName: .NSManagedObjectContextDidSave,
                                               object: managedObjectContext,
                                               queue: nil) { notification in
            let context = self.backgroundManagedObjectContext
            context.perform {
                context.mergeChanges(fromContextDidSave: notification)
            }
        }
        
        return managedObjectContext
    }()
    
    lazy var backgroundManagedObjectContext: NSManagedObjectContext = {
        let managedObjectContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        managedObjectContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        managedObjectContext.persistentStoreCoordinator = self.persistentStoreCoordinator
        
        NotificationCenter.default.addObserver(forName: .NSManagedObjectContextDidSave,
                                               object: managedObjectContext,
                                               queue: nil) { notification in
            let context = self.mainManagedObjectContext
            context.perform {
                context.mergeChanges(fromContextDidSave: notification)
            }
        }
        
        return managedObjectContext
    }()
    
    
    
    // MARK: - methods
    
    func managedObjectIDForURIRepresentation(_ urlString: String) -> NSManagedObjectID? {
        if let url = URL(string: urlString), url.scheme == "x-coredata" {
            return persistentStoreCoordinator?.managedObjectID(forURIRepresentation: url)
        }
        return nil
    }
    
    func makeReadonlyBackgroundManagedObjectContext() -> NSManagedObjectContext {
        let managedObjectContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = self.newPersistentStoreCoordinator(self.managedObjectModel)
        return managedObjectContext
    }
    
    class var dbUrl: URL {
        return FileManager.default.appGroupsDirectoryURL.appendingPathComponent("ProtonMail.sqlite")
    }
    class var modelBundle: Bundle {
        return Bundle(url: Bundle.main.url(forResource: "ProtonMail", withExtension: "momd")!)!
    }
    
    func newPersistentStoreCoordinator(_ managedObjectModel: NSManagedObjectModel) -> NSPersistentStoreCoordinator? {
        var coordinator: NSPersistentStoreCoordinator? = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)

        var url = CoreDataService.dbUrl
        do {
            let options: [AnyHashable: Any] = [
                NSInferMappingModelAutomaticallyOption: NSNumber(booleanLiteral: true)
            ]
            try coordinator?.addPersistentStore(ofType: NSSQLiteStoreType,
                                                configurationName: nil,
                                                at: url,
                                                options: options)
            url.excludeFromBackup()
        } catch let ex as NSError {
            if (ex.domain == "NSCocoaErrorDomain" && ex.code == 134100) {
                do {
                    try FileManager.default.removeItem(at: url)
                    coordinator = newPersistentStoreCoordinator(managedObjectModel)
                } catch let error as NSError{
                    coordinator = nil
                    popError(error)
                }
            } else {
                coordinator = nil
                popError(ex)
            }
        }
        return coordinator
    }
    
    func popError (_ error : NSError) {
        // Report any error we got.
        var dict = [AnyHashable: Any]()
        dict[NSLocalizedDescriptionKey] = LocalString._error_core_data_save_failed
        dict[NSLocalizedFailureReasonErrorKey] = LocalString._error_core_data_load_failed
        dict[NSUnderlyingErrorKey] = error
        //TODO:: need monitor
        let CoreDataServiceErrorDomain = NSError.protonMailErrorDomain("CoreDataService")
        let _ = NSError(domain: CoreDataServiceErrorDomain, code: 9999, userInfo: dict as [AnyHashable: Any] as? [String : Any])
        PMLog.D("Unresolved error \(error), \(error.userInfo)")
        
        //TODO::Fix later
//        let alertController = alertError.alertController()
//        alertController.addAction(UIAlertAction(title: LocalString._general_close_action, style: .default, handler: { (action) -> Void in
//            abort()
//        }))
//        UIApplication.shared.keyWindow?.rootViewController?.present(alertController, animated: true, completion: nil)
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
    
}
