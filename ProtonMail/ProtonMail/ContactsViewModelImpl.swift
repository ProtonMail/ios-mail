//
//  ContactViewModelImpl.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 5/1/17.
//  Copyright © 2017 ProtonMail. All rights reserved.
//

import Foundation

final class ContactsViewModelImpl : ContactsViewModel {
    // MARK: - fetch controller
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
        }
        
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
        return fetchedResultsController?.sectionIndexTitles
    }
    
    override func item(index: IndexPath) -> Contact? {
        return fetchedResultsController?.object(at: index) as? Contact
    }
    
    
    // MARK: - api part
    override func delete(contactID: String!, complete : @escaping ContactDeleteComplete) {
        sharedContactDataService.delete(contactID: contactID, completion: { (error) in
            if let err = error {
                complete(err)
            } else {
                complete(nil)
            }
        })
    }
    
    override func fetchContacts(completion: ContactFetchComplete?) {
        
        
        if let complete = completion {
            complete([], nil)
        }
        
        
        
        //        self.hideTopMessage()
        //        if !fetchingMessage {
        //            fetchingMessage = true
        //
        //            self.beginRefreshingManually()
        //            let updateTime = viewModel.lastUpdateTime()
        //            let complete : APIService.CompletionBlock = { (task, res, error) -> Void in
        //                self.needToShowNewMessage = false
        //                self.newMessageCount = 0
        //                self.fetchingMessage = false
        //
        //                if self.fetchingStopped! == true {
        //                    return;
        //                }
        //
        //                if let error = error {
        //                    self.handleRequestError(error)
        //                }
        //
        //                if error == nil {
        //                    self.onlineTimerReset()
        //                    self.viewModel.resetNotificationMessage()
        //                    if !updateTime.isNew {
        //
        //                    }
        //                    if let notices = res?["Notices"] as? [String] {
        //                        serverNotice.check(notices)
        //                    }
        //                }
        //
        //                delay(1.0, closure: {
        //                    self.refreshControl.endRefreshing()
        //                    if self.fetchingStopped! == true {
        //                        return;
        //                    }
        //                    self.showNoResultLabel()
        //                    self.tableView.reloadData()
        //                    let _ = self.checkHuman()
        //                })
        //            }
        //
        //            if (updateTime.isNew) {
        //                if lastUpdatedStore.lastEventID == "0" {
        //                    viewModel.fetchMessagesForLocationWithEventReset("", Time: 0, completion: complete)
        //                }
        //                else {
        //                    viewModel.fetchMessages("", Time: 0, foucsClean: false, completion: complete)
        //                }
        //            } else {
        //                //fetch
        //                self.needToShowNewMessage = true
        //                viewModel.fetchNewMessages(self.viewModel.getNotificationMessage(),
        //                                           Time: Int(updateTime.start.timeIntervalSince1970),
        //                                           completion: complete)
        //                self.checkEmptyMailbox()
        //            }
        //        }
    }

    // MARK: - timer overrride
    override internal func fireFetch() {
        self.fetchContacts(completion: nil)
    }
}
