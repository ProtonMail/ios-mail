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

import Foundation
import ProtonCoreDataModel
import UIKit

final class ReferralProgramPromptPresenter {
    typealias Dependencies = HasUserDefaults

    private enum Threshold {
        static let inboxNavigation = 3
    }

    private let userID: UserID
    private let referralProgram: ReferralProgram
    private let featureFlagCache: FeatureFlagCache
    private let featureFlagService: FeatureFlagsDownloadServiceProtocol
    private let dependencies: Dependencies
    private var inboxNavigationCounter = 0
    private var isInboxNavigationConditionMet: Bool {
        return inboxNavigationCounter >= Threshold.inboxNavigation
    }

    init(userID: UserID,
         referralProgram: ReferralProgram,
         featureFlagCache: FeatureFlagCache,
         featureFlagService: FeatureFlagsDownloadServiceProtocol,
         notificationCenter: NotificationCenter = .default,
         dependencies: Dependencies,
         firstRunDate: Date = Date()) {
        self.userID = userID
        self.referralProgram = referralProgram
        self.featureFlagCache = featureFlagCache
        self.featureFlagService = featureFlagService
        self.dependencies = dependencies
        if dependencies.userDefaults[.firstRunDate] == nil {
            dependencies.userDefaults[.firstRunDate] = firstRunDate
        }
        notificationCenter.addObserver(
            self,
            selector: #selector(appLostFocus),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
    }

    func didShowMailbox() {
        inboxNavigationCounter += 1
    }

    @objc
    private func appLostFocus() {
        // whenever the app loses focus we restart counting (app goes to the background, multi-tasking, ...)
        inboxNavigationCounter = 0
    }

    func shouldShowReferralProgramPrompt() -> Bool {
        !dependencies.userDefaults[.referralProgramPromptWasShown] &&
        isInboxNavigationConditionMet &&
        referralProgram.eligible &&
        featureFlagCache.isFeatureFlag(.referralPrompt, enabledForUserWithID: userID) &&
        isDateMoreThan30DaysInThePast(dependencies.userDefaults[.firstRunDate])
    }

    func promptWasShown() {
        dependencies.userDefaults[.referralProgramPromptWasShown] = true
        updateFeatureState()
    }

    private func updateFeatureState() {
        featureFlagService.updateFeatureFlag(FeatureFlagKey.referralPrompt, value: false) { error in
            if let error {
                // We don't enqueue it or handle the offline state since it's low risk,
                // at worst, it will be shown again a month later,
                // or when we update the `referralProgramPromptWasShown` field
                let message = "Failed to update referral program prompt feature flag: \(error)"
                SystemLogger.log(message: message, isError: true)
            }
        }
    }

    private func isDateMoreThan30DaysInThePast(_ date: Date?) -> Bool {
        guard let date else { return false }
        let today = LocaleEnvironment.currentDate()
        return date.add(.day, value: 30)?.compare(today) != .orderedDescending
    }
}
