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

import proton_app_uniffi
import InboxCore
import InboxCoreUI
import SwiftUI

final class AppSettingsStateStore: StateStore, Sendable {
    @Published var state: AppSettingsState
    private let appSettingsRepository: AppSettingsRepository
    private let notificationCenter: UserNotificationCenter
    private let urlOpener: URLOpener
    private let appLangaugeProvider: AppLangaugeProvider

    init(
        state: AppSettingsState,
        appSettingsRepository: AppSettingsRepository,
        notificationCenter: UserNotificationCenter = UNUserNotificationCenter.current(),
        urlOpener: URLOpener = UIApplication.shared,
        currentLocale: Locale = Locale.current,
        mainBundle: Bundle = Bundle.main
    ) {
        self.state = state
        self.appSettingsRepository = appSettingsRepository
        self.notificationCenter = notificationCenter
        self.urlOpener = urlOpener
        self.appLangaugeProvider = .init(currentLocale: currentLocale, mainBundle: mainBundle)
    }

    func handle(action: AppSettingsAction) async {
        switch action {
        case .notificationButtonTapped:
            await handleNotificationsFlow()
        case .languageButtonTapped:
            await openNativeAppSettings()
        case .onAppear:
            await refreshStoredAppSettings()
            await refreshDeviceSettings()
            await refreshCustomSettings()
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
        }
    }

    func presentUpsellScreen(presenter: UpsellScreenPresenter) async throws {
        let upsellScreenModel = try await presenter.presentUpsellScreen(entryPoint: .mobileSignature)
        state = state.copy(\.presentedUpsell, to: upsellScreenModel)
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

    private func refreshDeviceSettings() async {
        let areNotificationsEnabled = await areNotificationsEnabled()
        state =
            state
            .copy(\.areNotificationsEnabled, to: areNotificationsEnabled)
            .copy(\.appLanguage, to: appLangaugeProvider.appLangauge)
    }

    private func refreshStoredAppSettings() async {
        do {
            let settings = try await appSettingsRepository.getAppSettings().get()
            state = state.copy(\.storedAppSettings, to: settings)
        } catch {
            AppLogger.log(error: error, category: .appSettings)
        }
    }

    private func refreshCustomSettings() async {
        guard let userSession = AppContext.shared.sessionState.userSession else {
            return
        }

        let customSettings = customSettings(ctx: userSession)

        do {
            let mobileSignature = try await customSettings.mobileSignature().get()
            state = state.copy(\.mobileSignatureStatus, to: mobileSignature.status)
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
