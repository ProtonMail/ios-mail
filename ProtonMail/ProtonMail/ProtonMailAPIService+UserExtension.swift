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
    enum UserErrorCode: Int {
        case NoUser = 200
    }
    
    func userInfo(success: (AnyObject! -> Void), failure: (NSError -> Void)) {
        if let authCredential = authCredential() {
            let userInfoPath = "/user/\(authCredential.userID)"
            
            sessionManager.GET(userInfoPath, parameters: nil, success: { (task, response) -> Void in
                if let response = response as NSDictionary {
                    
                }
            }, failure: { (task, error) -> Void in
                failure(error)
            })
        } else {
            let error = NSError.protonMailError(code: UserErrorCode.NoUser.rawValue, localizedDescription: NSLocalizedString("User not logged in"), localizedFailureReason: NSLocalizedString("The user is not logged in."))
            
            failure(error)
        }
    }
}
