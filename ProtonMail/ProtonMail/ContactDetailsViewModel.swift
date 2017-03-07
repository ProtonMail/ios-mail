//
//  ContactDetailsViewModel.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 5/2/17.
//  Copyright © 2017 ProtonMail. All rights reserved.
//

import Foundation


typealias LoadingProgress = () -> Void
typealias ContactDetailsComplete = (_ contact: Contact?, _ error: NSError?) -> Void

class ContactDetailsViewModel {
    
    init() { }
    
    func statusType2() -> Bool {
        fatalError("This method must be overridden")
    }
    
    func statusType3() -> Bool {
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
    
    func getOrigEmails() -> [ContactEditEmail] {
        fatalError("This method must be overridden")
    }
    
    func getOrigCells() -> [ContactEditPhone] {
        fatalError("This method must be overridden")
    }
    
    func getOrigAddresses() -> [ContactEditAddress] {
        fatalError("This method must be overridden")
    }
    
    func getOrigInformations() -> [ContactEditInformation] {
        fatalError("This method must be overridden")
    }
    
    func getOrigFields() -> [ContactEditField] {
        fatalError("This method must be overridden")
    }
    
    func getOrigNotes() -> [ContactEditNote] {
        fatalError("This method must be overridden")
    }
    
}
