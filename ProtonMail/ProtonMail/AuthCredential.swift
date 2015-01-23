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
    enum Key: String {
        case keychainStore = "keychainStoreKey"
    }
    
    let accessToken: String!
    let refreshToken: String!
    let userID: String!
    let expiration: NSDate!
    
    override var description: String {
        return "\n  accessToken: \(accessToken)\n  refreshToken: \(refreshToken)\n  expiration: \(expiration)\n  userID: \(userID)"
    }

    private let accessTokenCoderKey = "accessTokenCoderKey"
    private let refreshTokenCoderKey = "refreshTokenCoderKey"
    private let userIDCoderKey = "userIDCoderKey"
    private let expirationCoderKey = "expirationCoderKey"

    required init?(credential: AnyObject!) {
        super.init()
        
        if let credential = credential as? NSDictionary {
            accessToken = credential["access_token"] as? String
            refreshToken = credential["refresh_token"] as? String
            userID = credential["uid"] as? String
            
            if let expiresIn = credential["expires_in"] as? NSTimeInterval {
                expiration = NSDate(timeIntervalSinceNow: expiresIn)
            }
        }
        
        if accessToken == nil || refreshToken == nil || userID == nil || expiration == nil {
            return nil
        }
    }
    
    func storeInKeychain() {
        UICKeyChainStore().setData(NSKeyedArchiver.archivedDataWithRootObject(self), forKey: Key.keychainStore.rawValue)
    }
    
    // MARK - Class methods
    
    class func fetchFromKeychain() -> AuthCredential? {
        if let data = UICKeyChainStore.dataForKey(Key.keychainStore.rawValue) {
            if let authCredential = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? AuthCredential {
                return authCredential
            }
        }
        
        return nil
    }
    
    // MARK - NSCoding
    
    required init(coder aDecoder: NSCoder) {
        super.init()
        
        accessToken = aDecoder.decodeObjectForKey(accessTokenCoderKey) as? String
        refreshToken = aDecoder.decodeObjectForKey(refreshToken) as? String
        userID = aDecoder.decodeObjectForKey(userIDCoderKey) as? String
        expiration = aDecoder.decodeObjectForKey(expirationCoderKey) as? NSDate
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(accessToken, forKey: accessTokenCoderKey)
        aCoder.encodeObject(refreshToken, forKey: refreshTokenCoderKey)
        aCoder.encodeObject(userID, forKey: userIDCoderKey)
        aCoder.encodeObject(expiration, forKey: expirationCoderKey)
    }
}
