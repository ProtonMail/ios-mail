//
//  MessageStatus.swift
//  ProtonMail - Created on 5/4/15.
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
import ProtonCore_Keymaker
import ProtonCore_Payments

let userCachedStatus = UserCachedStatus()

//the data in there store longer.

final class UserCachedStatus: SharedCacheBase, DohCacheProtocol, ContactCombinedCacheProtocol, EncryptedSearchCacheProtocol, EncryptedSearchDownloadedMessagesCacheProtocol {
    struct Key {
        // inuse
//        static let lastCacheVersion = "last_cache_version" //user cache
        static let isCheckSpaceDisabled = "isCheckSpaceDisabledKey" //Legacy -- remove it later
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
        static let UserWithLocalMobileSignature = "user_with_local_mobile_signature_mainKeyProtected"
        static let UserWithLocalMobileSignatureStatus = "user_with_local_mobile_signature_status"
        static let UserWithDefaultSignatureStatus = "user_with_default_signature_status"
        static let UserWithIsCheckSpaceDisabledStatus = "user_with_is_check_space_disabled_status"
        
        // Snooze Notifications
        static let snoozeConfiguration = "snoozeConfiguration"
        
        // FIX ME: double check if the value belongs to user. move it into user object. 2.0
        static let servicePlans = "servicePlans"
        static let currentSubscription = "currentSubscription"
        static let defaultPlanDetails = "defaultPlanDetails"
        static let isIAPAvailableOnBE = "isIAPAvailable"
        
        static let metadataStripping = "metadataStripping"
        static let browser = "browser"
        
        
        static let dohFlag = "doh_flag"
        static let dohWarningAsk = "doh_warning_ask"
        
        static let combineContactFlag = "combine_contact_flag"
        static let encrypedSearchFlag = "encrypted_search_flag"
        static let encryptedSearchDownloadViaMobileData = "encrypted_search_download_via_mobile_data_flag"
        static let encryptedSearchIndexComplete = "encrypted_search_index_complete"
        static let encryptedSearchStorageLimit = "encrypted_search_storage_limit_flag"
        static let encryptedSearchStatus = "encrypted_search_status_flag"
        
        static let primaryUserSessionId = "primary_user_session_id"
        
        //new value to check new messages
        static let newMessageFromNotification = "new_message_from_notification"

        static let leftToRightSwipeAction = "leftToRightSwipeAction"
        static let rightToLeftSwipeAction = "rightToLeftSwipeAction"

        static let darkModeFlag = "dark_mode_flag"
        static let localSystemUpTime = "localSystemUpTime"
        static let localServerTime = "localServerTime"
        
        // Random pin protection
        static let randomPinForProtection = "randomPinForProtection"
        static let realAttachments = "realAttachments"
    }
    
    var keymakerRandomkey: String? {
        get {
            return KeychainWrapper.keychain.string(forKey: Key.randomPinForProtection)
        }
        set {
            if let value = newValue {
                KeychainWrapper.keychain.set(value, forKey: Key.randomPinForProtection)
            } else {
                KeychainWrapper.keychain.remove(forKey: Key.randomPinForProtection)
            }
        }
    }
    
    var primaryUserSessionId: String? {
        get {
            if getShared()?.object(forKey: Key.primaryUserSessionId) == nil {
                return nil
            }
            return getShared()?.string(forKey: Key.primaryUserSessionId)
        }
        set {
            setValue(newValue, forKey: Key.primaryUserSessionId)
        }
    }
    
    var hasMessageFromNotification: Bool {
        get {
            if getShared()?.object(forKey: Key.newMessageFromNotification) == nil {
                return true
            }
            return getShared().bool(forKey: Key.newMessageFromNotification)
        }
        set {
            setValue(newValue, forKey: Key.newMessageFromNotification)
        }
    }
    
    var isDohOn: Bool {
        get {
            if getShared()?.object(forKey: Key.dohFlag) == nil {
                return true
            }
            return getShared().bool(forKey: Key.dohFlag)
        }
        set {
            setValue(newValue, forKey: Key.dohFlag)
        }
    }
    
