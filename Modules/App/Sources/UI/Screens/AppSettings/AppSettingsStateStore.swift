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
import InboxCoreUI
import SwiftUI
import proton_app_uniffi

final class AppSettingsStateStore: StateStore, Sendable {
    @Published var state: AppSettingsState
    private let appSettingsRepository: AppSettingsRepository
    private let customSettings: CustomSettingsProtocol
    private let notificationCenter: UserNotificationCenter
    private let urlOpener: URLOpener
    private let appLangaugeProvider: AppLangaugeProvider
    private let appIconConfigurator: AppIconConfigurable

    init(
        state: AppSettingsState,
        appSettingsRepository: AppSettingsRepository,
        customSettings: CustomSettingsProtocol,
        notificationCenter: UserNotificationCenter = UNUserNotificationCenter.current(),
        urlOpener: URLOpener = UIApplication.shared,
        appIconConfigurator: AppIconConfigurable,
        currentLocale: Locale = Locale.current,
        mainBundle: Bundle = Bundle.main
    ) {
        self.state = state
        self.appSettingsRepository = appSettingsRepository
        self.customSettings = customSettings
        self.notificationCenter = notificationCenter
        self.urlOpener = urlOpener
        self.appIconConfigurator = appIconConfigurator
        self.appLangaugeProvider = .init(currentLocale: currentLocale, mainBundle: mainBundle)
    }

    func handle(action: AppSettingsAction) async {
        switch action {
        case .notificationButtonTapped:
            await handleNotificationsFlow()
        case .languageButtonTapped:
            await openNativeAppSettings()
        case .onAppear:
            await refreshAllSettings()
        case .enterForeground:
            await refreshDeviceSettings()
        case .appearanceTapped:
            state = state.copy(\.isAppearanceMenuShown, to: true)
        case .appearanceSelected(let appearance):
            await update(setting: \.appearance, value: appearance)
        case .combinedContactsChanged(let value):
            await update(setting: \.useCombineContacts, value: value)
        case .alternativeRoutingChanged(let value):
            await update(setting: \.useAlternativeRouting, value: value)
        case .swipeToAdjacentConversationChanged(let value):
            _ = await customSettings.setSwipeToAdjacentConversation(enabled: value)
            await refreshSwipeToAdjacentSettings()
        case .appIconSelected(let appIcon):
            await updateAppIcon(appIcon)
        }
    }

    func updateAppIcon(_ icon: AppIcon) async {
        guard appIconConfigurator.supportsAlternateIcons else {
            return
        }

        try? await appIconConfigurator.setAlternateIconName(icon.alternateIconName)
        state = state.copy(\.appIcon, to: AppIcon(rawValue: icon.alternateIconName))
    }

    // MARK: - Private

    private func update<Value>(setting: WritableKeyPath<AppSettingsDiff, Value>, value: Value) async {
        var settingsDiff = AppSettingsDiff(
            appearance: nil,
            autoLock: nil,
            useCombineContacts: nil,
            useAlternativeRouting: nil
        )
        settingsDiff[keyPath: setting] = value
        do {
            try await appSettingsRepository.changeAppSettings(settings: settingsDiff).get()
        } catch {
            AppLogger.log(error: error, category: .appSettings)
        }
        await refreshStoredAppSettings()
    }

    private func refreshAllSettings() async {
        async let getAppSettings = appSettingsRepository.getAppSettings().get()
        async let getAreNotificationsEnabled = areNotificationsEnabled()
        async let getSwipeToAdjacentConversation = customSettings.swipeToAdjacentConversation().get()

        do {
            let (appSettings, areNotificationsEnabled, isSwipeToAdjacentEnabled) = try await (
                getAppSettings,
                getAreNotificationsEnabled,
                getSwipeToAdjacentConversation
            )

            state =
                state
                .copy(\.storedAppSettings, to: appSettings)
                .copy(\.areNotificationsEnabled, to: areNotificationsEnabled)
                .copy(\.appLanguage, to: appLangaugeProvider.appLangauge)
                .copy(\.isSwipeToAdjacentConversationEnabled, to: isSwipeToAdjacentEnabled)
        } catch {
            AppLogger.log(error: error, category: .appSettings)
        }
    }

    private func refreshStoredAppSettings() async {
        do {
            let settings = try await appSettingsRepository.getAppSettings().get()
            state = state.copy(\.storedAppSettings, to: settings)
        } catch {
            AppLogger.log(error: error, category: .appSettings)
        }
    }

    private func refreshDeviceSettings() async {
        let areNotificationsEnabled = await areNotificationsEnabled()
        state =
            state
            .copy(\.areNotificationsEnabled, to: areNotificationsEnabled)
            .copy(\.appLanguage, to: appLangaugeProvider.appLangauge)
    }

    func refreshSwipeToAdjacentSettings() async {
        do {
            let isSwipeToAdjacentEmailEnabled = try await customSettings.swipeToAdjacentConversation().get()
            state = state.copy(\.isSwipeToAdjacentConversationEnabled, to: isSwipeToAdjacentEmailEnabled)
        } catch {
            AppLogger.log(error: error, category: .appSettings)
        }
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
            AppLogger.log(error: error, category: .appSettings)
        }
    }

    private func areNotificationsEnabled() async -> Bool {
        switch await notificationCenter.authorizationStatus() {
        case .authorized:
            true
        case .denied, .ephemeral, .notDetermined, .provisional:
            false
        @unknown default:
            false
        }
    }

    private func openNativeAppSettings() async {
        await urlOpener.open(.settings, options: [:])
    }
}
