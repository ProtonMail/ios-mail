//
//  ContactViewModel.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 5/1/17.
//  Copyright © 2017 ProtonMail. All rights reserved.
//

import Foundation
import CoreData

class ContactsViewModel : ViewModelTimer {
    
    override init() { }
    
    func paidUser() -> Bool {
        if let role = sharedUserDataService.userInfo?.role, role > 0 {
            return true
        }
        return false
    }
    
    func set(searching isSearching: Bool) {
        fatalError("This method must be overridden")
    }
    
    func setupFetchedResults(delaget : NSFetchedResultsControllerDelegate?) {
        fatalError("This method must be overridden")
    }
    
    func search(text: String) {
        fatalError("This method must be overridden")
    }
    
    func fetchContacts(completion: ContactFetchComplete?) {
        fatalError("This method must be overridden")
    }
    
    //
    func sectionCount() -> Int {
        fatalError("This method must be overridden")
    }
    
    func rowCount(section: Int) -> Int {
        fatalError("This method must be overridden")
    }
    
    func item(index: IndexPath) -> Contact? {
        fatalError("This method must be overridden")
    }
    
    func isExsit(uuid: String) -> Bool {
        fatalError("This method must be overridden")
    }
    
    /**
     section title index  ::Enable it later
     **/
    func sectionIndexTitle() -> [String]? {
        fatalError("This method must be overridden")
    }
    
    func sectionForSectionIndexTitle(title: String, atIndex: Int) -> Int {
        fatalError("This method must be overridden")
    }
    
    //
    func delete(contactID: String, complete : @escaping ContactDeleteComplete) {
        fatalError("This method must be overridden")
    }
    
    
    func importContacts() {
        fatalError("This method must be overridden")
    }
    
    
}
