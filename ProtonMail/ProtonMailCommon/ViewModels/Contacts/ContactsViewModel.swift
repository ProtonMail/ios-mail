//
//  ContactViewModel.swift
//  Proton Mail - Created on 5/1/17.
//
//
//  Copyright (c) 2019 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import Foundation
import CoreData

class ContactsViewModel: ViewModelTimer {
    var user: UserManager
    let coreDataService: CoreDataService

    init(user: UserManager, coreDataService: CoreDataService) {
        self.user = user
        self.coreDataService = coreDataService
        super.init()
    }

    func resetFetchedController() {

    }

    func set(searching isSearching: Bool) {
        fatalError("This method must be overridden")
    }
    
    func setupFetchedResults() {
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
    
    func item(index: IndexPath) -> ContactEntity? {
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
    func delete(contactID: ContactID, complete : @escaping ContactDeleteComplete) {
        fatalError("This method must be overridden")
    }

    func importContacts() {
        fatalError("This method must be overridden")
    }
    
    func transformCoreDataObjects() {
        fatalError("This method must be overridden")
    }

    func setup(uiDelegate: ContactsVCUIProtocol?) {
        fatalError("This method must be overridden")
    }

    func getContactObject(by contactID: ContactID) -> Contact? {
        fatalError("This method must be overridden")
    }
}
