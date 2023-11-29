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

let userCachedStatus = UserCachedStatus()

// sourcery: mock
protocol UserCachedStatusProvider: AnyObject {
    var keymakerRandomkey: String? { get set }
    var primaryUserSessionId: String? { get set }
    var isDohOn: Bool { get set }
    var isCombineContactOn: Bool { get set }
    var lastDraftMessageID: String? { get set }
    var isPMMEWarningDisabled: Bool { get set }
    var serverNotices: [String] { get set }
    var serverNoticesNextTime: String { get set }

    func getDefaultSignaureSwitchStatus(uid: String) -> Bool?
    func setDefaultSignatureSwitchStatus(uid: String, value: Bool)
    func removeDefaultSignatureSwitchStatus(uid: String)
    func getIsCheckSpaceDisabledStatus(by uid: String) -> Bool?
    func setIsCheckSpaceDisabledStatus(uid: String, value: Bool)
    func removeIsCheckSpaceDisabledStatus(uid: String)
}

final class UserCachedStatus: SharedCacheBase, DohCacheProtocol, ContactCombinedCacheProtocol, UserCachedStatusProvider {
    struct Key {
        // inuse
        static let cachedServerNotices = "cachedServerNotices" // user cache
        static let showServerNoticesNextTime = "showServerNoticesNextTime" // user cache
        static let isPM_MEWarningDisabled = "isPM_MEWarningDisabledKey" // user cache -- maybe could be global

        // pin code

        static let autoLockTime = "autoLockTime" /// user cache but could restore
        static let lastPinFailedTimes = "lastPinFailedTimes" // user cache can't restore

        // Global Cache
        static let lastTourVersion = "last_tour_viersion" // global cache
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

        static let combineContactFlag = "combine_contact_flag"

        static let primaryUserSessionId = "primary_user_session_id"

        static let leftToRightSwipeAction = "leftToRightSwipeAction"
        static let rightToLeftSwipeAction = "rightToLeftSwipeAction"

        static let darkModeFlag = "dark_mode_flag"
        static let localSystemUpTime = "localSystemUpTime"
        static let localServerTime = "localServerTime"

        // Random pin protection
        static let randomPinForProtection = "randomPinForProtection"

        static let paymentMethods = "paymentMethods"

        static let initialUserLoggedInVersion = "initialUserLoggedInVersion"
        static let isContactsCached = "isContactsCached"

