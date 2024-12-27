// Copyright (c) 2023 Proton Technologies AG
//
// This file is part of Proton Mail.
//
// Proton Mail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Mail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Mail. If not, see https://www.gnu.org/licenses/.

import CryptoKit
import ProtonCorePayments

extension UserDefaultsKeys {
    static let firstRunDate = plainKey(named: "firstRunDate", ofType: Date.self)

    static let notificationAuthorizationRequestDates = plainKey(
        named: "notificationAuthorizationRequestDates",
        defaultValue: [Date]()
    )

    static let lastBugReport = plainKey(named: "BugReportCache_LastBugReport", defaultValue: "")

    /// Keys need to take both UserID and LabelID into account; use `UserSpecificLabelKey.userDefaultsKey`.
    static let mailboxLastUpdateTimes = plainKey(named: "mailboxLastUpdateTimes", defaultValue: [String: Date]())

    static let referralProgramPromptWasShown = plainKey(named: "referralProgramPromptWasShown", defaultValue: false)

    /// It is used to check if the spotlight view should be shown for the user that has a
    /// standard toolbar action setting.
    static let toolbarCustomizeSpotlightShownUserIds = plainKey(
        named: "toolbarCustomizeSpotlightShownUserIds",
        defaultValue: [String]()
    )

    static let toolbarCustomizationInfoBubbleViewIsShown = plainKey(
        named: "toolbarCustomizationInfoBubbleViewIsShown",
        defaultValue: false
    )

    /// Dictionary of booleans with users who've dismissed the storage banner. e.g. ["user-id-1": true]
    static let usersWhoHaveSeenStorageBanner = plainKey(
        named: "usersWhoHaveSeenStorageBanner",
        defaultValue: [String: Bool]()
    )

    static let isMessageSwipeNavigationEnabled = plainKey(named: "isMessageSwipeNavigationEnabled", defaultValue: true)

    static let hasContactAutoSyncBannerShown = plainKey(named: "hasContactAutoSyncBannerShown", defaultValue: false)

    static let upsellButtonDismissalDatesPerUserID = plainKey(
        named: "upsellButtonDismissalDatesPerUserID",
        defaultValue: [String: Date]()
    )

    // MARK: payments

    static let currentSubscription = codableKey(named: "currentSubscription", ofType: Subscription.self)
    static let defaultPlanDetails = codableKey(named: "defaultPlanDetails", ofType: Plan.self)
    static let isIAPAvailableOnBE = plainKey(named: "isIAPAvailableOnBE", defaultValue: false)
    static let paymentMethods = codableKey(named: "paymentMethods", ofType: [PaymentMethod].self)
    static let servicePlans = codableKey(named: "servicePlans", ofType: [Plan].self)
}

struct UserSpecificLabelKey {
    let labelID: LabelID
    let userID: UserID

    var userDefaultsKey: String {
        SHA256
            .hash(data: Data("\(userID.rawValue):\(labelID.rawValue)".utf8))
            .compactMap { String(format: "%02x", $0) }
            .joined()
    }
}
