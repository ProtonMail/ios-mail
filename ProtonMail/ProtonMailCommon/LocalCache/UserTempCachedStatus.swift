//
//  UserTempCachedStatus.swift
//  ProtonMail - Created on 4/15/16.
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

let userDebugCached =  SharedCacheBase.getDefault()
class UserTempCachedStatus: NSObject, NSCoding {
    struct Key{
        static let keychainStore = "UserTempCachedStatusKey"
    }
    
    struct CoderKey {
        static let lastLoggedInUser = "lastLoggedInUser"
        static let touchIDEmail = "touchIDEmail"
        static let isPinCodeEnabled = "isPinCodeEnabled"
        static let pinCodeCache = "pinCodeCache"
        static let autoLockTime = "autoLockTime"
        static let showMobileSignature = "showMobileSignature"
        static let localMobileSignature = "localMobileSignature"
    }
    
    var lastLoggedInUser : String!

    var touchIDEmail : String!
    var pinCodeCache : String!
    var autoLockTime : String!
    var localMobileSignature : String!
    var showMobileSignature : Bool = false
    var isPinCodeEnabled : Bool = false
    
    required init(lastLoggedInUser: String!,
                         touchIDEmail: String!,
                         isPinCodeEnabled: Bool,
                         pinCodeCache: String!,
                         autoLockTime : String!,
                         showMobileSignature: Bool,
                         localMobileSignature:String!) {
        super.init()
        self.lastLoggedInUser = lastLoggedInUser ?? ""
        self.touchIDEmail = touchIDEmail ?? ""
        self.isPinCodeEnabled = isPinCodeEnabled
        self.pinCodeCache = pinCodeCache ?? ""
        self.autoLockTime = autoLockTime ?? "-1"
        self.showMobileSignature = showMobileSignature
        self.localMobileSignature = localMobileSignature ?? ""
    }
    
    convenience required init(coder aDecoder: NSCoder) {
        self.init(
            lastLoggedInUser: aDecoder.decodeObject(forKey: CoderKey.lastLoggedInUser) as? String,
            touchIDEmail: aDecoder.decodeObject(forKey: CoderKey.touchIDEmail) as? String,
            isPinCodeEnabled: aDecoder.decodeObject(forKey: CoderKey.isPinCodeEnabled) as? Bool ?? false,
            pinCodeCache: aDecoder.decodeObject(forKey: CoderKey.pinCodeCache) as? String,
            autoLockTime: aDecoder.decodeObject(forKey: CoderKey.autoLockTime) as? String,
            showMobileSignature: aDecoder.decodeObject(forKey: CoderKey.showMobileSignature) as? Bool ?? false,
            localMobileSignature: aDecoder.decodeObject(forKey: CoderKey.localMobileSignature) as? String);
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(lastLoggedInUser, forKey: CoderKey.lastLoggedInUser)
        aCoder.encode(touchIDEmail, forKey: CoderKey.touchIDEmail)
        aCoder.encode(isPinCodeEnabled, forKey: CoderKey.isPinCodeEnabled)
        aCoder.encode(pinCodeCache, forKey: CoderKey.pinCodeCache)
        aCoder.encode(autoLockTime, forKey: CoderKey.autoLockTime)
        aCoder.encode(showMobileSignature, forKey: CoderKey.showMobileSignature)
        aCoder.encode(localMobileSignature, forKey: CoderKey.localMobileSignature)
    }
    
    
    class func backup () {
        if UserTempCachedStatus.fetchFromKeychain() == nil {
            let u = UserTempCachedStatus(
                lastLoggedInUser: sharedUserDataService.username,
                touchIDEmail: "FIXME",
                isPinCodeEnabled: userCachedStatus.isPinCodeEnabled,
                pinCodeCache: "FIXME",
                autoLockTime: "\(userCachedStatus.lockTime.rawValue)",
                showMobileSignature: sharedUserDataService.showMobileSignature,
                localMobileSignature: userCachedStatus.mobileSignature)
            u.storeInKeychain()
        }
    }
    
    class func restore() {
        if let cache = UserTempCachedStatus.fetchFromKeychain() {
            if sharedUserDataService.username == cache.lastLoggedInUser {
                userCachedStatus.lockTime = AutolockTimeout(rawValue: Int(cache.autoLockTime) ?? -1)
                sharedUserDataService.showMobileSignature = cache.showMobileSignature
                userCachedStatus.mobileSignature = cache.localMobileSignature ?? ""
            }
        }
        UserTempCachedStatus.clearFromKeychain()
    }
    
    
    func storeInKeychain() {
        userCachedStatus.isForcedLogout = false
        KeychainWrapper.keychain.set(NSKeyedArchiver.archivedData(withRootObject: self), forKey: Key.keychainStore)
    }
    
    // MARK - Class methods
    class func clearFromKeychain() {
        KeychainWrapper.keychain.remove(forKey: Key.keychainStore) //newer version
    }
    
    class func fetchFromKeychain() -> UserTempCachedStatus? {
        NSKeyedUnarchiver.setClass(UserTempCachedStatus.classForKeyedUnarchiver(), forClassName: "ProtonMail.UserTempCachedStatus")
        NSKeyedUnarchiver.setClass(UserTempCachedStatus.classForKeyedUnarchiver(), forClassName: "ProtonMailDev.UserTempCachedStatus")
        NSKeyedUnarchiver.setClass(UserTempCachedStatus.classForKeyedUnarchiver(), forClassName: "Share.UserTempCachedStatus")
        NSKeyedUnarchiver.setClass(UserTempCachedStatus.classForKeyedUnarchiver(), forClassName: "ShareDev.UserTempCachedStatus")
        NSKeyedUnarchiver.setClass(UserTempCachedStatus.classForKeyedUnarchiver(), forClassName: "PushService.UserTempCachedStatus")
        NSKeyedUnarchiver.setClass(UserTempCachedStatus.classForKeyedUnarchiver(), forClassName: "PushServiceDev.UserTempCachedStatus")
        
        if let data = KeychainWrapper.keychain.data(forKey: Key.keychainStore) {
            if let authCredential = NSKeyedUnarchiver.unarchiveObject(with: data) as? UserTempCachedStatus {
                return authCredential
            }
        }
        return nil
    }
}
