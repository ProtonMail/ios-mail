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

import Foundation
import CoreData

let CoreDataServiceErrorDomain = NSError.protonMailErrorDomain("CoreDataService")

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
    
    func newMainManagedObjectContext() -> NSManagedObjectContext {
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
        do {
            try coordinator?.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: nil)
            url!.excludeFromBackup()
            //TODO:: need to handle empty instead of !
        } catch let ex as NSError {
            if (ex.domain == "NSCocoaErrorDomain" && ex.code == 134100) {
                do {
                    try NSFileManager.defaultManager().removeItemAtURL(url!)
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
    
    func popError (error : NSError) {
        
        // Report any error we got.
        var dict = [NSObject : AnyObject]()
        dict[NSLocalizedDescriptionKey] = NSLocalizedString("Failed to initialize the application's saved data")
        dict[NSLocalizedFailureReasonErrorKey] = NSLocalizedString("There was an error creating or loading the application's saved data.")
        dict[NSUnderlyingErrorKey] = error
        //TODO:: need monitor
        let alertError = NSError(domain: CoreDataServiceErrorDomain, code: 9999, userInfo: dict as [NSObject : AnyObject])
        NSLog("Unresolved error \(error), \(error.userInfo)")
        
        let alertController = alertError.alertController()
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Close"), style: .Default, handler: { (action) -> Void in
            abort()
        }))
        UIApplication.sharedApplication().keyWindow?.rootViewController?.presentViewController(alertController, animated: true, completion: nil)
        
    }
}

// MARK: - NSError Core Data extensions

extension NSError {
    class func noManagedObjectContext() -> NSError {
        return NSError.protonMailError(
            10000,
            localizedDescription: NSLocalizedString("No managed object context"),
            localizedFailureReason: NSLocalizedString("No managed object context."))
    }
}
