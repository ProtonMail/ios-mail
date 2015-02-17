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
    
    struct Key {
        static let displayName = "displayNameKey"
        static let isRememberMailboxPassword = "isRememberMailboxPasswordKey"
        static let isRememberUser = "isRememberUserKey"
        static let mailboxPassword = "mailboxPasswordKey"
        static let username = "usernameKey"
        static let password = "passwordKey"
    }
    
    // MARK: - Private variables
    
    private(set) var displayName: String? {
        didSet {
            NSUserDefaults.standardUserDefaults().setValue(displayName, forKey: Key.displayName)
            NSUserDefaults.standardUserDefaults().synchronize()
        }
    }
    
    private(set) var isSignedIn: Bool = false
    
    /// Value is only stored in the keychain
    private(set) var mailboxPassword: String? {
        get {
            return UICKeyChainStore.stringForKey(Key.mailboxPassword)
        }
        set {
            UICKeyChainStore.setString(newValue, forKey: Key.mailboxPassword)
        }
    }
    
    /// Value is only stored in the keychain
    private(set) var password: String? {
        get {
            return UICKeyChainStore.stringForKey(Key.password)
        }
        set {
            UICKeyChainStore.setString(newValue, forKey: Key.password)
        }
    }

    private(set) var username: String? {
        didSet {
            NSUserDefaults.standardUserDefaults().setValue(username, forKey: Key.username)
            NSUserDefaults.standardUserDefaults().synchronize()
        }
    }
    // MARK: - Public variables
    
    var isMailboxPasswordStored: Bool {
        return mailboxPassword != nil
    }
    
    var isRememberMailboxPassword: Bool = false {
        didSet {
            NSUserDefaults.standardUserDefaults().setBool(isRememberMailboxPassword, forKey: Key.isRememberMailboxPassword)
            NSUserDefaults.standardUserDefaults().synchronize()
        }
    }
    
    var isRememberUser: Bool = false {
        didSet {
            NSUserDefaults.standardUserDefaults().setBool(isRememberUser, forKey: Key.isRememberUser)
            NSUserDefaults.standardUserDefaults().synchronize()
        }
    }
    
    var isUserCredentialStored: Bool {
        return username != nil && password != nil
    }
    
    // MARK: - Public methods
    
    init() {
        cleanUpIfFirstRun()

        displayName = NSUserDefaults.standardUserDefaults().stringForKey(Key.displayName)
        isRememberMailboxPassword = NSUserDefaults.standardUserDefaults().boolForKey(Key.isRememberMailboxPassword)
        isRememberUser = NSUserDefaults.standardUserDefaults().boolForKey(Key.isRememberUser)
        username = NSUserDefaults.standardUserDefaults().stringForKey(Key.username)
    }
    
    func fetchUserInfo(completion: (NSError? -> Void)? = nil) {
        sharedAPIService.userInfo(success: { (displayName, privateKey) -> Void in
            self.displayName = displayName
            
            if completion != nil {
                completion!(nil)
            }
            
            }, failure: { error in
                if completion != nil {
                    completion!(error)
                }
        })
    }
    
    func setMailboxPassword(password: String, isRemembered: Bool) {
        mailboxPassword = password
        isRememberMailboxPassword = isRemembered
    }
    
    func signIn(username: String, password: String, isRemembered: Bool, completion: (NSError? -> Void)) {
        sharedAPIService.authAuth(username: username, password: password, success: { () in
            self.isSignedIn = true
            self.username = username

            if isRemembered {
                self.isRememberUser = isRemembered
                self.password = password
            }
            
            sharedUserDataService.fetchUserInfo() { error in
                completion(error)
            }
            
            }) { error in
                self.signOut()
                completion(error)
        }
    }
    
    func signOut() {
        clearAll()
        
        sharedMessageDataService.deleteAllMessages()
        
        (UIApplication.sharedApplication().delegate as AppDelegate).switchTo(storyboard: .signIn)
    }
    
    func updatePassword(newPassword: String, completion: APIService.CompletionBlock) {
        sharedAPIService.settingUpdatePassword(newPassword, completion: completion)
    }
    
    // MARK: - Private methods
    
    private func cleanUpIfFirstRun() {
        let firstRunKey = "FirstRunKey"
        
        if NSUserDefaults.standardUserDefaults().objectForKey(firstRunKey) == nil {
            clearAll()
            
            NSUserDefaults.standardUserDefaults().setObject(NSDate(), forKey: firstRunKey)
            NSUserDefaults.standardUserDefaults().synchronize()
        }
    }
    
    private func clearAll() {
        isSignedIn = false
        
        isRememberUser = false
        password = nil
        username = nil
        
        isRememberMailboxPassword = false
        mailboxPassword = nil
    }
}