    var isCombineContactOn: Bool {
        get {
            if getShared()?.object(forKey: Key.combineContactFlag) == nil {
                return false
            }
            return getShared().bool(forKey: Key.combineContactFlag)
        }
        set {
            setValue(newValue, forKey: Key.combineContactFlag)
        }
    }

    private(set) var hasShownStorageOverAlert: Bool = false
    
    var isEncryptedSearchOn: Bool {
        get {
            if getShared()?.object(forKey: Key.encrypedSearchFlag) == nil {
                return false
            }
            return getShared().bool(forKey: Key.encrypedSearchFlag)
        }
        set {
            setValue(newValue, forKey: Key.encrypedSearchFlag)
        }
    }
    
    var downloadViaMobileData: Bool {
        get {
            if getShared().object(forKey: Key.encryptedSearchDownloadViaMobileData) == nil {
                return false
            }
            return getShared().bool(forKey: Key.encryptedSearchDownloadViaMobileData)
        }
        set {
            setValue(newValue, forKey: Key.encryptedSearchDownloadViaMobileData)
        }
    }
    
    var storageLimit: Int64 {
        get {
            if getShared().object(forKey: Key.encryptedSearchStorageLimit) == nil {
                return 600_000_000    // in bytes - default storage limit is 600 MB
            }
            return Int64(getShared().int(forKey: Key.encryptedSearchStorageLimit) ?? 600_000_000)
        }
        set {
            setValue(newValue, forKey: Key.encryptedSearchStorageLimit)
        }
    }
    
    var indexComplete: Bool {
        get {
            if getShared().object(forKey: Key.encryptedSearchIndexComplete) == nil {
                return false
            }
            return getShared().bool(forKey: Key.encryptedSearchIndexComplete)
        }
        set {
            setValue(newValue, forKey: Key.encryptedSearchIndexComplete)
        }
    }
    
    var indexStatus: Int {
        get {
            if getShared().object(forKey: Key.encryptedSearchStatus) == nil {
                return 0 // disabled
            }
            return getShared().integer(forKey: Key.encryptedSearchStatus)
        }
        set {
            setValue(newValue, forKey: Key.encryptedSearchStatus)
        }
    }
    
    struct CoderKey {//Conflict with Key object
           static let mailboxPassword           = "UsersManager.AtLeastoneLoggedIn"
           static let username                  = "usernameKeyProtectedWithMainKey"
           
//           static let userInfo                  = "userInfoKeyProtectedWithMainKey"
//           static let twoFAStatus               = "twofaKey"
//           static let userPasswordMode          = "userPasswordModeKey"
//
//           static let roleSwitchCache           = "roleSwitchCache"
//           static let defaultSignatureStatus    = "defaultSignatureStatus"
//
//           static let firstRunKey = "FirstRunKey"
       }

    var isForcedLogout : Bool = false
    
    /// Record the last draft messageID, so the app can do delete / restore
    var lastDraftMessageID: String?
    
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

