//
//  UserInfo.swift
//  Proton Mail
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
import ProtonCoreDataModel

extension UserInfo {

    var isAutoLoadRemoteContentEnabled: Bool {
        hideRemoteImages == 0
    }

    var isAutoLoadEmbeddedImagesEnabled: Bool {
        hideEmbeddedImages == 0
    }

    var hasPaidMailPlan: Bool {
        guard
            let organizationRole = UserInfo.OrganizationRole(rawValue: role),
            organizationRole != .none
        else { return false }
        return subscribed.contains(.mail)
    }

    var isOnAStoragePaidPlan: Bool {
        return subscribed.contains(.mail)
        || subscribed.contains(.drive)
    }

    var hasCrashReportingEnabled: Bool { crashReports == 1 }

    func update(from userSettings: UserSettingsResponse) {
        self.notificationEmail = userSettings.email.value ?? ""
        self.notify = userSettings.email.notify
        self.passwordMode = userSettings.password.mode
        self.twoFactor = userSettings.twoFactorVerify.enabled
        self.weekStart = userSettings.weekStart
        self.telemetry = userSettings.telemetry
        self.crashReports = userSettings.crashReports
        self.referralProgram = .init(link: userSettings.referral.link, eligible: userSettings.referral.eligible)
    }

    func update(from mailSettings: NewMailSettingsResponse) {
        self.displayName = mailSettings.displayName
        self.defaultSignature = mailSettings.signature
        self.hideEmbeddedImages = mailSettings.hideEmbeddedImages
        self.hideRemoteImages = mailSettings.hideRemoteImages
        self.imageProxy = .init(rawValue: mailSettings.imageProxy)
        self.autoSaveContact = mailSettings.autoSaveContacts
        self.swipeLeft = mailSettings.swipeLeft
        self.swipeRight = mailSettings.swipeRight
        self.linkConfirmation = mailSettings.confirmLink == 0 ? .openAtWill : .confirmationAlert
        self.attachPublicKey = mailSettings.attachPublicKey
        self.sign = mailSettings.sign
        self.enableFolderColor = mailSettings.enableFolderColor
        self.inheritParentFolderColor = mailSettings.inheritParentFolderColor
        self.groupingMode = mailSettings.viewMode
        self.delaySendSeconds = mailSettings.delaySendSeconds
        self.conversationToolbarActions = .init(
            isCustom: mailSettings.mobileSettings.conversationToolbar.isCustom,
            actions: mailSettings.mobileSettings.conversationToolbar.actions
        )
        self.messageToolbarActions = .init(
            isCustom: mailSettings.mobileSettings.messageToolbar.isCustom,
            actions: mailSettings.mobileSettings.messageToolbar.actions
        )
        self.listToolbarActions = .init(
            isCustom: mailSettings.mobileSettings.listToolbar.isCustom,
            actions: mailSettings.mobileSettings.listToolbar.actions
        )
    }

    func update(from user: UserResponse) {
        self.accountRecovery = user.accountRecovery
        self.delinquent = user.delinquent
        self.maxSpace = Int64(user.maxSpace)
        self.maxUpload = Int64(user.maxUpload)
        self.role = user.role
        self.subscribed = User.Subscribed(rawValue: UInt8(user.subscribed))
        self.usedSpace = Int64(user.usedSpace)
        self.userId = user.id
        self.userKeys = user.keys.map({ keyResponse in
            Key(
                keyID: keyResponse.id,
                privateKey: keyResponse.privateKey,
                active: keyResponse.active,
                version: keyResponse.version,
                primary: keyResponse.primary
            )
        })
    }
}
