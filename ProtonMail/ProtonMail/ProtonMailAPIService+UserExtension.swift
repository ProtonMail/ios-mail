//
//  ProtonMailAPIService+UserExtension.swift
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

extension ProtonMailAPIService {
    typealias UserInfo = (displayName: String?, privateKey: String?)
    
    func userInfo(#success: (UserInfo -> Void), failure: (NSError? -> Void)) {
        fetchAuthCredential(success: { authCredential in
            let userInfoPath = "/users/\(authCredential.userID)"
            
            self.sessionManager.GET(userInfoPath, parameters: nil, success: { (task, response) -> Void in
                if let userInfo = self.userInfoForResponse(response) {
                    success(userInfo)
                } else {
                    failure(NSError.protonMailError(code: APIError.unknown.rawValue, localizedDescription: APIError.unknown.localizedDescription, localizedFailureReason: response.description))
                }
                }) { task, error in
                    failure(error)
            }
        }, failure: failure)
    }
    
    func userInfoForResponse(response: AnyObject!) -> UserInfo? {
        if let response = response as? NSDictionary {
            let displayName = response["DisplayName"] as? String
            let privateKey = response["EncPrivateKey"] as? String
            
            return (displayName, privateKey)
        }
        
        return nil
    }
}
