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

@available(*, deprecated, message: "Remove global access of userCachedStatus in the future.")
let userCachedStatus = UserCachedStatus(keychain: KeychainWrapper.keychain)

protocol UserCachedStatusProvider: AnyObject {
    var lastDraftMessageID: String? { get set }
}

final class UserCachedStatus: UserCachedStatusProvider {
    struct Key {
        // Global Cache
        static let UserWithLocalMobileSignature = "user_with_local_mobile_signature_mainKeyProtected"
        static let UserWithLocalMobileSignatureStatus = "user_with_local_mobile_signature_status"
        static let UserWithDefaultSignatureStatus = "user_with_default_signature_status"
        static let UserWithIsCheckSpaceDisabledStatus = "user_with_is_check_space_disabled_status"

        // FIX ME: double check if the value belongs to user. move it into user object. 2.0

        static let leftToRightSwipeAction = "leftToRightSwipeAction"
        static let rightToLeftSwipeAction = "rightToLeftSwipeAction"

        static let localSystemUpTime = "localSystemUpTime"
        static let localServerTime = "localServerTime"

        static let initialUserLoggedInVersion = "initialUserLoggedInVersion"
    }

    // Do not set values for these keys, they are only needed to check for data saved by older versions
    struct LegacyKey {
        static let defaultSignatureStatus = "defaultSignatureStatus"
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
        SystemLogger.log(message: "deleting user defaults and keychain")
        let protectedUserDefaultsKeys: [String] = [
            Key.initialUserLoggedInVersion,
            UserDefaultsKeys.lastTourVersion.name,
            "latest_core_data_cache", // CoreDataCache.Key.coreDataVersion
            BackendConfigurationCache.Key.environment.rawValue,
            BackendConfigurationCache.Key.environmentCustomDomain.rawValue
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

#if !APP_EXTENSION

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
