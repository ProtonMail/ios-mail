//
//  AddressBookService.swift
//  ProtonMail
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
import RHAddressBook

class AddressBookService: Service {
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
            Analytics.shared.recordError(RuntimeError.cant_get_contacts.error)
        }
        return contactVOs
    }
}


