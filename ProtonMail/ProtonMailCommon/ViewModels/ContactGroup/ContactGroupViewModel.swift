//
//  ContactGroupViewModel.swift
//  ProtonMail
//
//  Created by Chun-Hung Tseng on 2018/8/20.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation
import CoreData
import PromiseKit

enum ContactGroupsViewModelState
{
    case ViewAllContactGroups
    case MultiSelectContactGroupsForContactEmail
}

protocol ContactGroupsViewModel {
    func getState() -> ContactGroupsViewModelState
    
    func save()
    func isSelected(groupID: String) -> Bool
    
    func fetchLatestContactGroup() -> Promise<Void>
    func timerStart(_ run: Bool)
    func timerStop()
    
    func getSelectedCount() -> Int
    
    func addSelectedGroup(ID: String, indexPath: IndexPath)
    func removeSelectedGroup(ID: String, indexPath: IndexPath)
    func removeAllSelectedGroups()
    
    func totalRows() -> Int
    func cellForRow(at indexPath: IndexPath) -> (ID: String, name: String, color: String, count: Int)
    
    // search
    func setFetchResultController(fetchedResultsController: inout NSFetchedResultsController<NSFetchRequestResult>?)
    func search(text: String?)
    
    // contact groups deletion
    func deleteGroups() -> Promise<Void>
}
