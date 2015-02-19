//
//  APIService+ContactExtension.swift
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

/// Contact extension
extension APIService {
    
    private struct KeyPath {
        static let basePath = "/contacts"
        static let contactEmail = "ContactEmail"
        static let contactName = "ContactName"
        static let contacts = "Contacts"
    }
    
    func contactAdd(#name: String, email: String, completion: CompletionBlock?) {
        let path = KeyPath.basePath
        let parameters = [
            KeyPath.contactName : name,
            KeyPath.contactEmail : email]
        
        POST(path, parameters: parameters, completion: completion)
    }
    
    func contactDelete(#contactID: String, completion: CompletionBlock?) {
        let path = "\(KeyPath.basePath)/\(contactID)"
        
        DELETE(path, parameters: nil, completion: completion)
    }
    
    func contactList(completion: CompletionBlock?) {
        let path = KeyPath.basePath
        
        let successBlock: SuccessBlock = { response in
            var error: NSError?
            
            if let contactsArray = response[KeyPath.contacts] as? [NSDictionary] {
                let context = sharedCoreDataService.newManagedObjectContext()
                
                context.performBlock() {
                    var contacts = GRTJSONSerialization.mergeObjectsForEntityName(Contact.Attributes.entityName, fromJSONArray: contactsArray, inManagedObjectContext: context, error: &error)
                    
                    if error == nil {
                        self.removeContacts(contacts as [Contact], notInContext: context, error: &error)
                        
                        if error != nil  {
                            NSLog("\(__FUNCTION__) error: \(error)")
                        }

                        error = context.saveUpstreamIfNeeded()
                    }
                    
                    if error != nil  {
                        NSLog("\(__FUNCTION__) error: \(error)")
                    }
                }
            } else {
                error = APIError.unableToParseResponse.asNSError()
            }
            
            completion?(error)
        }
        
        GET(path, parameters: nil, success: successBlock, failure: completion)
    }
    
    func contactUpdate(#contactID: String, name: String, email: String, completion: CompletionBlock?) {
        let path = "\(KeyPath.basePath)/\(contactID)"
        
        let parameters = [
            KeyPath.contactName : name,
            KeyPath.contactEmail : email]
        
        PUT(path, parameters: parameters, completion: completion)
    }
    
    // MARK: - Private methods
    
    private func removeContacts(contacts: [Contact], notInContext context: NSManagedObjectContext, error: NSErrorPointer) {
        if contacts.count == 0 {
            return
        }
        
        let fetchRequest = NSFetchRequest(entityName: Contact.Attributes.entityName)
        fetchRequest.predicate = NSPredicate(format: "SELF NOT IN %@", contacts)
        
        if let deletedObjects = context.executeFetchRequest(fetchRequest, error: error) {
            for deletedObject in deletedObjects as [NSManagedObject] {
                context.deleteObject(deletedObject)
            }
        }
    }
}
