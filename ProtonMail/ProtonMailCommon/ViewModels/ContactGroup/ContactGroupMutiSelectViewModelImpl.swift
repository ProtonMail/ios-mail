//
//  ContactGroupViewModelImpl.swift
//  ProtonMail - Created on 2018/8/20.
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
import PromiseKit

class ContactGroupMutiSelectViewModelImpl: ViewModelTimer, ContactGroupsViewModel {

    private var isFetching: Bool = false
    
    private let refreshHandler: ((Set<String>) -> Void)?
    private var groupCountInformation: [(ID: String, name: String, color: String, count: Int)]
    private var selectedGroupIDs: Set<String>
    
    
    private var isSearching : Bool = false
    private var filtered : [(ID: String, name: String, color: String, count: Int)] = []
    
    private let contactGroupService: ContactGroupsDataService
    private let messageService: MessageDataService
    private(set) var user: UserManager
    /**
     Init the view model with state
     
     State "ContactGroupsView" is for showing all contact groups in the contact group tab
     State "ContactSelectGroups" is for showing all contact groups in the contact creation / editing page
     */
    init(user: UserManager,
         groupCountInformation: [(ID: String, name: String, color: String, count: Int)]? = nil,
         selectedGroupIDs: Set<String>? = nil,
         refreshHandler: ((Set<String>) -> Void)? = nil) {
        self.user = user
        self.contactGroupService = user.contactGroupService
        self.messageService = user.messageService
        
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
                self.messageService.fetchEvents(byLable: Message.Location.inbox.rawValue, notificationMessageID: nil, completion: { (task, res, error) in
                    self.isFetching = false
                    if let error = error {
                        seal.reject(error)
                    } else {
                        seal.fulfill(())
                    }
                })
                self.user.contactService.fetchContacts { (_, error) in
                    
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
            self.messageService.fetchEvents(byLable: Message.Location.inbox.rawValue, notificationMessageID: nil, completion: { (task, res, error) in
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
                    arrayOfPromises.append(self.contactGroupService.deleteContactGroup(groupID: groupID))
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
