//
//  ContactViewModel.swift
//  ProtonMail - Created on 5/1/17.
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
import CoreData

class ContactsViewModel : ViewModelTimer {

    override init() { }
    
    func paidUser() -> Bool {
        if let role = sharedUserDataService.userInfo?.role, role > 0 {
            return true
        }
        return false
    }
    
    func resetFetchedController() {
        
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
