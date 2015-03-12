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
        static let isRememberMailboxPassword = "isRememberMailboxPasswordKey"
        static let isRememberUser = "isRememberUserKey"
        static let mailboxPassword = "mailboxPasswordKey"
        static let username = "usernameKey"
        static let password = "passwordKey"
        static let userInfo = "userInfoKey"
    }
    
    struct Notification {
        static let didSignOut = "UserDataServiceDidSignOutNotification"
        static let didSignIn = "UserDataServiceDidSignInNotification"
    }
        
    // MARK: - Private variables
    
    private(set) var userInfo: UserInfo? = NSUserDefaults.standardUserDefaults().customObjectForKey(Key.userInfo) as? UserInfo {
        didSet {
            NSUserDefaults.standardUserDefaults().setCustomValue(userInfo, forKey: Key.userInfo)
            NSUserDefaults.standardUserDefaults().synchronize()
            
            StorageLimit().checkSpace(usedSpace: usedSpace, maxSpace: maxSpace)
        }
    }
    
    private(set) var username: String? = NSUserDefaults.standardUserDefaults().stringForKey(Key.username) {
        didSet {
            NSUserDefaults.standardUserDefaults().setValue(username, forKey: Key.username)
            NSUserDefaults.standardUserDefaults().synchronize()
        }
    }
    
    var usedSpace: Int {
        return userInfo?.usedSpace ?? 0
    }
    
    // MARK: - Public variables
    
    var displayName: String {
        return userInfo?.displayName ?? ""
    }
    
    var isMailboxPasswordStored: Bool {
        return mailboxPassword != nil
    }
    
    var isRememberMailboxPassword: Bool = NSUserDefaults.standardUserDefaults().boolForKey(Key.isRememberMailboxPassword) {
        didSet {
            NSUserDefaults.standardUserDefaults().setBool(isRememberMailboxPassword, forKey: Key.isRememberMailboxPassword)
            NSUserDefaults.standardUserDefaults().synchronize()
        }
    }
    
    var isRememberUser: Bool = NSUserDefaults.standardUserDefaults().boolForKey(Key.isRememberUser) {
        didSet {
            NSUserDefaults.standardUserDefaults().setBool(isRememberUser, forKey: Key.isRememberUser)
            NSUserDefaults.standardUserDefaults().synchronize()
        }
    }
    
    private(set) var isSignedIn: Bool = false
    
    var isUserCredentialStored: Bool {
        return username != nil && password != nil
    }
    
    /// Value is only stored in the keychain
    private(set) var mailboxPassword: String? {
        get {
            return UICKeyChainStore.stringForKey(Key.mailboxPassword)
        }
        set {
            UICKeyChainStore.setString(newValue, forKey: Key.mailboxPassword)
        }
    }
    
    var maxSpace: Int {
        return userInfo?.maxSpace ?? 0
    }
    
    var notificationEmail: String {
        return userInfo?.notificationEmail ?? ""
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
    
    var signature: String {
        return userInfo?.signature ?? ""
    }
    
    // MARK: - Public methods
    
    init() {
        cleanUpIfFirstRun()
        launchCleanUp()
    }

    func fetchUserInfo(completion: UserInfoBlock? = nil) {
        sharedAPIService.userInfo() { userInfo, error in
            if error == nil {
                self.userInfo = userInfo
            }
            
            completion?(userInfo, error)
        }
    }
    
    func isMailboxPasswordValid(password: String) -> Bool {
        if let userInfo = userInfo {
            var error: NSError?
        
            let result = OpenPGP().checkPassphrase(password, forPrivateKey: userInfo.privateKey, publicKey: userInfo.publicKey, error: &error)
                
            if error == nil {
                return result
            } else {
                NSLog("\(__FUNCTION__) error: \(error!)")
            }
        }
        
        return false
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
                self.password = password
                
                if isRemembered {
                    self.isRememberUser = isRemembered
                }
                
                let completionWrapper: UserInfoBlock = { auth, error in
                    if error == nil {
                        NSNotificationCenter.defaultCenter().postNotificationName(Notification.didSignIn, object: self)
                    }
                    
                    completion(auth, error)
                }
                
                self.fetchUserInfo(completion: completionWrapper)
            } else {
                self.signOut(true)
                completion(nil, error)
            }
        }
    }
    
    func signOut(animated: Bool) {
        clearAll()
        clearAuthToken()
        
        NSNotificationCenter.defaultCenter().postNotificationName(Notification.didSignOut, object: self)
        
        (UIApplication.sharedApplication().delegate as AppDelegate).switchTo(storyboard: .signIn, animated: animated)
    }
    
    func updateDisplayName(displayName: String, completion: UserInfoBlock?) {
        sharedAPIService.settingUpdateDisplayName(displayName, completion: completionForUserInfo(completion))
    }
    
    func updateMailboxPassword(newMailboxPassword: String, completion: CompletionBlock) {
        sharedAPIService.settingUpdateMailboxPassword(newMailboxPassword, completion: { task, response, error in
            if error == nil {
                self.mailboxPassword = newMailboxPassword
            }
            
            completion(task, response, error)
        })
    }
    
    func updateNotificationEmail(newNotificationEmail: String, completion: UserInfoBlock?) {
        sharedAPIService.settingUpdateNotificationEmail(newNotificationEmail, completion: completionForUserInfo(completion))
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

    func updateSignature(signature: String, completion: UserInfoBlock?) {
        sharedAPIService.settingUpdateSignature(signature, completion: completionForUserInfo(completion))
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
        
        userInfo = nil
    }
    
    private func clearAuthToken() {
        AuthCredential.clearFromKeychain()
    }
    
    private func completionForUserInfo(completion: UserInfoBlock?) -> CompletionBlock {
        return { task, response, error in
            if error == nil {
                self.fetchUserInfo(completion: completion)
            } else {
                completion?(nil, error)
            }
        }
    }
    
    private func launchCleanUp() {
        if !self.isRememberUser {
            username = nil
            password = nil
        }
        
        if !isRememberMailboxPassword {
            mailboxPassword = nil
        }
    }
}

// MARK: - Message extension

extension Message {
    
    func decryptBody(error: NSErrorPointer?) -> String? {
        if !isEncrypted {
            return body
        } else {
            return body.decryptWithPrivateKey(sharedUserDataService.userInfo?.privateKey ?? "", passphrase: sharedUserDataService.mailboxPassword? ?? "", publicKey: sharedUserDataService.userInfo?.publicKey ?? "", error: error)
        }
    }
}
