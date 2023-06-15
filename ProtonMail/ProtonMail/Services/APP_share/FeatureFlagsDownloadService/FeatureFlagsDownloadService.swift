// Copyright (c) 2021 Proton AG
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

enum FeatureFlagKey: String, CaseIterable {
    case appRating = "RatingIOSMail"
    case sendRefactor = "SendMessageRefactor"
    case inAppFeedback = "InAppFeedbackIOS"
    case scheduleSend = "ScheduledSendFreemium"
    case senderImage = "ShowSenderImages"
    case referralPrompt = "ReferralActionSheetShouldBePresentedIOS"
}

// sourcery: mock
protocol FeatureFlagsSubscribeProtocol: AnyObject {
    func handleNewFeatureFlags(_ featureFlags: SupportedFeatureFlags)
}

// sourcery: mock
protocol FeatureFlagsDownloadServiceProtocol {
    func updateFeatureFlag(_ key: FeatureFlagKey, value: Any, completion: @escaping (Error?) -> Void)
}

/// This class is used to download the feature flags from the BE and send the flags to the subscribed objects.
class FeatureFlagsDownloadService: FeatureFlagsDownloadServiceProtocol {
    private let cache: FeatureFlagCache
    private let userID: UserID
    private let apiService: APIService
    private let sessionID: String
    private let subscribersTable: NSHashTable<AnyObject> = NSHashTable.weakObjects()
    var subscribers: [FeatureFlagsSubscribeProtocol] {
        subscribersTable.allObjects.compactMap { $0 as? FeatureFlagsSubscribeProtocol }
    }
    private(set) var lastFetchingTime: Date?
    private let appRatingStatusProvider: AppRatingStatusProvider
    private let userIntroductionProgressProvider: UserIntroductionProgressProvider

    init(
        cache: FeatureFlagCache,
        userID: UserID,
        apiService: APIService,
        sessionID: String,
        appRatingStatusProvider: AppRatingStatusProvider,
        userIntroductionProgressProvider: UserIntroductionProgressProvider
    ) {
        self.cache = cache
        self.userID = userID
        self.apiService = apiService
        self.sessionID = sessionID
        self.appRatingStatusProvider = appRatingStatusProvider
        self.userIntroductionProgressProvider = userIntroductionProgressProvider
    }

    func register(newSubscriber: FeatureFlagsSubscribeProtocol) {
        subscribersTable.add(newSubscriber)
    }

    enum FeatureFlagFetchingError: Error {
        case fetchingTooOften
        case selfIsReleased
    }

    func getFeatureFlags(completion: ((Error?) -> Void)?) {
        if let time = self.lastFetchingTime,
            Date().timeIntervalSince1970 - time.timeIntervalSince1970 > 300.0 {
            completion?(FeatureFlagFetchingError.fetchingTooOften)
            return
        }

        let request = FetchFeatureFlagsRequest()
        apiService.perform(request: request, response: FeatureFlagsResponse()) { [weak self] task, response in
            guard let self = self else {
                completion?(FeatureFlagFetchingError.selfIsReleased)
                return
            }
            if let error = task?.error {
                completion?(error)
                return
            }

            self.lastFetchingTime = Date()

            let supportedFeatureFlags = SupportedFeatureFlags(response: response)

            self.subscribers.forEach { $0.handleNewFeatureFlags(supportedFeatureFlags) }

            let isScheduleSendEnabledAfterUpdate = supportedFeatureFlags[.scheduleSend]
            let wasScheduleSendEnabledBeforeUpdate = self.cache.featureFlags(for: self.userID)[.scheduleSend]

                if isScheduleSendEnabledAfterUpdate && !wasScheduleSendEnabledBeforeUpdate {
                    // We need to reset spotlight when transitioning from expicitly disabled to enabled.
                    // However, we should not do it if the feature state was not set at all,
                    // which is the case right after sign in.
                    self.userIntroductionProgressProvider.markSpotlight(
                        for: .scheduledSend,
                        asSeen: false,
                        byUserWith: self.userID
                    )
                }

            let appRatingStatus = supportedFeatureFlags[.appRating]
                self.appRatingStatusProvider.setIsAppRatingEnabled(appRatingStatus)

            self.cache.storeFeatureFlags(supportedFeatureFlags, for: self.userID)

            completion?(nil)
        }
    }

    func updateFeatureFlag(_ key: FeatureFlagKey, value: Any, completion: @escaping (Error?) -> Void) {
        let request = UpdateFeatureFlagsRequest(featureFlagName: key.rawValue, value: value)
        apiService.perform(
            request: request,
            callCompletionBlockUsing: .immediateExecutor
        ) { task, _ in
            completion(task?.error)
        }
    }

    #if DEBUG
    func setLastFetchedTime(date: Date) {
        self.lastFetchingTime = date
    }
    #endif
}
