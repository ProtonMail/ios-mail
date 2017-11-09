//
//  ContactsAPI.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 3/10/17.
//  Copyright © 2017 ProtonMail. All rights reserved.
//

import Foundation



// MARK : Get messages part
class ContactEmailsRequest<T : ApiResponse> : ApiRequest<T> {
    
    var page : Int = 0
    var max : Int = 100
    
    init(page: Int, pageSize : Int) {
        self.page = page
        self.max = pageSize
    }
    
    override public func getRequestPath() -> String {
        //    let path = ContactPath.base
        //    //setApiVesion(1, appVersion: 1)
        //    request(method: .get, path: path, parameters: nil, headers: ["x-pm-apiversion": 1], completion: completion)
        return ContactsAPI.Path + "/emails" +  AppConstants.DEBUG_OPTION
    }
    
    override func toDictionary() -> Dictionary<String, Any>? {
        return ["Page" : page, "PageSize" : max]
    }
    
    override public func getVersion() -> Int {
        return ContactsAPI.V_ContactEmailsRequest
    }
    
    override func getAPIMethod() -> APIService.HTTPMethod {
        return .get
    }
}


class ContactEmailsResponse : ApiResponse {
    var contacts : [Dictionary<String, Any>] = []
    override func ParseResponse (_ response: Dictionary<String, Any>!) -> Bool {
        if let tempContacts = response?["ContactEmails"] as? [Dictionary<String, Any>] {
            for contact in tempContacts {
                if let contactID = contact["ContactID"] as? String, let name = contact["Name"] as? String {
                    var found = false
                    for (index, var c) in contacts.enumerated() {
                        if let obj = c["ID"] as? String, obj == contactID {
                            found = true
                            if var emails = c["ContactEmails"] as? [Dictionary<String, Any>] {
                                emails.append(contact)
                                c["ContactEmails"] = emails
                            } else {
                                c["ContactEmailsE"] = [contact]
                            }
                            contacts[index] = c
                        }
                    }
                    if !found {
                        let newContact : Dictionary<String, Any> = [
                            "ID" : contactID,
                            "Name" : name,
                            "ContactEmails" : [contact]
                        ]
                        self.contacts.append(newContact)
                    }
                }
            }
        }
        PMLog.D(self.JSONStringify(value: self.contacts, prettyPrinted: true))
        return true
    }
}

// MARK : Get messages part
final class ContactDetailRequest<T : ApiResponse> : ApiRequest<T> {
    
    let contactID : String
    
    init(cid : String) {
        self.contactID = cid
    }

    override public func getRequestPath() -> String {
        return ContactsAPI.Path + "/" + self.contactID +  AppConstants.DEBUG_OPTION
    }
    
    override public func getVersion() -> Int {
        return ContactsAPI.V_ContactDetailRequest
    }
    
    override func getAPIMethod() -> APIService.HTTPMethod {
        return .get
    }
}


class ContactDetailResponse : ApiResponse {
    var contact : Dictionary<String, Any>?
    override func ParseResponse (_ response: Dictionary<String, Any>!) -> Bool {
        PMLog.D(JSONStringify(value: response))
        contact = response["Contact"] as? Dictionary<String, Any>
        return true
    }
}


final class ContactEmail : Package {
    let id : String
    let email : String
    let type : String

    // e email  //    "Email": "feng@protonmail.com",
    // t type   //    "Type": "Email"
    init(e : String, t: String) {
        self.email = e
        self.type = t
        self.id = ""
    }
    
    func toDictionary() -> Dictionary<String, Any>? {
        return [
            "ID" : self.id,
            "Email": self.email,
            "Type": self.type
        ]
    }
}

// 0, 1, 2, 3 // 0 for cleartext, 1 for encrypted only (not used), 2 for signed, 3 for both
enum CardDataType : Int {
    case PlainText = 0
    case EncryptedOnly = 1
    case SignedOnly = 2
    case SignAndEncrypt = 3
}

// add contacts Card object
final class CardData : Package {
    let type : CardDataType
    let data : String
    let sign : String
    
    // t   "Type": CardDataType
    // d   "Data": ""
    // s   "Signature": ""
    init(t : CardDataType, d: String, s : String) {
        self.data = d
        self.type = t
        self.sign = s
    }
    