    var realAttachments: Bool {
        if let flagString = getShared().string(forKey: Key.realAttachments),
           let data = flagString.data(using: .utf8),
           let dict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Bool],
           let sessionID = self.primaryUserSessionId,
           let flag = dict[sessionID] {
            return flag
        } else {
            return false
        }
    }

    func set(realAttachments: Bool, sessionID: String) {
        if let flagString = getShared().string(forKey: Key.realAttachments),
           let data = flagString.data(using: .utf8),
           var dict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
            dict[sessionID] = realAttachments
            let jsonString = dict.json()
            setValue(jsonString, forKey: Key.realAttachments)
        } else {
            let dict: [String: Any] = [sessionID: realAttachments]
            let jsonString = dict.json()
            setValue(jsonString, forKey: Key.realAttachments)
        }
    }

    func isSplashOk() -> Bool {
        let splashVersion = getShared().int(forKey: Key.lastSplashViersion)
        return splashVersion == Constants.App.SplashVersion
    }
    
    func isTourOk() -> Bool {
        let tourVersion = getShared().int(forKey: Key.lastTourViersion)
        return tourVersion == Constants.App.TourVersion
    }
    
    func showTourNextTime() {
        setValue(0, forKey: Key.lastTourViersion)
    }
    
    func isAuthCacheOk() -> Bool {
        let cachedVersion = getShared().int(forKey: Key.lastAuthCacheVersion)
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
            guard let mainKey = keymaker.mainKey(by: RandomPinProtection.randomPin),
                let cypherData = SharedCacheBase.getDefault()?.data(forKey: Key.lastLocalMobileSignature),
                case let locked = Locked<String>(encryptedValue: cypherData),
                let customSignature = try? locked.unlock(with: mainKey) else
            {
                SharedCacheBase.getDefault()?.removeObject(forKey: Key.lastLocalMobileSignature)
                return "Sent from ProtonMail for iOS"
            }

            return customSignature
        }
        set {
            guard let mainKey = keymaker.mainKey(by: RandomPinProtection.randomPin),
                let locked = try? Locked<String>(clearValue: newValue, with: mainKey) else
            {
                return
            }
            SharedCacheBase.getDefault()?.set(locked.encryptedValue, forKey: Key.lastLocalMobileSignature)
            SharedCacheBase.getDefault().synchronize()
        }
    }
    
    func migrateLagcy() {
        guard let mainKey = keymaker.mainKey(by: RandomPinProtection.randomPin),
            let cypherData = SharedCacheBase.getDefault()?.data(forKey: Key.lastLocalMobileSignature),
            case let locked = Locked<String>(encryptedValue: cypherData),
            let customSignature = try? locked.lagcyUnlock(with: mainKey) else
        {
            return
        }
        guard let lockedNew = try? Locked<String>(clearValue: customSignature, with: mainKey) else
        {
            return
        }
        SharedCacheBase.getDefault()?.set(lockedNew.encryptedValue, forKey: Key.lastLocalMobileSignature)
        SharedCacheBase.getDefault().synchronize()
        
        if var signatureData = SharedCacheBase.getDefault()?.dictionary(forKey: Key.UserWithLocalMobileSignature) {
            signatureData.keys.forEach {
                if let encryptedSignature = signatureData[$0] as? Data, case let locked = Locked<String>(encryptedValue: encryptedSignature),
                    let customSignature = try? locked.lagcyUnlock(with: mainKey) {
                    if let lockedSign = try? Locked<String>(clearValue: customSignature, with: mainKey) {
                        signatureData[$0] = lockedSign.encryptedValue
                    }
                }
            }
            SharedCacheBase.getDefault()?.set(signatureData, forKey: Key.UserWithLocalMobileSignature)
            SharedCacheBase.getDefault().synchronize()
        }
    }
    
    func resetMobileSignature() {
        getShared().removeObject(forKey: Key.lastLocalMobileSignature)
        getShared().synchronize()
    }
    
    func getDefaultSignaureSwitchStatus(uid: String) -> Bool? {
        guard let switchData = SharedCacheBase.getDefault()?.dictionary(forKey: Key.UserWithDefaultSignatureStatus),
        let switchStatus = switchData[uid] as? Bool else {
            return nil
        }
        return switchStatus
    }
    
    func setDefaultSignatureSwitchStatus(uid: String, value: Bool) {
        guard var switchData = SharedCacheBase.getDefault()?.dictionary(forKey: Key.UserWithDefaultSignatureStatus) else {
            var newDictiondary: [String: Bool] = [:]
            newDictiondary[uid] = value
            SharedCacheBase.getDefault()?.set(newDictiondary, forKey: Key.UserWithDefaultSignatureStatus)
            SharedCacheBase.getDefault()?.synchronize()
            return
        }
        switchData[uid] = value
        SharedCacheBase.getDefault()?.set(switchData, forKey: Key.UserWithDefaultSignatureStatus)
        SharedCacheBase.getDefault()?.synchronize()
    }
    
    func removeDefaultSignatureSwitchStatus(uid: String) {
        guard var switchData = SharedCacheBase.getDefault()?.dictionary(forKey: Key.UserWithDefaultSignatureStatus) else {
            return
        }
        
        switchData.removeValue(forKey: uid)
        SharedCacheBase.getDefault()?.set(switchData, forKey: Key.UserWithDefaultSignatureStatus)
        SharedCacheBase.getDefault()?.synchronize()
    }
    
    func getMobileSignatureSwitchStatus(by uid: String) -> Bool? {
        guard let switchData = SharedCacheBase.getDefault()?.dictionary(forKey: Key.UserWithLocalMobileSignatureStatus),
        let switchStatus = switchData[uid] as? Bool else {
            return nil
        }
        return switchStatus
    }
    
    func setMobileSignatureSwitchStatus(uid: String, value: Bool) {
        guard var switchData = SharedCacheBase.getDefault()?.dictionary(forKey: Key.UserWithLocalMobileSignatureStatus) else {
            var newDictiondary: [String: Bool] = [:]
            newDictiondary[uid] = value
            SharedCacheBase.getDefault()?.set(newDictiondary, forKey: Key.UserWithLocalMobileSignatureStatus)
            SharedCacheBase.getDefault()?.synchronize()
            return
        }
        switchData[uid] = value
        SharedCacheBase.getDefault()?.set(switchData, forKey: Key.UserWithLocalMobileSignatureStatus)
        SharedCacheBase.getDefault()?.synchronize()
    }
    
    func removeMobileSignatureSwitchStatus(uid: String) {
        guard var switchData = SharedCacheBase.getDefault()?.dictionary(forKey: Key.UserWithLocalMobileSignatureStatus) else {
            return
        }
        
        switchData.removeValue(forKey: uid)
        SharedCacheBase.getDefault()?.set(switchData, forKey: Key.UserWithLocalMobileSignatureStatus)
        SharedCacheBase.getDefault()?.synchronize()
    }
    
    func getMobileSignature(by uid: String) -> String {
        guard let mainKey = keymaker.mainKey(by: RandomPinProtection.randomPin),
            let signatureData = SharedCacheBase.getDefault()?.dictionary(forKey: Key.UserWithLocalMobileSignature),
            let encryptedSignature = signatureData[uid] as? Data ,
            case let locked = Locked<String>(encryptedValue: encryptedSignature),
            let customSignature = try? locked.unlock(with: mainKey) else
        {
            //Get data from legacy
            if let mainKey = keymaker.mainKey(by: RandomPinProtection.randomPin),
                let cypherData = SharedCacheBase.getDefault()?.data(forKey: Key.lastLocalMobileSignature),
                case let locked = Locked<String>(encryptedValue: cypherData),
                let customSignature = try? locked.unlock(with: mainKey) {
                
                setMobileSignature(uid: uid, signature: customSignature)
                SharedCacheBase.getDefault()?.synchronize()
                return customSignature
            }
            
            SharedCacheBase.getDefault()?.removeObject(forKey: Key.lastLocalMobileSignature)
            removeMobileSignature(uid: uid)
            return "Sent from ProtonMail for iOS"
        }
        return customSignature
    }
    
    func setMobileSignature(uid: String, signature: String) {
        guard let mainKey = keymaker.mainKey(by: RandomPinProtection.randomPin),
            let locked = try? Locked<String>(clearValue: signature, with: mainKey) else
        {
            return
        }
        
        if var signatureData = SharedCacheBase.getDefault()?.dictionary(forKey: Key.UserWithLocalMobileSignature) {
            signatureData[uid] = locked.encryptedValue
            SharedCacheBase.getDefault()?.set(signatureData, forKey: Key.UserWithLocalMobileSignature)
            
        } else {
            var newDictionary: [String: Data] = [:]
            newDictionary[uid] = locked.encryptedValue
            SharedCacheBase.getDefault()?.set(newDictionary, forKey: Key.UserWithLocalMobileSignature)
        }
        SharedCacheBase.getDefault().synchronize()
    }
    
    func removeMobileSignature(uid: String) {
        if var signatureData = SharedCacheBase.getDefault()?.dictionary(forKey: Key.UserWithLocalMobileSignature) {
            signatureData.removeValue(forKey: uid)
            SharedCacheBase.getDefault()?.set(signatureData, forKey: Key.UserWithLocalMobileSignature)
            SharedCacheBase.getDefault()?.synchronize()
        }
    }
    
    func getIsCheckSpaceDisabledStatus(by uid: String) -> Bool? {
        guard let switchData = SharedCacheBase.getDefault()?.dictionary(forKey: Key.UserWithIsCheckSpaceDisabledStatus),
        let switchStatus = switchData[uid] as? Bool else {
            return nil
        }
        return switchStatus
    }
    
    func setIsCheckSpaceDisabledStatus(uid: String, value: Bool) {
        guard var switchData = SharedCacheBase.getDefault()?.dictionary(forKey: Key.UserWithIsCheckSpaceDisabledStatus) else {
            var newDictiondary: [String: Bool] = [:]
            newDictiondary[uid] = value
            SharedCacheBase.getDefault()?.set(newDictiondary, forKey: Key.UserWithIsCheckSpaceDisabledStatus)
            SharedCacheBase.getDefault()?.synchronize()
            return
        }
        switchData[uid] = value
        SharedCacheBase.getDefault()?.set(switchData, forKey: Key.UserWithIsCheckSpaceDisabledStatus)
        SharedCacheBase.getDefault()?.synchronize()
    }
    
    func removeIsCheckSpaceDisabledStatus(uid: String) {
        guard var switchData = SharedCacheBase.getDefault()?.dictionary(forKey: Key.UserWithIsCheckSpaceDisabledStatus) else {
            return
        }
        
        switchData.removeValue(forKey: uid)
        SharedCacheBase.getDefault()?.set(switchData, forKey: Key.UserWithIsCheckSpaceDisabledStatus)
        SharedCacheBase.getDefault()?.synchronize()
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
        getShared().removeObject(forKey: Key.combineContactFlag)
        getShared().removeObject(forKey: Key.browser)
        
        //pin code
        getShared().removeObject(forKey: Key.lastPinFailedTimes)
        
        //for version <= 1.6.5 clean old stuff.
        KeychainWrapper.keychain.remove(forKey: Key.lastLoggedInUser)
        KeychainWrapper.keychain.remove(forKey: Key.autoLockTime)
        
        //for newer version > 1.6.5
        KeychainWrapper.keychain.remove(forKey: Key.lastLoggedInUser)
        KeychainWrapper.keychain.remove(forKey: Key.autoLockTime)
        
        // Clean the keys Anatoly added
        getShared().removeObject(forKey: Key.snoozeConfiguration)
        getShared().removeObject(forKey: Key.servicePlans)
        getShared().removeObject(forKey: Key.currentSubscription)
        getShared().removeObject(forKey: Key.defaultPlanDetails)
        getShared().removeObject(forKey: Key.isIAPAvailableOnBE)
        
        KeychainWrapper.keychain.remove(forKey: Key.metadataStripping)
        KeychainWrapper.keychain.remove(forKey: Key.browser)
        
        ////
        getShared().removeObject(forKey: Key.dohWarningAsk)
        
        //
        KeychainWrapper.keychain.remove(forKey: Key.randomPinForProtection)
                        
        getShared().synchronize()
    }
    
    func cleanGlobal() {
        getShared().removeObject(forKey: Key.dohFlag)
        
        getShared().removeObject(forKey: Key.lastSplashViersion)
        getShared().removeObject(forKey: Key.lastTourViersion)
        
        //touch id
        getShared().removeObject(forKey: Key.autoLogoutTime)
        getShared().removeObject(forKey: Key.askEnableTouchID)

        getShared().removeObject(forKey: Key.lastLocalMobileSignature)

        getShared().removeObject(forKey: Key.leftToRightSwipeAction)
        getShared().removeObject(forKey: Key.rightToLeftSwipeAction)

        getShared().synchronize()
    }

    func showStorageOverAlert() {
        self.hasShownStorageOverAlert = true
    }
}


