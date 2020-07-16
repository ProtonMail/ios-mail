//
//  BugDataService.swift
//  ProtonMail
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

public class BugDataService: Service {
    private let apiService : API
    init(api: API) {
        self.apiService = api
    }
    
    func reportPhishing(messageID : String, messageBody : String, completion: ((NSError?) -> Void)?) {
        let api = ReportPhishing(msgID: messageID,
                                 mimeType: "text/html",
                                 body: messageBody)
        api.call(api: self.apiService) { (task, res, hasError) in
            completion?(res?.error)
        }
    }
    
    public func reportBug(_ bug: String, username : String, email: String, completion: ((NSError?) -> Void)?) {
        let systemVersion = UIDevice.current.systemVersion;
        let model = UIDevice.current.model
        let mainBundle = Bundle.main
        let username = username
        let useremail = email
        let butAPI = BugReportRequest(os: model, osVersion: "\(systemVersion)", clientVersion: mainBundle.appVersion, title: "ProtonMail App bug report", desc: bug, userName: username, email: useremail)
        
        butAPI.call(api: self.apiService) { (task, response, hasError) -> Void in
            completion?(response?.error)
        }
    }
    
    public class func debugReport(_ title: String, _ bug: String, completion: ((NSError?) -> Void)?) {
        let userInfo = [
            NSLocalizedDescriptionKey: "ProtonMail App bug debugging.",
            NSLocalizedFailureReasonErrorKey: "Parser issue.",
            NSLocalizedRecoverySuggestionErrorKey: "Parser failed.",
            "Title": title,
            "Value": bug
        ]
        
        let errors = NSError(domain: dataServiceDomain, code: -10000000, userInfo: userInfo)
        Analytics.shared.recordError(errors)
    }
    
    
    public class func sendingIssue(title: String,
                                   bug: String,
                                   status: Int,
                                   emials: [String],
                                   attCount: Int) {
        let userInfo = [
            NSLocalizedDescriptionKey: "ProtonMail App bug debugging.",
            NSLocalizedFailureReasonErrorKey: "Parser issue.",
            NSLocalizedRecoverySuggestionErrorKey: "Parser failed.",
            "Title": title,
            "Value": bug,
        ]
        
        let errors = NSError(domain: dataServiceDomain, code: -10000000, userInfo: userInfo)
        Analytics.shared.recordError(errors)
    }
}
