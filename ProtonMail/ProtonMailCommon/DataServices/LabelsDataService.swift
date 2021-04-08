//
//  LabelsDataService.swift
//  ProtonMail - Created on 8/13/15.
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
import Groot
import PromiseKit
import PMCommon

enum LabelFetchType : Int {
    case all = 0
    case label = 1
    case folder = 2
    case contactGroup = 3
    case folderWithInbox = 4
    case folderWithOutbox = 5
}

class LabelsDataService: Service, HasLocalStorage {
    
    public let apiService: APIService
    private let userID : String
    private let coreDataService: CoreDataService
    
    init(api: APIService, userID: String, coreDataService: CoreDataService) {
        self.apiService = api
        self.userID = userID
        self.coreDataService = coreDataService
    }
    
    func cleanUp() -> Promise<Void> {
        return Promise { seal in
            let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: Label.Attributes.entityName)
            fetch.predicate = NSPredicate(format: "%K == %@", Label.Attributes.userID, self.userID)
            let request = NSBatchDeleteRequest(fetchRequest: fetch)
            let moc = self.coreDataService.backgroundManagedObjectContext
            self.coreDataService.enqueue(context: moc) { (context) in
                if let _ = try? moc.execute(request) {
                    _ = context.saveUpstreamIfNeeded()
                }
                seal.fulfill_()
            }
        }
    }
    
    static func cleanUpAll() -> Promise<Void> {
        return Promise { seal in
            let coreDataService = sharedServices.get(by: CoreDataService.self)
            let context = coreDataService.backgroundManagedObjectContext
            coreDataService.enqueue(context: context) { (context) in
                Label.deleteAll(inContext: context)
                LabelUpdate.deleteAll(inContext: context)
                seal.fulfill_()
            }            
        }
    }
    
    /**
     Fetch all contact groups using API call
     
     No email list is included in this fetching operation
     ````
     - Parameter type: type 1 is for message labels, type 2 is for contact groups
     */
    func fetchLabels(type: Int = 1, completion: (() -> Void)? = nil) { //TODO:: fix the completion in case of error
        let labelsRoute = GetLabelsRequest(type: type)
        self.apiService.exec(route: labelsRoute) { (response: GetLabelsResponse) in
            if var labels = response.labels {
                // add prebuild inbox label
                for (index, _) in labels.enumerated() {
                    labels[index]["UserID"] = self.userID
                }
                // these labels should be created without UserID because they are "native" and shared across all users
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
                let context = self.coreDataService.mainManagedObjectContext
                self.coreDataService.enqueue(context: context) { (context) in
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
                    completion?()
                }
            } else {
                //TODO:: error
                completion?()
            }
        }
    }
    
    func getAllLabels(of type : LabelFetchType, context: NSManagedObjectContext) -> [Label] {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: Label.Attributes.entityName)
        
        if type == .contactGroup && userCachedStatus.isCombineContactOn {
            // in contact group searching, predicate must be consistent with this one
            fetchRequest.predicate = NSPredicate(format: "(%K == 2)", Label.Attributes.type)
        } else {
            fetchRequest.predicate = self.fetchRequestPrecidate(type)
        }
        
        let context = context
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
        let moc = self.coreDataService.mainManagedObjectContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: Label.Attributes.entityName)
        fetchRequest.predicate = self.fetchRequestPrecidate(type)
        
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
    
    private func fetchRequestPrecidate(_ type: LabelFetchType) -> NSPredicate {
        switch type {
        case .all:
            return NSPredicate(format: "(labelID MATCHES %@) AND (%K == 1) AND (%K == %@)", "(?!^\\d+$)^.+$", Label.Attributes.type, Label.Attributes.userID, self.userID)
        case .folder:
            return NSPredicate(format: "(labelID MATCHES %@) AND (%K == 1) AND (%K == true) AND (%K == %@)", "(?!^\\d+$)^.+$", Label.Attributes.type, Label.Attributes.exclusive, Label.Attributes.userID, self.userID)
        case .folderWithInbox:
            // 0 - inbox, 6 - archive, 3 - trash, 4 - spam
            let defaults = NSPredicate(format: "labelID IN %@", [0, 6, 3, 4])
            // custom folders like in previous (LabelFetchType.folder) case
            let folder = NSPredicate(format: "(labelID MATCHES %@) AND (%K == 1) AND (%K == true) AND (%K == %@)", "(?!^\\d+$)^.+$", Label.Attributes.type, Label.Attributes.exclusive, Label.Attributes.userID, self.userID)
            
            return NSCompoundPredicate(orPredicateWithSubpredicates: [defaults, folder])
        case .folderWithOutbox:
            // 7 - sent, 6 - archive, 3 - trash
            let defaults = NSPredicate(format: "labelID IN %@", [6, 7, 3])
            // custom folders like in previous (LabelFetchType.folder) case
            let folder = NSPredicate(format: "(labelID MATCHES %@) AND (%K == 1) AND (%K == true) AND (%K == %@)", "(?!^\\d+$)^.+$", Label.Attributes.type, Label.Attributes.exclusive, Label.Attributes.userID, self.userID)
            
            return NSCompoundPredicate(orPredicateWithSubpredicates: [defaults, folder])
        case .label:
            return NSPredicate(format: "(labelID MATCHES %@) AND (%K == 1) AND (%K == false) AND (%K == %@)", "(?!^\\d+$)^.+$", Label.Attributes.type, Label.Attributes.exclusive, Label.Attributes.userID, self.userID)
        case .contactGroup:
            return NSPredicate(format: "(%K == 2) AND (%K == %@)", Label.Attributes.type, Label.Attributes.userID, self.userID)
        }
    }
    
    func addNewLabel(_ response : [String : Any]?) {
        if var label = response {
            let context = self.coreDataService.backgroundManagedObjectContext
            context.performAndWait() {
                do {
                    label["UserID"] = self.userID
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
        let context = self.coreDataService.backgroundManagedObjectContext
        return Label.labelForLableID(labelID, inManagedObjectContext: context) 
    }
    
    func unreadCount(by lableID: String, userID: String? = nil) -> Promise<Int> {
        let context = self.coreDataService.mainManagedObjectContext
        return lastUpdatedStore.unreadCount(by: lableID, userID: userID ?? self.userID, context: context)
    }
}
