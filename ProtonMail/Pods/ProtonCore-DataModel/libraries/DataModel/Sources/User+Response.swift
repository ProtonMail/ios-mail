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

extension UserInfo {
    /// Initializes the UserInfo with the response data
    public convenience init(response: [String: Any]) {
        var uKeys: [Key] = [Key]()
        if let user_keys = response["Keys"] as? [[String: Any]] {
            for key_res in user_keys {
                uKeys.append(Key.init(response: key_res))
            }
        }
        let userId = response["ID"] as? String
        let usedS = response["UsedSpace"] as? NSNumber
        let maxS = response["MaxSpace"] as? NSNumber
        let credit = response["Credit"] as? NSNumber
        let currency = response["Currency"] as? String
        let subscribed = response["Subscribed"] as? Int
        self.init(
            maxSpace: maxS?.int64Value,
            usedSpace: usedS?.int64Value,
            language: response["Language"] as? String,
            maxUpload: response["MaxUpload"] as? Int64,
            role: response["Role"] as? Int,
            delinquent: response["Delinquent"] as? Int,
            keys: uKeys,
            userId: userId,
            linkConfirmation: response["ConfirmLink"] as? Int,
            credit: credit?.intValue,
            currency: currency,
            subscribed: subscribed
        )
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
        }
    }
    
    public func parse(mailSettings: [String: Any]?) {
        if let settings = mailSettings {
            self.displayName = settings["DisplayName"] as? String ?? "'"
            self.defaultSignature = settings["Signature"] as? String ?? ""
            self.autoSaveContact  = settings["AutoSaveContacts"] as? Int ?? 0
            self.showImages = ShowImages(rawValue: settings["ShowImages"] as? Int ?? 0)
            self.swipeLeft = settings["SwipeLeft"] as? Int ?? 3
            self.swipeRight = settings["SwipeRight"] as? Int ?? 0
            self.linkConfirmation = settings["ConfirmLink"] as? Int == 0 ? .openAtWill : .confirmationAlert
            
            self.attachPublicKey = settings["AttachPublicKey"] as? Int ?? 0
            self.sign = settings["Sign"] as? Int ?? 0
            self.enableFolderColor = settings["EnableFolderColor"] as? Int ?? 0
            self.inheritParentFolderColor = settings["InheritParentFolderColor"] as? Int ?? 0
            self.groupingMode = settings["ViewMode"] as? Int ?? 0
            self.delaySendSeconds = settings["DelaySendSeconds"] as? Int ?? 10
        }
    }
}
