//
//  MessageStatus.swift
//  Proton Mail - Created on 5/4/15.
//
//
//  Copyright (c) 2019 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import Foundation
import ProtonCoreKeymaker
#if !APP_EXTENSION
import ProtonCorePayments
#endif

let userCachedStatus = UserCachedStatus(keychain: KeychainWrapper.keychain)

// sourcery: mock
protocol UserCachedStatusProvider: AnyObject {
    var keymakerRandomkey: String? { get set }
    var lastDraftMessageID: String? { get set }

    func getDefaultSignaureSwitchStatus(uid: String) -> Bool?
    func setDefaultSignatureSwitchStatus(uid: String, value: Bool)
    func removeDefaultSignatureSwitchStatus(uid: String)
    func getIsCheckSpaceDisabledStatus(by uid: String) -> Bool?
    func setIsCheckSpaceDisabledStatus(uid: String, value: Bool)
    func removeIsCheckSpaceDisabledStatus(uid: String)
}

final class UserCachedStatus: UserCachedStatusProvider {
    struct Key {

        // pin code

        static let autoLockTime = "autoLockTime" /// user cache but could restore

        // Global Cache
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

        static let leftToRightSwipeAction = "leftToRightSwipeAction"
        static let rightToLeftSwipeAction = "rightToLeftSwipeAction"

        static let darkModeFlag = "dark_mode_flag"
        static let localSystemUpTime = "localSystemUpTime"
        static let localServerTime = "localServerTime"

        // Random pin protection
        static let randomPinForProtection = "randomPinForProtection"

        static let paymentMethods = "paymentMethods"

        static let initialUserLoggedInVersion = "initialUserLoggedInVersion"
    }

    // Do not set values for these keys, they are only needed to check for data saved by older versions
    struct LegacyKey {
        static let defaultSignatureStatus = "defaultSignatureStatus"
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

    private(set) var hasShownStorageOverAlert: Bool = false

    /// Record the last draft messageID, so the app can do delete / restore
    var lastDraftMessageID: String?

    private let keychain: Keychain    
    let userDefaults: UserDefaults

    convenience init(keychain: Keychain) {
        self.init(userDefaults: UserDefaults(suiteName: Constants.AppGroup)!, keychain: keychain)
    }

    init(userDefaults: UserDefaults, keychain: Keychain) {
        self.keychain = keychain
        self.userDefaults = userDefaults
    }

    func getDefaultSignaureSwitchStatus(uid: String) -> Bool? {
        guard let switchData = userDefaults.dictionary(forKey: Key.UserWithDefaultSignatureStatus),
        let switchStatus = switchData[uid] as? Bool else {
            return nil
        }
        return switchStatus
    }

    func setDefaultSignatureSwitchStatus(uid: String, value: Bool) {
        guard var switchData = userDefaults.dictionary(forKey: Key.UserWithDefaultSignatureStatus) else {
            var newDictiondary: [String: Bool] = [:]
            newDictiondary[uid] = value
            userDefaults.set(newDictiondary, forKey: Key.UserWithDefaultSignatureStatus)
            userDefaults.synchronize()
            return
        }
        switchData[uid] = value
        userDefaults.set(switchData, forKey: Key.UserWithDefaultSignatureStatus)
        userDefaults.synchronize()
    }

    func removeDefaultSignatureSwitchStatus(uid: String) {
        guard var switchData = userDefaults.dictionary(forKey: Key.UserWithDefaultSignatureStatus) else {
            return
        }

        switchData.removeValue(forKey: uid)
        userDefaults.set(switchData, forKey: Key.UserWithDefaultSignatureStatus)
        userDefaults.synchronize()
    }

    func getIsCheckSpaceDisabledStatus(by uid: String) -> Bool? {
        guard let switchData = userDefaults.dictionary(forKey: Key.UserWithIsCheckSpaceDisabledStatus),
        let switchStatus = switchData[uid] as? Bool else {
            return nil
        }
        return switchStatus
    }

    func setIsCheckSpaceDisabledStatus(uid: String, value: Bool) {
        guard var switchData = userDefaults.dictionary(forKey: Key.UserWithIsCheckSpaceDisabledStatus) else {
            var newDictiondary: [String: Bool] = [:]
            newDictiondary[uid] = value
            userDefaults.set(newDictiondary, forKey: Key.UserWithIsCheckSpaceDisabledStatus)
            userDefaults.synchronize()
            return
        }
        switchData[uid] = value
        userDefaults.set(switchData, forKey: Key.UserWithIsCheckSpaceDisabledStatus)
        userDefaults.synchronize()
    }