// touch id part
extension UserCachedStatus : CacheStatusInject {
    var isUserCredentialStored: Bool {
//        return SharedCacheBase.getDefault()?.data(forKey: CoderKey.mailboxPassword) != nil
        return KeychainWrapper.keychain.string(forKey: CoderKey.mailboxPassword) != nil
    }
    
    var isMailboxPasswordStored: Bool {
        return KeychainWrapper.keychain.string(forKey: CoderKey.mailboxPassword) != nil
    }
    
    var isTouchIDEnabled: Bool {
        return keymaker.isProtectorActive(BioProtection.self)
    }
    
    var isPinCodeEnabled : Bool {
        return keymaker.isProtectorActive(PinProtection.self)
    }
    
    var isAppKeyEnabled: Bool {
        return keymaker.isProtectorActive(RandomPinProtection.self) == false
    }
    
    var pinFailedCount : Int {
        get {
            return getShared().integer(forKey: Key.lastPinFailedTimes)
        }
        set {
            setValue(newValue, forKey: Key.lastPinFailedTimes)
        }
    }
    
    var lockTime: AutolockTimeout { // historically, it was saved as String
        get {
            guard let string = KeychainWrapper.keychain.string(forKey: Key.autoLockTime),
                let number = Int(string) else
            {
                return .always
            }
            return AutolockTimeout(rawValue: number)
        }
        set {
            KeychainWrapper.keychain.set("\(newValue.rawValue)", forKey: Key.autoLockTime)
            keymaker.resetAutolock()
        }
    }
    
