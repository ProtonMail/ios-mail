//
//  AddressBookService.swift
//  ProtonMail
//
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.


import Foundation
import Contacts

class AddressBookService: Service {
    enum RuntimeError : Error {
        case cant_get_contacts
        var desc: String {
            get {
                switch self {
                case .cant_get_contacts:
                    return LocalString._unable_to_get_contacts
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
            /*
             this key needs special entitlement since iOS 13 SDK, which should be approved by Apple stuff
             more info: https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_developer_contacts_notes
             commented out until beaurocracy resolved
            */
            // CNContactNoteKey as CNKeyDescriptor,
            CNContactVCardSerialization.descriptorForRequiredKeys()]
        
        // Get all the containers
        var allContainers: [CNContainer] = []
        do {
            allContainers = try store.containers(matching: nil)
        } catch let error {
            PMLog.D("Error fetching containers: " + error.localizedDescription)
        }
        
        var results: [CNContact] = []
        
        // Iterate all containers and append their contacts to our results array
        for container in allContainers {
            let fetchPredicate = CNContact.predicateForContactsInContainer(withIdentifier: container.identifier)
            do {
                let containerResults = try store.unifiedContacts(matching: fetchPredicate, keysToFetch: keysToFetch)
                results.append(contentsOf: containerResults)
            } catch let error {
                PMLog.D("Error fetching results for container: " + error.localizedDescription)
            }
        }
        
        return results
    }
    
    func contacts() -> [ContactVO] {
        var contactVOs: [ContactVO] = []
        
        guard case let contacts = self.getAllContacts(), !contacts.isEmpty else {
            //TODO:: refactor this later
            //Analytics.shared.recordError(RuntimeError.cant_get_contacts.error)
            return []
        }
        
        for contact in contacts {
            var name: String = [contact.givenName, contact.middleName, contact.familyName].filter { !$0.isEmpty }.joined(separator: " ")
            let emails = contact.emailAddresses
            for email in emails {
                let emailAsString = email.value as String
                if (emailAsString.isValidEmail()) {
                    let email = emailAsString
                    if (name.isEmpty) {
                        name = email
                    }
                    contactVOs.append(ContactVO(name: name, email: email, isProtonMailContact: false))
                }
            }
        }
        return contactVOs
    }
}


