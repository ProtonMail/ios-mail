//
//  ContactGroupViewModel.swift
//  ProtonMail
//
//  Created by Chun-Hung Tseng on 2018/8/20.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation
import CoreData

protocol ContactGroupsViewModel {
    func fetchAllContactGroup()
    
    // search
    func setFetchResultController(fetchedResultsController: inout NSFetchedResultsController<NSFetchRequestResult>?)
    func search(text: String?)
}