        static let isAppRatingEnabled = "isAppRatingEnabled"
        static let appRatingPromptedInVersion = "appRatingPromptedInVersion"
        static let toolbarCustomizationInfoBubbleViewIsShown = "toolbarCustomizationInfoBubbleViewIsShown"
        static let toolbarCustomizeSpotlightShownUserIds = "toolbarCustomizeSpotlightShownUserIds"
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
            if getShared().object(forKey: Key.primaryUserSessionId) == nil {
                return nil
            }
            return getShared().string(forKey: Key.primaryUserSessionId)
        }
        set {
            setValue(newValue, forKey: Key.primaryUserSessionId)
        }
    }

    var isDohOn: Bool {
        get {
            if getShared().object(forKey: Key.dohFlag) == nil {
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
            if getShared().object(forKey: Key.combineContactFlag) == nil {
                return false
            }
            return getShared().bool(forKey: Key.combineContactFlag)
        }
        set {
            setValue(newValue, forKey: Key.combineContactFlag)
        }
    }

    private(set) var hasShownStorageOverAlert: Bool = false

    /// Record the last draft messageID, so the app can do delete / restore
    var lastDraftMessageID: String?

    var isPMMEWarningDisabled: Bool {
        get {
            return getShared().bool(forKey: Key.isPM_MEWarningDisabled)
        }
        set {
            setValue(newValue, forKey: Key.isPM_MEWarningDisabled)
        }
    }

    var serverNotices: [String] {
        get {
            return getShared().object(forKey: Key.cachedServerNotices) as? [String] ?? [String]()
        }
        set {
            setValue(newValue, forKey: Key.cachedServerNotices)
        }
    }

    var serverNoticesNextTime: String {
        get {
            return getShared().string(forKey: Key.showServerNoticesNextTime) ?? "0"
        }
        set {
            setValue(newValue, forKey: Key.showServerNoticesNextTime)
        }
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
        getShared().removeObject(forKey: Key.cachedServerNotices)
        getShared().removeObject(forKey: Key.showServerNoticesNextTime)
        getShared().removeObject(forKey: Key.isPM_MEWarningDisabled)
        getShared().removeObject(forKey: Key.combineContactFlag)
        getShared().removeObject(forKey: Key.browser)
        getShared().removeObject(forKey: Key.lastPinFailedTimes)

        KeychainWrapper.keychain.remove(forKey: Key.autoLockTime)

        // Clean the keys Anatoly added
        getShared().removeObject(forKey: Key.snoozeConfiguration)
        getShared().removeObject(forKey: Key.servicePlans)
        getShared().removeObject(forKey: Key.currentSubscription)
        getShared().removeObject(forKey: Key.defaultPlanDetails)
        getShared().removeObject(forKey: Key.isIAPAvailableOnBE)

        KeychainWrapper.keychain.remove(forKey: Key.metadataStripping)
        KeychainWrapper.keychain.remove(forKey: Key.browser)
        KeychainWrapper.keychain.remove(forKey: Key.randomPinForProtection)

        getShared().removeObject(forKey: Key.isContactsCached)

        getShared().removeObject(forKey: Key.dohFlag)

        getShared().removeObject(forKey: Key.leftToRightSwipeAction)
        getShared().removeObject(forKey: Key.rightToLeftSwipeAction)

        getShared().removeObject(forKey: Key.initialUserLoggedInVersion)
        getShared().removeObject(forKey: Key.darkModeFlag)
        getShared().removeObject(forKey: Key.toolbarCustomizeSpotlightShownUserIds)

#if !APP_EXTENSION
        getShared().removeObject(forKey: Key.usersThatFetchedTheirBlockedSenderLists)
#endif

        getShared().synchronize()
    }

    func showStorageOverAlert() {
        self.hasShownStorageOverAlert = true
    }
}

extension UserCachedStatus {
    var lockTime: AutolockTimeout { // historically, it was saved as String
        get {
            guard let string = KeychainWrapper.keychain.string(forKey: Key.autoLockTime),
                let number = Int(string) else {
                return .always
            }
            return AutolockTimeout(rawValue: number)
        }
        set {
            KeychainWrapper.keychain.set("\(newValue.rawValue)", forKey: Key.autoLockTime)
        }
    }
}

extension UserCachedStatus: PinFailedCountCache {
    var pinFailedCount: Int {
        get {
            return getShared().integer(forKey: Key.lastPinFailedTimes)
        }
        set {
            setValue(newValue, forKey: Key.lastPinFailedTimes)
        }
    }
}

