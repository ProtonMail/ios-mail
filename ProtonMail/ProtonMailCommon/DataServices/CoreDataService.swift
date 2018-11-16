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


let sharedCoreDataService = CoreDataService()

class CoreDataService {
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
    
    // MARK: - variables
    
    lazy var mainManagedObjectContext: NSManagedObjectContext? = {
        if self.persistentStoreCoordinator == nil {
            return nil
        }
        
        let managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        managedObjectContext.persistentStoreCoordinator = self.persistentStoreCoordinator
        return managedObjectContext
        }()
    
    
    // MARK: - methods
    
    func managedObjectIDForURIRepresentation(_ urlString: String) -> NSManagedObjectID? {
        if let url = URL(string: urlString), url.scheme == "x-coredata" {
            return persistentStoreCoordinator?.managedObjectID(forURIRepresentation: url)
        }
        return nil
    }
    
    func newMainManagedObjectContext() -> NSManagedObjectContext {
        let managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        managedObjectContext.parent = mainManagedObjectContext
        return managedObjectContext
    }
    
    // This context will not automatically merge upstream context saves
    func newManagedObjectContext() -> NSManagedObjectContext {
        let managedObjectContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        managedObjectContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        managedObjectContext.parent = mainManagedObjectContext
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
