//
//  UserDataService.swift
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

let sharedUserDataService = UserDataService()

/// Stores information related to the user
class UserDataService {
    private let isRememberUserKey = "isRememberUserKey"
    private let usernameKey = "usernameKey"
    private let passwordKey = "passwordKey"
    
    let userDefaults = NSUserDefaults.standardUserDefaults()
    
    var isRememberUser: Bool {
        didSet {
            userDefaults.setBool(isRememberUser, forKey: isRememberUserKey)
        }
    }
    
    var isUserCredentialStored: Bool {
        return username != nil && password != nil
    }
    
    /// Value is only stored in the keychain
    private(set) var password: String? {
        get {
            return UICKeyChainStore.stringForKey(passwordKey)
        }
        set {
            UICKeyChainStore.setString(password, forKey: passwordKey)
        }
    }
    
    private(set) var username: String? {
        didSet {
            userDefaults.setValue(username, forKey: usernameKey)
        }
    }
    
    init() {
        isRememberUser = userDefaults.boolForKey(isRememberUserKey)
        username = userDefaults.stringForKey(usernameKey)
    }
    
    func signIn(username: String, password: String, isRemembered: Bool, completion: (NSError? -> Void)) {
        SharedProtonMailAPIService.authAuth(username: username, password: password, success: { () in
            if isRemembered {
                self.isRememberUser = isRemembered
                self.username = username
                self.password = password
            }
            
            completion(nil)
            }) { error in
                self.signOut()
                completion(error)
        }
    }
    
    func signOut() {
        isRememberUser = false
        password = nil
        username = nil
    }
}