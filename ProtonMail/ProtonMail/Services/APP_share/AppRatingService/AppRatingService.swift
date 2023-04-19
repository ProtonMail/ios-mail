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

import ProtonCore_Services

final class AppRatingService {
    private enum Threshold {
        static let inboxNavigation = 2
        static let inboxNavigationWhenSignedIn = 4
    }
    
    private var userSignedIn: Bool = false
    private var inboxNavigationCounter = 0
    private var isInboxNavigationConditionMet: Bool {
        if userSignedIn {
            return inboxNavigationCounter >= Threshold.inboxNavigationWhenSignedIn
        } else {
            return inboxNavigationCounter >= Threshold.inboxNavigation
        }
    }
    private let dependencies: Dependencies

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
        dependencies.notificationCenter.addObserver(
            self,
            selector: #selector(appLostFocus),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
    }

    /// Add events that determine whether to show the AppRating prompt or not. After relevant events the
    /// app rating will be evaluated and shown if conditions are met
    func preconditionEventDidOccur(_ event: AppRatingPreConditionEvent) {
        let evaluateShowingAppRating: Bool
        switch event {
        case .userSignIn:
            userSignedIn = true
            evaluateShowingAppRating = false
        case .inboxNavigation:
            inboxNavigationCounter += 1
            evaluateShowingAppRating = true
        }
        if evaluateShowingAppRating {
            promptAppRatingIfConditionsAreMet()
        }
    }

    private func promptAppRatingIfConditionsAreMet() {
        guard
            dependencies.internetStatus.currentStatus.isConnected,
            dependencies.appRatingStatusProvider.isAppRatingEnabled(),
            !dependencies.appRatingStatusProvider.hasAppRatingBeenShownInCurrentVersion(),
            isInboxNavigationConditionMet
        else {
            return
        }
        updateFeatureState()
        DispatchQueue.main.async {
            self.dependencies.appRating.requestAppRating()
        }
    }

    private func updateFeatureState() {
        dependencies.appRatingStatusProvider.setIsAppRatingEnabled(false)
        dependencies.appRatingStatusProvider.setAppRatingAsShownInCurrentVersion()
        let featureFlagKey: FeatureFlagKey = .appRating
        dependencies.featureFlagService.updateFeatureFlag(featureFlagKey, value: false) { result in
            if let error = result.error {
                /** Because there is an internet connection check before showing the rating prompt it's unlikely
                 the request fails for that reason. There is no need to do anything else if the update fails. Worse case
                 scenario the app would try to show the rating prompt again in the next app version,
                 but `SKStoreReviewController` won't show it if the user already has rated the app.
                 */
                let message = "Failed to update feature \(featureFlagKey.rawValue): \(error)"
                SystemLogger.log(message: message, isError: true)
            }
        }
    }

    @objc
    private func appLostFocus() {
        // whenever the app loses focus we restart counting (app goes to the background, multi-tasking, ...)
        inboxNavigationCounter = 0
        userSignedIn = false
    }
}

enum AppRatingPreConditionEvent {
    case userSignIn
    case inboxNavigation
}

extension AppRatingService {

    struct Dependencies {
        let featureFlagService: FeatureFlagsDownloadServiceProtocol
        let appRating: AppRatingWrapper
        let internetStatus: InternetConnectionStatusProviderProtocol
        let appRatingStatusProvider: AppRatingStatusProvider
        let notificationCenter: NotificationCenter

        init(
            featureFlagService: FeatureFlagsDownloadServiceProtocol,
            appRating: AppRatingWrapper,
            internetStatus: InternetConnectionStatusProviderProtocol = InternetConnectionStatusProvider(),
            appRatingPrompt: AppRatingStatusProvider = userCachedStatus,
            notificationCenter: NotificationCenter = .default
        ) {
            self.internetStatus = internetStatus
            self.appRating = appRating
            self.featureFlagService = featureFlagService
            self.appRatingStatusProvider = appRatingPrompt
            self.notificationCenter = notificationCenter
        }
    }
}
