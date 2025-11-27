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
import SwiftUI
import proton_app_uniffi

final class UserAnalyticsConfigurator: Sendable, ObservableObject {
    private let mailUserSession: MailUserSessionProtocol
    private let analytics: Analytics

    private var userSettingsWatchHandle: WatchHandle?

    init(
        mailUserSession: MailUserSessionProtocol,
        analytics: Analytics
    ) {
        self.mailUserSession = mailUserSession
        self.analytics = analytics
    }

    func observeUserAnalyticsSettings() async {
        setUpUserSettingsObservation()
        await readUserSettingsAndConfigureAnalytics()
    }

    private func setUpUserSettingsObservation() {
        let callback = AsyncLiveQueryCallbackWrapper(callback: { [weak self] in
            await self?.readUserSettingsAndConfigureAnalytics()
        })
        do {
            userSettingsWatchHandle = try mailUserSession.watchUserSettings(callback: callback).get()
        } catch {
            AppLogger.log(error: error, category: .sentryConfiguration)
        }
    }

    private func readUserSettingsAndConfigureAnalytics() async {
        do {
            let userSettings = try await mailUserSession.userSettings().get()
            let shouldAnalyticsBeEnabled = userSettings.telemetry || userSettings.crashReports
            if shouldAnalyticsBeEnabled {
                await analytics.enable(
                    configuration: .init(
                        crashReports: userSettings.crashReports,
                        telemetry: userSettings.telemetry
                    ))
            } else {
                await analytics.disable()
            }
        } catch {
            AppLogger.log(error: error, category: .sentryConfiguration)
        }
    }
}
