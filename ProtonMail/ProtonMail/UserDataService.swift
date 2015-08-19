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
    typealias UserNameCheckBlock = APIService.UserNameCheckBlock
    
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
        }
    }
    
    private(set) var username: String? = NSUserDefaults.standardUserDefaults().stringForKey(Key.username) {
        didSet {
            NSUserDefaults.standardUserDefaults().setValue(username, forKey: Key.username)
            NSUserDefaults.standardUserDefaults().synchronize()
        }
    }
    
    var usedSpace: Int64 {
        return userInfo?.usedSpace ?? 0
    }
    
    
    // MARK: - Public variables
    
    var userAddresses: Array<Address> { //never be null
        return userInfo?.userAddresses ?? Array<Address>()
    }
    
    var displayName: String {
        return (userInfo?.displayName ?? "").decodeHtml()
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
    
    var isSignedIn: Bool = false
    private(set) var isMailboxPWDOk: Bool = false
    
    var isUserCredentialStored: Bool {
        return username != nil && password != nil && isRememberUser
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
    
    var maxSpace: Int64 {
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
    
    var isSet : Bool {
        return userInfo != nil
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
    
    func isMailboxPasswordValid(password: String, privateKey : String) -> Bool {
        var error: NSError?
        let result = OpenPGP().checkPassphrase(password, forPrivateKey: privateKey, error: &error)
        if error == nil {
            return result
        } else {
            NSLog("\(__FUNCTION__) error: \(error!)")
        }
        return false
    }
    
    func setMailboxPassword(password: String, isRemembered: Bool) {
        mailboxPassword = password
        isRememberMailboxPassword = isRemembered
    }
    
    func isPasswordValid(password: String?) -> Bool {
        return self.password == password
    }
    
    
    func signIn(username: String, password: String, isRemembered: Bool, completion: UserInfoBlock) {
        sharedAPIService.auth(username, password: password) { task, error in
            if error == nil {
                self.isSignedIn = true
                self.username = username
                self.password = password
                if isRemembered {
                    self.isRememberUser = isRemembered
                }
                completion(nil, nil)
            } else {
                self.signOut(true)
                completion(nil, error)
            }
        }
        
//        if error == nil {
//            NSNotificationCenter.defaultCenter().postNotificationName(Notification.didSignIn, object: self)
//        }
//        //completion(auth, error)
//        self.fetchUserInfo(completion: completionWrapper)

    }
    
    func clean() {
        clearAll()
        clearAuthToken()
    }
    
    func signOut(animated: Bool) {
        clearAll()
        clearAuthToken()
        
        NSNotificationCenter.defaultCenter().postNotificationName(Notification.didSignOut, object: self)
        
        (UIApplication.sharedApplication().delegate as! AppDelegate).switchTo(storyboard: .signIn, animated: animated)
    }
    
    func updateDisplayName(displayName: String, completion: UserInfoBlock?) {
        let new_displayName = displayName.trim()
        sharedAPIService.settingUpdateDisplayName(new_displayName, completion: completionForUserInfo(completion))
    }
    
    func updateMailboxPassword(old_mbp: String, newMailboxPassword: String, completion: CompletionBlock?) {
        var error: NSError?
        
        if let userInfo = userInfo {
            if let mailboxPassword = mailboxPassword {
                if let newPrivateKey = OpenPGP().updatePassphrase(userInfo.privateKey, publicKey: userInfo.publicKey, old_pass: mailboxPassword, new_pass: newMailboxPassword, error: &error) {
                    sharedAPIService.userUpdateKeypair(sharedUserDataService.password!, publicKey: userInfo.publicKey, privateKey: newPrivateKey, completion: { task, response, error in
                        if error == nil {
                            self.mailboxPassword = newMailboxPassword
                            
                            let userInfo = UserInfo(displayName: userInfo.displayName, maxSpace: userInfo.maxSpace, notificationEmail: userInfo.notificationEmail, privateKey: newPrivateKey, publicKey: userInfo.publicKey, signature: userInfo.signature, usedSpace: userInfo.usedSpace, userStatus:userInfo.userStatus, userAddresses:userInfo.userAddresses)
                            
                            self.userInfo = userInfo
                        }
                        
                        completion?(task: task, response: response, error: error)
                    })
                } else {
                    completion?(task: nil, response: nil, error: error)
                }
            }
        }
    }
    
    func updateNewUserKeys(mbp:String, completion: CompletionBlock?) {
        var error: NSError?
        if let userInfo = userInfo {
            if let newPrivateKey = OpenPGP().generateKey(mbp, userName: username!, error: &error) {
                var pubkey = newPrivateKey["public"] as! String
                var privkey = newPrivateKey["private"] as! String
                sharedAPIService.userUpdateKeypair("" , publicKey: pubkey, privateKey: privkey, completion: { task, response, error in
                    if error == nil {
                        self.mailboxPassword = mbp;
                        let userInfo = UserInfo(displayName: userInfo.displayName, maxSpace: userInfo.maxSpace, notificationEmail: userInfo.notificationEmail, privateKey: privkey, publicKey: pubkey, signature: userInfo.signature, usedSpace: userInfo.usedSpace, userStatus:userInfo.userStatus, userAddresses:userInfo.userAddresses)
                        
                        self.userInfo = userInfo
                    }
                    completion?(task: task, response: response, error: error)
                })
            } else {
                completion?(task: nil, response: nil, error: error)
            }
        }
    }
    
    func updateUserDomiansOrder(email_domains: Array<Address>, completion: CompletionBlock) {
        
        let domainSetting = UpdateDomainOrder<ApiResponse>(adds: email_domains)
        domainSetting.call() { task, response, hasError in
            if !hasError {
                if let userInfo = self.userInfo {
                    let userInfo = UserInfo(displayName: userInfo.displayName, maxSpace: userInfo.maxSpace, notificationEmail: userInfo.notificationEmail, privateKey: userInfo.privateKey, publicKey: userInfo.publicKey, signature: userInfo.signature, usedSpace: userInfo.usedSpace, userStatus:userInfo.userStatus, userAddresses:email_domains)
                    
                    self.userInfo = userInfo
                }
            }
            completion(task: task, response: nil, error: nil)
        }
    }

    func updateNotificationEmail(newNotificationEmail: String, completion: UserInfoBlock?) {
        sharedAPIService.settingUpdateNotificationEmail(newNotificationEmail, completion: completionForUserInfo(completion))
    }
    
    func updatePassword(old_pwd: String, newPassword: String, completion: CompletionBlock) {
        sharedAPIService.settingUpdatePassword(old_pwd, newPassword: newPassword, completion: { task, responseDict, anError in
            var error = anError
            
            if error == nil {
                self.password = newPassword
            }            
            completion(task: task, response: responseDict, error: error)
        })
    }

    func updateSignature(signature: String, completion: UserInfoBlock?) {
        sharedAPIService.settingUpdateSignature(signature, completion: completionForUserInfo(completion))
    }
    
    func createNewUser(user_name: String, password: String, email: String, receive:Bool, completion: UserInfoBlock) {
        sharedAPIService.userCreate(user_name, pwd: password, email: email, receive_news: receive){ auth, error in
            if error == nil {
                self.isSignedIn = true
                self.username = user_name
                self.password = password
                self.isRememberUser = false
                
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

    func checkUserNameIsExsit(user_name: String, completion: UserNameCheckBlock) {
        sharedAPIService.userCheckExist(user_name, completion: completion)
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
    

}
