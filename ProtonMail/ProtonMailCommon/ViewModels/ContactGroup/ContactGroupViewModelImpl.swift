//
//  ContactGroupViewModelImpl.swift
//  ProtonMail
//
//  Created by Chun-Hung Tseng on 2018/8/20.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation
import CoreData

class ContactGroupsViewModelImpl: ContactGroupsViewModel
{
    var searchText: String? = nil
    var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>? = nil
    
    /**
     Fetch all contact groups from the server using API
     
     TODO: use event!
     */
    func fetchAllContactGroup()
    {
        // TODO: why error?
        //        if let context = sharedCoreDataService.mainManagedObjectContext {
        //            Label.deleteAll(inContext: context)
        //        } else {
        //            PMLog.D("Can't get context for fetchAllContactGroup")
        //        }
        sharedLabelsDataService.fetchLabels(type: 2)
    }
    
    // search
    /**
     
     */
    func setFetchResultController(fetchedResultsController: inout NSFetchedResultsController<NSFetchRequestResult>?) {
        self.fetchedResultsController = fetchedResultsController
    }
    
    /**
     
     */
    func search(text: String?) {
        searchText = text
        
        if let text = text {
            if text == "" {
                fetchedResultsController?.fetchRequest.predicate = nil
            } else {
                fetchedResultsController?.fetchRequest.predicate = NSPredicate(format: "name CONTAINS[cd] %@ OR ANY emails.email CONTAINS[cd] %@",
                                                                               argumentArray: [text, text])
            }
        } else {
            fetchedResultsController?.fetchRequest.predicate = nil
        }
        
        do {
            try fetchedResultsController?.performFetch()
        } catch let ex as NSError {
            PMLog.D("error: \(ex)")
        }
    }
}
