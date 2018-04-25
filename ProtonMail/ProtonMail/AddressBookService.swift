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
import RHAddressBook
import Crashlytics

let sharedAddressBookService = AddressBookService()

class AddressBookService {
    enum RuntimeError : String, Error, CustomErrorVar {
        case cant_get_contacts = "Unable to get contacts"
        var code: Int {
            get {
                return -1003000
            }
        }
        var desc: String {
            get {
                switch self {
                case .cant_get_contacts:
                    return LocalString._unable_to_get_contacts
                }
            }
        }
        var reason: String {
            get {
                switch self {
                case .cant_get_contacts:
                    return NSLocalizedString("get contacts() failed, peopleOrderedByUsersPreference return null!!", comment: "contacts api error when fetch")
                }
            }
        }
    }
    
    typealias AuthorizationCompletionBlock = (_ granted: Bool, _ error: Error?) -> Void
    
    fileprivate var addressBook: RHAddressBook!
    
    init() {
        addressBook = RHAddressBook()
    }
    
    func hasAccessToAddressBook() -> Bool {
        return RHAddressBook.authorizationStatus() == RHAuthorizationStatusAuthorized
    }
    
    func requestAuthorizationWithCompletion(_ completion: @escaping AuthorizationCompletionBlock) {
        if let addressBook = addressBook {
            addressBook.requestAuthorization(completion: completion)
        } else {
            completion(false, nil)
        }
    }
    
    func contactsWith(_ name: String?, email: String?) -> NSArray {
        let filteredPeople = NSMutableArray()
        
        if let name = name {
            filteredPeople.addObjects(from: addressBook.people(withName: name))
        }
        
        if let email = email {
            filteredPeople.addObjects(from: addressBook.people(withEmail: email))
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
                    if let emailAsString = emails.value(at: index) as? String {
                        DispatchQueue.main.sync {
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
            Crashlytics.sharedInstance().recordError(RuntimeError.cant_get_contacts.error)
        }
        return contactVOs
    }
}


