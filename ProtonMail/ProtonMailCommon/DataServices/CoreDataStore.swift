//
//  CoreDataStoreService.swift
//  ProtonMail - Created on 12/19/18.
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


/// Provide the local store for core data.
/// Inital does nothing extra
class CoreDataStore {
    ///TODO::fixme tempary.
    static let shared = CoreDataStore()
    
    class var dbUrl: URL {
        return FileManager.default.appGroupsDirectoryURL.appendingPathComponent("ProtonMail.sqlite")
    }
    
    class var tempUrl: URL {
        return FileManager.default.temporaryDirectoryUrl.appendingPathComponent("ProtonMail.sqlite")
    }
    
    class var modelBundle: Bundle {
        return Bundle(url: Bundle.main.url(forResource: "ProtonMail", withExtension: "momd")!)!
    }
    
    public lazy var defaultPersistentStore: NSPersistentStoreCoordinator! = {
        return self.newPersistentStoreCoordinator(self.managedObjectModel, url: CoreDataStore.dbUrl)
    }()
    
    public lazy var memoryPersistentStore: NSPersistentStoreCoordinator! = {
        return self.newMemeryStoreCoordinator(self.managedObjectModel)
    }()
    
    public lazy var testPersistentStore: NSPersistentStoreCoordinator! = {
        return self.newPersistentStoreCoordinator(self.managedObjectModel, url: CoreDataStore.tempUrl)
    }()
    
    private lazy var managedObjectModel: NSManagedObjectModel = {
        var modelURL = Bundle.main.url(forResource: "ProtonMail", withExtension: "momd")!
        return NSManagedObjectModel(contentsOf: modelURL)!
    }()
    
    private func newMemeryStoreCoordinator(_ objectModel: NSManagedObjectModel) -> NSPersistentStoreCoordinator? {
        let coordinator: NSPersistentStoreCoordinator? = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
        // Coordinator with in-mem store type
        do {
            try coordinator?.addPersistentStore(ofType: NSInMemoryStoreType, configurationName: nil, at: nil, options: nil)
        } catch let ex as NSError {
            PMLog.D(api: ex)
        }
        return coordinator
    }

    private func newPersistentStoreCoordinator(_ managedObjectModel: NSManagedObjectModel, url: URL) -> NSPersistentStoreCoordinator? {
        var coordinator: NSPersistentStoreCoordinator? = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
        var url = url
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
                    coordinator = newPersistentStoreCoordinator(managedObjectModel, url: url)
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
        
        assert(false, "Unresolved error \(error), \(error.userInfo)")
        PMLog.D("Unresolved error \(error), \(error.userInfo)")
        
        //TODO::Fix should use delegate let windown to know
        //let alertController = alertError.alertController()
        //alertController.addAction(UIAlertAction(title: LocalString._general_close_action, style: .default, handler: { (action) -> Void in
        //abort()
        //}))
        //UIApplication.shared.keyWindow?.rootViewController?.present(alertController, animated: true, completion: nil)
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
    
   // func migrate(from model, to model, replace : Bool)
}
