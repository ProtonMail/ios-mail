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
    
    let passwordKey = "AuthenticationServicePasswordKey"
    let usernameKey = "AuthenticationServiceUsernameKey"
    
    func isAuthenticated() -> Bool {
        // TODO: check if we have credentials that work
        
        let store = UICKeyChainStore()
        
        return store.stringForKey(usernameKey) != nil
    }
    
    func rememberedCredentials() -> (username: String, password: String)? {
        let store = UICKeyChainStore()
        let username = store.stringForKey(usernameKey)
        let password = store.stringForKey(passwordKey)
        
        if username == nil || password == nil {
            return nil
        }
        
        return (username, password)
    }
    
    func signIn(username: String, password: String, isRemembered: Bool, completion: (NSError? -> Void)) {
        SharedProtonMailAPIService.authAuth(username: username, password: password, success: { credential in
            if isRemembered {
                self.saveUserCredentials(username: username, password: password)
            }
            
            NSLog("\(__FUNCTION__) credential: \(credential)")
            
            completion(nil)
            }) { error in
                self.removeUserCredentials()
                completion(error)
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
    }
    
    func saveUserCredentials(#username: String, password: String) {
        let store = UICKeyChainStore()
        store.setString(username, forKey: usernameKey)
        store.setString(password, forKey: passwordKey)
    }
}