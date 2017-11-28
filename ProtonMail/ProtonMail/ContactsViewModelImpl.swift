//
//  ContactViewModelImpl.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 5/1/17.
//  Copyright © 2017 ProtonMail. All rights reserved.
//

import Foundation



final class ContactsViewModelImpl : ContactsViewModel {
    // MARK: - fetch
    fileprivate var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>?
    
    override func setupFetchedResults(delaget: NSFetchedResultsControllerDelegate?) {
        self.fetchedResultsController = self.getFetchedResultsController()
        self.fetchedResultsController?.delegate = delaget
    }
    
    
    private func getFetchedResultsController() -> NSFetchedResultsController<NSFetchRequestResult>? {
        if let fetchedResultsController = sharedContactDataService.resultController() {
            do {
                try fetchedResultsController.performFetch()
            } catch let ex as NSError {
                PMLog.D("error: \(ex)")
            }
            return fetchedResultsController
        }
        return nil
    }
    

    override func search(text: String) {
        if text.isEmpty {
            fetchedResultsController?.fetchRequest.predicate = nil
        } else {
            fetchedResultsController?.fetchRequest.predicate = NSPredicate(format: "name CONTAINS[cd] %@ OR ANY emails.email CONTAINS[cd] %@", argumentArray: [text, text])
            
            //            searchResults = contacts.filter({ (contact: ContactVO) -> Bool in
            //                let contactNameContainsFilteredText = contact.name.lowercased().range(of: searchText.lowercased()) != nil
            //                let contactEmailContainsFilteredText = contact.email.lowercased().range(of: searchText.lowercased()) != nil
            //                return contactNameContainsFilteredText || contactEmailContainsFilteredText
            //            })
        }
        
        do {
            try fetchedResultsController?.performFetch()
        } catch let ex as NSError {
            PMLog.D("error: \(ex)")
        }
        
    }
    //
    override func sectionCount() -> Int {
        return fetchedResultsController?.numberOfSections() ?? 0
    }
    
    override func rowCount(section: Int) -> Int {
        return fetchedResultsController?.numberOfRows(in: section) ?? 0
    }
    
    override func item(index: IndexPath) -> Contact? {
        return fetchedResultsController?.object(at: index) as? Contact
    }
    
    override func delete(contactID: String!, complete : @escaping ContactDeleteComplete) {
        sharedContactDataService.delete(contactID: contactID, completion: { (error) in
            if let err = error {
                complete(err)
            } else {
                complete(nil)
            }
        })
        
    }
}
