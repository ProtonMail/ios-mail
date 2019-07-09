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
import Contacts

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
    
    private lazy var store: CNContactStore = CNContactStore()
    
    func hasAccessToAddressBook() -> Bool {
        return CNContactStore.authorizationStatus(for: .contacts) == .authorized
    }
    
    func requestAuthorizationWithCompletion(_ completion: @escaping AuthorizationCompletionBlock) {
        store.requestAccess(for: .contacts, completionHandler: completion)
    }
    
    func getAllContacts() -> [CNContact] {
        let keysToFetch : [CNKeyDescriptor] = [
            CNContactFormatter.descriptorForRequiredKeys(for: .fullName),
            CNContactEmailAddressesKey as CNKeyDescriptor,
            CNContactPhoneNumbersKey as CNKeyDescriptor,
            CNContactImageDataAvailableKey as CNKeyDescriptor,
            CNContactImageDataKey as CNKeyDescriptor,
            CNContactThumbnailImageDataKey as CNKeyDescriptor,
            CNContactIdentifierKey as CNKeyDescriptor,
            CNContactNoteKey as CNKeyDescriptor,
            CNContactVCardSerialization.descriptorForRequiredKeys()]
        
        // Get all the containers
        var allContainers: [CNContainer] = []
        do {
            allContainers = try store.containers(matching: nil)
        } catch {
            PMLog.D("Error fetching containers")
        }
        
        var results: [CNContact] = []
        
        // Iterate all containers and append their contacts to our results array
        for container in allContainers {
            let fetchPredicate = CNContact.predicateForContactsInContainer(withIdentifier: container.identifier)
            do {
                let containerResults = try store.unifiedContacts(matching: fetchPredicate, keysToFetch: keysToFetch)
                results.append(contentsOf: containerResults)
            } catch {
                PMLog.D("Error fetching results for container")
            }
        }
        
        return results
    }
    
    func contacts() -> [ContactVO] {
        var contactVOs: [ContactVO] = []
        
        guard case let contacts = self.getAllContacts(), !contacts.isEmpty else {
            Analytics.shared.recordError(RuntimeError.cant_get_contacts.error)
            return []
        }
        
        for contact in contacts {
            var name: String = [contact.givenName, contact.middleName, contact.familyName].filter { !$0.isEmpty }.joined(separator: " ")
            
            let emails = contact.emailAddresses
            for email in emails {
                let emailAsString = email.value as String
                DispatchQueue.main.sync {
                    if (emailAsString.isValidEmail()) {
                        let email = emailAsString
                        if (name.isEmpty) {
                            name = email
                        }
                        contactVOs.append(ContactVO(name: name, email: email, isProtonMailContact: false))
                    }
                }
            }
        }

        return contactVOs
    }
}


