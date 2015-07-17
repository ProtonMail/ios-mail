//
//  AuthDataService.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 7/16/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation



let sharedAuthDataService = AuthDataService()

/// Stores information related to the user
class AuthDataService {
    
    typealias AuthComplete = (task: NSURLSessionDataTask?, hasError : NSError?) -> Void

    func auth(username: String, password: String, completion: AuthComplete?) {
        AuthRequest<AuthResponse>(username: username, password: password).call() { task, res , hasError in
            if hasError {
                completion?(task: task, hasError: NSError.authInvalidGrant())
            }
            else if res?.code == 1000 {
                let credential = AuthCredential(res: res)
                credential.storeInKeychain()
                completion?(task: task, hasError: nil)
            }
            else {
                completion?(task: task, hasError: NSError.authUnableToParseToken())
            }
//            if self.isErrorResponse(response) {
//
//            } else if let authInfo = self.authInfoForResponse(response) {
//                
//            } else if error == nil {
//                completion?(nil, NSError.authUnableToParseToken())
//            } else {
//                completion?(nil, NSError.unableToParseResponse(response))
//            }
        }
        
    }
    
    
}