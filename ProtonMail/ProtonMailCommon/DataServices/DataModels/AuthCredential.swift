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
import PMKeymaker

final class AuthCredential: NSObject, NSCoding {
    internal init(sessionID: String, accessToken: String, refreshToken: String, expiration: Date, privateKey: String?, passwordKeySalt: String?) {
        self.sessionID = sessionID
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiration = expiration
        self.privateKey = privateKey
        self.passwordKeySalt = passwordKeySalt
    }
    
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
        static let userName      = "AuthCredential.UserName"
    }
    
    static var none: AuthCredential = AuthCredential.init(res: AuthResponse() )
    
    // user session id, this change in every login
    var sessionID: String
    // plain text accessToken
    private(set) var accessToken: String
    // refresh token use to renew access token
    var refreshToken: String
    // the expiration time
    private(set) var expiration: Date
    
    // the login private key, ususally it is first userkey
    private(set) var privateKey : String?
    private(set) var passwordKeySalt : String?
    private(set) var mailboxpassword: String = ""
    
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
    
    func expire() {
        expiration = Date.distantPast
    }

    func update(salt: String?, privateKey: String?) {
        self.privateKey = privateKey
        self.passwordKeySalt = salt
    }

    func udpate (password: String) {
        self.mailboxpassword = password
    }
    
    func udpate(sessionID: String,
                accessToken: String,
                refreshToken: String,
                expiration: Date)
    {
        self.sessionID = sessionID
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiration = expiration
    }
    
    required init(res : AuthResponse) {
        self.sessionID = res.sessionID ?? ""
        self.accessToken = res.accessToken ?? ""
        self.refreshToken = res.refreshToken ?? ""
        self.expiration =  Date(timeIntervalSinceNow: res.expiresIn ?? 0)
    }
    
    required init?(coder aDecoder: NSCoder) {
        guard
            let token = aDecoder.decodeObject(forKey: CoderKey.accessToken) as? String,
            let refreshToken = aDecoder.decodeObject(forKey: CoderKey.refreshToken) as? String,
            let sessionID = aDecoder.decodeObject(forKey: CoderKey.sessionID) as? String,
            let expirationDate = aDecoder.decodeObject(forKey: CoderKey.expiration) as? Date else
        {
                return nil
        }
        
        self.accessToken = token
        self.sessionID = sessionID
        self.refreshToken = refreshToken
        self.expiration = expirationDate

        self.privateKey = aDecoder.decodeObject(forKey: CoderKey.key) as? String
        self.passwordKeySalt = aDecoder.decodeObject(forKey: CoderKey.salt) as? String
        self.mailboxpassword = aDecoder.decodeObject(forKey: CoderKey.password) as? String ?? ""
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
    
    func archive() -> Data {
        return NSKeyedArchiver.archivedData(withRootObject: self)
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(sessionID, forKey:  CoderKey.sessionID)
        aCoder.encode(accessToken, forKey: CoderKey.accessToken)
        aCoder.encode(refreshToken, forKey: CoderKey.refreshToken)
        aCoder.encode(expiration, forKey: CoderKey.expiration)
        aCoder.encode(privateKey, forKey: CoderKey.key)
        aCoder.encode(mailboxpassword, forKey: CoderKey.password)
        aCoder.encode(passwordKeySalt, forKey: CoderKey.salt)
    }
}
