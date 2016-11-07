//
//  APIService+UserExtension.swift
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

/// User extensions
extension APIService {
    
    typealias UserInfoBlock = (UserInfo?, String?, NSError?) -> Void

    private struct UserPath {
        static let base = AppConstants.BaseAPIPath + "/users"
    }

    func userPublicKeyForUsername(username: String, completion: CompletionBlock?) {
        let path = UserPath.base + "/pubkey" + "/\(username)"
        
        setApiVesion(1, appVersion: 1)
        request(method: .GET, path: path, parameters: nil, completion: completion)
    }
    
    func userPublicKeysForEmails(emails: Array<String>, completion: CompletionBlock?) {
        let emailsString = emails.joinWithSeparator(",")
        
        userPublicKeysForEmails(emailsString, completion: completion)
    }
    
    func userPublicKeysForEmails(emails: String, completion: CompletionBlock?) {
        PMLog.D("userPublicKeysForEmails -- \(emails)")
        if !emails.isEmpty {
            if let base64Emails = emails.base64Encoded() {
                let escapedValue : String? = base64Emails.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet(charactersInString: "/+=\n").invertedSet)
                let path = UserPath.base.stringByAppendingPathComponent("pubkeys").stringByAppendingPathComponent(escapedValue ?? base64Emails)
                setApiVesion(2, appVersion: 1)
                request(method: .GET, path: path, parameters: nil, completion: { task, response, error in
                    PMLog.D("userPublicKeysForEmails -- res \(response) || error -- \(error)")
                    let error = error
                    let response = response
                    if let paserError = self.isErrorResponse(response) {
                        completion?(task: task, response: response, error: paserError)
                    } else {
                        completion?(task: task, response: response, error: error)
                    }
                })
                return
            }
        }
        completion?(task: nil, response: nil, error: NSError.badParameter(emails))
    }
    
    func userUpdateKeypair(pwd: String, publicKey: String, privateKey: String, completion: CompletionBlock?) {
        let path = UserPath.base + "/keys"
        let parameters = [
            "Password" : pwd,
            "PublicKey" : publicKey,
            "PrivateKey" : privateKey
        ]
        setApiVesion(2, appVersion: 1)
        request(method: .PUT, path: path, parameters: parameters, completion: completion)
    }
    
    // MARK: private mothods
    private func isErrorResponse(response: AnyObject!) -> NSError? {
        if let dict = response as? NSDictionary {
            if let code = dict["Code"] as? Int where code != 1000 && code != 1001 {
                let error = dict["Error"] as? String ?? ""
                let desc = dict["ErrorDescription"] as? String ?? ""
                return NSError.apiServiceError(code: code, localizedDescription: error, localizedFailureReason: desc, localizedRecoverySuggestion: "")
            } else {
                return nil
            }
        }
        
        return  NSError.unableToParseResponse(response)
    }
}
