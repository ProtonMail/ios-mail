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
    var contacts : [Dictionary<String, AnyObject>]?
    
    override func ParseResponse(response: Dictionary<String, AnyObject>!) -> Bool {
        self.contacts = response?["Contacts"] as? [Dictionary<String, AnyObject>]
        return true
    }
}
