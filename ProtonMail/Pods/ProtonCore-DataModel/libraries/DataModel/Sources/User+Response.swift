//
//  User+Response.swift
//  ProtonCore-DataModel - Created on 17/03/2020.
//
//  Copyright (c) 2022 Proton Technologies AG
//
//  This file is part of Proton Technologies AG and ProtonCore.
//
//  ProtonCore is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonCore is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore.  If not, see <https://www.gnu.org/licenses/>.

import Foundation
import ProtonCoreLog

extension UserInfo {
    /// Initializes the UserInfo with the response data
    public convenience init(response: [String: Any]) {
        var uKeys: [Key] = [Key]()
        if let user_keys = response["Keys"] as? [[String: Any]] {
            for key_res in user_keys {
                uKeys.append(Key.init(response: key_res))
            }
        }
        let subscribed = response["Subscribed"] as? UInt8
        var lockedFlags: LockedFlags? = nil
        if let lockedFlagsRes = response["LockedFlags"] as? Int8 {
            lockedFlags = LockedFlags(rawValue: lockedFlagsRes)
        }
        
        self.init(
            maxSpace: response["MaxSpace"] as? Int64,
            maxBaseSpace: response["MaxBaseSpace"] as? Int64,
            maxDriveSpace: response["MaxDriveSpace"] as? Int64,
            usedSpace: response["UsedSpace"] as? Int64,
            usedBaseSpace: response["UsedBaseSpace"] as? Int64,
            usedDriveSpace: response["UsedDriveSpace"] as? Int64,
            language: response["Language"] as? String,
            maxUpload: response["MaxUpload"] as? Int64,
            role: response["Role"] as? Int,
            delinquent: response["Delinquent"] as? Int,
            keys: uKeys,
            userId: response["ID"] as? String,
            linkConfirmation: response["ConfirmLink"] as? Int,
            credit: response["Credit"] as? Int,
            currency: response["Currency"] as? String,
            createTime: response["CreateTime"] as? Int64,
            subscribed: subscribed.map(User.Subscribed.init(rawValue:)),
            accountRecovery: UserInfo.parse(accountRecovery: response["AccountRecovery"] as? [String: Any]),
            lockedFlags: lockedFlags
        )
    }

    // convenience function for parsing from [String: Any]?, needed by some clients
    private static func parse(accountRecovery: [String: Any]?) -> AccountRecovery? {
        guard let accountRecovery else { return nil }

        guard JSONSerialization.isValidJSONObject(accountRecovery as Any) else {
            PMLog.error("Account Recovery state from /users response is not a valid JSON object", sendToExternal: true)
            return nil
        }

        guard let data = try? JSONSerialization.data(withJSONObject: accountRecovery as Any) else {
            PMLog.error("Account Recovery state is not encodable", sendToExternal: true)
            return nil
        }
        let decodedResults = try? JSONDecoder.decapitalisingFirstLetter.decode(AccountRecovery.self, from: data)
        return decodedResults
    }

    public func parse(userSettings: [String: Any]?) {
        if let settings = userSettings {
            if let email = settings["Email"] as? [String: Any] {
                self.notificationEmail = email["Value"] as? String ?? ""
                self.notify = email["Notify"] as? Int ?? 0
            }

            if let pwdMode = settings["PasswordMode"] as? Int {
                self.passwordMode = pwdMode
            } else {
                if let pwd = settings["Password"] as? [String: Any] {
                    if let mode = pwd["Mode"] as? Int {
                        self.passwordMode = mode
                    }
                }
            }

            if let twoFA = settings["2FA"]  as? [String: Any] {
                self.twoFactor = twoFA["Enabled"] as? Int ?? 0
            }

            if let weekStart = settings["WeekStart"] as? Int {
                self.weekStart = weekStart
            }

            if let telemetry = settings["Telemetry"] as? Int {
                self.telemetry = telemetry
            }

            if let crashReports = settings["CrashReports"] as? Int {
                self.crashReports = crashReports
            }

            if let referralInfo = settings["Referral"] as? [String: Any],
               let link = referralInfo["Link"] as? String,
               let eligible = referralInfo["Eligible"] as? Bool {
                self.referralProgram = .init(link: link, eligible: eligible)
            }
        }
    }

    public func parse(mailSettings: [String: Any]?) {
        if let settings = mailSettings {
            self.displayName = settings["DisplayName"] as? String ?? "'"
            self.defaultSignature = settings["Signature"] as? String ?? ""
            self.hideEmbeddedImages = settings["HideEmbeddedImages"] as? Int ?? DefaultValue.hideEmbeddedImages
            self.hideRemoteImages = settings["HideRemoteImages"] as? Int ?? DefaultValue.hideRemoteImages
            self.imageProxy = ImageProxy(rawValue: settings["ImageProxy"] as? Int ?? DefaultValue.imageProxy.rawValue)
            self.autoSaveContact  = settings["AutoSaveContacts"] as? Int ?? 0
            self.swipeLeft = settings["SwipeLeft"] as? Int ?? 3
            self.swipeRight = settings["SwipeRight"] as? Int ?? 0
            self.linkConfirmation = settings["ConfirmLink"] as? Int == 0 ? .openAtWill : .confirmationAlert

            self.attachPublicKey = settings["AttachPublicKey"] as? Int ?? 0
            self.sign = settings["Sign"] as? Int ?? 0
            self.enableFolderColor = settings["EnableFolderColor"] as? Int ?? 0
            self.inheritParentFolderColor = settings["InheritParentFolderColor"] as? Int ?? 0
            self.groupingMode = settings["ViewMode"] as? Int ?? 0
            self.delaySendSeconds = settings["DelaySendSeconds"] as? Int ?? 10

            if let mobileSettings = settings["MobileSettings"] as? [String: Any] {
                self.conversationToolbarActions = ToolbarActions(rawValue: mobileSettings["ConversationToolbar"] as? [String: Any])
                self.messageToolbarActions = ToolbarActions(rawValue: mobileSettings["MessageToolbar"] as? [String: Any])
                self.listToolbarActions = ToolbarActions(rawValue: mobileSettings["ListToolbar"] as? [String: Any])
            }
        }
    }
}
