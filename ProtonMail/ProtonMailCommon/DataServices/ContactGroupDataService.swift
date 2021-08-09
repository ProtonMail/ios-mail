//
//  ContactGroupDataService.swift
//  ProtonMail - Created on 2018/8/20.
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
import ProtonCore_Services

//let sharedContactGroupsDataService = ContactGroupsDataService(api: APIService.shared)

class ContactGroupsDataService: Service, HasLocalStorage {
    func cleanUp() -> Promise<Void> {
        return Promise { seal in
            let context = self.coreDataService.operationContext
            self.coreDataService.enqueue(context: context) { (context) in
                let groups = self.labelDataService.getAllLabels(of: .contactGroup, context: context)
                groups.forEach {
                    context.delete($0)
                }
                seal.fulfill_()
            }
        }
    }
    
    static func cleanUpAll() -> Promise<Void> {
        // FIXME: this will remove not only contactGroups but all other labels as well
        return LabelsDataService.cleanUpAll()
    }
    
    private let apiService : APIService
    private let labelDataService: LabelsDataService
    private let coreDataService: CoreDataService
    private weak var queueManager: QueueManager?
    private let userID: String
    
    init(api: APIService , labelDataService: LabelsDataService, coreDataService: CoreDataService, queueManager: QueueManager, userID: String) {
        self.apiService = api
        self.labelDataService = labelDataService
        self.coreDataService = coreDataService
        self.queueManager = queueManager
        self.userID = userID
    }
    
    /**
     Create a new contact group on the server and save it in core data
     
     - Parameters:
     - name: The name of the contact group
     - color: The color of the contact group
     - objectID: CoreData object ID of group label
     */
    func createContactGroup(name: String, color: String, objectID: String? = nil) -> Promise<String> {
        return Promise {
            seal in
            self.labelDataService.createNewLabel(name: name, color: color, type: .contactGroup, objectID: objectID) { (labelId, error) in
                if let err = error {
                    seal.reject(err)
                } else {
                    seal.fulfill(labelId ?? "")
                }
            }
        }
    }
    
    /**
     Edit a contact group on the server and edit it in core data
     
     - Parameters:
     - name: The name of the contact group
     - color: The color of the contact group
     */
    func editContactGroup(groupID: String, name: String, color: String) -> Promise<Void> {
        return Promise { seal in
            let route = UpdateLabelRequest(id: groupID, name: name, color: color)
            self.apiService.exec(route: route) { (response: CreateLabelRequestResponse) in
                if let error = response.error {
                    seal.reject(error)
                } else {
                    if let updatedContactGroup = response.label {
                        PMLog.D("[Contact Group editContactGroup API] result = \(String(describing: updatedContactGroup))")
                        self.labelDataService.addNewLabel(updatedContactGroup)
                        seal.fulfill(())
                    } else {
                        seal.reject(NSError.unableToParseResponse(response))
                    }
                }
            }
        }
    }
    
    /**
     Delete a contact group on the server and delete it in core data
     
     - Parameters:
     - name: The name of the contact group
     */
    func deleteContactGroup(groupID: String) -> Promise<Void> {
        return Promise { seal in
            let eventAPI = DeleteLabelRequest(lable_id: groupID)
            self.apiService.exec(route: eventAPI) { (response: DeleteLabelRequestResponse) in
                if let error = response.error {
                    seal.reject(error)
                } else {
                    if let returnedCode = response.returnedCode {
                        PMLog.D("[Contact Group deleteContactGroup API] result = \(String(describing: returnedCode))")
                        // successfully deleted on the server
                        let context = self.coreDataService.operationContext
                        self.coreDataService.enqueue(context: context) { (context) in
                            let label = Label.labelForLabelID(groupID, inManagedObjectContext: context)
                            if let label = label {
                                context.delete(label)
                            }
                            do {
                                try context.save()
                                seal.fulfill(())
                                return
                            } catch {
                                PMLog.D("deleteContactGroup updating error: \(error)")
                                seal.reject(error)
                                return
                            }
                        }
                    } else {
                        seal.reject(NSError.unableToParseResponse(response))
                    }
                }
            }
        }
    }
    
