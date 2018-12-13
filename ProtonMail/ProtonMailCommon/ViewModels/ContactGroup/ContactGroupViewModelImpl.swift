//
//  ContactGroupViewModelImpl.swift
//  ProtonMail - Created on 2018/8/20.
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
import PromiseKit

class ContactGroupsViewModelImpl: ViewModelTimer, ContactGroupsViewModel
{
    private var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>? = nil
    private var isFetching: Bool = false
    private let state: ContactGroupsViewModelState
    private let refreshHandler: ((Set<String>) -> Void)?
    private var groupCountInformation: [(ID: String, name: String, color: String, count: Int)]
    private var selectedGroupIDs: Set<String>
    
    /**
     Init the view model with state
     
     State "ContactGroupsView" is for showing all contact groups in the contact group tab
     State "ContactSelectGroups" is for showing all contact groups in the contact creation / editing page
     */
    init(state: ContactGroupsViewModelState,
         groupCountInformation: [(ID: String, name: String, color: String, count: Int)]? = nil,
         selectedGroupIDs: Set<String>? = nil,
         refreshHandler: ((Set<String>) -> Void)? = nil) {
        self.state = state
        
        if let groupCountInformation = groupCountInformation {
            self.groupCountInformation = groupCountInformation
        } else {
            self.groupCountInformation = []
        }
        
        if let selectedGroupIDs = selectedGroupIDs {
            self.selectedGroupIDs = selectedGroupIDs
        } else {
            self.selectedGroupIDs = Set<String>()
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
     - Returns: if the give group is currently selected or not
     */
    func isSelected(groupID: String) -> Bool {
        return selectedGroupIDs.contains(groupID)
    }
    
    func totalRows() -> Int {
        return self.groupCountInformation.count
    }
    
    /**
     Gets the cell data for the multi-select contact group view
     */
    func cellForRow(at indexPath: IndexPath) -> (ID: String, name: String, color: String, count: Int) {
        let row = indexPath.row
        
        guard row < self.groupCountInformation.count else {
            PMLog.D("FatalError: The row count is not correct")
            return ("", "", "", 0)
        }
        
        return self.groupCountInformation[row]
    }
    
    /**
     Call this function when we are in "ContactSelectGroups" for returning the selected conatct groups
     */
    func save() {
        if state == .MultiSelectContactGroupsForContactEmail,
            let refreshHandler = refreshHandler {
            refreshHandler(selectedGroupIDs)
        }
    }
    
    /**
     Add the group ID to the selected group list
     */
    func addSelectedGroup(ID: String, indexPath: IndexPath) {
        if selectedGroupIDs.contains(ID) == false {
            if state == .MultiSelectContactGroupsForContactEmail {
                let row = indexPath.row
                if row < groupCountInformation.count {
                    groupCountInformation[row].count += 1
                }
            }
            selectedGroupIDs.insert(ID)
        }
    }
    
    /**
     Remove the group ID from the selected group list
     */
    func removeSelectedGroup(ID: String, indexPath: IndexPath) {
        if selectedGroupIDs.contains(ID) {
            if state == .MultiSelectContactGroupsForContactEmail {
                let row = indexPath.row
                if row < groupCountInformation.count {
                    groupCountInformation[row].count -= 1
                }
            }
            selectedGroupIDs.remove(ID)
        }
    }
    
    /**
     Remove all group IDs from the selected group list
     */
    func removeAllSelectedGroups() {
        selectedGroupIDs.removeAll()
    }
    
    /**
     Get the count of currently selected groups
     */
    func getSelectedCount() -> Int {
        return selectedGroupIDs.count
    }
    
    /**
     Fetch all contact groups from the server using API
     */
    func fetchLatestContactGroup() -> Promise<Void>
    {
        return Promise { seal in
            if self.isFetching == false {
                self.isFetching = true
                
                //TODO::fixme
//                sharedMessageDataService.fetchNewMessagesForLocation(.inbox,
//                                                                     notificationMessageID: nil,
//                                                                     completion: { (task, res, error) in
//                                                                        self.isFetching = false
//
//                                                                        if let error = error {
//                                                                            seal.reject(error)
//                                                                        } else {
//                                                                            seal.fulfill(())
//                                                                        }
//                })
                
                sharedContactDataService.fetchContacts { (_, error) in
                    
                }
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
            
            //TODO::Fixme
//            sharedMessageDataService.fetchNewMessagesForLocation(.inbox, notificationMessageID: nil, completion: { (task, res, error) in
//                self.isFetching = false
//            })
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
                fetchedResultsController?.fetchRequest.predicate = NSPredicate(format: "(%K == 2)",
                                                                               Label.Attributes.type)
            } else {
                fetchedResultsController?.fetchRequest.predicate = NSPredicate(format: "%K == 2 AND name CONTAINS[cd] %@",
                                                                               argumentArray: [Label.Attributes.type, text])
            }
        } else {
            fetchedResultsController?.fetchRequest.predicate = NSPredicate(format: "(%K == 2)",
                                                                           Label.Attributes.type)
        }
        
        do {
            try fetchedResultsController?.performFetch()
        } catch let ex as NSError {
            PMLog.D("contact group search error: \(ex)")
        }
    }
    
    func deleteGroups() -> Promise<Void> {
        return Promise {
            seal in
            
            if selectedGroupIDs.count > 0 {
                var arrayOfPromises: [Promise<Void>] = []
                for groupID in selectedGroupIDs {
                    arrayOfPromises.append(sharedContactGroupsDataService.deleteContactGroup(groupID: groupID))
                }
                
                when(fulfilled: arrayOfPromises).done {
                    seal.fulfill(())
                    self.selectedGroupIDs.removeAll()
                    }.catch {
                        error in
                        seal.reject(error)
                }
            } else {
                seal.fulfill(())
            }
        }
    }
}
