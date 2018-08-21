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

struct ContactGroup
{
    let ID: String
    let name: String
    let color: String
    let emailIDs: [String]?
    
    init(ID: String, name: String, color: String, emailIDs: [String]?)
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
    func fetchContactGroups(completionHandler: @escaping ([[String : Any]]?) -> Void)
    {
        let eventAPI = GetLabelsRequest(type: 2)
        
        eventAPI.call() {
            task, response, hasError in
            if response == nil {
                // TODO: handle error
                PMLog.D("[Contact Group API] error = \(String(describing: task)) \(String(describing: response)) \(hasError)")
            } else if let contactGroups = response?.labels {
                // TODO: save
                PMLog.D("[Contact Group API] result = \(contactGroups)")
                completionHandler(contactGroups)
            } else {
                // TODO: handle error
                PMLog.D("[Contact Group API] error = \(String(describing: task)) \(String(describing: response)) \(hasError)")
            }
        }
    }
    
    func fetchContactGroupDetail(groupID: String, completionHandler: @escaping ([String : Any]) -> Void)
    {
        let eventAPI = ContactDetailRequest<ContactDetailResponse>(cid: groupID)
        
        eventAPI.call() {
            task, response, hasError in
            if response == nil {
                // TODO: handle error
                PMLog.D("[Contact Group API] error = \(String(describing: task)) \(String(describing: response)) \(hasError)")
            } else if let contactGroup = response?.contact {
                // TODO: save
                PMLog.D("[Contact Group API] result = \(contactGroup)")
                completionHandler(contactGroup)
            } else {
                // TODO: handle error
                PMLog.D("[Contact Group API] error = \(String(describing: task)) \(String(describing: response)) \(hasError)")
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
