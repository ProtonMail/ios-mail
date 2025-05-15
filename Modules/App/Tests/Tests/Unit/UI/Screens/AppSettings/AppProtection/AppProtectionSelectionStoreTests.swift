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
import Testing

@MainActor
final class AppProtectionSelectionStoreTests {
    private let laContextSpy = LAContextSpy()
    private let router = Router<SettingsRoute>()
    private let appProtectionConfiguratorSpy = AppProtectionConfiguratorSpy()
    private lazy var appSettingsRepositorySpy = AppSettingsRepositorySpy()
    private lazy var sut = AppProtectionSelectionStore(
        state: .initial,
        router: router,
        appSettingsRepository: appSettingsRepositorySpy,
        appProtectionConfigurator: appProtectionConfiguratorSpy,
        laContext: { [unowned self] in self.laContextSpy }
    )

    @Test
    func viewAppears_ItLoadsSupportedProtectionTypes() async {
        await sut.handle(action: .onAppear)
        #expect(
            sut.state.availableAppProtectionMethods == [
                .init(type: .none, isSelected: false),
                .init(type: .pin, isSelected: true),
                .init(type: .faceID, isSelected: false),
            ]
        )
        #expect(sut.state.currentProtection == .pin)
    }

    @Test
    func protectionIsBiometricAndPINOptionIsSelected_ItTriggersSetPINFlow() async {
        appSettingsRepositorySpy.stubbedAppSettings = appSettingsRepositorySpy.stubbedAppSettings
            .copy(\.protection, to: .biometrics)

        await sut.handle(action: .onAppear)
        await sut.handle(action: .selected(.pin))

        #expect(sut.state.presentedPINScreen == .set)
    }

    @Test
    func protectionIsPINAndPINOptionIsSelected_ItDoesNotTriggerSetPINFlow() async {
        await sut.handle(action: .onAppear)
        await sut.handle(action: .selected(.pin))

        #expect(router.stack == [])
    }

    @Test
    func protectionIsNonAndPINIsSelected_ItTriggersSetPINFlow() async {
        appSettingsRepositorySpy.stubbedAppSettings = appSettingsRepositorySpy.stubbedAppSettings
            .copy(\.protection, to: .none)

        await sut.handle(action: .onAppear)
        await sut.handle(action: .selected(.pin))

        #expect(sut.state.presentedPINScreen == .set)
    }

    @Test
    func protectionIsNonAndFaceIDIsSelected_ItEnablesBiometryProtection() async {
        appSettingsRepositorySpy.stubbedAppSettings = appSettingsRepositorySpy.stubbedAppSettings
            .copy(\.protection, to: .none)

        await sut.handle(action: .onAppear)
        await sut.handle(action: .selected(.faceID))

        #expect(appProtectionConfiguratorSpy.setBiometricsAppProtectionInvokeCount == 1)
    }

    @Test
    func protectionIsBiometricsAndNoneIsSelected_ItDisablesBiometryProtection() async {
        appSettingsRepositorySpy.stubbedAppSettings = appSettingsRepositorySpy.stubbedAppSettings
            .copy(\.protection, to: .biometrics)

        await sut.handle(action: .onAppear)
        await sut.handle(action: .selected(.none))

        #expect(laContextSpy.evaluatePolicyCalls.count == 1)
        #expect(appProtectionConfiguratorSpy.unsetBiometricsAppProtectionInvokeCount == 1)
    }

    @Test
    func protectionIsPINAndNoneIsSelected_ItPresentsPINVerificationScreen() async {
        appSettingsRepositorySpy.stubbedAppSettings = appSettingsRepositorySpy.stubbedAppSettings
            .copy(\.protection, to: .pin)

        await sut.handle(action: .onAppear)
        await sut.handle(action: .selected(.none))

        #expect(sut.state.presentedPINScreen == .verify(reason: .disablePIN))
    }

    @Test
    func protectionIsPINAndFaceIDIsSelected_ItPresentsPINVerificationScreen() async {
        appSettingsRepositorySpy.stubbedAppSettings = appSettingsRepositorySpy.stubbedAppSettings
            .copy(\.protection, to: .pin)

        await sut.handle(action: .onAppear)
        await sut.handle(action: .selected(.faceID))

        #expect(sut.state.presentedPINScreen == .verify(reason: .changeToBiometry))
    }

    @Test
    func pinScreenIsPresented_PINIsDisabledAndPINScreenIsDismissed_ItReloadsData() async {
        appSettingsRepositorySpy.stubbedAppSettings = appSettingsRepositorySpy.stubbedAppSettings
            .copy(\.protection, to: .pin)

        await sut.handle(action: .onAppear)

        appSettingsRepositorySpy.stubbedAppSettings = appSettingsRepositorySpy.stubbedAppSettings
            .copy(\.protection, to: .none)

        await sut.handle(action: .pinScreenPresentationChanged(presentedPINScreen: nil))

        #expect(sut.state.currentProtection == .none)
    }

    @Test
    func changePINButtonIsTapped_ItPresentsPINVerifyScreen() async {
        await sut.handle(action: .changePINTapped)

        #expect(sut.state.presentedPINScreen == .verify(reason: .changePIN))
    }
}
