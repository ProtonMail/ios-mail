//
//  LabelsDataService.swift
//  ProtonMail - Created on 8/13/15.
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
import Groot


let sharedLabelsDataService = LabelsDataService()

enum LabelFetchType : Int {
    case all = 0
    case label = 1
    case folder = 2
    case contactGroup = 3
    case folderWithDefaults = 4
}

class LabelsDataService {
    
    func cleanUp() {
        Label.deleteAll(inContext: sharedCoreDataService.backgroundManagedObjectContext)
    }
    
    /**
     Fetch all contact groups using API call
     
     No email list is included in this fetching operation
     ````
     - Parameter type: type 1 is for message labels, type 2 is for contact groups
     */
    func fetchLabels(type: Int = 1) {
        let eventAPI = GetLabelsRequest(type: type)
        eventAPI.call() {
            task, response, hasError in
            
            if response == nil {
                //TODO:: error
            } else if var labels = response?.labels {
                // add prebuild inbox label
                if type == 1 {
                    labels.append(["ID": "0"]) //case inbox   = "0"
                    labels.append(["ID": "8"]) //case draft   = "8"
                    labels.append(["ID": "1"]) //case draft   = "1"
                    labels.append(["ID": "7"]) //case sent    = "7"
                    labels.append(["ID": "2"]) //case sent    = "2"
                    labels.append(["ID": "10"]) //case starred = "10"
                    labels.append(["ID": "6"]) //case archive = "6"
                    labels.append(["ID": "4"]) //case spam    = "4"
                    labels.append(["ID": "3"]) //case trash   = "3"
                    labels.append(["ID": "5"]) //case allmail = "5"
                }
                
                //save
                let context = sharedCoreDataService.backgroundManagedObjectContext
                context.performAndWait() {
                    do {
                        let labels_out = try GRTJSONSerialization.objects(withEntityName: Label.Attributes.entityName, fromJSONArray: labels, in: context)
                        let error = context.saveUpstreamIfNeeded()
                        if error == nil {
                            if labels_out.count != labels.count {
                               PMLog.D("error: label insertions failed partially!")
                            }
                        } else {
                            //TODO:: error
                            PMLog.D("error: \(String(describing: error))")
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
    
    func getAllLabels(of type : LabelFetchType) -> [Label] {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: Label.Attributes.entityName)
        switch type {
        case .all:
            fetchRequest.predicate = NSPredicate(format: "(labelID MATCHES %@) AND (%K == 1)", "(?!^\\d+$)^.+$", Label.Attributes.type)
        case .folder:
            fetchRequest.predicate = NSPredicate(format: "(labelID MATCHES %@) AND (%K == 1) AND (%K == true) ", "(?!^\\d+$)^.+$", Label.Attributes.type, Label.Attributes.exclusive)
        case .folderWithDefaults:
            let defaults = NSPredicate(format: "labelID IN %@", [0, 6, 3, 4])
            // custom folders like in previous (LabelFetchType.folder) case
            let folder = NSPredicate(format: "(labelID MATCHES %@) AND (%K == 1) AND (%K == true) ", "(?!^\\d+$)^.+$", Label.Attributes.type, Label.Attributes.exclusive)
            
            fetchRequest.predicate = NSCompoundPredicate(orPredicateWithSubpredicates: [defaults, folder])
            
        case .label:
            fetchRequest.predicate = NSPredicate(format: "(labelID MATCHES %@) AND (%K == 1) AND (%K == false) ", "(?!^\\d+$)^.+$", Label.Attributes.type, Label.Attributes.exclusive)
        case .contactGroup:
            // in contact group searching, predicate must be consistent with this one
            fetchRequest.predicate = NSPredicate(format: "(%K == 2)", Label.Attributes.type)
        }
        
        let context = sharedCoreDataService.mainManagedObjectContext
        do {
            let results = try context.fetch(fetchRequest)
            if let results = results as? [Label] {
                return results
            } else {
                // TODO: handle error
                PMLog.D("COnversion to Label error")
            }
        } catch {
            PMLog.D("Get context failed")
        }
        
        return []
    }
    
    func fetchedResultsController(_ type : LabelFetchType) -> NSFetchedResultsController<NSFetchRequestResult>? {
        let moc = sharedCoreDataService.mainManagedObjectContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: Label.Attributes.entityName)
        
        switch type {
        case .all:
            fetchRequest.predicate = NSPredicate(format: "(labelID MATCHES %@) AND (%K == 1)", "(?!^\\d+$)^.+$", Label.Attributes.type)
        case .folder:
            fetchRequest.predicate = NSPredicate(format: "(labelID MATCHES %@) AND (%K == 1) AND (%K == true) ", "(?!^\\d+$)^.+$", Label.Attributes.type, Label.Attributes.exclusive)
        case .folderWithDefaults:
            // 0 - inbox, 6 - archive, 3 - trash, 4 - spam
            let defaults = NSPredicate(format: "labelID IN %@", [0, 6, 3, 4])
            // custom folders like in previous (LabelFetchType.folder) case
            let folder = NSPredicate(format: "(labelID MATCHES %@) AND (%K == 1) AND (%K == true) ", "(?!^\\d+$)^.+$", Label.Attributes.type, Label.Attributes.exclusive)
            
            fetchRequest.predicate = NSCompoundPredicate(orPredicateWithSubpredicates: [defaults, folder])
            
        case .label:
            fetchRequest.predicate = NSPredicate(format: "(labelID MATCHES %@) AND (%K == 1) AND (%K == false) ", "(?!^\\d+$)^.+$", Label.Attributes.type, Label.Attributes.exclusive)
        case .contactGroup:
            // in contact group searching, predicate must be consistent with this one
            fetchRequest.predicate = NSPredicate(format: "(%K == 2)", Label.Attributes.type)
        }
        
        if type != .contactGroup {
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: Label.Attributes.order, ascending: true)]
        } else {
            let strComp = NSSortDescriptor(key: Label.Attributes.name,
                                           ascending: true,
                                           selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))
            fetchRequest.sortDescriptors = [strComp]
        }
        return NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: moc, sectionNameKeyPath: nil, cacheName: nil)
    }
    
    func addNewLabel(_ response : [String : Any]?) {
        if let label = response {
            let context = sharedCoreDataService.backgroundManagedObjectContext
            context.performAndWait() {
                do {
                    try GRTJSONSerialization.object(withEntityName: Label.Attributes.entityName, fromJSONDictionary: label, in: context)
                    if let error = context.saveUpstreamIfNeeded() {
                        PMLog.D("addNewLabel error: \(error)")
                    }
                } catch let ex as NSError {
                    PMLog.D("addNewLabel error: \(ex)")
                }
            }
        }
    }
    
    func label(by labelID : String) -> Label? {
        let context = sharedCoreDataService.backgroundManagedObjectContext
        return Label.labelForLableID(labelID, inManagedObjectContext: context) 
    }
}
