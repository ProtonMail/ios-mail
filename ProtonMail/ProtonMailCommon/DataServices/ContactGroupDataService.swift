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

class ContactGroupsDataService {
    /**
     Create a new contact group on the server and save it in core data
     
     - Parameters:
     - name: The name of the contact group
     - color: The color of the contact group
     - completionHandler: The completion handler called upon successful creation
     */
    func createContactGroup(name: String, color: String, completionHandler: @escaping (String?) -> Void)
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
                completionHandler(newContactGroup["ID"] as? String)
            } else {
                // TODO: handle error
                PMLog.D("[Contact Group addContactGroup API] error = \(String(describing: task)) \(String(describing: response)) \(hasError)")
            }
        }
    }
    
    /**
     Edit a contact group on the server and edit it in core data
     
     - Parameters:
     - name: The name of the contact group
     - color: The color of the contact group
     - completionHandler: The completion handler called upon successful editing
     */
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
    
    /**
     Delete a contact group on the server and delete it in core data
     
     - Parameters:
     - name: The name of the contact group
     - completionHandler: The completion handler called upon successful deletion
     */
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
    
    func addEmailsToContactGroup(groupID: String, emailList: [Email], completionHandler: @escaping () -> Void)
    {
        if emailList.count == 0 {
            completionHandler()
            return
        }
        
        let emails = emailList.map({
            (email: Email) -> String in
            return email.emailID
        })
        let eventAPI = ContactLabelAnArrayOfContactEmailsRequest(labelID: groupID, contactEmailIDs: emails)
        
        eventAPI.call() {
            task, response, hasError in
            if response == nil {
                // TODO: handle error
                PMLog.D("[Contact Group addEmailsToContactGroup API] response nil error = \(String(describing: task)) \(String(describing: response)) \(hasError)")
            } else if let emailIDs = response?.emailIDs {
                // save
                PMLog.D("[Contact Group addEmailsToContactGroup API] result = \(String(describing: response))")
                
                if let context = sharedCoreDataService.mainManagedObjectContext {
                    context.performAndWait {
                        let label = Label.labelForLableID(groupID, inManagedObjectContext: context)
                        
                        if let label = label, var newSet = label.emails as? Set<Email> {
                            for emailID in emailIDs {
                                for email in emailList {
                                    if email.emailID == emailID {
                                        newSet.insert(email)
                                        break
                                    }
                                }
                            }
                            
                            label.emails = newSet as NSSet
                            
                            do {
                                try context.save()
                            } catch {
                                PMLog.D("addEmailsToContactGroup updating error: \(error)")
                            }
                        } else {
                            PMLog.D("addEmailsToContactGroup error: can't get label or newSet")
                        }
                    }
                } else {
                    PMLog.D("addEmailsToContactGroup error: can't get context")
                }
                
                completionHandler()
            } else {
                // TODO: handle error
                PMLog.D("[Contact Group addEmailsToContactGroup API] error = \(String(describing: task)) \(String(describing: response)) \(hasError)")
            }
        }
    }
    
    func removeEmailsFromContactGroup(groupID: String, emailList: [Email], completionHandler: @escaping () -> Void)
    {
        if emailList.count == 0 {
            completionHandler()
            return
        }
        
        let emails = emailList.map({
            (email: Email) -> String in
            return email.emailID
        })
        let eventAPI = ContactUnlabelAnArrayOfContactEmailsRequest(labelID: groupID, contactEmailIDs: emails)
        
        eventAPI.call() {
            task, response, hasError in
            if response == nil {
                // TODO: handle error
                PMLog.D("[Contact Group removeEmailsFromContactGroup API] response nil error = \(String(describing: task)) \(String(describing: response)) \(hasError)")
            } else if let emailIDs = response?.emailIDs {
                // save
                PMLog.D("[Contact Group removeEmailsFromContactGroup API] result = \(String(describing: response))")
                
                if let context = sharedCoreDataService.mainManagedObjectContext {
                    let label = Label.labelForLableID(groupID, inManagedObjectContext: context)
                    
                    if let label = label, var newSet = label.emails as? Set<Email> {
                        for emailID in emailIDs {
                            for email in emailList {
                                if email.emailID == emailID {
                                    newSet.remove(email)
                                    break
                                }
                            }
                        }
                        
                        label.emails = newSet as NSSet
                        
                        do {
                            try context.save()
                        } catch {
                            PMLog.D("addEmailsToContactGroup updating error: \(error)")
                        }
                    } else {
                        PMLog.D("addEmailsToContactGroup error: can't get label or newSet")
                    }
                } else {
                    PMLog.D("addEmailsToContactGroup error: can't get context")
                }
                
                completionHandler()
            } else {
                // TODO: handle error
                PMLog.D("[Contact Group removeEmailsFromContactGroup API] error = \(String(describing: task)) \(String(describing: response)) \(hasError)")
            }
        }
    }
    
}
