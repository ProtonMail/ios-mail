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
//import AwaitKit
//import PromiseKit
//import Pm
//


/// Stores information related to the user
class UserDataService {

    struct Key {
        static let isRememberMailboxPassword = "isRememberMailboxPasswordKey"
        static let isRememberUser            = "isRememberUserKey"
        static let mailboxPassword           = "mailboxPasswordKey"
        static let username                  = "usernameKey"
        static let password                  = "passwordKey"
        static let userInfo                  = "userInfoKey"
        static let twoFAStatus               = "twofaKey"
        static let userPasswordMode          = "userPasswordModeKey"
        
        static let roleSwitchCache           = "roleSwitchCache"
        static let defaultSignatureStatus    = "defaultSignatureStatus"
    }
    
    // MARK: - Private variables
    //TODO::Fix later fileprivate(set)
    fileprivate(set) var userInfo: UserInfo? = SharedCacheBase.getDefault().customObjectForKey(Key.userInfo) as? UserInfo {
        didSet {
            SharedCacheBase.getDefault().setCustomValue(userInfo, forKey: Key.userInfo)
            SharedCacheBase.getDefault().synchronize()
        }
    }
    //TODO::Fix later fileprivate(set)
    fileprivate(set) var username: String? = SharedCacheBase.getDefault().string(forKey: Key.username) {
        didSet {
            SharedCacheBase.getDefault().setValue(username, forKey: Key.username)
            SharedCacheBase.getDefault().synchronize()
        }
    }
    
    // Value is only stored in the keychain
    var password: String? {
        get {
            do {
                let savedPwd = sharedKeychain.keychain().string(forKey: Key.password)
                return try savedPwd?.decrypt(withPwd: "$Proton$" + Key.password)
            }catch {
                return nil
            }
        }
        set {
            do {
                let nv = try newValue?.encrypt(withPwd: "$Proton$" + Key.password)
                sharedKeychain.keychain().setString(nv, forKey: Key.password)
            }catch {
            }
        }
    }

//
//    var passwordMode: Int = SharedCacheBase.getDefault().integer(forKey: Key.userPasswordMode)  {
//        didSet {
//            SharedCacheBase.getDefault().setValue(passwordMode, forKey: Key.userPasswordMode)
//            SharedCacheBase.getDefault().synchronize()
//        }
//    }
//
//    var showDefaultSignature : Bool {
//        get {
//            return defaultSignatureStauts
//        }
//        set {
//            defaultSignatureStauts = newValue
//        }
//    }
//
//    var showMobileSignature : Bool {
//        get {
//            #if Enterprise
//                let isEnterprise = true
//            #else
//                let isEnterprise = false
//            #endif
//
//            if userInfo?.role > 0 || isEnterprise {
//                return switchCacheOff == false //TODO:: need test this part
//            } else {
//                switchCacheOff = false
//                return true;
//            } }
//        set {
//            switchCacheOff = (newValue == false)
//        }
//    }
//
//    var mobileSignature : String {
//        get {
//            #if Enterprise
//                let isEnterprise = true
//            #else
//                let isEnterprise = false
//            #endif
//
//            if userInfo?.role > 0 || isEnterprise {
//                return userCachedStatus.mobileSignature
//            } else {
//                userCachedStatus.resetMobileSignature()
//                return userCachedStatus.mobileSignature
//            }
//        }
//        set {
//            userCachedStatus.mobileSignature = newValue
//        }
//    }
//
//    var usedSpace: Int64 {
//        return userInfo?.usedSpace ?? 0
//    }
//
//    var showShowImageView: Bool {
//        return userInfo?.showImages == 0
//    }
//
//    var firstUserPublicKey: String? {
//        if let keys = userInfo?.userKeys, keys.count > 0 {
//            for k in keys {
//                return k.publicKey
//            }
//        }
//        return nil
//    }
//
    func getAddressPrivKey(address_id : String) -> String {
        let addr = userAddresses.indexOfAddress(address_id) ?? userAddresses.defaultSendAddress()
        return addr?.keys.first?.private_key ?? ""
    }
//
//    var addressPrivKeys : Data {
//        var out = Data()
//        var error : NSError?
//        for addr in userAddresses {
//            for key in addr.keys {
//                if let privK = PmUnArmor(key.private_key, &error) {
//                    out.append(privK)
//                }
//            }
//        }
//        return out
//    }
//
//    var userPrivKeys : Data {
//        var out = Data()
//        var error : NSError?
//        for addr in userAddresses {
//            for key in addr.keys {
//                if let privK = PmUnArmor(key.private_key, &error) {
//                    out.append(privK)
//                }
//            }
//        }
//        return out
//    }
//
//    // MARK: - Public variables
//
//    var defaultEmail : String {
//        if let addr = userAddresses.defaultAddress() {
//            return addr.email;
//        }
//        return "";
//    }
//
//    var defaultDisplayName : String {
//        if let addr = userAddresses.defaultAddress() {
//            return addr.display_name;
//        }
//        return displayName;
//    }


    var userAddresses: [Address] { //never be null
        return userInfo?.userAddresses ?? [Address]()
    }

//    var displayName: String {
//        return (userInfo?.displayName ?? "").decodeHtml()
//    }
//
//    var isMailboxPasswordStored: Bool {
//
//        isMailboxPWDOk = mailboxPassword != nil;
//
//        return mailboxPassword != nil
//    }
//
//    var isRememberMailboxPassword: Bool = SharedCacheBase.getDefault().bool(forKey: Key.isRememberMailboxPassword) {
//        didSet {
//            SharedCacheBase.getDefault().set(isRememberMailboxPassword, forKey: Key.isRememberMailboxPassword)
//            SharedCacheBase.getDefault().synchronize()
//        }
//    }

