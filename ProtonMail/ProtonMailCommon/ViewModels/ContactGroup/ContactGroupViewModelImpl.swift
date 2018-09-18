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

class ContactGroupsViewModelImpl: ContactGroupsViewModel
{
    var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>? = nil
    let state: ContactGroupsViewModelState
    let refreshHandler: ((NSSet) -> Void)?
    
    /**
     Init the view model with state
     
     State "ContactGroupsView" is for showing all contact groups in the contact group tab
     State "ContactSelectGroups" is for showing all contact groups in the contact creation / editing page
     */
    init(state: ContactGroupsViewModelState, refreshHandler: ((NSSet) -> Void)? = nil) {
        self.state = state
        
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
    private var isFetching: Bool = false
    func fetchAllContactGroup() -> Promise<Void>
    {
        return Promise {
            seal in
            
            if isFetching == false {
                isFetching = true
                
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
