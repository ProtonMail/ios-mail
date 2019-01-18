//
//  MessageStatus.swift
//  ProtonMail - Created on 5/4/15.
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
import UICKeyChainStore
import Keymaker

let userCachedStatus = UserCachedStatus()

//the data in there store longer.

final class UserCachedStatus : SharedCacheBase {
    struct Key {
        // inuse
//        static let lastCacheVersion = "last_cache_version" //user cache
        static let isCheckSpaceDisabled = "isCheckSpaceDisabledKey" //user cache
        static let lastAuthCacheVersion = "last_auth_cache_version" //user cache
        static let cachedServerNotices = "cachedServerNotices" //user cache
        static let showServerNoticesNextTime = "showServerNoticesNextTime" //user cache
        static let isPM_MEWarningDisabled = "isPM_MEWarningDisabledKey" //user cache -- maybe could be global
        
        // touch id 
        
        static let autoLogoutTime = "autoLogoutTime" //global cache
        
        static let askEnableTouchID = "askEnableTouchID" //global cache
        
        // pin code
        
        
        static let autoLockTime = "autoLockTime" ///user cache but could restore
        
        static let lastLoggedInUser = "lastLoggedInUser" //user cache but could restore
        static let lastPinFailedTimes = "lastPinFailedTimes" //user cache can't restore
        
        
        
        
        //wait
        static let lastFetchMessageID = "last_fetch_message_id"
        static let lastFetchMessageTime = "last_fetch_message_time"
        static let lastUpdateTime = "last_update_time"
        static let historyTimeStamp = "history_timestamp"
        
        //Global Cache
        static let lastSplashViersion = "last_splash_viersion" //global cache
        static let lastTourViersion = "last_tour_viersion" //global cache
        static let lastLocalMobileSignature = "last_local_mobile_signature_mainkeyProtected" //user cache but could restore
        
        // Snooze Notifications
        static let snoozeConfiguration = "snoozeConfiguration"
        
        // FIX ME: double check if the value belongs to user. move it into user object. 2.0
        static let servicePlans = "servicePlans"
        static let currentSubscription = "currentSubscription"
        static let defaultPlanDetails = "defaultPlanDetails"
        static let isIAPAvailable = "isIAPAvailable"
    }

    var isForcedLogout : Bool = false
    
    var isCheckSpaceDisabled: Bool {
        get {
            return getShared().bool(forKey: Key.isCheckSpaceDisabled)
        }
        set {
            setValue(newValue, forKey: Key.isCheckSpaceDisabled)
        }
    }
    
    var isPMMEWarningDisabled : Bool {
        get {
            return getShared().bool(forKey: Key.isPM_MEWarningDisabled)
        }
        set {
            setValue(newValue, forKey: Key.isPM_MEWarningDisabled)
        }
    }
    
    var serverNotices : [String] {
        get {
            return getShared().object(forKey: Key.cachedServerNotices) as? [String] ?? [String]()
        }
        set {
            setValue(newValue, forKey: Key.cachedServerNotices)
        }
    }
    
    var serverNoticesNextTime : String {
        get {
            return getShared().string(forKey: Key.showServerNoticesNextTime) ?? "0"
        }
        set {
            setValue(newValue, forKey: Key.showServerNoticesNextTime)
        }
    }
    
    func isSplashOk() -> Bool {
        let splashVersion = getShared().integer(forKey: Key.lastSplashViersion)
        return splashVersion == Constants.App.SplashVersion
    }
    
    func isTourOk() -> Bool {
        let tourVersion = getShared().integer(forKey: Key.lastTourViersion)
        return tourVersion == Constants.App.TourVersion
    }
    
    func showTourNextTime() {
        setValue(0, forKey: Key.lastTourViersion)
    }
    
    func isAuthCacheOk() -> Bool {
        let cachedVersion = getShared().integer(forKey: Key.lastAuthCacheVersion)
        return cachedVersion == Constants.App.AuthCacheVersion
    }
    
    func resetAuthCache() -> Void {
        setValue(Constants.App.AuthCacheVersion, forKey: Key.lastAuthCacheVersion)
    }
    
    func resetSplashCache() -> Void {
        setValue(Constants.App.SplashVersion, forKey: Key.lastSplashViersion)
    }
    
    func resetTourValue() {
        setValue(Constants.App.TourVersion, forKey: Key.lastTourViersion)
    }
    
    var mobileSignature : String {
        get {
            guard let mainKey = keymaker.mainKey,
                let cypherData = SharedCacheBase.getDefault()?.data(forKey: Key.lastLocalMobileSignature),
                case let locked = Locked<String>(encryptedValue: cypherData),
                let customSignature = try? locked.unlock(with: mainKey) else
            {
                SharedCacheBase.getDefault()?.removeObject(forKey: Key.lastLocalMobileSignature)
                return "Sent from ProtonMail Mobile"
            }

            return customSignature
        }
        set {
            guard let mainKey = keymaker.mainKey,
                let locked = try? Locked<String>(clearValue: newValue, with: mainKey) else
            {
                return
            }
            SharedCacheBase.getDefault()?.set(locked.encryptedValue, forKey: Key.lastLocalMobileSignature)
            SharedCacheBase.getDefault().synchronize()
        }
    }
    
