//
//  BugDataService.swift
//  ProtonMail
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

public class BugDataService: Service {
    public init() {
        
    }
    
    func reportPhishing(messageID : String, messageBody : String, completion: ((NSError?) -> Void)?) {
        let api = ReportPhishing(msgID: messageID,
                                 mimeType: "text/html",
                                 body: messageBody)
        api.call { (task, res, hasError) in
            completion?(res?.error)
        }
    }
    
    public func reportBug(_ bug: String, completion: ((NSError?) -> Void)?) {
        let systemVersion = UIDevice.current.systemVersion;
        let model = UIDevice.current.model
        let mainBundle = Bundle.main
        let username = sharedUserDataService.username ?? ""
        let useremail = sharedUserDataService.defaultEmail 
        let butAPI = BugReportRequest(os: model, osVersion: "\(systemVersion)", clientVersion: mainBundle.appVersion, title: "ProtonMail App bug report", desc: bug, userName: username, email: useremail)
        
        butAPI.call { (task, response, hasError) -> Void in
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
