//
//  AuthCredential.swift
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

let authDebugCached =  UserDefaults.standard
class AuthCredential: NSObject, NSCoding {
    struct Key{
        static let keychainStore = "keychainStoreKey"
    }
    
    var encryptToken: String!
    var refreshToken: String!
    var userID: String!
    var expiration: Date!
    var privateKey : String?
    var plainToken : String?
    var password : String?
    var passwordKeySalt : String?
    
    override var description: String {
        return "\n  token: \(String(describing: plainToken))\n  refreshToken: \(refreshToken)\n  expiration: \(expiration)\n  userID: \(userID)"
    }
    
    var isExpired: Bool {
        return expiration == nil || Date().compare(expiration) != .orderedAscending
    }
    
    class func setupToken (_ password:String, isRememberMailbox : Bool = true) throws {
        #if DEBUG
            if let data = authDebugCached.data(forKey: Key.keychainStore) {
                if let authCredential = NSKeyedUnarchiver.unarchiveObject(with: data) as? AuthCredential {
                    try authCredential.setupToken(password)
                }
            }
        #else
            if let data = UICKeyChainStore.data(forKey: Key.keychainStore) {
                if let authCredential = NSKeyedUnarchiver.unarchiveObject(with: data) as? AuthCredential {
                    try authCredential.setupToken(password)
                }
            }
        #endif
    }
    
    func setupToken (_ password:String) throws {
        if let key = self.privateKey {
            self.plainToken = try self.encryptToken.decryptMessageWithSinglKey(key, passphrase: password)
        } else {
            self.plainToken = encryptToken
        }
        self.password = password;
        self.storeInKeychain()
    }
    
    var token : String? {
        return self.plainToken
    }
    
    func update(_ res : AuthResponse!) {
        self.encryptToken = res.accessToken
        if res.refreshToken != nil {
            self.refreshToken = res.refreshToken
        }
        self.userID = res.userID
        self.expiration = Date(timeIntervalSinceNow: res.expiresIn ?? 0)
        self.privateKey = res.encPrivateKey
        self.passwordKeySalt = res.keySalt
    }
    
    required init(res : AuthResponse!) {
        super.init()
        self.encryptToken = res.accessToken
        self.refreshToken = res.refreshToken
        self.userID = res.userID
        self.expiration = Date(timeIntervalSinceNow: res.expiresIn ?? 0)
        self.privateKey = res.privateKey
        self.passwordKeySalt = res.keySalt
    }
    
    required init(accessToken: String!, refreshToken: String!, userID: String!, expiration: Date!, key : String!, plain: String?, pwd:String?, salt:String?) {
        super.init()
        self.encryptToken = accessToken
        self.refreshToken = refreshToken
        self.userID = userID
        self.expiration = expiration
        self.privateKey = key
        self.plainToken = plain
        self.password = pwd
        self.passwordKeySalt = salt
    }
    
    convenience required init(coder aDecoder: NSCoder) {
        self.init(accessToken: aDecoder.decodeObject(forKey: CoderKey.accessToken) as? String,
            refreshToken: aDecoder.decodeObject(forKey: CoderKey.refreshToken) as? String,
            userID: aDecoder.decodeObject(forKey: CoderKey.userID) as? String,
            expiration: aDecoder.decodeObject(forKey: CoderKey.expiration) as? Date,
            key: aDecoder.decodeObject(forKey: CoderKey.key) as? String,
            plain: aDecoder.decodeObject(forKey: CoderKey.plainToken) as? String,
            pwd: aDecoder.decodeObject(forKey: CoderKey.pwd) as? String,
            salt : aDecoder.decodeObject(forKey: CoderKey.salt) as? String);
    }
    
    fileprivate func expire() {
        expiration = Date.distantPast 
        storeInKeychain()
    }
    
    func storeInKeychain() {
        userCachedStatus.isForcedLogout = false
        #if DEBUG
            authDebugCached.set(NSKeyedArchiver.archivedData(withRootObject: self), forKey: Key.keychainStore)
        #else
            UICKeyChainStore().setData(NSKeyedArchiver.archivedData(withRootObject: self), forKey: Key.keychainStore)
        #endif
    }
    
    class func getPrivateKey() -> String {
        
        #if DEBUG
            if let data = authDebugCached.data(forKey: Key.keychainStore) {
                if let authCredential = NSKeyedUnarchiver.unarchiveObject(with: data) as? AuthCredential {
                    return authCredential.privateKey ?? ""
                }
            }
        #else
            if let data = UICKeyChainStore.data(forKey: Key.keychainStore) {
                if let authCredential = NSKeyedUnarchiver.unarchiveObject(with: data) as? AuthCredential {
                    return authCredential.privateKey ?? ""
                }
            }
        #endif
        return ""
    }
    
    class func getKeySalt() -> String? {
        #if DEBUG
            if let data = authDebugCached.data(forKey: Key.keychainStore) {
                if let authCredential = NSKeyedUnarchiver.unarchiveObject(with: data) as? AuthCredential {
                    return authCredential.passwordKeySalt
                }
            }
        #else
            if let data = UICKeyChainStore.data(forKey: Key.keychainStore) {
                if let authCredential = NSKeyedUnarchiver.unarchiveObject(with: data) as? AuthCredential {
                    return authCredential.passwordKeySalt
                }
            }
        #endif
        return ""
    }
    
    // MARK - Class methods
    class func clearFromKeychain() {
        userCachedStatus.isForcedLogout = true
        authDebugCached.removeObject(forKey: Key.keychainStore)
        UICKeyChainStore.removeItem(forKey: Key.keychainStore)
    }
    
    class func expireOrClear(_ token : String?) {
        if let credential = AuthCredential.fetchFromKeychain() {
            if !credential.isExpired {
                if let t = token, t == credential.plainToken {
                    credential.expire()
                }
            } else {
               // AuthCredential.clearFromKeychain()
            }
        }
    }
    
    class func fetchFromKeychain() -> AuthCredential? {
        
        #if DEBUG
            if let data = authDebugCached.data(forKey: Key.keychainStore) {
                if let authCredential = NSKeyedUnarchiver.unarchiveObject(with: data) as? AuthCredential {
                    return authCredential
                }
            }
        #else
            if let data = UICKeyChainStore.data(forKey: Key.keychainStore) {
                if let authCredential = NSKeyedUnarchiver.unarchiveObject(with: data) as? AuthCredential {
                    return authCredential
                }
            }
        #endif

        return nil
    }
    
    // MARK - NSCoding
    
    struct CoderKey {
        static let accessToken = "accessTokenCoderKey"
        static let refreshToken = "refreshTokenCoderKey"
        static let userID = "userIDCoderKey"
        static let expiration = "expirationCoderKey"
        static let key = "privateKeyCoderKey"
        static let plainToken = "plainCoderKey"
        static let pwd = "pwdKey"
        static let salt = "passwordKeySalt"
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(encryptToken, forKey: CoderKey.accessToken)
        aCoder.encode(refreshToken, forKey: CoderKey.refreshToken)
        aCoder.encode(userID, forKey: CoderKey.userID)
        aCoder.encode(expiration, forKey: CoderKey.expiration)
        aCoder.encode(privateKey, forKey: CoderKey.key)
        aCoder.encode(plainToken, forKey: CoderKey.plainToken)
        aCoder.encode(password, forKey: CoderKey.pwd)
        aCoder.encode(passwordKeySalt, forKey: CoderKey.salt)
    }
}