    func toDictionary() -> Dictionary<String, Any>? {
        return [
            "Data": self.data,
            "Type": self.type.rawValue,
            "Signature": self.sign
        ]
    }
}

extension Array where Element: CardData {
    func toDictionary() -> [Dictionary<String, Any>] {
        var dicts = [Dictionary<String, Any>]()
        for element in self {
            if let e = element.toDictionary() {
                dicts.append(e)
            }
        }
        return dicts
    }
}


final class ContactAddRequest<T : ApiResponse> : ApiRequest<T> {
    let Cards : [CardData]
    init(cards: [CardData]) {
        self.Cards = cards
    }
    
    override public func getRequestPath() -> String {
        return ContactsAPI.Path +  AppConstants.DEBUG_OPTION
    }
    
    override public func getVersion() -> Int {
        return ContactsAPI.V_ContactAddRequest
    }
    
    override func getAPIMethod() -> APIService.HTTPMethod {
        return .post
    }
    
    override func toDictionary() -> Dictionary<String, Any>? {
        var contacts : [Any] = [Any]()
        var cards_dict : [Any] = [Any] ()
        
        for c in self.Cards {
            if let dict = c.toDictionary() {
                cards_dict.append(dict)
            }
        }
        
        let contact : [String : Any]  = [
            "Cards": cards_dict
        ]
        
        contacts.append(contact)
        
        return [
            "Contacts" : contacts,
            "Overwrite": 1, // when UID conflict, 0 = error, 1 = overwrite
            "Groups": 1, // import groups if present, will silently skip if group does not exist
            "Labels": 1 // import
        ]
    }
}

final class ContactAddResponse : ApiResponse {
    var contact : [String : Any]?
    var resError : NSError?
    override func ParseResponse (_ response: Dictionary<String, Any>!) -> Bool {
        PMLog.D(JSONStringify(value: response))
        if let responses = response["Responses"] as? [Dictionary<String, Any>] {
            for res in responses {
                if let response = res["Response"] as? Dictionary<String, Any> {
                    let code = response["Code"] as? Int
                    let errorMessage = response["Error"] as? String
                    let errorDetails = response["ErrorDescription"] as? String
                    
                    if code != 1000 && code != 1001 {
                        resError = NSError.protonMailError(code ?? 1000, localizedDescription: errorMessage ?? "", localizedFailureReason: errorDetails, localizedRecoverySuggestion: nil)
                    } else {
                        contact = response["Contact"] as? Dictionary<String, Any>
                    }
                }
            }
        }
        return true
    }
}

final class ContactDeleteRequest<T : ApiResponse> : ApiRequest<T> {
    var IDs : [String] = []
    init(ids: [String]) {
        IDs = ids
    }
    
    override public func getRequestPath() -> String {
        return ContactsAPI.Path + "/delete" +  AppConstants.DEBUG_OPTION
    }
    
    override public func getVersion() -> Int {
        return ContactsAPI.V_ContactDeleteRequest
    }
    
    override func getAPIMethod() -> APIService.HTTPMethod {
        return .put
    }
    
    override func toDictionary() -> Dictionary<String, Any>?  {
        return ["IDs": IDs]
    }
}


final class ContactUpdateRequest<T : ApiResponse> : ApiRequest<T> {
    var contactID : String
    let Cards : [CardData]
    
    init(contactid: String,
         cards: [CardData]) {
        self.contactID = contactid
        self.Cards = cards
    }
    
    override public func getRequestPath() -> String {
        return ContactsAPI.Path + "/" + self.contactID +  AppConstants.DEBUG_OPTION
    }
    
    override public func getVersion() -> Int {
        return ContactsAPI.V_ContactUpdateRequest
    }
    
    override func getAPIMethod() -> APIService.HTTPMethod {
        return .put
    }
    
    override func toDictionary() -> Dictionary<String, Any>? {
        var cards_dict : [Any] = [Any] ()
        for c in self.Cards {
            if let dict = c.toDictionary() {
                cards_dict.append(dict)
            }
        }
        return [
            "Cards": cards_dict
        ]
    }
}

