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

@testable import ProtonMail
import InboxCore
import proton_app_uniffi
import SwiftUI
import Testing

@MainActor
class AppSettingsStateStoreTests {
    private lazy var sut = AppSettingsStateStore(
        state: .initial,
        appSettingsRepository: appSettingsRepositorySpy,
        customSettings: customSettingsSpy,
        notificationCenter: notificationCenterSpy,
        urlOpener: urlOpenerSpy,
        mainBundle: bundleStub
    )
    private let notificationCenterSpy = UserNotificationCenterSpy()
    private let urlOpenerSpy = URLOpenerSpy()
    private let bundleStub = BundleStub()
    private let appSettingsRepositorySpy = AppSettingsRepositorySpy()
    private let customSettingsSpy = CustomSettingsSpy()

    init() {
        bundleStub.preferredLocalizationsStub = ["en"]
    }

    // MARK: - `notificationButtonTapped` action

    @Test
    func whenNotificationsButtonIsTapped_ItAskForNotificationsPermissions() async {
        notificationCenterSpy.stubbedAuthorizationStatus = .notDetermined

        await sut.handle(action: .notificationButtonTapped)

        #expect(notificationCenterSpy.requestAuthorizationInvocations == [[.alert, .badge, .sound]])
        #expect(urlOpenerSpy.openURLInvocations.isEmpty)
    }

    @Test
    func whenNotificationsButtonIsTapped_ItOpensNativeSettings() async {
        notificationCenterSpy.stubbedAuthorizationStatus = .authorized

        await sut.handle(action: .notificationButtonTapped)

        #expect(notificationCenterSpy.requestAuthorizationInvocations.isEmpty)
        #expect(urlOpenerSpy.openURLInvocations == [.settings])
    }

    // MARK: - `onAppear` action

    @Test
    func whenViewAppears_ItOverrideDefaultStateValuesAndSetCorrectOnes() async {
        notificationCenterSpy.stubbedAuthorizationStatus = .authorized
        bundleStub.preferredLocalizationsStub = ["pl"]
        appSettingsRepositorySpy.stubbedAppSettings = .init(
            appearance: .lightMode,
            protection: .biometrics,
            autoLock: .minutes(15),
            useCombineContacts: true,
            useAlternativeRouting: true
        )
        customSettingsSpy.stubbedSwipeToAdjacent = .ok(true)

        await sut.handle(action: .onAppear)

        #expect(sut.state.areNotificationsEnabled)
        #expect(sut.state.appLanguage == "Polish")
        #expect(sut.state.storedAppSettings == appSettingsRepositorySpy.stubbedAppSettings)
        #expect(sut.state.isSwipeToAdjacentEmailEnabled == true)
    }

    // MARK: - `appearanceTapped` action

    @Test
    func whenAppearanceIsTapped_WhenAppearanceIsChnaged_ItUpdatesAppearance() async {
        #expect(sut.state.storedAppSettings.appearance == .system)
        #expect(sut.state.isAppearanceMenuShown == false)

        await sut.handle(action: .appearanceTapped)
        #expect(sut.state.isAppearanceMenuShown == true)

        await changeAppAppearance(.darkMode)

        #expect(sut.state.storedAppSettings.appearance == .darkMode)

        #expect(appSettingsRepositorySpy.changedAppSettingsWithDiff == [.diff(appearance: .darkMode)])
    }

    // MARK: - `alternativeRoutingChanged` action

    @Test
    func whenAlternativeRoutingIsDisabledAndThenEnabled_ItUpdatesStoredValues() async {
        #expect(sut.state.storedAppSettings.useAlternativeRouting == true)

        await changeAlternativeRoutingValue(false)

        #expect(
            appSettingsRepositorySpy.changedAppSettingsWithDiff == [
                .diff(useAlternativeRouting: false)
            ])
        #expect(sut.state.storedAppSettings.useAlternativeRouting == false)

        await changeAlternativeRoutingValue(true)

        #expect(
            appSettingsRepositorySpy.changedAppSettingsWithDiff == [
                .diff(useAlternativeRouting: false),
                .diff(useAlternativeRouting: true),
            ])
        #expect(sut.state.storedAppSettings.useAlternativeRouting == true)
    }

    @Test
    func whenCombinedContactsAreEnabledAndThenDisabled_ItUpdatesStoredValues() async {
        #expect(sut.state.storedAppSettings.useCombineContacts == false)

        await changeCombinedContactsValue(true)

        #expect(
            appSettingsRepositorySpy.changedAppSettingsWithDiff == [
                .diff(useCombineContacts: true)
            ])
        #expect(sut.state.storedAppSettings.useCombineContacts == true)

        await changeCombinedContactsValue(false)

        #expect(
            appSettingsRepositorySpy.changedAppSettingsWithDiff == [
                .diff(useCombineContacts: true),
                .diff(useCombineContacts: false),
            ])
        #expect(sut.state.storedAppSettings.useCombineContacts == false)
    }

    // MARK: - `swipeToNextEmailChanged` action

    @Test
    func whenSwipeToNextEmailChanged_AndSucceeds_ItUpdatesToGivenState() async {
        #expect(sut.state.isSwipeToAdjacentEmailEnabled == false)

        await sut.handle(action: .swipeToNextEmailChanged(true))

        #expect(sut.state.isSwipeToAdjacentEmailEnabled == true)

        await sut.handle(action: .swipeToNextEmailChanged(false))

        #expect(sut.state.isSwipeToAdjacentEmailEnabled == false)
    }

    @Test
    func whenSwipeToNextEmailChanged_AndFails_ItRevertsToPreviousState() async {
        #expect(sut.state.isSwipeToAdjacentEmailEnabled == false)

        customSettingsSpy.stubbedSwipeToAdjacent = .error(ProtonError.network)

        await sut.handle(action: .swipeToNextEmailChanged(true))

        #expect(sut.state.isSwipeToAdjacentEmailEnabled == false)
    }

    // MARK: - Private

    private func changeAppAppearance(_ appAppearance: AppAppearance) async {
        appSettingsRepositorySpy.stubbedAppSettings = appSettingsRepositorySpy.stubbedAppSettings
            .copy(\.appearance, to: appAppearance)
        await sut.handle(action: .appearanceSelected(.darkMode))
    }

    private func changeCombinedContactsValue(_ value: Bool) async {
        appSettingsRepositorySpy.stubbedAppSettings = appSettingsRepositorySpy.stubbedAppSettings
            .copy(\.useCombineContacts, to: value)
        await sut.handle(action: .combinedContactsChanged(value))
    }

    private func changeAlternativeRoutingValue(_ value: Bool) async {
        appSettingsRepositorySpy.stubbedAppSettings = appSettingsRepositorySpy.stubbedAppSettings
            .copy(\.useAlternativeRouting, to: value)
        await sut.handle(action: .alternativeRoutingChanged(value))
    }
}

extension AppSettings: @retroactive Copying {}

private extension AppSettingsDiff {

    static func diff(
        appearance: AppAppearance? = nil,
        useCombineContacts: Bool? = nil,
        useAlternativeRouting: Bool? = nil
    ) -> Self {
        .init(
            appearance: appearance,
            autoLock: nil,
            useCombineContacts: useCombineContacts,
            useAlternativeRouting: useAlternativeRouting
        )
    }

}
