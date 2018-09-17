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
    case ContactGroupsView
    case ContactSelectGroups
}

protocol ContactGroupsViewModel {
    func getState() -> ContactGroupsViewModelState
    
    func fetchAllContactGroup()
    
    // search
    func setFetchResultController(fetchedResultsController: inout NSFetchedResultsController<NSFetchRequestResult>?)
    func search(text: String?)
    
    // contact groups deletion
    func deleteGroups(groupIDs: [String]) -> Promise<Void>
}