    func addEmailsToContactGroup(groupID: String, emailList: [Email], emailIDs: [String]? = nil) -> Promise<Void> {
        return Promise { seal in
            var emailList = emailList
            // check
            if emailList.isEmpty && (emailIDs ?? []).isEmpty {
                seal.fulfill(())
                return
            }

            if let emailIDs = emailIDs {
                let context = self.coreDataService.operationContext
                let mails = emailIDs
                    .compactMap { Email.EmailForID($0, inManagedObjectContext: context)}
                emailList += mails
            }

            let emails = emailList.map { $0.emailID }
            
            let route = ContactLabelAnArrayOfContactEmailsRequest(labelID: groupID, contactEmailIDs: emails)
            self.apiService.exec(route: route) { (response: ContactLabelAnArrayOfContactEmailsResponse) in
                if let error = response.error {
                    seal.reject(error)
                } else {
                    if !response.emailIDs.isEmpty {
                        // save
                        PMLog.D("[Contact Group addEmailsToContactGroup API] result = \(String(describing: response))")
                        let context = self.coreDataService.operationContext
                        self.coreDataService.enqueue(context: context) { (context) in
                            let label = Label.labelForLabelID(groupID, inManagedObjectContext: context)
                            
                            let emailsToUse = emailList.compactMap { (email) -> Email? in
                                try? context.existingObject(with: email.objectID) as? Email
                            }
                            
                            if let label = label,
                                var newSet = label.emails as? Set<Email> {
                                // insert those email objects that is in the response only
                                for emailID in response.emailIDs {
                                    for email in emailsToUse {
                                        if email.emailID == emailID {
                                            newSet.insert(email)
                                            break
                                        }
                                    }
                                }
                                
                                label.emails = newSet as NSSet

                                if let error = context.saveUpstreamIfNeeded() {
                                    PMLog.D("addEmailsToContactGroup updating error: \(error)")
                                    seal.reject(error)
                                } else {
                                    seal.fulfill(())
                                }
                            } else {
                                PMLog.D("addEmailsToContactGroup error: can't get label or newSet")
                                seal.reject(ContactGroupEditError.InternalError)
                            }
                        }
                    } else {
                        seal.reject(NSError.unableToParseResponse(response))
                    }
                }
            }
        }
    }
    
    func removeEmailsFromContactGroup(groupID: String, emailList: [Email], emailIDs: [String]? = nil) -> Promise<Void> {
        return Promise {
            seal in
            var emailList = emailList
            let emailIDs = emailIDs ?? []
            // check
            if emailList.isEmpty && emailIDs.isEmpty {
                seal.fulfill(())
                return
            }
            let context = self.coreDataService.operationContext
            let mails = emailIDs
                .compactMap { Email.EmailForID($0, inManagedObjectContext: context) }
            emailList += mails
            
            let emails = emailList.map { $0.emailID }
            let route = ContactUnlabelAnArrayOfContactEmailsRequest(labelID: groupID, contactEmailIDs: emails)
            self.apiService.exec(route: route) { (response: ContactUnlabelAnArrayOfContactEmailsResponse) in
                if let error = response.error {
                    seal.reject(error)
                } else {
                    if !response.emailIDs.isEmpty {
                        // save
                        PMLog.D("[Contact Group removeEmailsFromContactGroup API] result = \(String(describing: response))")
                        
                        let context = self.coreDataService.operationContext
                        self.coreDataService.enqueue(context: context) { (context) in
                            let label = Label.labelForLabelID(groupID, inManagedObjectContext: context)
                            
                            // remove only the email objects in the response
                            if let label = label {
                                let emailObjects = label.mutableSetValue(forKey: Label.Attributes.emails)

                                for emailID in response.emailIDs {
                                    for email in emailList {
                                        if email.emailID == emailID {
                                            if let emailToDelete = emailObjects.compactMap({ $0 as? Email }).first(where: { email in
                                                return email.emailID == emailID
                                            }) {
                                                emailObjects.remove(emailToDelete)
                                            }
                                        }
                                    }
                                }

                                if let error = context.saveUpstreamIfNeeded() {
                                    PMLog.D("addEmailsToContactGroup updating error: \(error)")
                                    seal.reject(error)
                                } else {
                                    seal.fulfill(())
                                }

                            } else {
                                PMLog.D("addEmailsToContactGroup error: can't get label or newSet")
                                seal.reject(ContactGroupEditError.InternalError)
                            }
                        }
                    } else {
                        seal.reject(NSError.unableToParseResponse(response))
                    }
                }
            }
        }
    }
    
