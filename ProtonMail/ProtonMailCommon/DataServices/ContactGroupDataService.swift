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
     Fetch emails in a specific contact group
     
     TODO: eliminate this?
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
        let api = CreateLabelRequest<CreateLabelRequestResponse>(name: name, color: color, exclusive: false, type: 2)
        api.call() {
            task, response, hasError in
            if response == nil {
                // TODO: handle error
                PMLog.D("[Contact Group addContactGroup API] error = \(String(describing: task)) \(String(describing: response)) \(hasError)")
            } else if let newContactGroup = response?.label {
                // save
                PMLog.D("[Contact Group addContactGroup API] result = \(newContactGroup)")
                sharedLabelsDataService.addNewLabel(newContactGroup)
                completionHandler(newContactGroup)
            } else {
                // TODO: handle error
                PMLog.D("[Contact Group addContactGroup API] error = \(String(describing: task)) \(String(describing: response)) \(hasError)")
            }
        }
    }
    
    func editContactGroup(groupID: String, name: String, color: String, completionHandler: @escaping () -> Void)
    {
        let eventAPI = UpdateLabelRequest<UpdateLabelRequestResponse>(id: groupID, name: name, color: color)
        
        eventAPI.call() {
            task, response, hasError in
            if response == nil {
                // TODO: handle error
                PMLog.D("[Contact Group editContactGroup API] response nil error = \(String(describing: task)) \(String(describing: response)) \(hasError)")
            } else if let updatedContactGroup = response?.label {
                // save
                PMLog.D("[Contact Group editContactGroup API] result = \(String(describing: updatedContactGroup))")
                sharedLabelsDataService.addNewLabel(updatedContactGroup)
                completionHandler()
            } else {
                // TODO: handle error
                PMLog.D("[Contact Group editContactGroup API] error = \(String(describing: task)) \(String(describing: response)) \(hasError)")
            }
        }
    }
    
    func deleteContactGroup(groupID: String, completionHandler: @escaping () -> Void)
    {
        let eventAPI = DeleteLabelRequest<DeleteLabelRequestResponse>(lable_id: groupID)
        
        eventAPI.call() {
            task, response, hasError in
            if response == nil {
                // TODO: handle error
                PMLog.D("[Contact Group deleteContactGroup API] response nil error = \(String(describing: task)) \(String(describing: response)) \(hasError)")
            } else if let returnedCode = response?.returnedCode {
                PMLog.D("[Contact Group deleteContactGroup API] result = \(String(describing: returnedCode))")
                
                if returnedCode == 1000 {
                    // successfully deleted on the server
                    if let context = sharedCoreDataService.mainManagedObjectContext {
                        context.performAndWait {
                            () -> Void in
                            let label = Label.labelForLableID(groupID, inManagedObjectContext: context)
                            if let label = label {
                                context.delete(label)
                            }
                            return
                        }
                    }
                    
                    completionHandler()
                } else {
                    // TODO: handle error
                }
            } else {
                // TODO: handle error
                PMLog.D("[Contact Group deleteContactGroup API] error = \(String(describing: task)) \(String(describing: response)) \(hasError)")
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
                PMLog.D("[Contact Group addEmailsToContactGroup API] response nil error = \(String(describing: task)) \(String(describing: response)) \(hasError)")
            } else if response != nil {
                // TODO: save
                PMLog.D("[Contact Group addEmailsToContactGroup API] result = \(String(describing: response))")
                completionHandler()
            } else {
                // TODO: handle error
                PMLog.D("[Contact Group addEmailsToContactGroup API] error = \(String(describing: task)) \(String(describing: response)) \(hasError)")
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
                PMLog.D("[Contact Group removeEmailsFromContactGroup API] response nil error = \(String(describing: task)) \(String(describing: response)) \(hasError)")
            } else if response != nil {
                // TODO: save
                PMLog.D("[Contact Group removeEmailsFromContactGroup API] result = \(String(describing: response))")
                completionHandler()
            } else {
                // TODO: handle error
                PMLog.D("[Contact Group removeEmailsFromContactGroup API] error = \(String(describing: task)) \(String(describing: response)) \(hasError)")
            }
        }
    }
    
}
