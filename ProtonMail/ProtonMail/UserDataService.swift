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
    
    //typealias LoginBlock = (mailboxPwd: String? error: NSError?) -> Void
    //Login callback blocks
    typealias LoginAsk2FABlock = () -> Void
    typealias LoginErrorBlock = (error: NSError) -> Void
    typealias LoginSuccessBlock = (mpwd: String?) -> Void
    
    struct Key {
        static let isRememberMailboxPassword = "isRememberMailboxPasswordKey"
        static let isRememberUser = "isRememberUserKey"
        static let mailboxPassword = "mailboxPasswordKey"
        static let username = "usernameKey"
        static let password = "passwordKey"
        static let userInfo = "userInfoKey"
        static let twoFAStatus = "twofaKey"
        static let userPasswordMode = "userPasswordModeKey"
        
        static let roleSwitchCache = "roleSwitchCache"
        static let defaultSignatureStatus = "defaultSignatureStatus"
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
    
    // Value is only stored in the keychain
    private(set) var password: String? {
        get {
            return UICKeyChainStore.stringForKey(Key.password)
        }
        set {
            UICKeyChainStore.setString(newValue, forKey: Key.password)
        }
    }
    
    private var switchCacheOff: Bool? = NSUserDefaults.standardUserDefaults().boolForKey(Key.roleSwitchCache) {
        
        didSet {
            NSUserDefaults.standardUserDefaults().setValue(switchCacheOff, forKey: Key.roleSwitchCache)
            NSUserDefaults.standardUserDefaults().synchronize()
        }
    }
    
    private var defaultSignatureStauts: Bool = NSUserDefaults.standardUserDefaults().boolForKey(Key.defaultSignatureStatus) {
        didSet {
            NSUserDefaults.standardUserDefaults().setValue(defaultSignatureStauts, forKey: Key.defaultSignatureStatus)
            NSUserDefaults.standardUserDefaults().synchronize()
        }
    }
    
    var twoFactorStatus: Int = NSUserDefaults.standardUserDefaults().integerForKey(Key.twoFAStatus)  {
        didSet {
            NSUserDefaults.standardUserDefaults().setValue(twoFactorStatus, forKey: Key.twoFAStatus)
            NSUserDefaults.standardUserDefaults().synchronize()
        }
    }
    
    var passwordMode: Int = NSUserDefaults.standardUserDefaults().integerForKey(Key.userPasswordMode)  {
        didSet {
            NSUserDefaults.standardUserDefaults().setValue(passwordMode, forKey: Key.userPasswordMode)
            NSUserDefaults.standardUserDefaults().synchronize()
        }
    }
    
    var showDefaultSignature : Bool {
        get {
            return defaultSignatureStauts
        }
        set {
            defaultSignatureStauts = newValue
        }
    }
    
    var showMobileSignature : Bool {
        get {
            #if Enterprise
                let isEnterprise = true
            #else
                let isEnterprise = false
            #endif
            
            if userInfo?.role > 0 || isEnterprise {
                return (switchCacheOff == false) ?? true
            } else {
                switchCacheOff = false
                return true;
            } }
        set {
            switchCacheOff = (newValue == false)
        }
    }
    
    var mobileSignature : String {
        get {
            #if Enterprise
                let isEnterprise = true
            #else
                let isEnterprise = false
            #endif
            
            if userInfo?.role > 0 || isEnterprise {
                return userCachedStatus.mobileSignature
            } else {
                userCachedStatus.resetMobileSignature()
                return userCachedStatus.mobileSignature
            }
        }
        set {
            userCachedStatus.mobileSignature = newValue
        }
    }
    
    var usedSpace: Int64 {
        return userInfo?.usedSpace ?? 0
    }
    
    var showShowImageView: Bool {
        return userInfo?.showImages == 0
    }
    
    // MARK: - Public variables
    
    var defaultEmail : String {
        if let addr = userAddresses.getDefaultAddress() {
            return addr.email;
        }
        return "";
    }
    
    var defaultDisplayName : String {
        if let addr = userAddresses.getDefaultAddress() {
            return addr.display_name;
        }
        return displayName;
    }
    
    var swiftLeft : MessageSwipeAction! {
        get {
            return MessageSwipeAction(rawValue: userInfo?.swipeLeft ?? 3) ?? .archive
        }
    }
    
    var swiftRight : MessageSwipeAction! {
        get {
            return MessageSwipeAction(rawValue: userInfo?.swipeRight ?? 0) ?? .trash
        }
    }
    
    var userAddresses: Array<Address> { //never be null
        return userInfo?.userAddresses ?? Array<Address>()
    }
    
    var displayName: String {
        return (userInfo?.displayName ?? "").decodeHtml()
    }
    
    var isMailboxPasswordStored: Bool {
        
        isMailboxPWDOk = mailboxPassword != nil;
        
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
    var isNewUser : Bool = false
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
    
    var notify: Bool {
        return (userInfo?.notify ?? 0 ) == 1;
    }
    
    var signature: String {
        return (userInfo?.signature ?? "").ln2br()
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
        
        let getUserInfo = GetUserInfoRequest<GetUserInfoResponse>()
        getUserInfo.call { (task, response, hasError) -> Void in
            if !hasError {
                self.userInfo = response?.userInfo
                if let addresses = self.userInfo?.userAddresses.toPMNAddresses() {
                    sharedOpenPGP.setAddresses(addresses);
                }
            }
            completion?(self.userInfo, nil, response?.error)
        }
    }
    
    func updateUserInfoFromEventLog (userInfo : UserInfo){
        self.userInfo = userInfo
        if let addresses = self.userInfo?.userAddresses.toPMNAddresses() {
            sharedOpenPGP.setAddresses(addresses);
        }
    }
    
    func isMailboxPasswordValid(password: String, privateKey : String) -> Bool {
        let result = PMNOpenPgp.checkPassphrase(password, forPrivateKey: privateKey)
        return result
    }
    
    func setMailboxPassword(password: String, isRemembered: Bool) {
        mailboxPassword = password
        isRememberMailboxPassword = isRemembered
        self.isMailboxPWDOk = true;
    }
    
    func isPasswordValid(password: String?) -> Bool {
        return self.password == password
    }
    
    func signIn(username: String, password: String, twoFACode: String?, ask2fa: LoginAsk2FABlock, onError:LoginErrorBlock, onSuccess: LoginSuccessBlock) {
        sharedAPIService.auth(username, password: password, twoFACode: twoFACode) { task, mpwd, status, error in
            if status == .Ask2FA {
                self.twoFactorStatus = 1
                ask2fa()
            } else {
                if error == nil {
                    self.isSignedIn = true
                    self.username = username
                    self.password = password
                    self.isRememberUser = true
                    self.passwordMode = mpwd != nil ? 1 : 2
                    
                    onSuccess(mpwd: mpwd)
                } else {
                    self.twoFactorStatus = 0
                    self.signOut(true)
                    onError(error: error!)
                }
            }
        }
    }
    
    func clean() {
        clearAll()
        clearAuthToken()
    }
    
    func signOut(animated: Bool) {
        sharedVMService.signOut()
        if let authCredential = AuthCredential.fetchFromKeychain(), token = authCredential.token where !token.isEmpty {
            AuthDeleteRequest().call { (task, response, hasError) in }
        }
        NSNotificationCenter.defaultCenter().postNotificationName(NotificationDefined.didSignOut, object: self)
        clearAll()
        clearAuthToken()
        (UIApplication.sharedApplication().delegate as! AppDelegate).switchTo(storyboard: .signIn, animated: animated)
    }
    
    func signOutAfterSignUp() {
        sharedVMService.signOut()
        if let authCredential = AuthCredential.fetchFromKeychain(), token = authCredential.token where !token.isEmpty {
            AuthDeleteRequest().call { (task, response, hasError) in }
        }
        NSNotificationCenter.defaultCenter().postNotificationName(NotificationDefined.didSignOut, object: self)
        clearAll()
        clearAuthToken()
    }
    
    func updateDisplayName(displayName: String, completion: UserInfoBlock?) {
        let new_displayName = displayName.trim()
        let api = UpdateDisplayNameRequest(displayName: new_displayName)
        api.call() { task, response, hasError in
            if !hasError {
                if let userInfo = self.userInfo {
                    userInfo.displayName = new_displayName
                    self.userInfo = userInfo
                }
            }
            completion?(self.userInfo, nil, nil)
        }
    }
    
    func updateAddress(addressId: String, displayName: String, signature: String, completion: UserInfoBlock?) {
        let new_displayName = displayName.trim()
        let new_signature = signature.trim()
        
        let api = UpdateAddressRequest(id: addressId, displayName: new_displayName, signature: new_signature)
        api.call() { task, response, hasError in
            if !hasError {
                if let userInfo = self.userInfo {
                    let addresses = userInfo.userAddresses
                    for addr in addresses {
                        if addr.address_id == addressId {
                            addr.display_name = new_displayName
                            addr.signature = new_signature
                            break
                        }
                    }
                    userInfo.userAddresses = addresses
                    self.userInfo = userInfo
                }
            }
            completion?(self.userInfo, nil, nil)
        }
    }
    
    func updateAutoLoadImage(status : Int, completion: UserInfoBlock?) {
        let api = UpdateShowImagesRequest(status: status)
        api.call() { task, response, hasError in
            if !hasError {
                if let userInfo = self.userInfo {
                    userInfo.showImages = status
                    self.userInfo = userInfo
                }
            }
            completion?(self.userInfo, nil, nil)
        }
    }
    
    //TODO:: change the errors throw
    func updatePassword(old_pwd: String, newPassword: String, twoFACode:String?, completion: CompletionBlock) {
        {//asyn
            do {
                
                throw UpdatePasswordError.InvalidUserName.toError()
                //generate new pwd and verifier
                guard let _username = self.username else {
                    throw UpdatePasswordError.InvalidUserName.toError()
                }
                let authModuls = try AuthModulusRequest<AuthModulusResponse>().syncCall()
                guard let moduls_id = authModuls?.ModulusID else {
                    throw UpdatePasswordError.InvalidModulsID.toError()
                }
                guard let new_moduls = authModuls?.Modulus, let new_encodedModulus = try new_moduls.getSignature() else {
                    throw UpdatePasswordError.InvalidModuls.toError()
                }
                //generat new verifier
                let new_decodedModulus : NSData = new_encodedModulus.decodeBase64()
                let new_salt : NSData = PMNOpenPgp.randomBits(80)
                guard let new_hashed_password = PasswordUtils.hashPasswordVersion4(newPassword, salt: new_salt, modulus: new_decodedModulus) else {
                    throw UpdatePasswordError.CantHashPassword.toError()
                }
                
                guard let verifier = try generateVerifier(2048, modulus: new_decodedModulus, hashedPassword: new_hashed_password) else {
                    throw UpdatePasswordError.CantGenerateVerifier.toError()
                }
                
                //start check exsit srp
                var forceRetry = false
                var forceRetryVersion = 2
                
                repeat {
                    // get auto info
                    let info = try AuthInfoRequest<AuthInfoResponse>(username: _username).syncCall()
                    guard let authVersion = info?.Version, let modulus = info?.Modulus, let ephemeral = info?.ServerEphemeral, let salt = info?.Salt, let session = info?.SRPSession else {
                        throw UpdatePasswordError.InvalideAuthInfo.toError()
                    }
                    guard let encodedModulus = try modulus.getSignature() else {
                        throw UpdatePasswordError.InvalideAuthInfo.toError()
                    }
                    
                    let decodedModulus : NSData = encodedModulus.decodeBase64()
                    let decodedSalt : NSData = salt.decodeBase64()
                    let serverEphemeral : NSData = ephemeral.decodeBase64()
                    
                    if authVersion <= 2 && !forceRetry {
                        forceRetry = true
                        forceRetryVersion = 2
                    }
                    
                    //init api calls
                    let hashVersion = forceRetry ? forceRetryVersion : authVersion
                    guard let hashedPassword = PasswordUtils.getHashedPwd(hashVersion, password: old_pwd , username: _username, decodedSalt: decodedSalt, decodedModulus: decodedModulus) else {
                        throw UpdatePasswordError.CantHashPassword.toError()
                    }
                    
                    guard let srpClient = try generateSrpProofs(2048, modulus: decodedModulus, serverEphemeral: serverEphemeral, hashedPassword: hashedPassword) where srpClient.isValid() == true else {
                        throw UpdatePasswordError.CantGenerateSRPClient.toError()
                    }
                    
                    do {
                        let updatePwd = try UpdateLoginPassword<ApiResponse>(clientEphemeral: srpClient.clientEphemeral.encodeBase64(),
                                                                             clientProof: srpClient.clientProof.encodeBase64(),
                                                                             SRPSession: session,
                                                                             modulusID: moduls_id,
                                                                             salt: new_salt.encodeBase64(),
                                                                             verifer: verifier.encodeBase64(),
                                                                             tfaCode: twoFACode).syncCall()
                        if updatePwd?.code == 1000 {
                            self.password = newPassword
                            forceRetry = false
                        } else {
                            throw UpdatePasswordError.UpdatePasswordFailed.toError()
                        }
                    } catch let error as NSError {
                        if error.isInternetError() {
                            throw error
                        } else {
                            if forceRetry && forceRetryVersion != 0 {
                                forceRetryVersion -= 1
                            } else {
                                throw error
                            }
                        }
                    }
                } while(forceRetry && forceRetryVersion >= 0)
                return { completion(task: nil, response: nil, error: nil) } ~> .Main
            } catch let error as NSError {
                return { completion(task: nil, response: nil, error: error) } ~> .Main
            }
        } ~> .Async
    }
    
    func updateMailboxPassword(old_mbp: String, newMailboxPassword: String, completion: CompletionBlock?) {
        if let userInfo = userInfo {
            if let mailboxPassword = mailboxPassword {
                do {
                    //check old pwd on address keys,
                    
                    //check old pwd on user-level keys
                    
                    //check user role if equal 2 try to get the org key.
                    //if yes check org key old pwd
                    
                    //generat keysalt
                    
                    //generat new pwd
                    
                    
                    // need update the user kyes with
                    
                    
                    if let newPrivateKey = try sharedOpenPGP.updatePassphrase(userInfo.privateKey, publicKey: userInfo.publicKey, old_pass: mailboxPassword, new_pass: newMailboxPassword) {
                        sharedAPIService.userUpdateKeypair(sharedUserDataService.password!, publicKey: userInfo.publicKey, privateKey: newPrivateKey, completion: { task, response, error in
                            if error == nil {
                                self.mailboxPassword = newMailboxPassword
                                if let userInfo = self.userInfo {
                                    userInfo.privateKey = newPrivateKey
                                    self.userInfo = userInfo
                                }
                            }
                            completion?(task: task, response: response, error: error)
                        })
                    }
                } catch let ex as NSError {
                    completion?(task: nil, response: nil, error: ex)
                }
            }
        }
    }
    
    //    func updateNewUserKeys(mbp:String, completion: CompletionBlock?) {
    //        var error: NSError?
    //        if let userInfo = userInfo {
    //            if let newPrivateKey = sharedOpenPGP.generateKey(mbp, userName: username!, error: &error) {
    //                var pubkey = newPrivateKey.publicKey
    //                var privkey = newPrivateKey.privateKey
    //                sharedAPIService.userUpdateKeypair("" , publicKey: pubkey, privateKey: privkey, completion: { task, response, error in
    //                    if error == nil {
    //                        self.mailboxPassword = mbp;
    //                        let userInfo = UserInfo(displayName: userInfo.displayName, maxSpace: userInfo.maxSpace, notificationEmail: userInfo.notificationEmail, privateKey: privkey, publicKey: pubkey, signature: userInfo.signature, usedSpace: userInfo.usedSpace, userStatus:userInfo.userStatus, userAddresses:userInfo.userAddresses,
    //                            autoSC:userInfo.autoSaveContact, language:userInfo.language, maxUpload:userInfo.maxUpload, notify:userInfo.notify, showImage:userInfo.showImages,
    //
    //                            swipeL: userInfo.swipeLeft, swipeR: userInfo.swipeRight
    //                        )
    //
    //                        self.userInfo = userInfo
    //                    }
    //                    completion?(task: task, response: response, error: error)
    //                })
    //            } else {
    //                completion?(task: nil, response: nil, error: error)
    //            }
    //        }
    //    }
    
    func updateUserDomiansOrder(email_domains: Array<Address>, newOrder : Array<Int>, completion: CompletionBlock) {
        let domainSetting = UpdateDomainOrder<ApiResponse>(adds: newOrder)
        domainSetting.call() { task, response, hasError in
            if !hasError {
                if let userInfo = self.userInfo {
                    userInfo.userAddresses = email_domains
                    self.userInfo = userInfo
                }
            }
            completion(task: task, response: nil, error: nil)
        }
    }
    
    func updateUserSwipeAction(isLeft : Bool , action: MessageSwipeAction, completion: CompletionBlock) {
        let api = isLeft ? UpdateSwiftLeftAction<ApiResponse>(action: action) : UpdateSwiftRightAction<ApiResponse>(action: action)
        api.call() { task, response, hasError in
            if !hasError {
                if let userInfo = self.userInfo {
                    userInfo.swipeLeft = isLeft ? action.rawValue : userInfo.swipeLeft
                    userInfo.swipeRight = isLeft ? userInfo.swipeRight : action.rawValue
                    self.userInfo = userInfo
                }
            }
            completion(task: task, response: nil, error: nil)
        }
    }
    
    func updateNotificationEmail(newNotificationEmail: String, password : String, tfaCode: String?, completion: CompletionBlock) {
        let emailSetting = UpdateNotificationEmail<ApiResponse>(password: password, notificationEmail: newNotificationEmail, tfaCode: tfaCode)
        emailSetting.call() { task, response, hasError in
            if !hasError {
                if let userInfo = self.userInfo {
                    userInfo.notificationEmail = newNotificationEmail
                    self.userInfo = userInfo
                }
            }
            completion(task: task, response: nil, error: response?.error)
        }
    }
    func updateNotify(isOn: Bool, completion: CompletionBlock) {
        let notifySetting = UpdateNotify<ApiResponse>(notify: isOn ? 1 : 0)
        notifySetting.call() { task, response, hasError in
            if !hasError {
                if let userInfo = self.userInfo {
                    userInfo.notify = (isOn ? 1 : 0)
                    self.userInfo = userInfo
                }
            }
            completion(task: task, response: nil, error: nil)
        }
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
        twoFactorStatus = 0
        passwordMode = 2
        
        sharedOpenPGP.cleanAddresses()
    }
    
    private func clearAuthToken() {
        AuthCredential.clearFromKeychain()
    }
    
    private func completionForUserInfo(completion: UserInfoBlock?) -> CompletionBlock {
        return { task, response, error in
            if error == nil {
                self.fetchUserInfo(completion)
            } else {
                completion?(nil, nil, error)
            }
        }
    }
    
    private func launchCleanUp() {
        if !self.isRememberUser {
            username = nil
            password = nil
            twoFactorStatus = 0
            passwordMode = 2
        }
        
        if !isRememberMailboxPassword {
            mailboxPassword = nil
        }
    }
}

