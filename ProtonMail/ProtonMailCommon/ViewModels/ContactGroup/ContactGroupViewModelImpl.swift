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

class ContactGroupsViewModelImpl: ViewModelTimer, ContactGroupsViewModel {
    let coreDataService: CoreDataService
    private var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>? = nil
    private var isFetching: Bool = false
    
    private(set) var user: UserManager
    private let contactGroupService: ContactGroupsDataService
    private let labelDataService: LabelsDataService
    private let messageService: MessageDataService
    
    private var selectedGroupIDs: Set<String> = Set<String>()
    
    
    private var isSearching : Bool = false
    private var filtered : [Label] = []
    
    /**
     Init the view model with state
     
     State "ContactGroupsView" is for showing all contact groups in the contact group tab
     State "ContactSelectGroups" is for showing all contact groups in the contact creation / editing page
     */
    init(user: UserManager, coreDataService: CoreDataService) {
        self.user = user
        self.coreDataService = coreDataService
        self.contactGroupService = user.contactGroupService
        self.labelDataService = user.labelService
        self.messageService = user.messageService
    }
    

    func initEditing() -> Bool {
        return false
    }
    /**
     - Returns: if the give group is currently selected or not
     */
    func isSelected(groupID: String) -> Bool {
        return selectedGroupIDs.contains(groupID)
    }
    
    /**
     Call this function when we are in "ContactSelectGroups" for returning the selected conatct groups
     */
    func save() {
        
    }
    
    /**
     Add the group ID to the selected group list
     */
    func addSelectedGroup(ID: String, indexPath: IndexPath) {
        if selectedGroupIDs.contains(ID) == false {
            selectedGroupIDs.insert(ID)
        }
    }
    
    /**
     Remove the group ID from the selected group list
     */
    func removeSelectedGroup(ID: String, indexPath: IndexPath) {
        if selectedGroupIDs.contains(ID) {
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
    func fetchLatestContactGroup() -> Promise<Void> {
        return Promise { seal in
            if self.isFetching == false {
                self.isFetching = true
                self.messageService.fetchEvents(byLable: Message.Location.inbox.rawValue, notificationMessageID: nil, context: self.coreDataService.mainManagedObjectContext, completion: { (task, res, error) in
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
        super.setupTimer(run)
    }
    
    func timerStop() {
        super.stopTimer()
    }
    
    private func fetchContacts() {
        if isFetching == false {
            isFetching = true
            
            self.messageService.fetchEvents(byLable: Message.Location.inbox.rawValue, notificationMessageID: nil, context: self.coreDataService.mainManagedObjectContext, completion: { (task, res, error) in
                self.isFetching = false
            })
        }
    }
    
    override internal func fireFetch() {
        self.fetchContacts()
    }
    
    func setFetchResultController(delegate: NSFetchedResultsControllerDelegate?) -> NSFetchedResultsController<NSFetchRequestResult>? {
        self.fetchedResultsController = self.labelDataService.fetchedResultsController(.contactGroup)
        self.fetchedResultsController?.delegate = delegate
        if let fetchController = self.fetchedResultsController {
            do {
                try fetchController.performFetch()
            } catch let error as NSError {
                PMLog.D("fetchedContactGroupResultsController Error: \(error.userInfo)")
            }
        }
        return self.fetchedResultsController
    }
    
    func search(text: String?, searchActive: Bool) {
        self.isSearching = searchActive
        
        guard self.isSearching, let objects = self.fetchedResultsController?.fetchedObjects as? [Label] else {
            self.filtered = []
            return
        }
        
        guard let query = text, !query.isEmpty else {
            self.filtered = objects
            return
        }
        
        self.filtered = objects.compactMap {
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
                }.catch(policy: .allErrors) {
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
        return self.fetchedResultsController?.fetchedObjects?.count ?? 0
    }
    
    func dateForRow(at indexPath: IndexPath) -> (ID: String, name: String, color: String, count: Int, wasSelected: Bool, showEmailIcon: Bool) {
        if self.isSearching {
            guard self.filtered.count > indexPath.row else {
                return ("", "", "", 0, false, false)
            }
            
            let label = filtered[indexPath.row]
            return (label.labelID, label.name, label.color, label.emails.count, false, true)
        }
        guard let label = fetchedResultsController?.object(at: indexPath) as? Label else {
            return ("", "", "", 0, false, false)
        }
        return (label.labelID, label.name, label.color, label.emails.count, false, true)
        
    }
    
    func labelForRow(at indexPath: IndexPath) -> Label? {
        if self.isSearching {
            guard self.filtered.count > indexPath.row else {
                return nil
            }
            let label = filtered[indexPath.row]
            return label
        }
        return fetchedResultsController?.object(at: indexPath) as? Label
    }
    
    
    func searchingActive() -> Bool {
        return self.isSearching
    }
}
