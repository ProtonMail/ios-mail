//
//  AuthCredential.swift
//  ProtonMail
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
import Keymaker

//TODO:: refactor required later
final class AuthCredential: NSObject, NSCoding {
    struct Key {
        static let keychainStore = "keychainStoreKeyProtectedWithMainKey"
    }
    
    struct CoderKey {
        static let accessToken   = "accessTokenCoderKey"
        static let refreshToken  = "refreshTokenCoderKey"
        static let sessionID     = "userIDCoderKey"
        static let expiration    = "expirationCoderKey"
        static let key           = "privateKeyCoderKey"
        static let plainToken    = "plainCoderKey"
        static let pwd           = "pwdKey"
        static let salt          = "passwordKeySalt"
        
        static let userID        = "AuthCredential.UserID"
        static let password      = "AuthCredential.Password"
    }
    
    // user session id, this change in every login
    var sessionID: String
    // plain text accessToken
    private var accessToken: String
    // refresh token use to renew access token
    var refreshToken: String
    // the expiration time
    private var expiration: Date
    
    // userID this will not change
    private var userID: String = ""
    
    // the login private key, ususally it is first userkey
    public var privateKey : String?
    private var passwordKeySalt : String?
    
    public var password: String = ""
    
    override var description: String {
        return """
        AccessToken: \(accessToken)
        RefreshToken: \(refreshToken)
        Expiration: \(expiration))
        SessionID: \(sessionID)
        """
    }
    
    var isExpired: Bool {
        return Date().compare(expiration) != .orderedAscending
    }
    
    class func setupToken (_ password:String) throws {
        //        try self.fetchFromKeychain()?.setupToken(password)
    }
    
    func update(salt: String?, privateKey: String?) {
        self.privateKey = privateKey
        self.passwordKeySalt = salt
    }
    
    func udpate (password: String) {
        self.password = password
    }
    
    var token : String {
        return self.accessToken
    }
    
    func update(_ res : AuthResponse, updateUID: Bool) {
        assert(false)
        //        self.encryptToken = res.accessToken
        //        if res.refreshToken != nil {
        //            self.refreshToken = res.refreshToken
        //        }
        //
        //        if updateUID {
        //            self.userID = res.userID ?? ""
        //        }
        //        self.expiration = Date(timeIntervalSinceNow: res.expiresIn ?? 0)
        //
        //        ///TODO:: rmeove this later , when server switch off them
        //        self.privateKey = res.privateKey
        //        self.passwordKeySalt = res.keySalt
    }
    
    required init(res : AuthResponse) {
        self.sessionID = res.sessionID ?? ""
        self.accessToken = res.accessToken ?? ""
        self.refreshToken = res.refreshToken ?? ""
        self.expiration =  Date(timeIntervalSinceNow: res.expiresIn ?? 0)
        //        super.init()
        //        self.encryptToken = res.accessToken
        //        self.refreshToken = res.refreshToken
        //        self.expiration = Date(timeIntervalSinceNow: res.expiresIn ?? 0)
        //
        //        ///TODO:: rmeove this later , when server switch off them
        self.privateKey = res.privateKey
        self.passwordKeySalt = res.keySalt
    }
    
    required init(accessToken: String, refreshToken: String, sessionID: String, expiration: Date, key : String, /*plain: String?, pwd:String?,*/ salt:String?) {
        self.accessToken = accessToken
        self.sessionID = sessionID
        self.refreshToken = refreshToken
        self.expiration = expiration
        
        //        self.encryptToken = accessToken
        //        self.refreshToken = refreshToken
        //        self.userID = userID
        //        self.expiration = expiration
        //        self.plainToken = plain
        //        self.password = pwd
        self.privateKey = key
        self.passwordKeySalt = salt
    }
    
    convenience required init?(coder aDecoder: NSCoder) {
        guard
            let token = aDecoder.decodeObject(forKey: CoderKey.accessToken) as? String,
            let refreshToken = aDecoder.decodeObject(forKey: CoderKey.refreshToken) as? String,
            let sessionID = aDecoder.decodeObject(forKey: CoderKey.sessionID) as? String,
            let expirationDate = aDecoder.decodeObject(forKey: CoderKey.expiration) as? Date else {
                return nil
        }
        
        self.init(accessToken: token,
                  refreshToken: refreshToken,
                  sessionID: sessionID,
                  expiration: expirationDate,
                  key: aDecoder.decodeObject(forKey: CoderKey.key) as? String ?? "",
                  salt: aDecoder.decodeObject(forKey: CoderKey.salt) as? String)
        self.userID = aDecoder.decodeObject(forKey: CoderKey.userID) as? String ?? ""
        self.password = aDecoder.decodeObject(forKey: CoderKey.password) as? String ?? ""
    }
    
    fileprivate func expire() {
        expiration = Date.distantPast 
    }
    
    //    func storeInKeychain() {
    //        userCachedStatus.isForcedLogout = false
    //        let data = self.archive()
    //        guard let mainKey = keymaker.mainKey,
    //            let locked = try? Locked<Data>.init(clearValue: data, with: mainKey) else
    //        {
    //            return
    //        }
    ////        KeychainWrapper.keychain.set(locked.encryptedValue, forKey: Key.keychainStore)
    //    }
    
//    func getPrivateKey() -> String! {
//        return ""
        // return self.fetchFromKeychain()?.privateKey
//    }
    
    func getKeySalt() -> String? {
        return self.passwordKeySalt
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
    
    // MARK - Class methods
    class func clearFromKeychain() {
        userCachedStatus.isForcedLogout = true
        KeychainWrapper.keychain.remove(forKey: Key.keychainStore) //newer version
    }
    
    func archive() -> Data {
        return NSKeyedArchiver.archivedData(withRootObject: self)
    }
    
    class func expireOrClear(_ token : String?) {
        //        if let credential = AuthCredential.fetchFromKeychain() {
        //            if !credential.isExpired {
        //                if let t = token, t == credential.token {
        //                    credential.expire()
        //                }
        //            } else {
        //               // AuthCredential.clearFromKeychain()
        //            }
        //        }
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
        aCoder.encode(sessionID, forKey:  CoderKey.sessionID)
        aCoder.encode(accessToken, forKey: CoderKey.accessToken)
        aCoder.encode(refreshToken, forKey: CoderKey.refreshToken)
        aCoder.encode(expiration, forKey: CoderKey.expiration)
        aCoder.encode(userID, forKey: CoderKey.userID)
        aCoder.encode(privateKey, forKey: CoderKey.key)
        aCoder.encode(password, forKey: CoderKey.password)
        aCoder.encode(passwordKeySalt, forKey: CoderKey.salt)
    }
}
