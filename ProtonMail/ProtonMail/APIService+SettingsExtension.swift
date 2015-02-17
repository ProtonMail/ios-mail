//
//  APIService+SettingsExtension.swift
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

/// Settings extension
extension APIService {
    func settingUpdatePassword(newPassword: String, completion: CompletionBlock) {
        fetchAuthCredential(success: { authCredential in
            let path = "/setting/password"
            
            let parameters = [
                "username" : sharedUserDataService.username ?? "",
                "password" : newPassword,
                "client_id" : "demoapp",
                "response_type" : "password"]
            
            self.sessionManager.PUT(path, parameters: parameters, success: { (task, response) -> Void in
                if let response = response as? NSDictionary {
                    if let data = response["data"] as? NSDictionary {
                        completion(nil)
                        return
                    }
                }
                
                completion(APIError.unableToParseResponse.asNSError())
                }, failure: { task, error in
                    completion(error)
            })
            }, failure: completion)
    }
}