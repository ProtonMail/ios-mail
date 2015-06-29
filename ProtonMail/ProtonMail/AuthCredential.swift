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

class AuthCredential: NSObject, NSCoding {
    struct Key{
        static let keychainStore = "keychainStoreKey"
    }
    
    let accessToken: String!
    let refreshToken: String!
    let userID: String!
    var expiration: NSDate!
    
    override var description: String {
        return "\n  accessToken: \(accessToken)\n  refreshToken: \(refreshToken)\n  expiration: \(expiration)\n  userID: \(userID)"
    }
    
    var isExpired: Bool {
        return expiration == nil || NSDate().compare(expiration) != .OrderedAscending
    }
    
    required init(accessToken: String!, refreshToken: String!, userID: String!, expiration: NSDate!) {
        
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.userID = userID
        self.expiration = expiration
        
        super.init()
    }
    
    convenience required init(coder aDecoder: NSCoder) {
        self.init(accessToken: aDecoder.decodeObjectForKey(CoderKey.accessToken) as? String,
            refreshToken: aDecoder.decodeObjectForKey(CoderKey.refreshToken) as? String,
            userID: aDecoder.decodeObjectForKey(CoderKey.userID) as? String,
            expiration: aDecoder.decodeObjectForKey(CoderKey.expiration) as? NSDate);
    }
    
    private func expire() {
        expiration = NSDate.distantPast() as! NSDate
        storeInKeychain()
    }
    
    func storeInKeychain() {
        UICKeyChainStore().setData(NSKeyedArchiver.archivedDataWithRootObject(self), forKey: Key.keychainStore)
    }
    
    // MARK - Class methods
    class func clearFromKeychain() {
        UICKeyChainStore.removeItemForKey(Key.keychainStore)
    }
    
    class func expireOrClear() {
        if let credential = AuthCredential.fetchFromKeychain() {
            if !credential.isExpired {
                credential.expire()
            } else {
                AuthCredential.clearFromKeychain()
            }
        }
    }
    
    class func fetchFromKeychain() -> AuthCredential? {
        if let data = UICKeyChainStore.dataForKey(Key.keychainStore) {
            if let authCredential = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? AuthCredential {
                return authCredential
            }
        }
        return nil
    }
    
    // MARK - NSCoding
    
    struct CoderKey {
        static let accessToken = "accessTokenCoderKey"
        static let refreshToken = "refreshTokenCoderKey"
        static let userID = "userIDCoderKey"
        static let expiration = "expirationCoderKey"
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(accessToken, forKey: CoderKey.accessToken)
        aCoder.encodeObject(refreshToken, forKey: CoderKey.refreshToken)
        aCoder.encodeObject(userID, forKey: CoderKey.userID)
        aCoder.encodeObject(expiration, forKey: CoderKey.expiration)
    }
}
