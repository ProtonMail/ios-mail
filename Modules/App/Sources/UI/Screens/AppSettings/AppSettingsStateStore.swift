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

final class AppSettingsStateStore: StateStore, Sendable {
    @Published var state: AppSettingsState
    private let notificationCenter: UserNotificationCenter
    private let urlOpener: URLOpener
    private let appLangaugeProvider: AppLangaugeProvider

    @MainActor
    init(
        state: AppSettingsState,
        notificationCenter: UserNotificationCenter = UNUserNotificationCenter.current(),
        urlOpener: URLOpener = UIApplication.shared,
        currentLocale: Locale = Locale.current,
        mainBundle: Bundle = Bundle.main
    ) {
        self.state = state
        self.notificationCenter = notificationCenter
        self.urlOpener = urlOpener
        self.appLangaugeProvider = .init(currentLocale: currentLocale, mainBundle: mainBundle)
    }

    @MainActor
    func handle(action: AppSettingsAction) async {
        switch action {
        case .notificationButtonTapped:
            await handleNotificationsFlow()
        case .languageButtonTapped:
            await openNativeAppSettings()
        case .enterForeground, .onLoad:
            await refreshDeviceSettings()
        }
    }

    // MARK: - Private

    @MainActor
    private func refreshDeviceSettings() async {
        let areNotificationsEnabled = await areNotificationsEnabled()
        state = state
            .copy(\.areNotificationsEnabled, to: areNotificationsEnabled)
            .copy(\.appLanguage, to: appLangaugeProvider.appLangauge)
    }

    private func handleNotificationsFlow() async {
        if await notificationCenter.authorizationStatus() == .notDetermined {
            await requestNotificationAuthorization()
            await refreshDeviceSettings()
        } else {
            await openNativeAppSettings()
        }
    }

    private func requestNotificationAuthorization() async {
        do {
            _ = try await notificationCenter.requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            AppLogger.log(error: error, category: .notifications)
        }
    }

    private func areNotificationsEnabled() async -> Bool {
        switch await notificationCenter.authorizationStatus() {
        case .authorized:
            true
        case .denied, .ephemeral, .notDetermined, .provisional:
            false
        @unknown default:
            fatalError()
        }
    }

    @MainActor
    private func openNativeAppSettings() async {
        await urlOpener.open(.settings, options: [:])
    }

}
