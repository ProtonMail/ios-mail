// Copyright (c) 2025 Proton Technologies AG
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

import SwiftUI
import proton_app_uniffi

@MainActor
final class RatingBooster {
    var requestReview: (() -> Void)?

    private let userSession: MailUserSessionProtocol
    private let clock: any Clock<Duration>

    private var mailboxViewCount = 0
    private var debouncingTask: Task<Bool, Never>?

    init(userSession: MailUserSessionProtocol, clock: any Clock<Duration> = ContinuousClock()) {
        self.userSession = userSession
        self.clock = clock
    }

    func feed(navigationPath: NavigationPath) async throws {
        guard
            await hasSpentSignificantTimeWithoutNewSignals(),
            navigationPath.isEmpty
        else {
            return
        }

        mailboxViewCount += 1

        if mailboxViewCount >= Constants.mailboxViewCountThreshold {
            try await requestReviewIfUserIsTargeted()
        }
    }

    private func hasSpentSignificantTimeWithoutNewSignals() async -> Bool {
        debouncingTask?.cancel()

        let task = Task {
            do {
                try await clock.sleep(for: Constants.debounceDuration)
                return true
            } catch {
                assert(error is CancellationError)
                return false
            }
        }

        debouncingTask = task
        return await task.value
    }

    private func requestReviewIfUserIsTargeted() async throws {
        guard try await userSession.isFeatureEnabled(featureId: LegacyFeatureFlag.ratingBooster).get() == true else {
            return
        }

        requestReview?()

        try await userSession.overrideUserFeatureFlag(flagName: LegacyFeatureFlag.ratingBooster, newValue: false).get()
    }
}

private extension RatingBooster {
    @MainActor
    enum Constants {
        static let debounceDuration = MailboxModel.estimatedBackNavigationDuration + .seconds(0.05)
        static let mailboxViewCountThreshold = 2
    }
}

enum LegacyFeatureFlag {
    static let ratingBooster = "RatingIOSMail"
}
