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
    
    private lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = NSBundle.mainBundle().URLForResource("ProtonMail", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
        }()
    
    private lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
        // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        var coordinator: NSPersistentStoreCoordinator? = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = NSFileManager.defaultManager().applicationSupportDirectoryURL.URLByAppendingPathComponent("ProtonMail.sqlite")
        
        NSLog("\(__FUNCTION__) path: \(url.absoluteString)")

        var error: NSError? = nil
        var failureReason = NSLocalizedString("There was an error creating or loading the application's saved data.")
        if coordinator!.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: nil, error: &error) == nil {
            coordinator = nil
            // Report any error we got.
            let dict = NSMutableDictionary()
            dict[NSLocalizedDescriptionKey] = NSLocalizedString("Failed to initialize the application's saved data")
            dict[NSLocalizedFailureReasonErrorKey] = failureReason
            dict[NSUnderlyingErrorKey] = error
            error = NSError(domain: CoreDataServiceErrorDomain, code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(error), \(error!.userInfo)")
            
            let alertController = error?.alertController()
            let action = UIAlertAction(title: NSLocalizedString("Close"), style: .Default, handler: { (action) -> Void in
                abort()
            })
        } else {
           url.excludeFromBackup()
        }
        
        return coordinator
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
    
    // This context will not automatically merge upstream context saves
    func newManagedObjectContext() -> NSManagedObjectContext {
        let managedObjectContext = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        managedObjectContext.parentContext = mainManagedObjectContext
        return managedObjectContext
    }
    
}
