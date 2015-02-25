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
    
    typealias CompletionBlock = APIService.CompletionBlock
    typealias UserInfoBlock = APIService.UserInfoBlock
    
    struct Key {
        static let displayName = "displayNameKey"
        static let isRememberMailboxPassword = "isRememberMailboxPasswordKey"
        static let isRememberUser = "isRememberUserKey"
        static let mailboxPassword = "mailboxPasswordKey"
        static let notificationEmail = "notificationEmailKey"
        static let signature = "signatureKey"
        static let username = "usernameKey"
        static let password = "passwordKey"
    }
    
    struct Notification {
        static let didSignOut = "UserDataServiceDidSignOutNotification"
    }
    
    // MARK: - Private variables
    
    private(set) var displayName: String = "" {
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
    
    private(set) var notificationEmail: String = "" {
        didSet {
            NSUserDefaults.standardUserDefaults().setValue(notificationEmail, forKey: Key.notificationEmail)
            NSUserDefaults.standardUserDefaults().synchronize()
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

    private(set) var signature: String = "" {
        didSet {
            NSUserDefaults.standardUserDefaults().setValue(signature, forKey: Key.signature)
            NSUserDefaults.standardUserDefaults().synchronize()
        }
    }
    
    private(set) var username: String? {
        didSet {
            NSUserDefaults.standardUserDefaults().setValue(username, forKey: Key.username)
            NSUserDefaults.standardUserDefaults().synchronize()
        }
    }
    
    private(set) var usedSpace: Int!
    private(set) var maxSpace: Int!
    
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

        displayName = NSUserDefaults.standardUserDefaults().stringOrEmptyStringForKey(Key.displayName)
        isRememberMailboxPassword = NSUserDefaults.standardUserDefaults().boolForKey(Key.isRememberMailboxPassword)
        isRememberUser = NSUserDefaults.standardUserDefaults().boolForKey(Key.isRememberUser)
        notificationEmail = NSUserDefaults.standardUserDefaults().stringOrEmptyStringForKey(Key.notificationEmail)
        signature = NSUserDefaults.standardUserDefaults().stringOrEmptyStringForKey(Key.signature)
        username = NSUserDefaults.standardUserDefaults().stringForKey(Key.username)
    }
    
    func fetchUserInfo(completion: UserInfoBlock? = nil) {
        sharedAPIService.userInfo() { userInfo, error in
            if let (displayName, notificationEmail, privateKey, signature, usedSpace, maxSpace) = userInfo {
                self.displayName = displayName
                self.notificationEmail = notificationEmail
                self.signature = signature
                self.usedSpace = usedSpace.toInt()
                self.maxSpace = maxSpace
            }
            
            completion?(userInfo, error)
        }
    }
    
    func setMailboxPassword(password: String, isRemembered: Bool) {
        mailboxPassword = password
        isRememberMailboxPassword = isRemembered
    }
    
    func signIn(username: String, password: String, isRemembered: Bool, completion: UserInfoBlock) {
        sharedAPIService.authAuth(username: username, password: password) { auth, error in
            if error == nil {
                self.isSignedIn = true
                self.username = username
                
                if isRemembered {
                    self.isRememberUser = isRemembered
                    self.password = password
                }
                
                self.fetchUserInfo() { userInfo, error in
                    completion(userInfo, error)
                }
            } else {
                self.signOut()
                completion(nil, error)
            }
        }
    }
    
    func signOut() {
        clearAll()
        clearAuthToken()
        
        NSNotificationCenter.defaultCenter().postNotificationName(Notification.didSignOut, object: self)
        
        (UIApplication.sharedApplication().delegate as AppDelegate).switchTo(storyboard: .signIn)
    }
    
    func updateDisplayName(displayName: String, completion: CompletionBlock) {
        sharedAPIService.settingUpdateDisplayName(displayName, completion: { task, response, error in
            if error == nil {
                self.displayName = displayName
            }
            
            completion(task, response, error)
        })
    }
    
    func updateMailboxPassword(newMailboxPassword: String, completion: CompletionBlock) {
        sharedAPIService.settingUpdateMailboxPassword(newMailboxPassword, completion: { task, response, error in
            if error == nil {
                self.mailboxPassword = newMailboxPassword
            }
            
            completion(task, response, error)
        })
    }
    
    func updateNotificationEmail(newNotificationEmail: String, completion: CompletionBlock) {
        sharedAPIService.settingUpdateNotificationEmail(newNotificationEmail, completion: { task, response, error in
            if error == nil {
                self.notificationEmail = newNotificationEmail
            }
            
            completion(task, response, error)
        })
    }
    
    func updatePassword(newPassword: String, completion: CompletionBlock) {
        sharedAPIService.settingUpdatePassword(newPassword, completion: { task, responseDict, anError in
            var error = anError
            
            if error == nil {
                if let data = responseDict?["data"] as? Dictionary<String,AnyObject> {
                    self.password = newPassword
                } else {
                    error = NSError.unableToParseResponse(responseDict)
                }
            }
            
            completion(task, responseDict, error)
        })
    }

    func updateSignature(signature: String, completion: CompletionBlock) {
        sharedAPIService.settingUpdateSignature(signature, completion: { task, response, error in
            if error == nil {
                self.signature = signature
            }
            
            completion(task, response, error)
        })
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
        
        displayName = ""
        notificationEmail = ""
        signature = ""
    }
    
    private func clearAuthToken() {
        AuthCredential.clearFromKeychain()
    }
}