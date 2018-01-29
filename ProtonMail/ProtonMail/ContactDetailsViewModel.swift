//
//  ContactDetailsViewModel.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 5/2/17.
//  Copyright © 2017 ProtonMail. All rights reserved.
//

import Foundation


typealias LoadingProgress = () -> Void

class ContactDetailsViewModel {
    
    init() { }
    
    func paidUser() -> Bool {
        if let role = sharedUserDataService.userInfo?.role, role > 0 {
            return true
        }
        return false
    }
    
    func rebuild() -> Bool {
        fatalError("This method must be overridden")
    }
    
    func sections() -> [ContactEditSectionType] {
        fatalError("This method must be overridden")
    }
    
    func statusType2() -> Bool {
        fatalError("This method must be overridden")
    }
    
    func statusType3() -> Bool {
        fatalError("This method must be overridden")
    }
    
    func hasEncryptedContacts() -> Bool {
        fatalError("This method must be overridden")
    }
    
    func getDetails(loading : LoadingProgress, complete: @escaping ContactDetailsComplete) {
        fatalError("This method must be overridden")
    }
    
    func getContact() -> Contact {
        fatalError("This method must be overridden")
    }
    
    func getProfile() -> ContactEditProfile {
        fatalError("This method must be overridden")
    }
    
    func getEmails() -> [ContactEditEmail] {
        fatalError("This method must be overridden")
    }
    
    func getPhones() -> [ContactEditPhone] {
        fatalError("This method must be overridden")
    }
    
    func getAddresses() -> [ContactEditAddress] {
        fatalError("This method must be overridden")
    }
    
    func getInformations() -> [ContactEditInformation] {
        fatalError("This method must be overridden")
    }
    
    func getFields() -> [ContactEditField] {
        fatalError("This method must be overridden")
    }
    
    func getNotes() -> [ContactEditNote] {
        fatalError("This method must be overridden")
    }
    
    func getUrls() -> [ContactEditUrl] {
        fatalError("This method must be overridden")
    }
    
    func export() -> String {
        fatalError("This method must be overridden")
    }
    
    func exportName() -> String {
        fatalError("This method must be overridden")
    }
}
