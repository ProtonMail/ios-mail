//
//  ContactGroupDataService.swift
//  ProtonMail
//
//  Created by Chun-Hung Tseng on 2018/8/20.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation
import CoreData
import Groot

let sharedContactGroupsDataService = ContactGroupsDataService()

// TODO: merge into Label struct
struct ContactGroup
{
    var ID: String?
    var name: String?
    var color: String?
    var emailIDs: [String]?
    
    init(ID: String? = nil, name: String? = nil, color: String? = nil, emailIDs: [String]? = nil)
    {
        self.ID = ID
        self.name = name
        self.color = color
        self.emailIDs = emailIDs
    }
}

/*
 Prototyping:
 1. Currently all of the operations are not saved.
 */

class ContactGroupsDataService {
    /**
     Fetch all contact groups using API call
     
     No email list is included in this fetching operation
     
     - Parameters:
     - completionHandler: The fetched data is passed directly back to the caller by this closure
     */
    func fetchContactGroups(completionHandler: @escaping ([[String : Any]]?) -> Void)
    {
        let eventAPI = GetLabelsRequest(type: 2)
        
        eventAPI.call() {
            task, response, hasError in
            if response == nil {
                // TODO: handle error
                PMLog.D("fetchContactGroups error (response is nil): \(String(describing: task)) \(String(describing: response)) \(hasError)")
            } else if let contactGroups = response?.labels {
                // save
                PMLog.D("fetchContactGroups result = \(contactGroups)")
                
                let context = sharedCoreDataService.newMainManagedObjectContext()
                context.performAndWait() {
                    do {
                        let labels_out = try GRTJSONSerialization.objects(withEntityName: Label.Attributes.entityName,
                                                                          fromJSONArray: contactGroups,
                                                                          in: context)
                        let error = context.saveUpstreamIfNeeded()
                        if error == nil {
                            if labels_out.count != contactGroups.count {
                                PMLog.D("error: label insertions failed partially!")
                            }
                        } else {
                            //TODO: error
                            PMLog.D("error: \(String(describing: error))")
                        }
                    } catch let ex as NSError {
                        PMLog.D("error: \(ex)")
                    }
                }
                
                completionHandler(contactGroups)
            } else {
                // TODO: handle error
                PMLog.D("fetchContactGroups error = \(String(describing: task)) \(String(describing: response)) \(hasError)")
            }
        }
    }
    
    /**
     Fetch emails in a specific contact group
     */
    func fetchContactGroupEmailList(groupID: String, completionHandler: @escaping ([[String : Any]]) -> Void)
    {
        // TODO: need to perform exhaustive API call on this
        let eventAPI = ContactEmailsRequest<ContactEmailsResponseForContactGroup>(page: 0,
                                                                                  pageSize: 100,
                                                                                  labelID: groupID)
        
        eventAPI.call() {
            task, response, hasError in
            if response == nil {
                // TODO: handle error
                PMLog.D("fetchContactGroupEmailList response nil error = \(String(describing: task)) \(String(describing: response)) \(hasError)")
            } else if let emailList = response?.emailList {
                // TODO: save
                PMLog.D("fetchContactGroupEmailList result = \(emailList)")
                completionHandler(emailList)
            } else {
                // TODO: handle error
                PMLog.D("fetchContactGroupEmailList error = \(String(describing: task)) \(String(describing: response)) \(hasError)")
            }
        }
    }
    
    func addContactGroup(name: String, color: String, completionHandler: @escaping ([String: Any]) -> Void)
    {
        let eventAPI = CreateLabelRequest<CreateLabelRequestResponse>(name: name,
                                                                      color: color,
                                                                      type: 2)
        
        eventAPI.call() {
            task, response, hasError in
            if response == nil {
                // TODO: handle error
                PMLog.D("[Contact Group API] error = \(String(describing: task)) \(String(describing: response)) \(hasError)")
            } else if let newContactGroup = response?.label {
                // TODO: save
                PMLog.D("[Contact Group API] result = \(newContactGroup)")
                completionHandler(newContactGroup)
            } else {
                // TODO: handle error
                PMLog.D("[Contact Group API] error = \(String(describing: task)) \(String(describing: response)) \(hasError)")
            }
        }
    }
    
    func editContactGroup(groupID: String, name: String, color: String, completionHandler: @escaping () -> Void)
    {
        let eventAPI = UpdateLabelRequest(id: groupID, name: name, color: color)
        
        eventAPI.call() {
            task, response, hasError in
            if response == nil {
                // TODO: handle error
                PMLog.D("[Contact Group API] error = \(String(describing: task)) \(String(describing: response)) \(hasError)")
            } else if response != nil {
                // TODO: save
                PMLog.D("[Contact Group API] result = \(String(describing: response))")
                completionHandler()
            } else {
                // TODO: handle error
                PMLog.D("[Contact Group API] error = \(String(describing: task)) \(String(describing: response)) \(hasError)")
            }
        }
    }
    
    func deleteContactGroup(groupID: String, completionHandler: @escaping () -> Void)
    {
        let eventAPI = DeleteLabelRequest(lable_id: groupID)
        
        eventAPI.call() {
            task, response, hasError in
            if response == nil {
                // TODO: handle error
                PMLog.D("[Contact Group API] error = \(String(describing: task)) \(String(describing: response)) \(hasError)")
            } else if response != nil {
                // TODO: save
                PMLog.D("[Contact Group API] result = \(String(describing: response))")
                completionHandler()
            } else {
                // TODO: handle error
                PMLog.D("[Contact Group API] error = \(String(describing: task)) \(String(describing: response)) \(hasError)")
            }
        }
    }
    
    func addEmailsToContactGroup(groupID: String, emailList: [String], completionHandler: @escaping () -> Void)
    {
        let eventAPI = ContactLabelAnArrayOfContactEmailsRequest(labelID: groupID, contactEmailIDs: emailList)
        
        eventAPI.call() {
            task, response, hasError in
            if response == nil {
                // TODO: handle error
                PMLog.D("[Contact Group API] error = \(String(describing: task)) \(String(describing: response)) \(hasError)")
            } else if response != nil {
                // TODO: save
                PMLog.D("[Contact Group API] result = \(String(describing: response))")
                completionHandler()
            } else {
                // TODO: handle error
                PMLog.D("[Contact Group API] error = \(String(describing: task)) \(String(describing: response)) \(hasError)")
            }
        }
    }
    
    func removeEmailsFromContactGroup(groupID: String, emailList: [String], completionHandler: @escaping () -> Void)
    {
        let eventAPI = ContactUnlabelAnArrayOfContactEmailsRequest(labelID: groupID, contactEmailIDs: emailList)
        
        eventAPI.call() {
            task, response, hasError in
            if response == nil {
                // TODO: handle error
                PMLog.D("[Contact Group API] error = \(String(describing: task)) \(String(describing: response)) \(hasError)")
            } else if response != nil {
                // TODO: save
                PMLog.D("[Contact Group API] result = \(String(describing: response))")
                completionHandler()
            } else {
                // TODO: handle error
                PMLog.D("[Contact Group API] error = \(String(describing: task)) \(String(describing: response)) \(hasError)")
            }
        }
    }
    
}
