//
//  ContactViewModel.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 5/1/17.
//  Copyright © 2017 ProtonMail. All rights reserved.
//

import Foundation




class ContactsViewModel {
    
    public init() { }
    
    func setupFetchedResults(delaget : NSFetchedResultsControllerDelegate?) {
        fatalError("This method must be overridden")
    }
    
    func search(text: String) {
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
    
    //
    func delete(contactID: String, complete : @escaping ContactDeleteComplete) {
        fatalError("This method must be overridden")
    }
    
    
}
