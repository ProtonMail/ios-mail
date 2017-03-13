//
//  ContactsAPI.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 3/10/17.
//  Copyright © 2017 ProtonMail. All rights reserved.
//

import Foundation



// MARK : Get messages part
public class ContactEmailsRequest<T : ApiResponse> : ApiRequest<T> {
    
    override public func getRequestPath() -> String {
        return ContactsAPI.Path + "/emails" +  AppConstants.getDebugOption
    }
    
    override public func getVersion() -> Int {
        return ContactsAPI.V_ContactEmailsRequest
    }
    
    override func getAPIMethod() -> APIService.HTTPMethod {
        return .GET
    }
}


public class ContactEmailsResponse : ApiResponse {
    var contacts : [Dictionary<String, AnyObject>] = []
    
    override func ParseResponse(response: Dictionary<String, AnyObject>!) -> Bool {
        if let tempContacts = response?["Contacts"] as? [Dictionary<String, AnyObject>] {
            for contact in tempContacts {
                if let contactID = contact["ContactID"] as? String, let name = contact["Name"] as? String {
                    var found = false
                    for (index, var c) in contacts.enumerate() {
                        if let obj = c["ID"] as? String where obj == contactID {
                            found = true
                            if var emails = c["Emails"] as? [Dictionary<String, AnyObject>] {
                                emails.append(contact)
                                c["Emails"] = emails
                            } else {
                                c["Emails"] = [contact]
                            }
                            contacts[index] = c
                        }
                    }
                    if !found {
                        let newContact : Dictionary<String, AnyObject> = [
                            "ID" : contactID,
                            "Name" : name,
                            "Emails" : [contact]
                        ]
                        self.contacts.append(newContact)
                    }
                }
            }
        }
        
        PMLog.D(self.JSONStringify(self.contacts, prettyPrinted: true))
        
        return true
    }
}