    func getAllContactGroupVOs() -> [ContactGroupVO] {
        let labels = self.labelDataService.getAllLabels(of: .contactGroup, context: self.coreDataService.mainContext)
        
        var result: [ContactGroupVO] = []
        for label in labels {
            result.append(ContactGroupVO.init(ID: label.labelID,
                                              name: label.name,
                                              groupSize: label.emails.count,
                                              color: label.color))
        }
        
        return result
    }
}

// MAKR: Queue
extension ContactGroupsDataService {
    func queueCreate(name: String, color: String, emailIDs: [String]) -> Promise<Void> {
        return Promise<Void> { [weak self] seal in
            guard let self = self else { return }
            let context = self.coreDataService.operationContext
            let userID = self.userID
            let queue = self.queueManager
            context.perform {
                // Create a temporary label for display, the label will be removed after getting response
                let groupLabel = Label.makeGroupLabel(context: context,
                                                      userID: userID,
                                                      color: color,
                                                      name: name,
                                                      emailIDs: emailIDs)
                if let error = context.saveUpstreamIfNeeded() {
                    seal.reject(error)
                } else {
                    let objectID = groupLabel.objectID.uriRepresentation().absoluteString
                    let action: MessageAction = .addContactGroup(objectID: objectID, name: name, color: color, emailIDs: emailIDs)
                    let task = QueueManager.Task(messageID: "", action: action, userID: userID, dependencyIDs: [], isConversation: false)
                    _ = queue?.addTask(task)
                    seal.fulfill_()
                }
            }
        }
    }

    func queueUpdate(groupID: String, name: String, color: String, addedEmailIDs: [String], removedEmailIDs: [String]) -> Promise<Void> {
        return Promise<Void> { [weak self] seal in
            guard let self = self else { return }
            let context = self.coreDataService.operationContext
            let userID = self.userID
            let queue = self.queueManager
            context.perform {
                guard let label = Label.labelGroup(byID: groupID, inManagedObjectContext: context) else {
                    seal.fulfill_()
                    return
                }
                label.name = name
                label.color = color
                if var mails = label.emails.allObjects as? [Email] {
                    for id in addedEmailIDs {
                        if let _ = mails.first(where: { $0.emailID == id }) { continue }
                        guard let mail = Email.EmailForID(id, inManagedObjectContext: context) else { continue }
                        mails.append(mail)
                    }
                    for id in removedEmailIDs {
                        guard let index = mails.firstIndex(where: { $0.emailID == id }) else {
                            continue
                        }
                        mails.remove(at: index)
                    }
                    label.emails = Set(mails) as NSSet
                }

                if let error = context.saveUpstreamIfNeeded() {
                    seal.reject(error)
                } else {
                    let objectID = label.objectID.uriRepresentation().absoluteString
                    let action: MessageAction = .updateContactGroup(objectID: objectID, name: name, color: color, addedEmailList: addedEmailIDs, removedEmailList: removedEmailIDs)
                    let task = QueueManager.Task(messageID: "", action: action, userID: userID, dependencyIDs: [], isConversation: false)
                    _ = queue?.addTask(task)
                    seal.fulfill_()
                }
            }
        }
    }

    func queueDelete(groupID: String) -> Promise<Void> {
        let context = self.coreDataService.operationContext
        let userID = self.userID
        let queue = self.queueManager
        return Promise<Void> { seal in
            context.perform {
                guard let label = Label.labelGroup(byID: groupID, inManagedObjectContext: context) else {
                    seal.fulfill_()
                    return
                }
                label.isSoftDeleted = true
                if let error = context.saveUpstreamIfNeeded() {
                    seal.reject(error)
                    return
                }
                let objectID = label.objectID.uriRepresentation().absoluteString
                let action: MessageAction = .deleteContactGroup(objectID: objectID)
                let task = QueueManager.Task(messageID: "", action: action, userID: userID, dependencyIDs: [], isConversation: false)
                _ = queue?.addTask(task)
                seal.fulfill_()
            }
        }
    }
}
