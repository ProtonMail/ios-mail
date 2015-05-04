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

let sharedAddressBookService = AddressBookService()

class AddressBookService {
    
    typealias AuthorizationCompletionBlock = (granted: Bool, error: NSError!) -> Void
    
    private var addressBook: RHAddressBook!
    
    init() {
        addressBook = RHAddressBook()
    }
    
    func hasAccessToAddressBook() -> Bool {
        return RHAddressBook.authorizationStatus().value == RHAuthorizationStatusAuthorized.value
    }
    
    func requestAuthorizationWithCompletion(completion: AuthorizationCompletionBlock) {
        if let addressBook = addressBook {
            addressBook.requestAuthorizationWithCompletion(completion)
        } else {
            completion(granted: false, error: nil)
        }
    }
    
    func contactsWith(name: String?, email: String?) -> NSArray {
        var filteredPeople = NSMutableArray()
        
        if let name = name {
            filteredPeople.addObjectsFromArray(addressBook.peopleWithName(name))
        }
        
        if let email = email {
            filteredPeople.addObjectsFromArray(addressBook.peopleWithEmail(email))
        }
        
        return filteredPeople
    }
    
    func contacts() -> [ContactVO] {
        let contacts = addressBook.peopleOrderedByUsersPreference() as! [RHPerson]
        var contactVOs: [ContactVO] = []
        
        for contact: RHPerson in contacts {
            var name: String? = contact.name
            let emails: RHMultiValue = contact.emails
            
            for (var emailIndex: UInt = 0; Int(emailIndex) < Int(emails.count()); emailIndex++) {
                let emailAsString = emails.valueAtIndex(emailIndex) as! String
                
                if (emailAsString.isValidEmail()) {
                    let email = emailAsString
                    
                    if (name == nil) {
                        name = email
                    }
                    
                    contactVOs.append(ContactVO(name: name, email: email, isProtonMailContact: false))
                }
            }
        }
        
        return contactVOs

    }
    
}
