//
//  ContactViewModelImpl.swift
//  ProtonMail - Created on 5/1/17.
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
import CoreData

final class ContactsViewModelImpl : ContactsViewModel {
    // MARK: - fetch controller
    fileprivate var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>?
    fileprivate var isSearching: Bool = false
    
    lazy var contactService : ContactDataService = self.user.contactService
    
    override func setupFetchedResults(delaget: NSFetchedResultsControllerDelegate?) {
        self.fetchedResultsController = self.getFetchedResultsController()
        self.correctCachedData()
        self.fetchedResultsController?.delegate = delaget
    }
    
    override func resetFetchedController() {
        if let fetch = self.fetchedResultsController {
            fetch.delegate = nil
            self.fetchedResultsController = nil
        }
    }
    
    func correctCachedData() {
        if let objects = fetchedResultsController?.fetchedObjects as? [Contact] {
            if let context = self.fetchedResultsController?.managedObjectContext {
                var needsSave = false
                for obj in objects {
                    if obj.fixName() {
                        needsSave = true
                    }
                }
                if needsSave {
                    let _ = context.saveUpstreamIfNeeded()
                    self.fetchedResultsController = self.getFetchedResultsController()
                }
            }
        }
    }
    
    private func getFetchedResultsController() -> NSFetchedResultsController<NSFetchRequestResult>? {
        if let fetchedResultsController = contactService.resultController() {
            do {
                try fetchedResultsController.performFetch()
            } catch let ex as NSError {
                PMLog.D("error: \(ex)")
            }
            return fetchedResultsController
        }
        return nil
    }
    
    override func set(searching isSearching: Bool) {
        self.isSearching = isSearching
    }
    
    override func search(text: String) {
        var predicate: NSPredicate?
        if text.isEmpty {
            predicate = NSPredicate(format: "%K == %@", Contact.Attributes.userID, self.user.userInfo.userId)
        } else {
            predicate = NSPredicate(format: "(name CONTAINS[cd] %@ OR ANY emails.email CONTAINS[cd] %@) AND %K == %@", argumentArray: [text, text, Contact.Attributes.userID, self.user.userInfo.userId])
        }
        fetchedResultsController?.fetchRequest.predicate = predicate
        
        do {
            try fetchedResultsController?.performFetch()
        } catch let ex as NSError {
            PMLog.D("error: \(ex)")
        }
        
    }
    
    // MARK: - table view part
    override func sectionCount() -> Int {
        return fetchedResultsController?.numberOfSections() ?? 0
    }
    
    override func rowCount(section: Int) -> Int {
        return fetchedResultsController?.numberOfRows(in: section) ?? 0
    }
    
    override func sectionIndexTitle() -> [String]? {
        if isSearching {
            return nil
        }
        return fetchedResultsController?.sectionIndexTitles
    }
    
    override func sectionForSectionIndexTitle(title: String, atIndex: Int) -> Int {
        if isSearching {
            return -1
        }
        return fetchedResultsController?.section(forSectionIndexTitle: title, at: atIndex) ?? -1
    }
    
    override func item(index: IndexPath) -> Contact? {
        guard let rows = self.fetchedResultsController?.numberOfRows(in: index.section) else {
            return nil
        }
        guard rows > index.row else {
            return nil
        }
        return fetchedResultsController?.object(at: index) as? Contact
    }
    
    override func isExsit(uuid: String) -> Bool {
        if let contacts = fetchedResultsController?.fetchedObjects as? [Contact] {
            for c in contacts {
                if c.uuid == uuid {
                    return true
                }
            }
        }
        return false
    }
    
    // MARK: - api part
    override func delete(contactID: String!, complete : @escaping ContactDeleteComplete) {
        self.contactService.delete(contactID: contactID, completion: { (error) in
            if let err = error {
                complete(err)
            } else {
                complete(nil)
            }
        })
    }
    
    private var isFetching : Bool = false
    private var fetchComplete : ContactFetchComplete? = nil
    override func fetchContacts(completion: ContactFetchComplete?) {
        if let c = completion {
            fetchComplete = c
        }
        if !isFetching {
            isFetching = true
            
            self.user.messageService.fetchEvents(byLable: Message.Location.inbox.rawValue,
                                                 notificationMessageID: nil,
                                                 completion: { (task, res, error) in
                self.isFetching = false
                self.fetchComplete?(nil, nil)
            })
            self.user.contactService.fetchContacts { (_, error) in
                
            }
        }
    }

    // MARK: - timer overrride
    override internal func fireFetch() {
        self.fetchContacts(completion: nil)
    }
}
