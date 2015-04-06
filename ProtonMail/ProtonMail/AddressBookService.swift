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
    
    func contacts() -> NSArray {
        return addressBook.peopleOrderedByUsersPreference()
    }
    
}
