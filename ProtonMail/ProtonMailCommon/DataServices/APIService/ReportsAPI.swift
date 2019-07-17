//
//  BugsAPI.swift
//  ProtonMail - Created on 7/21/15.
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
    
    override func method() -> HTTPMethod {
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
    let os : String
    let osVersion : String
    let clientVersion : String
    let title : String
    let desc : String
    let userName : String
    let email : String
    
    
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
    
    override func method() -> HTTPMethod {
        return .post
    }
    
    override func path() -> String {
        return ReportsAPI.path + "/bug" + Constants.App.DEBUG_OPTION
    }
    
    override func apiVersion() -> Int {
        return ReportsAPI.v_reports_bug
    }
}