    var isRememberUser: Bool = SharedCacheBase.getDefault().bool(forKey: Key.isRememberUser) {
        didSet {
            SharedCacheBase.getDefault().set(isRememberUser, forKey: Key.isRememberUser)
            SharedCacheBase.getDefault().synchronize()
        }
    }

//    var isSignedIn: Bool = false
//    var isNewUser : Bool = false
//    var isMailboxPWDOk: Bool = false
//
    var isUserCredentialStored: Bool {
        return username != nil && password != nil && isRememberUser
    }

    /// Value is only stored in the keychain
    var mailboxPassword: String? {
        get {
            do {
                let savedPwd = sharedKeychain.keychain().string(forKey: Key.mailboxPassword)
                return try savedPwd?.decrypt(withPwd: "$Proton$" + Key.mailboxPassword)
            }catch {
                return nil
            }
        }
        set {
            do {
                let nv = try newValue?.encrypt(withPwd: "$Proton$" + Key.mailboxPassword)
                sharedKeychain.keychain().setString(nv, forKey: Key.mailboxPassword)
            }catch {
            }
        }
    }
//
//    var maxSpace: Int64 {
//        return userInfo?.maxSpace ?? 0
//    }
//
//    var notificationEmail: String {
//        return userInfo?.notificationEmail ?? ""
//    }
//
//    var notify: Bool {
//        return (userInfo?.notify ?? 0 ) == 1;
//    }
//
//    var signature: String {
//        return (userInfo?.signature ?? "").ln2br()
//    }
//
//    var isSet : Bool {
//        return userInfo != nil
//    }
//
    // MARK: - methods
    init() {

    }
//
//    func fetchUserInfo() -> Promise<UserInfo?> {
//        return async {
//
//            let addrApi = GetAddressesRequest()
//            let userApi = GetUserInfoRequest()
//
//            let addrRes = try await(addrApi.run())
//            let userRes = try await(userApi.run())
//
//            userRes.userInfo?.setAddresses(addresses: addrRes.addresses)
//            self.userInfo = userRes.userInfo
////            if let addresses = self.userInfo?.userAddresses.toPMNAddresses() {
////                sharedOpenPGP.setAddresses(addresses);
////            }
//            return self.userInfo
//        }
//    }
//
//    func updateUserInfoFromEventLog (_ userInfo : UserInfo){
//        self.userInfo = userInfo
//    }
//
//    func isMailboxPasswordValid(_ password: String, privateKey : String) -> Bool {
//        return privateKey.check(passphrase: password)
//    }
//
//    func setMailboxPassword(_ password: String, keysalt: String?, isRemembered: Bool) {
//        mailboxPassword = password
//        isRememberMailboxPassword = isRemembered
//        self.isMailboxPWDOk = true;
//    }
//
//    func isPasswordValid(_ password: String?) -> Bool {
//        return self.password == password
//    }
//
//
//    func signOutAfterSignUp() {
//        sharedVMService.signOut()
//        if let authCredential = AuthCredential.fetchFromKeychain(), let token = authCredential.token, !token.isEmpty {
//            AuthDeleteRequest().call { (task, response, hasError) in
//
//            }
//        }
//        NotificationCenter.default.post(name: Notification.Name(rawValue: NotificationDefined.didSignOut), object: self)
//        clearAll()
//        clearAuthToken()
//    }
//
//    func updateDisplayName(_ displayName: String, completion: UserInfoBlock?) {
//        let new_displayName = displayName.trim()
//        let api = UpdateDisplayNameRequest(displayName: new_displayName)
//        api.call() { task, response, hasError in
//            if !hasError {
//                if let userInfo = self.userInfo {
//                    userInfo.displayName = new_displayName
//                    self.userInfo = userInfo
//                }
//            }
//            completion?(self.userInfo, nil, nil)
//        }
//    }
//
//    func updateAddress(_ addressId: String, displayName: String, signature: String, completion: UserInfoBlock?) {
//        let new_displayName = displayName.trim()
//        let new_signature = signature.trim()
//
//        let api = UpdateAddressRequest(id: addressId, displayName: new_displayName, signature: new_signature)
//        api.call() { task, response, hasError in
//            if !hasError {
//                if let userInfo = self.userInfo {
//                    let addresses = userInfo.userAddresses
//                    for addr in addresses {
//                        if addr.address_id == addressId {
//                            addr.display_name = new_displayName
//                            addr.signature = new_signature
//                            break
//                        }
//                    }
//                    userInfo.userAddresses = addresses
//                    self.userInfo = userInfo
//                }
//            }
//            completion?(self.userInfo, nil, nil)
//        }
//    }
//
//    func updateAutoLoadImage(_ status : Int, completion: UserInfoBlock?) {
//        let api = UpdateShowImagesRequest(status: status)
//        api.call() { task, response, hasError in
//            if !hasError {
//                if let userInfo = self.userInfo {
//                    userInfo.showImages = status
//                    self.userInfo = userInfo
//                }
//            }
//            completion?(self.userInfo, nil, nil)
//        }
//    }
//
//    func clearAuthToken() {
//        AuthCredential.clearFromKeychain()
//    }
//
//    func completionForUserInfo(_ completion: UserInfoBlock?) -> CompletionBlock {
//        return { task, response, error in
//            if error == nil {
//                self.fetchUserInfo().done { (userInfo) in
//
////                    self.fetchUserInfo(completion)
//                }.catch { error in
//
////                    self.fetchUserInfo(completion)
//                }
//
//            } else {
//                completion?(nil, nil, error)
//            }
//        }
//    }

}

