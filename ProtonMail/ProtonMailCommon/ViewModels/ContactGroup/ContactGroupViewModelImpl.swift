//
//  ContactGroupViewModelImpl.swift
//  ProtonMail
//
//  Created by Chun-Hung Tseng on 2018/8/20.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation
import CoreData
import PromiseKit

class ContactGroupsViewModelImpl: ViewModelTimer, ContactGroupsViewModel
{
    private var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>? = nil
    private var isFetching: Bool = false
    private let state: ContactGroupsViewModelState
    private let refreshHandler: ((NSSet) -> Void)?
    private let selectedGroupIDs: [String]
    
    /**
     Init the view model with state
     
     State "ContactGroupsView" is for showing all contact groups in the contact group tab
     State "ContactSelectGroups" is for showing all contact groups in the contact creation / editing page
     */
    init(state: ContactGroupsViewModelState,
         selectedGroupIDs: [String]? = nil,
         refreshHandler: ((NSSet) -> Void)? = nil) {
        self.state = state
        if let selectedGroupIDs = selectedGroupIDs {
            self.selectedGroupIDs = selectedGroupIDs
        } else {
            self.selectedGroupIDs = []
        }
        
        // TODO: handle error
        if state == .ContactSelectGroups && refreshHandler == nil {
            fatalError("Missing handler")
        }
        self.refreshHandler = refreshHandler
    }
    
    /**
     - Returns: ContactGroupsViewModelState
     */
    func getState() -> ContactGroupsViewModelState {
        return state
    }
    
    func isSelected(groupID: String) -> Bool {
        if state == .ContactSelectGroups {
            return selectedGroupIDs.contains(groupID)
        }
        
        return false
    }
    
    /**
     Call this function when we are in "ContactSelectGroups" for returning the selected conatct groups
     */
    func returnSelectedGroups(groupIDs: [String]) {
        if state == .ContactSelectGroups,
            let refreshHandler = refreshHandler {
            refreshHandler(NSSet.init(array: groupIDs))
        }
    }
    
    /**
     Fetch all contact groups from the server using API
     */
    func fetchLatestContactGroup() -> Promise<Void>
    {
        return Promise {
            seal in
            
            if self.isFetching == false {
                self.isFetching = true
                
                sharedMessageDataService.fetchNewMessagesForLocation(.inbox,
                                                                     notificationMessageID: nil,
                                                                     completion: { (task, res, error) in
                                                                        self.isFetching = false
                                                                        
                                                                        if let error = error {
                                                                            seal.reject(error)
                                                                        } else {
                                                                            seal.fulfill(())
                                                                        }
                })
            } else {
                seal.fulfill(())
            }
        }
    }
    
    func timerStart(_ run: Bool = true) {
        super.setupTimer(run)
    }
    
    func timerStop() {
        super.stopTimer()
    }
    
    private func fetchContacts() {
        if isFetching == false {
            isFetching = true
            
            sharedMessageDataService.fetchNewMessagesForLocation(.inbox, notificationMessageID: nil, completion: { (task, res, error) in
                self.isFetching = false
            })
        }
    }
    
    override internal func fireFetch() {
        self.fetchContacts()
    }
    
    // search
    func setFetchResultController(fetchedResultsController: inout NSFetchedResultsController<NSFetchRequestResult>?) {
        self.fetchedResultsController = fetchedResultsController
    }
    
    func search(text: String?) {
        if let text = text {
            if text == "" {
                fetchedResultsController?.fetchRequest.predicate = NSPredicate(format: "(%K == 2)", Label.Attributes.type)
            } else {
                fetchedResultsController?.fetchRequest.predicate = NSPredicate(format: "%K == 2 AND name CONTAINS[cd] %@",
                                                                               argumentArray: [Label.Attributes.type, text])
            }
        } else {
            fetchedResultsController?.fetchRequest.predicate = NSPredicate(format: "(%K == 2)", Label.Attributes.type)
        }
        
        do {
            try fetchedResultsController?.performFetch()
        } catch let ex as NSError {
            PMLog.D("contact group search error: \(ex)")
        }
    }
    
    // TODO: requires rewrite
    func deleteGroups(groupIDs: [String]) -> Promise<Void> {
        return Promise {
            seal in
            
            let lock = NSLock()
            var count = 0
            let completionHandler = { (ok: Bool) -> Void in
                if ok == false {
                    seal.reject(ContactGroupEditError.deleteFailed)
                } else {
                    lock.lock()
                    count += 1
                    if count == groupIDs.count {
                        seal.fulfill(())
                    }
                    lock.unlock()
                }
            }
            
            for groupID in groupIDs {
                sharedContactGroupsDataService.deleteContactGroup(groupID: groupID,
                                                                  completionHandler: completionHandler)
            }
        }
    }
}
