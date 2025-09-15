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
    var sut: AppSettingsStateStore!
    var notificationCenterSpy: UserNotificationCenterSpy!
    var urlOpenerSpy: URLOpenerSpy!
    var bundleStub: BundleStub!
    private var appSettingsRepositorySpy: AppSettingsRepositorySpy!
    private var appIconConfiguratorSpy = AppIconConfiguratorSpy()

    init() {
        notificationCenterSpy = .init()
        urlOpenerSpy = .init()
        bundleStub = .init()
        appSettingsRepositorySpy = .init()
        appIconConfiguratorSpy = .init()
        sut = AppSettingsStateStore(
            state: .initial,
            appSettingsRepository: appSettingsRepositorySpy,
            notificationCenter: notificationCenterSpy,
            urlOpener: urlOpenerSpy,
            appIconConfigurator: appIconConfiguratorSpy,
            mainBundle: bundleStub
        )

        bundleStub.preferredLocalizationsStub = ["en"]
    }

    deinit {
        notificationCenterSpy = nil
        urlOpenerSpy = nil
        bundleStub = nil
        appSettingsRepositorySpy = nil
        sut = nil
    }

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

        await sut.handle(action: .onAppear)

        #expect(sut.state.areNotificationsEnabled)
        #expect(sut.state.appLanguage == "Polish")
        #expect(sut.state.storedAppSettings == appSettingsRepositorySpy.stubbedAppSettings)
    }

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

    // MARK: - appIconSelected action

    @Test
    func changeIconFromDefaultToCalculator() async throws {
        setUpSUT(with: .default)

        await sut.handle(action: .appIconSelected(.calculator))

        #expect(sut.state == AppSettingsState.initial.copy(\.appIcon, to: .calculator))
        #expect(appIconConfiguratorSpy.setAlternateIconNameCalls == [AppIcon.calculator.alternateIconName])
    }

    @Test
    func changeIconFromCalculatorToNotes() async throws {
        setUpSUT(with: .calculator)

        await sut.handle(action: .appIconSelected(.notes))

        #expect(sut.state == AppSettingsState.initial.copy(\.appIcon, to: .notes))
        #expect(appIconConfiguratorSpy.setAlternateIconNameCalls == [AppIcon.notes.alternateIconName])
    }

    @Test
    func changeIconFromCalculatorToDefault() async throws {
        setUpSUT(with: .calculator)

        await sut.handle(action: .appIconSelected(.default))

        #expect(sut.state == AppSettingsState.initial.copy(\.appIcon, to: .default))
        #expect(appIconConfiguratorSpy.setAlternateIconNameCalls == [AppIcon.default.alternateIconName])
    }

    // MARK: - Private

    private func setUpSUT(with appIcon: AppIcon) {
        sut = AppSettingsStateStore(
            state: .initial.copy(\.appIcon, to: appIcon),
            appSettingsRepository: appSettingsRepositorySpy,
            notificationCenter: notificationCenterSpy,
            urlOpener: urlOpenerSpy,
            appIconConfigurator: appIconConfiguratorSpy,
            mainBundle: bundleStub
        )
    }

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

private class AppIconConfiguratorSpy: AppIconConfigurable {
    private(set) var setAlternateIconNameCalls: [String?] = []

    // MARK: - AppIconConfigurable

    var supportsAlternateIcons: Bool { true }

    func setAlternateIconName(_ alternateIconName: String?) async throws {
        setAlternateIconNameCalls.append(alternateIconName)
    }
}
