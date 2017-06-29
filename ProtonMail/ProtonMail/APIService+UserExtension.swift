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
import ProtonMailCommon

/// User extensions
extension APIService {
    
    typealias UserInfoBlock = (UserInfo?, String?, NSError?) -> Void

    fileprivate struct UserPath {
        static let base = AppConstants.API_PATH + "/users"
    }

    func userPublicKeyForUsername(_ username: String, completion: CompletionBlock?) {
        let path = UserPath.base + "/pubkey" + "/\(username)"
        //setApiVesion(1, appVersion: 1)
        request(method: .get, path: path, parameters: nil, headers: ["x-pm-apiversion": 1], completion: completion)
    }
    
    func userPublicKeysForEmails(_ emails: Array<String>, completion: CompletionBlock?) {
        let emailsString = emails.joined(separator: ",")
        
        userPublicKeysForEmails(emailsString, completion: completion)
    }
    
    func userPublicKeysForEmails(_ emails: String, completion: CompletionBlock?) {
        PMLog.D("userPublicKeysForEmails -- \(emails)")
        if !emails.isEmpty {
            if let base64Emails = emails.base64Encoded() {
                let escapedValue : String? = base64Emails.addingPercentEncoding(withAllowedCharacters: CharacterSet(charactersIn: "/+=\n").inverted)
                let path = UserPath.base.stringByAppendingPathComponent("pubkeys").stringByAppendingPathComponent(escapedValue ?? base64Emails)
                //setApiVesion(2, appVersion: 1)
                request(method: .get, path: path, parameters: nil, headers: ["x-pm-apiversion": 2], completion: { task, response, error in
                    PMLog.D("userPublicKeysForEmails -- res \(String(describing: response)) || error -- \(String(describing: error))")
                    if let paserError = self.isErrorResponse(response) {
                        completion?(task, response, paserError)
                    } else {
                        completion?(task, response, error)
                    }
                })
                return
            }
        }
        completion?(nil, nil, NSError.badParameter(emails))
    }
    
    func userUpdateKeypair(_ pwd: String, publicKey: String, privateKey: String, completion: CompletionBlock?) {
        let path = UserPath.base + "/keys"
        let parameters = [
            "Password" : pwd,
            "PublicKey" : publicKey,
            "PrivateKey" : privateKey
        ]
        //setApiVesion(2, appVersion: 1)
        request(method: .put, path: path, parameters: parameters, headers: ["x-pm-apiversion": 2], completion: completion)
    }
    
    // MARK: private mothods
    fileprivate func isErrorResponse(_ response: Any!) -> NSError? {
        if let dict = response as? NSDictionary {
            if let code = dict["Code"] as? Int, code != 1000 && code != 1001 {
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