    var lastLoggedInUser : String? {
        get {
            return KeychainWrapper.keychain.string(forKey: Key.lastLoggedInUser)
        }
        set {
            if let value = newValue {
                KeychainWrapper.keychain.set(value, forKey: Key.lastLoggedInUser)
            } else {
                KeychainWrapper.keychain.remove(forKey: Key.lastLoggedInUser)
            }
        }
    }
    
    func alreadyAskedEnableTouchID () -> Bool {
        let code = getShared().int(forKey: Key.askEnableTouchID)
        return code == Constants.App.AskTouchID
    }
    
    func resetAskedEnableTouchID() {
        setValue(Constants.App.AskTouchID, forKey: Key.askEnableTouchID)
    }
}

extension UserCachedStatus {
    var metadataStripping: AttachmentMetadataStripping {
        get {
            guard let string = KeychainWrapper.keychain.string(forKey: Key.metadataStripping),
                let mode = AttachmentMetadataStripping(rawValue: string) else
            {
                return .sendAsIs
            }
            return mode
        }
        set {
            KeychainWrapper.keychain.set(newValue.rawValue, forKey: Key.metadataStripping)
        }
    }
}

extension UserCachedStatus: DarkModeCacheProtocol {
    var darkModeStatus: DarkModeStatus {
        get {
            if getShared()?.object(forKey: Key.darkModeFlag) == nil {
                return .followSystem
            }
            let raw = getShared().integer(forKey: Key.darkModeFlag)
            if let status = DarkModeStatus(rawValue: raw) {
                return status
            } else {
                getShared().removeObject(forKey: Key.darkModeFlag)
                return .followSystem
            }
        }
        set {
            setValue(newValue.rawValue, forKey: Key.darkModeFlag)
        }
    }
}