    var pinFailedCount : Int {
        get {
            return getShared().integer(forKey: Key.lastPinFailedTimes)
        }
        set {
            setValue(newValue, forKey: Key.lastPinFailedTimes)
        }
    }
    
    func resetMobileSignature() {
        getShared().removeObject(forKey: Key.lastLocalMobileSignature)
        getShared().synchronize()
    }
    
    func signOut()
    {
        getShared().removeObject(forKey: Key.lastFetchMessageID)
        getShared().removeObject(forKey: Key.lastFetchMessageTime)
        getShared().removeObject(forKey: Key.lastUpdateTime)
        getShared().removeObject(forKey: Key.historyTimeStamp)
        getShared().removeObject(forKey: Key.isCheckSpaceDisabled)
        getShared().removeObject(forKey: Key.cachedServerNotices)
        getShared().removeObject(forKey: Key.showServerNoticesNextTime)
        getShared().removeObject(forKey: Key.lastAuthCacheVersion)
        getShared().removeObject(forKey: Key.isPM_MEWarningDisabled)
        
        //pin code
        getShared().removeObject(forKey: Key.lastPinFailedTimes)
        
        //for version <= 1.6.5 clean old stuff.
        UICKeyChainStore.removeItem(forKey: Key.lastLoggedInUser)
        UICKeyChainStore.removeItem(forKey: Key.autoLockTime)
        
        //for newer version > 1.6.5
        sharedKeychain.keychain.removeItem(forKey: Key.lastLoggedInUser)
        sharedKeychain.keychain.removeItem(forKey: Key.autoLockTime)
        
        // Clean the keys Anatoly added
        getShared().removeObject(forKey: Key.snoozeConfiguration)
        getShared().removeObject(forKey: Key.servicePlans)
        getShared().removeObject(forKey: Key.currentSubscription)
        getShared().removeObject(forKey: Key.defaultPlanDetails)
        getShared().removeObject(forKey: Key.isIAPAvailable)
                        
        getShared().synchronize()
    }
    
    func cleanGlobal() {
        getShared().removeObject(forKey: Key.lastSplashViersion)
        getShared().removeObject(forKey: Key.lastTourViersion)
        
        //touch id
        getShared().removeObject(forKey: Key.autoLogoutTime)
        getShared().removeObject(forKey: Key.askEnableTouchID)
        
        //
        getShared().removeObject(forKey: Key.lastLocalMobileSignature)
       
        getShared().synchronize()
    }
}


// touch id part
extension UserCachedStatus {
    var isTouchIDEnabled: Bool {
        return keymaker.isProtectorActive(BioProtection.self)
    }
    
    var isPinCodeEnabled : Bool {
        return keymaker.isProtectorActive(PinProtection.self)
    }
    
    var lockTime: AutolockTimeout { // historically, it was saved as String
        get {
            guard let string = sharedKeychain.keychain.string(forKey: Key.autoLockTime),
                let number = Int(string) else
            {
                return .always
            }
            return AutolockTimeout(rawValue: number)
        }
        set {
            sharedKeychain.keychain.setString("\(newValue.rawValue)", forKey: Key.autoLockTime)
            keymaker.resetAutolock()
        }
    }
    
    var lastLoggedInUser : String? {
        get {
            return sharedKeychain.keychain.string(forKey: Key.lastLoggedInUser)
        }
        set {
            sharedKeychain.keychain.setString(newValue, forKey: Key.lastLoggedInUser)
        }
    }
    
    func alreadyAskedEnableTouchID () -> Bool {
        let code = getShared().integer(forKey: Key.askEnableTouchID)
        return code == Constants.App.AskTouchID
    }
    
    func resetAskedEnableTouchID() {
        setValue(Constants.App.AskTouchID, forKey: Key.askEnableTouchID)
    }
}


#if !APP_EXTENSION
extension UserCachedStatus: ServicePlanDataStorage {
    var servicePlansDetails: [ServicePlanDetails]? {
        get {
            guard let data = self.getShared().data(forKey: Key.servicePlans) else {
                return nil
            }
            return try? PropertyListDecoder().decode(Array<ServicePlanDetails>.self, from: data)
        }
        set {
            let data = try? PropertyListEncoder().encode(newValue)
            self.setValue(data, forKey: Key.servicePlans)
        }
    }
    
    var defaultPlanDetails: ServicePlanDetails? {
        get {
            guard let data = self.getShared().data(forKey: Key.defaultPlanDetails) else {
                return nil
            }
            return try? PropertyListDecoder().decode(ServicePlanDetails.self, from: data)
        }
        set {
            let data = try? PropertyListEncoder().encode(newValue)
            self.setValue(data, forKey: Key.defaultPlanDetails)
        }
    }
    
    var currentSubscription: ServicePlanSubscription? {
        get {
            guard let data = self.getShared().data(forKey: Key.currentSubscription) else {
                return nil
            }
            return try? PropertyListDecoder().decode(ServicePlanSubscription.self, from: data)
        }
        set {
            let data = try? PropertyListEncoder().encode(newValue)
            self.setValue(data, forKey: Key.currentSubscription)
        }
    }
    
    var isIAPAvailable: Bool {
        get {
            return self.getShared().bool(forKey: Key.isIAPAvailable)
        }
        set {
            self.setValue(newValue, forKey: Key.isIAPAvailable)
        }
    }
}
#endif
