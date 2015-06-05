//
//  CoreDataService.swift
//  ProtonMail
//
//
// Copyright 2015 ArcTouch, Inc.
// All rights reserved.
//
// This file, its contents, concepts, methods, behavior, and operation
// (collectively the "Software") are protected by trade secret, patent,
// and copyright laws. The use of the Software is governed by a license
// agreement. Disclosure of the Software to third parties, in any form,
// in whole or in part, is expressly prohibited except as authorized by
// the license agreement.
//

import CoreData
import Foundation

let CoreDataServiceErrorDomain = NSError.protonMailErrorDomain(subdomain: "CoreDataService")

let sharedCoreDataService = CoreDataService()

class CoreDataService {
    
    struct ErrorCode {
        static let noManagedObjectContext = 10000
    }
    
    private lazy var managedObjectModel: NSManagedObjectModel = {
        let modelURL = NSBundle.mainBundle().URLForResource("ProtonMail", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
        }()
    
    private lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
        return self.newPersistentStoreCoordinator(self.managedObjectModel)
    }()
    
    // MARK: - Public variables
    
    lazy var mainManagedObjectContext: NSManagedObjectContext? = {
        if self.persistentStoreCoordinator == nil {
            return nil
        }
        
        let managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = self.persistentStoreCoordinator
        return managedObjectContext
        }()
    
    
    // MARK: - Public methods
    
    func managedObjectIDForURIRepresentation(urlString: String) -> NSManagedObjectID? {
        if let url = NSURL(string: urlString) {
            return persistentStoreCoordinator?.managedObjectIDForURIRepresentation(url)
        }
        return nil
    }
    
    func newMainManagedObjectContext() -> NSManagedObjectContext? {
        let managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        managedObjectContext.parentContext = mainManagedObjectContext
        return managedObjectContext
    }
    
    // This context will not automatically merge upstream context saves
    func newManagedObjectContext() -> NSManagedObjectContext {
        let managedObjectContext = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        managedObjectContext.parentContext = mainManagedObjectContext
        return managedObjectContext
    }
    
    func newPersistentStoreCoordinator(managedObjectModel: NSManagedObjectModel) -> NSPersistentStoreCoordinator? {
        var coordinator: NSPersistentStoreCoordinator? = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
        let url = NSFileManager.defaultManager().applicationSupportDirectoryURL.URLByAppendingPathComponent("ProtonMail.sqlite")
        var error: NSError? = nil
        
        if coordinator!.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: nil, error: &error) != nil {
            url.excludeFromBackup()
        } else {
            if error?.domain == "NSCocoaErrorDomain" && error?.code == 134100 && NSFileManager.defaultManager().removeItemAtURL(url, error: &error) {
                NSLog("\(__FUNCTION__) Removed old persistent store.  Error: \(error)")
                coordinator = newPersistentStoreCoordinator(managedObjectModel)
            } else {
                coordinator = nil
                
                // Report any error we got.
                let dict = NSMutableDictionary()
                dict[NSLocalizedDescriptionKey] = NSLocalizedString("Failed to initialize the application's saved data")
                dict[NSLocalizedFailureReasonErrorKey] = NSLocalizedString("There was an error creating or loading the application's saved data.")
                dict[NSUnderlyingErrorKey] = error
                //TODO:: need monitor
                error = NSError(domain: CoreDataServiceErrorDomain, code: 9999, userInfo: dict as [NSObject : AnyObject])
                NSLog("Unresolved error \(error), \(error!.userInfo)")
                
                if let alertController = error?.alertController() {
                    alertController.addAction(UIAlertAction(title: NSLocalizedString("Close"), style: .Default, handler: { (action) -> Void in
                        abort()
                    }))
                    
                    UIApplication.sharedApplication().keyWindow?.rootViewController?.presentViewController(alertController, animated: true, completion: nil)
                }
            }
        }
        
        return coordinator
    }
}

// MARK: - NSError Core Data extensions

extension NSError {
    class func noManagedObjectContext() -> NSError {
        return NSError.protonMailError(
            code: 10000,
            localizedDescription: NSLocalizedString("No managed object context"),
            localizedFailureReason: NSLocalizedString("No managed object context."))
    }
}