#if !APP_EXTENSION
extension UserCachedStatus: LinkOpenerCacheProtocol {
    var browser: LinkOpener {
        get {
            guard let raw = KeychainWrapper.keychain.string(forKey: Key.browser) ?? getShared().string(forKey: Key.browser) else {
                return .safari
            }
            return LinkOpener(rawValue: raw) ?? .safari
        }
        set {
            getShared().setValue(newValue.rawValue, forKey: Key.browser)
            KeychainWrapper.keychain.set(newValue.rawValue, forKey: Key.browser)
        }
    }
}
extension UserCachedStatus: ServicePlanDataStorage {
    /* TODO NOTE: this should be updated alongside Payments integration */
    var credits: Credits? {
        get { nil }
        set { }
    }

    var servicePlansDetails: [Plan]? {
        get {
            guard let data = self.getShared().data(forKey: Key.servicePlans) else {
                return nil
            }
            return try? PropertyListDecoder().decode(Array<Plan>.self, from: data)
        }
        set {
            let data = try? PropertyListEncoder().encode(newValue)
            self.setValue(data, forKey: Key.servicePlans)
        }
    }
    
    var defaultPlanDetails: Plan? {
        get {
            guard let data = self.getShared().data(forKey: Key.defaultPlanDetails) else {
                return nil
            }
            return try? PropertyListDecoder().decode(Plan.self, from: data)
        }
        set {
            let data = try? PropertyListEncoder().encode(newValue)
            self.setValue(data, forKey: Key.defaultPlanDetails)
        }
    }
    
