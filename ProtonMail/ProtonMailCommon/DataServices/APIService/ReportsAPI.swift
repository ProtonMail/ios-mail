//
//  BugsAPI.swift
//  ProtonMail - Created on 7/21/15.
//
//
//  The MIT License
//
//  Copyright (c) 2018 Proton Technologies AG
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.


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
        return ReportsAPI.path + "/phishing" + Constants.App.DEBUG_OPTION
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
        return ReportsAPI.path + "/bug" + Constants.App.DEBUG_OPTION
    }
    
    override func apiVersion() -> Int {
        return ReportsAPI.v_reports_bug
    }
}


