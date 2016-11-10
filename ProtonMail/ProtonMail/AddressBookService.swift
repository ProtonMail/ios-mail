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
        return RHAddressBook.authorizationStatus() == RHAuthorizationStatusAuthorized
    }
    
    func requestAuthorizationWithCompletion(completion: AuthorizationCompletionBlock) {
        if let addressBook = addressBook {
            addressBook.requestAuthorizationWithCompletion(completion)
        } else {
            completion(granted: false, error: nil)
        }
    }
    
    func contactsWith(name: String?, email: String?) -> NSArray {
        let filteredPeople = NSMutableArray()
        
        if let name = name {
            filteredPeople.addObjectsFromArray(addressBook.peopleWithName(name))
        }
        
        if let email = email {
            filteredPeople.addObjectsFromArray(addressBook.peopleWithEmail(email))
        }
        
        return filteredPeople
    }
    
    func contacts() -> [ContactVO] {
        var contactVOs: [ContactVO] = []
        if let contacts = self.addressBook.peopleOrderedByUsersPreference() as? [RHPerson] {
            for contact: RHPerson in contacts {
                var name: String? = contact.name
                let emails: RHMultiValue = contact.emails
                let count = UInt(emails.count())
                for emailIndex in 0 ..< count {
                    let index = UInt(emailIndex)
                    if let emailAsString = emails.valueAtIndex(index) as? String {
                        
                        dispatch_sync(dispatch_get_main_queue()) {
                            if (emailAsString.isValidEmail()) {
                                let email = emailAsString
                                if (name == nil) {
                                    name = email
                                }
                                contactVOs.append(ContactVO(name: name, email: email, isProtonMailContact: false))
                            }
                        }
                    }
                }
            }
        } else {
            let err =  NSError.getContactsError()
            err.uploadFabricAnswer(ContactsErrorTitle)
        }
        return contactVOs
    }
}

extension NSError {
    class func getContactsError() -> NSError {
        return apiServiceError(
            code: APIErrorCode.SendErrorCode.draftBad,
            localizedDescription: NSLocalizedString("Unable to get contacts"),
            localizedFailureReason: NSLocalizedString("get contacts() failed, peopleOrderedByUsersPreference return null!!"))
    }
}
