//
//  BugsAPI.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 7/21/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation



// MARK : Get messages part
public class BugReportRequest<T : ApiResponse> : ApiRequest<T> {
    let os : String!
    let osVersion : String!
    let clientVersion : String!
    let title : String!
    let desc : String!
    let userName : String!
    let email : String!
    
    
    init(os : String!, osVersion : String!, clientVersion : String!, title : String!, desc : String!, userName : String!, email : String!) {
        self.os = os
        self.osVersion = osVersion
        self.clientVersion = clientVersion
        self.title = title
        self.desc = desc
        self.userName = userName
        self.email = email
    }
    
    override func toDictionary() -> Dictionary<String, AnyObject>? {
        
        let out : [String : AnyObject] = [
            "OS": self.os,
            "OSVersion" : self.osVersion,
            "Client": "iOS_Native",
            "ClientVersion" : self.clientVersion,
            "Title": self.title,
            "Description": self.desc,
            "Username": self.userName,
            "Email": self.email
        ]
        
        PMLog.D(self.JSONStringify(out, prettyPrinted: true))
        
        return out
    }
    
    override func getAPIMethod() -> APIService.HTTPMethod {
        return .POST
    }
    
    override public func getRequestPath() -> String {
        return BugsAPI.Path + AppConstants.getDebugOption
    }
    
    override public func getVersion() -> Int {
        return BugsAPI.V_BugsReportRequest
    }
}


