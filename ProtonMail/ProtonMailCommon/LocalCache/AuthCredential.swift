//
//  AuthCredential.swift
//  ProtonMail
//
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.


import Foundation
import Keymaker

//TODO:: refactor required later
final class AuthCredential: NSObject, NSCoding {
    
    struct Key {
        static let keychainStore = "keychainStoreKeyProtectedWithMainKey"
    }
    
    struct CoderKey {
        static let accessToken   = "accessTokenCoderKey"
        static let refreshToken  = "refreshTokenCoderKey"
        static let userID        = "userIDCoderKey"
        static let expiration    = "expirationCoderKey"
        static let key           = "privateKeyCoderKey"
        static let plainToken    = "plainCoderKey"
        static let pwd           = "pwdKey"
        static let salt          = "passwordKeySalt"
    }
    
    var userID: String!
    private var encryptToken: String!
    var refreshToken: String!
    private var expiration: Date!
    private var plainToken : String?
    var password : String?
    
    
    private var privateKey : String?
    private var passwordKeySalt : String?
    
    override var description: String {
        return """
        Token: \(plainToken ?? "NONE")
        RefreshToken: \(refreshToken ?? "NONE")
        Expiration: \(expiration ?? Date(timeIntervalSinceNow: 0))
        UserID: \(userID ?? "NONE")
        """
    }
    
    var isExpired: Bool {
        return expiration == nil || Date().compare(expiration) != .orderedAscending
    }
    
    class func setupToken (_ password:String, isRememberMailbox : Bool = true) throws {
        try self.fetchFromKeychain()?.setupToken(password)
    }
    
    func update(salt: String?, privateKey: String?) {
        self.privateKey = privateKey
        self.passwordKeySalt = salt
    }
    
    func setupToken (_ password:String) throws {
        if encryptToken.armored, let key = self.privateKey  {
            self.plainToken = try Crypto().decrypt(encrytped: encryptToken, privateKey: key, passphrase: password)
        } else {
            self.plainToken = encryptToken
        }
        
        self.password = password;
        self.storeInKeychain()
    }
    
    func trySetToken() {
        guard !encryptToken.armored else {
            return
        }
        self.plainToken = encryptToken
        self.storeInKeychain()
    }
    
    var token : String? {
        return self.plainToken
    }
    
    func update(_ res : AuthResponse!, updateUID: Bool) {
        self.encryptToken = res.accessToken
        if res.refreshToken != nil {
            self.refreshToken = res.refreshToken
        }
        
        if updateUID {
            self.userID = res.userID
        }
        self.expiration = Date(timeIntervalSinceNow: res.expiresIn ?? 0)
        
        ///TODO:: rmeove this later , when server switch off them
        self.privateKey = res.privateKey
        self.passwordKeySalt = res.keySalt
    }
    
    required init(res : AuthResponse!) {
        super.init()
        self.encryptToken = res.accessToken
        self.refreshToken = res.refreshToken
        self.userID = res.userID
        self.expiration = Date(timeIntervalSinceNow: res.expiresIn ?? 0)
        
        ///TODO:: rmeove this later , when server switch off them
        self.privateKey = res.privateKey
        self.passwordKeySalt = res.keySalt
    }
    
    required init(accessToken: String!, refreshToken: String!, userID: String!, expiration: Date!, key : String!, plain: String?, pwd:String?, salt:String?) {
        super.init()
        self.encryptToken = accessToken
        self.refreshToken = refreshToken
        self.userID = userID
        self.expiration = expiration
        self.plainToken = plain
        self.password = pwd
        self.privateKey = key
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
    
    class func unarchive(data: NSData?) -> AuthCredential? {
        guard let data = data as Data? else { return nil }
        
        // Looks like this is necessary for cases when AuthCredential was updated and saved by one target, and unarchived by another. For example, Share extension updates token from server, archives AuthCredential with its prefix, and after a while main target should unarchive it - and should know that prefix
        NSKeyedUnarchiver.setClass(AuthCredential.classForKeyedUnarchiver(), forClassName: "ProtonMail.AuthCredential")
        NSKeyedUnarchiver.setClass(AuthCredential.classForKeyedUnarchiver(), forClassName: "ProtonMailDev.AuthCredential")
        NSKeyedUnarchiver.setClass(AuthCredential.classForKeyedUnarchiver(), forClassName: "Share.AuthCredential")
        NSKeyedUnarchiver.setClass(AuthCredential.classForKeyedUnarchiver(), forClassName: "ShareDev.AuthCredential")
        NSKeyedUnarchiver.setClass(AuthCredential.classForKeyedUnarchiver(), forClassName: "PushService.AuthCredential")
        NSKeyedUnarchiver.setClass(AuthCredential.classForKeyedUnarchiver(), forClassName: "PushServiceDev.AuthCredential")
        
        return NSKeyedUnarchiver.unarchiveObject(with: data) as? AuthCredential
    }
    
    func archive() -> Data {
        return NSKeyedArchiver.archivedData(withRootObject: self)
    }
    
    fileprivate func expire() {
        expiration = Date.distantPast 
        storeInKeychain()
    }
    
    func storeInKeychain() {
        userCachedStatus.isForcedLogout = false
        let data = self.archive()
        guard let mainKey = keymaker.mainKey,
            let locked = try? Locked<Data>.init(clearValue: data, with: mainKey) else
        {
            return
        }
        KeychainWrapper.keychain.set(locked.encryptedValue, forKey: Key.keychainStore)
    }
    
    class func getPrivateKey() -> String! {
        return self.fetchFromKeychain()?.privateKey
    }
    
    class func getKeySalt() -> String? {
        return self.fetchFromKeychain()?.passwordKeySalt
    }
    
    // MARK - Class methods
    class func clearFromKeychain() {
        userCachedStatus.isForcedLogout = true
        KeychainWrapper.keychain.remove(forKey: Key.keychainStore) //newer version
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
        guard let mainKey = keymaker.mainKey,
            let encryptedData = KeychainWrapper.keychain.data(forKey: Key.keychainStore),
            case let locked = Locked<Data>(encryptedValue: encryptedData),
            let data = try? locked.unlock(with: mainKey),
            let authCredential = AuthCredential.unarchive(data: data as NSData) else
        {
            return nil
        }
        
        return authCredential
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

extension AuthCredential {
    convenience init(authInfo: APIService.AuthInfo) {
        let expiration = Date(timeIntervalSinceNow: (authInfo.expiresId ?? 0))
        self.init(accessToken: authInfo.accessToken,
                  refreshToken: authInfo.refreshToken,
                  userID: authInfo.userID,
                  expiration: expiration,
                  key : "",
                  plain: authInfo.accessToken,
                  pwd: "",
                  salt: "")
    }
}
