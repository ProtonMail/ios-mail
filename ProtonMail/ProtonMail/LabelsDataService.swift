//
//  LabelsDataService.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 8/13/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation
import CoreData


let sharedLabelsDataService = LabelsDataService()

class LabelsDataService {

    private var managedObjectContext: NSManagedObjectContext? {
        return sharedCoreDataService.mainManagedObjectContext
    }
    
    //
    func cleanUp()
    {
        if let context = managedObjectContext {
            Label.deleteAll(inContext: context)
        }
    }
    
    func fetchLabels() {
        let eventAPI = GetLabelsRequest<GetLabelsResponse>()
        eventAPI.call() { task, response, hasError in
            if response == nil {
                //TODO:: error
            } else if let labels = response?.labels {
                //save
                let context = sharedCoreDataService.newMainManagedObjectContext()
                context.performBlockAndWait() {
                    do {
                        let labels_out = try GRTJSONSerialization.objectsWithEntityName(Label.Attributes.entityName, fromJSONArray: labels, inContext: context)
                        let error = context.saveUpstreamIfNeeded()
                        if error == nil {
                            if labels_out.count != labels.count {
                               PMLog.D(" error: labels insert partial failed!")
                            }
                        } else {
                            //TODO:: error
                            PMLog.D("error: \(error)")
                        }
                    } catch let ex as NSError {
                        PMLog.D("error: \(ex)")
                    }
                }
            } else {
                //TODO:: error
            }
        }
    }
    
    func fetchedResultsController() -> NSFetchedResultsController? {
        if let moc = managedObjectContext {
            let fetchRequest = NSFetchRequest(entityName: Label.Attributes.entityName)
            fetchRequest.predicate = NSPredicate(format: "labelID MATCHES %@", "(?!^\\d+$)^.+$")
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: Label.Attributes.order, ascending: true)]
            return NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: moc, sectionNameKeyPath: nil, cacheName: nil)
        }
        return nil
    }
    
    func addNewLabel(response : Dictionary<String, AnyObject>?) {
        if let label = response {
            let context = sharedCoreDataService.newMainManagedObjectContext()
            context.performBlockAndWait() {
                do {
                    try GRTJSONSerialization.objectWithEntityName(Label.Attributes.entityName, fromJSONDictionary: label, inContext: context)
                    if let error = context.saveUpstreamIfNeeded() {
                        PMLog.D("error: \(error)")
                    }
                } catch let ex as NSError {
                    PMLog.D("error: \(ex)")
                }
            }
        }
    }
}