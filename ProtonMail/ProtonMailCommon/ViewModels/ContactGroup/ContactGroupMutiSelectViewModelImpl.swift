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

class ContactGroupMutiSelectViewModelImpl: ViewModelTimer, ContactGroupsViewModel {

    private var isFetching: Bool = false
    
    private let refreshHandler: ((Set<String>) -> Void)?
    private var groupCountInformation: [(ID: String, name: String, color: String, count: Int)]
    private var selectedGroupIDs: Set<String>
    
    
    private var isSearching : Bool = false
    private var filtered : [(ID: String, name: String, color: String, count: Int)] = []
    
    /**
     Init the view model with state
     
     State "ContactGroupsView" is for showing all contact groups in the contact group tab
     State "ContactSelectGroups" is for showing all contact groups in the contact creation / editing page
     */
    init(groupCountInformation: [(ID: String, name: String, color: String, count: Int)]? = nil,
         selectedGroupIDs: Set<String>? = nil,
         refreshHandler: ((Set<String>) -> Void)? = nil) {
        
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

    func initEditing() -> Bool {
        return true
    }
    
    
    /**
     - Returns: if the give group is currently selected or not
     */
    func isSelected(groupID: String) -> Bool {
        return selectedGroupIDs.contains(groupID)
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
        self.refreshHandler?(selectedGroupIDs)
    }
    
    /**
     Add the group ID to the selected group list
     */
    func addSelectedGroup(ID: String, indexPath: IndexPath) {
        if selectedGroupIDs.contains(ID) == false {
            for i in 0 ..< groupCountInformation.count {
                if groupCountInformation[i].ID == ID {
                    groupCountInformation[i].count += 1;
                    selectedGroupIDs.insert(ID)
                    break
                }
            }
            
            if isSearching {
                for i in 0 ..< filtered.count {
                    if filtered[i].ID == ID {
                        filtered[i].count += 1;
                        break
                    }
                }
            }
        }
    }
    
    /**
     Remove the group ID from the selected group list
     */
    func removeSelectedGroup(ID: String, indexPath: IndexPath) {
        if selectedGroupIDs.contains(ID) {
            for i in 0 ..< groupCountInformation.count {
                if groupCountInformation[i].ID == ID {
                    groupCountInformation[i].count -= 1;
                    selectedGroupIDs.remove(ID)
                    break
                }
            }
            
            if isSearching {
                for i in 0 ..< filtered.count {
                    if filtered[i].ID == ID {
                        filtered[i].count -= 1;
                        break
                    }
                }
            }
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
    func fetchLatestContactGroup() -> Promise<Void> {
        return Promise { seal in
            if self.isFetching == false {
                self.isFetching = true
                sharedMessageDataService.fetchEvents(byLable: Message.Location.inbox.rawValue, notificationMessageID: nil, completion: { (task, res, error) in
                    self.isFetching = false
                    if let error = error {
                        seal.reject(error)
                    } else {
                        seal.fulfill(())
                    }
                })
                sharedContactDataService.fetchContacts { (_, error) in
                    
                }
            } else {
                seal.fulfill(())
            }
        }
    }
    
    func timerStart(_ run: Bool = true) {
        
    }
    
    func timerStop() {
        
    }
    
    private func fetchContacts() {
        if isFetching == false {
            isFetching = true
            
            sharedMessageDataService.fetchEvents(byLable: Message.Location.inbox.rawValue, notificationMessageID: nil, completion: { (task, res, error) in
                self.isFetching = false
            })
        }
    }
    
    override internal func fireFetch() {
        self.fetchContacts()
    }
    
    func setFetchResultController(delegate: NSFetchedResultsControllerDelegate?) -> NSFetchedResultsController<NSFetchRequestResult>? {
        return nil
    }
    
    func search(text: String?, searchActive: Bool) {
        self.isSearching = searchActive
        
        guard self.isSearching else {
            self.filtered = []
            return
        }
        
        guard let query = text, !query.isEmpty else {
            self.filtered = self.groupCountInformation
            return
        }
        
        self.filtered = self.groupCountInformation.compactMap {
            let name = $0.name
            if name.range(of: query, options: [.caseInsensitive]) != nil {
                return $0
            }
            return nil
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
    
    func count() -> Int {
        if self.isSearching {
            return filtered.count
        }
        return self.groupCountInformation.count
    }
    
    func dateForRow(at indexPath: IndexPath) -> (ID: String, name: String, color: String, count: Int, wasSelected: Bool, showEmailIcon: Bool) {
        if self.isSearching {
            guard self.filtered.count > indexPath.row else {
                return ("", "", "", 0, false, false)
            }
            
            let data = filtered[indexPath.row]
            return (data.ID, data.name, data.color, data.count, isSelected(groupID: data.ID), false)
        }
        
        let row = indexPath.row
        guard row < self.groupCountInformation.count else {
            PMLog.D("FatalError: The row count is not correct")
            return ("", "", "", 0, false, false)
        }
        let data = self.groupCountInformation[row]
        return (data.ID, data.name, data.color, data.count, isSelected(groupID: data.ID), false)
    }
    
    func labelForRow(at indexPath: IndexPath) -> Label? {
        return nil
    }
    
    func searchingActive() -> Bool {
        return isSearching
    }
}
