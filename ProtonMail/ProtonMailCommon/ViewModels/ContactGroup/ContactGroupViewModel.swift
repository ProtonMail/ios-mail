//
//  ContactGroupViewModel.swift
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

//enum ContactGroupsViewModelState
//{
//    case ViewAllContactGroups
//    case MultiSelectContactGroupsForContactEmail
//}

protocol ContactGroupsViewModel {
    var user: UserManager { get }
    var coreDataService: CoreDataService { get }
    func initEditing() -> Bool
    
    func save()
    func isSelected(groupID: String) -> Bool
    
    func fetchLatestContactGroup() -> Promise<Void>
    func timerStart(_ run: Bool)
    func timerStop()
    
    func getSelectedCount() -> Int
    
    func addSelectedGroup(ID: String, indexPath: IndexPath)
    func removeSelectedGroup(ID: String, indexPath: IndexPath)
    func removeAllSelectedGroups()
    
    func setFetchResultController(delegate: NSFetchedResultsControllerDelegate?) -> NSFetchedResultsController<NSFetchRequestResult>? 
    // search
    func search(text: String?, searchActive: Bool)
    
    // contact groups deletion
    func deleteGroups() -> Promise<Void>
    
    // table count
    func searchingActive() -> Bool 
    func count() -> Int
    func dateForRow(at indexPath: IndexPath) -> (ID: String, name: String, color: String, count: Int, wasSelected: Bool, showEmailIcon: Bool)
    
    func labelForRow(at indexPath: IndexPath) -> Label?
}
