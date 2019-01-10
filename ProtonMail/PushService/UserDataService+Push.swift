//
//  UserDataService.swift
//  PushService
//
//
//  The MIT License
//
//  Copyright (c) 2018 Proton Technologies AG
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.


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

