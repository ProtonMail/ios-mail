//
//  ContactDataService.swift
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

let sharedContactDataService = ContactDataService()

class ContactDataService {
    typealias CompletionBlock = APIService.CompletionBlock
    
    func addContact(#name: String, email: String, completion: CompletionBlock?) {
        sharedAPIService.contactAdd(name: name, email: email, completion: fetchContactsCompletionBlockForCompletion(completion))
    }
    
    func deleteContact(contact: Contact, completion: CompletionBlock?) {
        sharedAPIService.contactDelete(contactID: contact.contactID, completion: fetchContactsCompletionBlockForCompletion(completion))
    }
    
    func fetchContacts(completion: CompletionBlock?) {
        sharedAPIService.contactList(completion)
    }
    
    func updateContact(#contactID: String, name: String, email: String, completion: CompletionBlock?) {
        sharedAPIService.contactUpdate(contactID: contactID, name: name, email: email, completion: fetchContactsCompletionBlockForCompletion(completion))
    }
    
    // MARK: - Private methods
    
    private func fetchContactsCompletionBlockForCompletion(completion: CompletionBlock?) -> CompletionBlock {
        return { error in
            if error == nil {
                self.fetchContacts(completion)
            } else {
                completion?(error)
            }
        }
    }
}
