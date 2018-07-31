//
//  BugsAPI.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 7/21/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation



// MARK : Get messages part
final class ReportPhishing : ApiRequest<ApiResponse> {
    let msgID : String
    let mimeType : String
    let body : String
    
    init(msgID : String, mimeType : String, body : String) {
        self.msgID = msgID
        self.mimeType = mimeType
        self.body = body
    }
    
    override func toDictionary() -> [String : Any]? {
        let out : [String : Any] = [
            "MessageID": self.msgID,
            "MIMEType" : self.mimeType,
            "Body": self.body
        ]
        return out
    }
    
    override func method() -> APIService.HTTPMethod {
        return .post
    }
    
    override func path() -> String {
        return ReportsAPI.path + "/phishing" + AppConstants.DEBUG_OPTION
    }
    
    override func apiVersion() -> Int {
        return ReportsAPI.v_reports_phishing
    }
}


// MARK : Report a bug
final class BugReportRequest : ApiRequest<ApiResponse> {
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
    
    override func toDictionary() -> [String : Any]? {
        let out : [String : Any] = [
            "OS": self.os,
            "OSVersion" : self.osVersion,
            "Client": "iOS_Native",
            "ClientVersion" : self.clientVersion,
            "Title": self.title,
            "Description": self.desc,
            "Username": self.userName,
            "Email": self.email
        ]
        return out
    }
    
    override func method() -> APIService.HTTPMethod {
        return .post
    }
    
    override func path() -> String {
        return ReportsAPI.path + "/bug" + AppConstants.DEBUG_OPTION
    }
    
    override func apiVersion() -> Int {
        return ReportsAPI.v_reports_bug
    }
}


