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






// LETS GET RID OF THIS!






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
                let savedPwd = sharedKeychain.keychain.string(forKey: Key.password)
                return try savedPwd?.decrypt(withPwd: "$Proton$" + Key.password)
            }catch {
                return nil
            }
        }
        set {
            do {
                let nv = try newValue?.encrypt(withPwd: "$Proton$" + Key.password)
                sharedKeychain.keychain.setString(nv, forKey: Key.password)
            }catch {
            }
        }
    }
    
    func getAddressPrivKey(address_id : String) -> String {
        let addr = userAddresses.indexOfAddress(address_id) ?? userAddresses.defaultSendAddress()
        return addr?.keys.first?.private_key ?? ""
    }
    
    var userAddresses: [Address] { //never be null
        return userInfo?.userAddresses ?? [Address]()
    }

    var isRememberUser: Bool = SharedCacheBase.getDefault().bool(forKey: Key.isRememberUser) {
        didSet {
            SharedCacheBase.getDefault().set(isRememberUser, forKey: Key.isRememberUser)
            SharedCacheBase.getDefault().synchronize()
        }
    }

    var isUserCredentialStored: Bool {
        return username != nil && password != nil && isRememberUser
    }

    /// Value is only stored in the keychain
    var mailboxPassword: String? {
        get {
            do {
                let savedPwd = sharedKeychain.keychain.string(forKey: Key.mailboxPassword)
                return try savedPwd?.decrypt(withPwd: "$Proton$" + Key.mailboxPassword)
            }catch {
                return nil
            }
        }
        set {
            do {
                let nv = try newValue?.encrypt(withPwd: "$Proton$" + Key.mailboxPassword)
                sharedKeychain.keychain.setString(nv, forKey: Key.mailboxPassword)
            }catch {
            }
        }
    }
    
    // MARK: - methods
    init() {

    }
}

