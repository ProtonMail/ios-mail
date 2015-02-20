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
    
    typealias UserInfo = (displayName: String, notificationEmail: String, privateKey: String, signature: String, usedSpace: String, maxSpace: Int)
    typealias UserInfoBlock = (UserInfo?, NSError?) -> Void
    
    func userInfo(completion: UserInfoBlock) {
        fetchAuthCredential() { authCredential, error in
            if let authCredential = authCredential {
                let path = "/users/\(authCredential.userID)"
                
                let completionWrapper: CompletionBlock = { task, response, error in
                    if let userInfo = self.userInfoForResponse(response) {
                        completion(userInfo, nil)
                    } else {
                        completion(nil, NSError.unableToParseResponse(response))
                    }
                }
                
                self.request(method: .GET, path: path, parameters: nil, completion: completionWrapper)
            } else {
                completion(nil, error)
            }
        }
    }
    
    private func userInfoForResponse(response: Dictionary<String, AnyObject>?) -> UserInfo? {
        if let response = response {
            let displayName = response["DisplayName"] as? String ?? ""
            let notificationEmail = response["NotificationEmail"] as? String ?? ""
            let privateKey = response["EncPrivateKey"] as? String ?? ""
            let signature = response["Signature"] as? String ?? ""
            let usedSpace = response["UsedSpace"] as? String ?? "0"
            let maxSpace = response["MaxSpace"] as? Int ?? 0
            
            return (displayName, notificationEmail, privateKey, signature, usedSpace, maxSpace)
        }
        
        return nil
    }
}