    func removeIsCheckSpaceDisabledStatus(uid: String) {
        guard var switchData = userDefaults.dictionary(forKey: Key.UserWithIsCheckSpaceDisabledStatus) else {
            return
        }

        switchData.removeValue(forKey: uid)
        userDefaults.set(switchData, forKey: Key.UserWithIsCheckSpaceDisabledStatus)
        userDefaults.synchronize()
    }

    func cleanAllData() {
        let protectedUserDefaultsKeys: [String] = [
            Key.initialUserLoggedInVersion,
            UserDefaultsKeys.lastTourVersion.name
        ]

        for key in userDefaults.dictionaryRepresentation().keys where !protectedUserDefaultsKeys.contains(key) {
            userDefaults.remove(forKey: key)
        }

        keychain.removeEverything()
    }

    func showStorageOverAlert() {
        self.hasShownStorageOverAlert = true
    }
}

extension UserCachedStatus {
    var lockTime: AutolockTimeout { // historically, it was saved as String
        get {
            guard let string = keychain.string(forKey: Key.autoLockTime),
                let number = Int(string) else {
                return .always
            }
            return AutolockTimeout(rawValue: number)
        }
        set {
            keychain.set("\(newValue.rawValue)", forKey: Key.autoLockTime)
        }
    }
}

extension UserCachedStatus: AttachmentMetadataStrippingProtocol {
    var metadataStripping: AttachmentMetadataStripping {
        get {
            guard let string = keychain.string(forKey: Key.metadataStripping),
                let mode = AttachmentMetadataStripping(rawValue: string) else {
                return .sendAsIs
            }
            return mode
        }
        set {
            keychain.set(newValue.rawValue, forKey: Key.metadataStripping)
        }
    }
}

extension UserCachedStatus: DarkModeCacheProtocol {
    var darkModeStatus: DarkModeStatus {
        get {
            if userDefaults.object(forKey: Key.darkModeFlag) == nil {
                return .followSystem
            }
            let raw = userDefaults.integer(forKey: Key.darkModeFlag)
            if let status = DarkModeStatus(rawValue: raw) {
                return status
            } else {
                userDefaults.removeObject(forKey: Key.darkModeFlag)
                return .followSystem
            }
        }
        set {
            userDefaults.set(newValue.rawValue, forKey: Key.darkModeFlag)
        }
    }
}

#if !APP_EXTENSION
extension UserCachedStatus {
    var browser: LinkOpener {
        get {
            guard let raw = keychain.string(forKey: Key.browser) ?? userDefaults.string(forKey: Key.browser) else {
                return .safari
            }
            return LinkOpener(rawValue: raw) ?? .safari
        }
        set {
            userDefaults.setValue(newValue.rawValue, forKey: Key.browser)
            keychain.set(newValue.rawValue, forKey: Key.browser)
        }
    }
}

extension UserCachedStatus: ServicePlanDataStorage {
    var paymentMethods: [PaymentMethod]? {
        get {
            userDefaults.decodableValue(forKey: Key.paymentMethods)
        }
        set {
            userDefaults.setEncodableValue(newValue, forKey: Key.paymentMethods)
        }
    }
    /* TODO NOTE: this should be updated alongside Payments integration */
    var credits: Credits? {
        get { nil }
        set { }
    }

    var servicePlansDetails: [Plan]? {
        get {
            userDefaults.decodableValue(forKey: Key.servicePlans)
        }
        set {
            userDefaults.setEncodableValue(newValue, forKey: Key.servicePlans)
        }
    }

    var defaultPlanDetails: Plan? {
        get {
            userDefaults.decodableValue(forKey: Key.defaultPlanDetails)
        }
        set {
            userDefaults.setEncodableValue(newValue, forKey: Key.defaultPlanDetails)
        }
    }

    var currentSubscription: Subscription? {
        get {
            userDefaults.decodableValue(forKey: Key.currentSubscription)
        }
        set {
            userDefaults.setEncodableValue(newValue, forKey: Key.currentSubscription)
        }
    }
    
    var paymentsBackendStatusAcceptsIAP: Bool {
        get {
            return self.userDefaults.bool(forKey: Key.isIAPAvailableOnBE)
        }
        set {
            userDefaults.set(newValue, forKey: Key.isIAPAvailableOnBE)
        }
    }

}

extension UserCachedStatus: SwipeActionCacheProtocol {
    var leftToRightSwipeActionType: SwipeActionSettingType? {
        get {
            if let value = self.userDefaults.int(forKey: Key.leftToRightSwipeAction), let action = SwipeActionSettingType(rawValue: value) {
                return action
            } else {
                return nil
            }
        }
        set {
            userDefaults.set(newValue?.rawValue, forKey: Key.leftToRightSwipeAction)
        }
    }