extension UserCachedStatus: AttachmentMetadataStrippingProtocol {
    var metadataStripping: AttachmentMetadataStripping {
        get {
            guard let string = KeychainWrapper.keychain.string(forKey: Key.metadataStripping),
                let mode = AttachmentMetadataStripping(rawValue: string) else {
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
            if getShared().object(forKey: Key.darkModeFlag) == nil {
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

extension UserCachedStatus: ContactCacheStatusProtocol {
    var contactsCached: Int {
        get {
            return getShared().integer(forKey: Key.isContactsCached)
        }
        set {
            getShared().setValue(newValue, forKey: Key.isContactsCached)
            getShared().synchronize()
        }
    }
}

#if !APP_EXTENSION
extension UserCachedStatus {
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
    var paymentMethods: [PaymentMethod]? {
        get {
            getShared().decodableValue(forKey: Key.paymentMethods)
        }
        set {
            getShared().setEncodableValue(newValue, forKey: Key.paymentMethods)
        }
    }
    /* TODO NOTE: this should be updated alongside Payments integration */
    var credits: Credits? {
        get { nil }
        set { }
    }

    var servicePlansDetails: [Plan]? {
        get {
            getShared().decodableValue(forKey: Key.servicePlans)
        }
        set {
            getShared().setEncodableValue(newValue, forKey: Key.servicePlans)
        }
    }

    var defaultPlanDetails: Plan? {
        get {
            getShared().decodableValue(forKey: Key.defaultPlanDetails)
        }
        set {
            getShared().setEncodableValue(newValue, forKey: Key.defaultPlanDetails)
        }
    }

    var currentSubscription: Subscription? {
        get {
            getShared().decodableValue(forKey: Key.currentSubscription)
        }
        set {
            getShared().setEncodableValue(newValue, forKey: Key.currentSubscription)
        }
    }
    
    var paymentsBackendStatusAcceptsIAP: Bool {
        get {
            return self.getShared().bool(forKey: Key.isIAPAvailableOnBE)
        }
        set {
            self.setValue(newValue, forKey: Key.isIAPAvailableOnBE)
        }
    }

}

extension UserCachedStatus: SwipeActionCacheProtocol {
    var leftToRightSwipeActionType: SwipeActionSettingType? {
        get {
            if let value = self.getShared().int(forKey: Key.leftToRightSwipeAction), let action = SwipeActionSettingType(rawValue: value) {
                return action
            } else {
                return nil
            }
        }
        set {
            self.setValue(newValue?.rawValue, forKey: Key.leftToRightSwipeAction)
        }
    }

    var rightToLeftSwipeActionType: SwipeActionSettingType? {
        get {
            if let value = self.getShared().int(forKey: Key.rightToLeftSwipeAction), let action = SwipeActionSettingType(rawValue: value) {
                return action
            } else {
                return nil
            }
        }
        set {
            self.setValue(newValue?.rawValue, forKey: Key.rightToLeftSwipeAction)
        }
    }

    func initialSwipeActionIfNeeded(leftToRight: Int, rightToLeft: Int) {
        if self.getShared().int(forKey: Key.leftToRightSwipeAction) == nil,
           let action = SwipeActionSettingType.convertFromServer(rawValue: leftToRight) {
            self.leftToRightSwipeActionType = action
        }

        if self.getShared().int(forKey: Key.rightToLeftSwipeAction) == nil,
           let action = SwipeActionSettingType.convertFromServer(rawValue: rightToLeft) {
            self.rightToLeftSwipeActionType = action
        }
    }
}

extension UserCachedStatus: WelcomeCarrouselCacheProtocol {
    var lastTourVersion: Int? {
        getShared().int(forKey: Key.lastTourVersion)
    }

    func resetTourValue() {
        setValue(Constants.App.TourVersion, forKey: Key.lastTourVersion)
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

extension UserCachedStatus: ToolbarCustomizationInfoBubbleViewStatusProvider {
    var shouldHideToolbarCustomizeInfoBubbleView: Bool {
        get {
            userDefaults.bool(forKey: Key.toolbarCustomizationInfoBubbleViewIsShown)
        }
        set {
            userDefaults.setValue(newValue, forKey: Key.toolbarCustomizationInfoBubbleViewIsShown)
            userDefaults.synchronize()
        }
    }
}

extension UserCachedStatus: ToolbarCustomizeSpotlightStatusProvider {
    var toolbarCustomizeSpotlightShownUserIds: [String] {
        get {
            (userDefaults.array(forKey: Key.toolbarCustomizeSpotlightShownUserIds) as? [String]) ?? []
        }
        set {
            userDefaults.setValue(newValue, forKey: Key.toolbarCustomizeSpotlightShownUserIds)
            userDefaults.synchronize()
        }
    }
}

#endif

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
        let rawData = getShared().dictionary(forKey: Key.UserWithLocalMobileSignature)
        return rawData?[userID] as? Data
    }

    func setEncryptedMobileSignature(userID: String, signatureData: Data) {
        var dataToSave: [String: Any] = [:]
        if var rawData = getShared().dictionary(forKey: Key.UserWithLocalMobileSignature) {
            rawData[userID] = signatureData
            dataToSave = rawData
        } else {
            dataToSave[userID] = signatureData
        }
        getShared().set(dataToSave, forKey: Key.UserWithLocalMobileSignature)
    }

    func removeEncryptedMobileSignature(userID: String) {
        if var signatureData = getShared().dictionary(forKey: Key.UserWithLocalMobileSignature) {
            signatureData.removeValue(forKey: userID)
            getShared().set(signatureData, forKey: Key.UserWithLocalMobileSignature)
        }
    }
}

extension UserCachedStatus: Service {}
