//
//  NSErrorExtension.swift
//  ProtonMail
//
//
// Copyright 2015 ArcTouch, Inc.
// All rights reserved.
//
// This file, its contents, concepts, methods, behavior, and operation
// (collectively the "Software") are protected by trade secret, patent,
// and copyright laws. The use of the Software is governed by a license
// agreement. Disclosure of the Software to third parties, in any form,
// in whole or in part, is expressly prohibited except as authorized by
// the license agreement.
//

import Foundation

extension NSError {
    
    convenience init(domain: String, code: Int, localizedDescription: String, localizedFailureReason: String? = nil, localizedRecoverySuggestion: String? = nil) {
        var userInfo = [NSLocalizedDescriptionKey : localizedDescription]
        
        if let localizedFailureReason = localizedFailureReason {
            userInfo[NSLocalizedFailureReasonErrorKey] = localizedFailureReason
        }
        
        if let localizedRecoverySuggestion = localizedRecoverySuggestion {
            userInfo[NSLocalizedRecoverySuggestionErrorKey] = localizedRecoverySuggestion
        }
        
        self.init(domain: domain, code: code, userInfo: userInfo)
    }
    
    class func protonMailError(_ code: Int, localizedDescription: String, localizedFailureReason: String? = nil, localizedRecoverySuggestion: String? = nil) -> NSError {
        return NSError(domain: protonMailErrorDomain(), code: code, localizedDescription: localizedDescription, localizedFailureReason: localizedFailureReason, localizedRecoverySuggestion: localizedRecoverySuggestion)
    }
    
    class func protonMailErrorDomain(_ subdomain: String? = nil) -> String {
        var domain = Bundle.main.bundleIdentifier ?? "ch.protonmail"
        
        if let subdomain = subdomain {
            domain += ".\(subdomain)"
        }
        return domain
    }
 
    func getCode() -> Int {
        var defaultCode : Int = code;
        if defaultCode == Int.max {
            if let detail = self.userInfo["com.alamofire.serialization.response.error.response"] as? HTTPURLResponse {
                defaultCode = detail.statusCode
            }
        }
        return defaultCode
    }
    
    class func unknowError() -> NSError {
        return apiServiceError(
            code: -1,
            localizedDescription: LocalString._unknow_error,
            localizedFailureReason: LocalString._unknow_error)
    }
    
    func isInternetError() -> Bool {
        var isInternetIssue = false
        if let _ = self.userInfo ["com.alamofire.serialization.response.error.response"] as? HTTPURLResponse {
        } else {
            //                        if(error?.code == -1001) {
            //                            // request timed out
            //                        }
            if self.code == -1009 || self.code == -1004 || self.code == -1001 { //internet issue
                isInternetIssue = true
            }
        }
        return isInternetIssue
    }
    
    
}