    var currentSubscription: Subscription? {
        get {
            guard let data = self.getShared().data(forKey: Key.currentSubscription) else {
                return nil
            }
            return try? PropertyListDecoder().decode(Subscription.self, from: data)
        }
        set {
            let data = try? PropertyListEncoder().encode(newValue)
            self.setValue(data, forKey: Key.currentSubscription)
        }
    }
    
    var isIAPUpgradePlanAvailable: Bool {
        get {
            return self.getShared().bool(forKey: Key.isIAPAvailableOnBE)
        }
        set {
            self.setValue(newValue, forKey: Key.isIAPAvailableOnBE)
        }
    }

}

extension UserCachedStatus: SwipeActionCacheProtocol {
    var leftToRightSwipeActionType: SwipeActionSettingType {
        get {
            if let value = self.getShared()?.int(forKey: Key.leftToRightSwipeAction), let action = SwipeActionSettingType(rawValue: value) {
                return action
            } else {
                self.leftToRightSwipeActionType = .readAndUnread
                return .readAndUnread
            }
        }
        set {
            self.setValue(newValue.rawValue, forKey: Key.leftToRightSwipeAction)
        }
    }

    var rightToLeftSwipeActionType: SwipeActionSettingType {
        get {
            if let value = self.getShared()?.int(forKey: Key.rightToLeftSwipeAction), let action = SwipeActionSettingType(rawValue: value) {
                return action
            } else {
                self.rightToLeftSwipeActionType = .trash
                return .trash
            }
        }
        set {
            self.setValue(newValue.rawValue, forKey: Key.rightToLeftSwipeAction)
        }
    }
    
    func initialSwipeActionIfNeeded(leftToRight: Int, rightToLeft: Int) {
        if self.getShared()?.int(forKey: Key.leftToRightSwipeAction) == nil,
           let action = SwipeActionSettingType.migrateFromV3(rawValue: leftToRight) {
            self.leftToRightSwipeActionType = action
        }
        
        if self.getShared()?.int(forKey: Key.rightToLeftSwipeAction) == nil,
           let action = SwipeActionSettingType.migrateFromV3(rawValue: rightToLeft) {
            self.rightToLeftSwipeActionType = action
        }
    }
}

extension UserCachedStatus: SystemUpTimeProtocol {

    var localServerTime: TimeInterval {
        get {
            return TimeInterval(self.getShared().double(forKey: Key.localServerTime))
        }
        set {
            self.setValue(newValue, forKey: Key.localServerTime)
        }
    }

    var localSystemUpTime: TimeInterval {
        get {
            let time = self.getShared().double(forKey: Key.localSystemUpTime)
            return time == 0 ? Date().timeIntervalSince1970: TimeInterval(time)
        }
        set {
            self.setValue(newValue, forKey: Key.localSystemUpTime)
        }
    }

    var systemUpTime: TimeInterval {
        ProcessInfo.processInfo.systemUptime
    }

    func updateLocalSystemUpTime(time: TimeInterval = ProcessInfo.processInfo.systemUptime) {
        self.localSystemUpTime = time
    }
}
#endif