    var rightToLeftSwipeActionType: SwipeActionSettingType? {
        get {
            if let value = self.userDefaults.int(forKey: Key.rightToLeftSwipeAction), let action = SwipeActionSettingType(rawValue: value) {
                return action
            } else {
                return nil
            }
        }
        set {
            userDefaults.set(newValue?.rawValue, forKey: Key.rightToLeftSwipeAction)
        }
    }

    func initialSwipeActionIfNeeded(leftToRight: Int, rightToLeft: Int) {
        if self.userDefaults.int(forKey: Key.leftToRightSwipeAction) == nil,
           let action = SwipeActionSettingType.convertFromServer(rawValue: leftToRight) {
            self.leftToRightSwipeActionType = action
        }

        if self.userDefaults.int(forKey: Key.rightToLeftSwipeAction) == nil,
           let action = SwipeActionSettingType.convertFromServer(rawValue: rightToLeft) {
            self.rightToLeftSwipeActionType = action
        }
    }
}

extension UserCachedStatus {
    var initialUserLoggedInVersion: String? {
        get {
            userDefaults.string(forKey: Key.initialUserLoggedInVersion)
        }
        set {
            userDefaults.set(newValue, forKey: Key.initialUserLoggedInVersion)
            userDefaults.synchronize()
        }
    }
}

#endif

extension UserCachedStatus: SystemUpTimeProtocol {

    var localServerTime: TimeInterval {
        get {
            userDefaults.double(forKey: Key.localServerTime)
        }
        set {
            userDefaults.set(newValue, forKey: Key.localServerTime)
        }
    }

    var localSystemUpTime: TimeInterval {
        get {
            userDefaults.double(forKey: Key.localSystemUpTime)
        }
        set {
            userDefaults.set(newValue, forKey: Key.localSystemUpTime)
        }
    }

    var systemUpTime: TimeInterval {
        ProcessInfo.processInfo.systemUptime
    }
}

extension UserCachedStatus: MobileSignatureCacheProtocol {
    func getMobileSignatureSwitchStatus(by uid: String) -> Bool? {
        guard let switchData = userDefaults.dictionary(forKey: Key.UserWithLocalMobileSignatureStatus),
              let switchStatus = switchData[uid] as? Bool else {
            return nil
        }
        return switchStatus
    }

    func setMobileSignatureSwitchStatus(uid: String, value: Bool) {
        guard var switchData = userDefaults.dictionary(forKey: Key.UserWithLocalMobileSignatureStatus) else {
            var newDictiondary: [String: Bool] = [:]
            newDictiondary[uid] = value
            userDefaults.set(newDictiondary, forKey: Key.UserWithLocalMobileSignatureStatus)
            userDefaults.synchronize()
            return
        }
        switchData[uid] = value
        userDefaults.set(switchData, forKey: Key.UserWithLocalMobileSignatureStatus)
        userDefaults.synchronize()
    }

    func removeMobileSignatureSwitchStatus(uid: String) {
        guard var switchData = userDefaults.dictionary(forKey: Key.UserWithLocalMobileSignatureStatus) else {
            return
        }

        switchData.removeValue(forKey: uid)
        userDefaults.set(switchData, forKey: Key.UserWithLocalMobileSignatureStatus)
        userDefaults.synchronize()
    }

    func getEncryptedMobileSignature(userID: String) -> Data? {
        let rawData = userDefaults.dictionary(forKey: Key.UserWithLocalMobileSignature)
        return rawData?[userID] as? Data
    }

    func setEncryptedMobileSignature(userID: String, signatureData: Data) {
        var dataToSave: [String: Any] = [:]
        if var rawData = userDefaults.dictionary(forKey: Key.UserWithLocalMobileSignature) {
            rawData[userID] = signatureData
            dataToSave = rawData
        } else {
            dataToSave[userID] = signatureData
        }
        userDefaults.set(dataToSave, forKey: Key.UserWithLocalMobileSignature)
    }

    func removeEncryptedMobileSignature(userID: String) {
        if var signatureData = userDefaults.dictionary(forKey: Key.UserWithLocalMobileSignature) {
            signatureData.removeValue(forKey: userID)
            userDefaults.set(signatureData, forKey: Key.UserWithLocalMobileSignature)
        }
    }
}
