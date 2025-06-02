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

import InboxCore
import UserNotifications

enum NotificationAuthorizationRequestTrigger: CaseIterable {
    case onboardingFinished
    case messageSent
}

final class NotificationAuthorizationStore {
    private let userDefaults: UserDefaults
    private let userNotificationCenter: UserNotificationCenter

    init(
        userDefaults: UserDefaults,
        userNotificationCenter: UserNotificationCenter = UNUserNotificationCenter.current()
    ) {
        self.userDefaults = userDefaults
        self.userNotificationCenter = userNotificationCenter
    }

    func shouldRequestAuthorization(trigger: NotificationAuthorizationRequestTrigger) async -> Bool {
        let authorizationStatus = await userNotificationCenter.authorizationStatus()

        guard authorizationStatus == .notDetermined else {
            return false
        }

        let pastRequestDates = userDefaults[.notificationAuthorizationRequestDates]

        guard let mostRecentRequestDate = pastRequestDates.last else {
            return true
        }

        let requestedAtMostOnce = pastRequestDates.count < 2
        return trigger == .messageSent && requestedAtMostOnce && mostRecentRequestDate.isMoreThan(daysAgo: 20)
    }

    func userDidRespondToAuthorizationRequest(accepted: Bool) async {
        userDefaults[.notificationAuthorizationRequestDates].append(.now)

        if accepted {
            await requestNotificationAuthorization()
        }
    }

    private func requestNotificationAuthorization() async {
        do {
            _ = try await userNotificationCenter.requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            AppLogger.log(error: error, category: .notifications)
        }
    }
}

private extension Date {
    func isMoreThan(daysAgo: Int) -> Bool {
        self < Calendar.autoupdatingCurrent.date(byAdding: .day, value: -daysAgo, to: .now)!
    }
}
