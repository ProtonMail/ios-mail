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

public let sharedCoreDataService = CoreDataService()

public class CoreDataService {
    
    struct ErrorCode {
        static let noManagedObjectContext = 10000
    }
    
    fileprivate lazy var managedObjectModel: NSManagedObjectModel = {
        let modelURL = Bundle.main.url(forResource: "ProtonMail", withExtension: "momd")!
        return NSManagedObjectModel(contentsOf: modelURL)!
        }()
    
    fileprivate lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
        return self.newPersistentStoreCoordinator(self.managedObjectModel)
    }()
    
    // MARK: - Public variables
    
    lazy var mainManagedObjectContext: NSManagedObjectContext? = {
        if self.persistentStoreCoordinator == nil {
            return nil
        }
        
        let managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = self.persistentStoreCoordinator
        return managedObjectContext
        }()
    
    
    // MARK: - Public methods
    
    public func managedObjectIDForURIRepresentation(_ urlString: String) -> NSManagedObjectID? {
        if let url = URL(string: urlString) {
            return persistentStoreCoordinator?.managedObjectID(forURIRepresentation: url)
        }
        return nil
    }
    
    public func newMainManagedObjectContext() -> NSManagedObjectContext {
        let managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext.parent = mainManagedObjectContext
        return managedObjectContext
    }
    
    // This context will not automatically merge upstream context saves
    public func newManagedObjectContext() -> NSManagedObjectContext {
        let managedObjectContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        managedObjectContext.parent = mainManagedObjectContext
        return managedObjectContext
    }
    
    func newPersistentStoreCoordinator(_ managedObjectModel: NSManagedObjectModel) -> NSPersistentStoreCoordinator? {
        var coordinator: NSPersistentStoreCoordinator? = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
        var url = FileManager.default.applicationSupportDirectoryURL.appendingPathComponent("ProtonMail.sqlite")
        do {
            try coordinator?.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: nil)
            url.excludeFromBackup()
            //TODO:: need to handle empty instead of !
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
        dict[NSLocalizedDescriptionKey] = NSLocalizedString("Failed to initialize the application's saved data", comment: "Description")
        dict[NSLocalizedFailureReasonErrorKey] = NSLocalizedString("There was an error creating or loading the application's saved data.", comment: "Description")
        dict[NSUnderlyingErrorKey] = error
        //TODO:: need monitor
        let alertError = NSError(domain: CoreDataServiceErrorDomain, code: 9999, userInfo: dict as [AnyHashable: Any])
        PMLog.D("Unresolved error \(error), \(error.userInfo)")
        
        let alertController = alertError.alertController()
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Close", comment: "Action"), style: .default, handler: { (action) -> Void in
            abort()
        }))
        UIApplication.shared.keyWindow?.rootViewController?.present(alertController, animated: true, completion: nil)
        
    }
}

// MARK: - NSError Core Data extensions

extension NSError {
    class func noManagedObjectContext() -> NSError {
        return NSError.protonMailError(
            10000,
            localizedDescription: NSLocalizedString("No managed object context", comment: "Description"),
            localizedFailureReason: NSLocalizedString("No managed object context.", comment: "Description"))
    }
}
