//
//  AuthenticationService.swift
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

class AuthenticationService {
    let usernameKey = "AuthenticationServiceUsernameKey"
    let passwordKey = "AuthenticationServicePasswordKey"
    
    func signIn(username: String, password: String, isRemembered: Bool, completion: (NSError? -> Void)) {
        
        // TODO: network authentication call
        let delayTime = dispatch_time(DISPATCH_TIME_NOW,
            Int64(5 * Double(NSEC_PER_SEC)))
        dispatch_after(delayTime, dispatch_get_main_queue()) { () -> Void in
            
            var error: NSError? = nil
            
            if isRemembered {
                self.saveUserCredentials(username: username, password: password, error: &error)
            }

            completion(nil)
        }
    }
    
    func signOut() {
        // TODO: clear credentials
        
        removeUserCredentials()
    }
    
    // MARK: - Private methods
    
    func removeUserCredentials() {
        let store = UICKeyChainStore()
        store.removeItemForKey(usernameKey)
        store.removeItemForKey(passwordKey)
        store.synchronize()
    }
    
    func saveUserCredentials(#username: String, password: String, error: NSErrorPointer) -> Bool {
        let store = UICKeyChainStore()
        store.setString(username, forKey: usernameKey)
        store.setString(password, forKey: passwordKey)
        
        return store.synchronizeWithError(error)
    }
}