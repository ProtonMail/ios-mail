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

import Combine
import InboxCore
import InboxCoreUI
import LocalAuthentication
import proton_app_uniffi

class AppProtectionSelectionStore: StateStore {
    @Published var state: AppProtectionSelectionState
    private let router: Router<SettingsRoute>
    private let appSettingsRepository: AppSettingsRepository
    private let biometricAuthenticator: BiometricAuthenticator
    private let appProtectionConfigurator: AppProtectionConfigurator
    private let laContext: () -> LAContext

    init(
        state: AppProtectionSelectionState,
        router: Router<SettingsRoute>,
        appSettingsRepository: AppSettingsRepository = AppContext.shared.mailSession,
        appProtectionConfigurator: AppProtectionConfigurator,
        laContext: @Sendable @escaping () -> LAContext = { .init() }
    ) {
        self.state = state
        self.router = router
        self.appSettingsRepository = appSettingsRepository
        self.biometricAuthenticator = .init(method: .builtIn(laContext))
        self.appProtectionConfigurator = appProtectionConfigurator
        self.laContext = laContext
    }

    @MainActor
    func handle(action: AppProtectionSelectionAction) async {
        switch action {
        case .onAppear:
            await reloadProtectionData()
        case .selected(let selectedMethod):
            guard selectedMethod.appProtection != state.currentProtection else { return }
            switch selectedMethod {
            case .none:
                await disableProtection()
                await reloadProtectionData()
            case .pin:
                await setPINProtection()
            case .faceID, .touchID:
                await enableBiometricProtection()
                await reloadProtectionData()
            }
        case .pinScreenDismissed:
            state = state.copy(\.presentedPINScreen, to: nil)
            await reloadProtectionData()
        case .pinScreenPresented(let screenType):
            state = state.copy(\.presentedPINScreen, to: screenType)
        case .changePINTapped:
            state = state.copy(\.presentedPINScreen, to: .verify(reason: .changePIN))
        case .autoLockTapped:
            router.go(to: .autoLock)
        }
    }

    @MainActor
    private func reloadProtectionData() async {
        guard let settings = await currentAppSettings() else { return }
        let protection = settings.protection
        state = state.copy(\.availableAppProtectionMethods, to: availableAppProtectionMethods(selected: protection))
            .copy(\.currentProtection, to: protection)
            .copy(\.autoLock, to: settings.autoLock)
    }

    @MainActor
    private func disableProtection() async {
        switch state.currentProtection {
        case .biometrics:
            await disableBiometricProtection()
        case .pin:
            state = state.copy(\.presentedPINScreen, to: .verify(reason: .disablePIN))
        case .none:
            break
        }
    }

    @MainActor
    private func disableBiometricProtection() async {
        guard await biometricAuthDidSucceed() else { return }
        do {
            try await appProtectionConfigurator.unsetBiometricsAppProtection().get()
        } catch {
            AppLogger.log(error: error, category: .appSettings)
        }
    }

    @MainActor
    private func enableBiometricProtection() async {
        switch state.currentProtection {
        case .none:
            do {
                try await appProtectionConfigurator.setBiometricsAppProtection().get()
            } catch {
                AppLogger.log(error: error, category: .appSettings)
            }
        case .pin:
            state = state.copy(\.presentedPINScreen, to: .verify(reason: .changeToBiometry))
        case .biometrics:
            break
        }
    }

    @MainActor
    private func setPINProtection() async {
        switch state.currentProtection {
        case .none:
            state = state.copy(\.presentedPINScreen, to: .set(reason: .setNewPIN))
        case .biometrics:
            if await biometricAuthenticator.authenticate().isSuccess {
                state = state.copy(\.presentedPINScreen, to: .set(reason: .setNewPIN))
            }
        case .pin:
            break
        }
    }

    @MainActor
    private func currentAppSettings() async -> AppSettings? {
        do {
            return try await appSettingsRepository.getAppSettings().get()
        } catch {
            AppLogger.log(error: error, category: .appSettings)
            return nil
        }
    }

    @MainActor
    private func availableAppProtectionMethods(selected: AppProtection?) -> [AppProtectionMethodViewModel] {
        let availableMethods: [AppProtectionMethodViewModel.MethodType] =
            [.none, .pin] + [supportedBiometry()].compactMap { $0 }

        return availableMethods.map { type in
            .init(
                type: type,
                isSelected: type.appProtection == selected
            )
        }
    }

    @MainActor
    private func supportedBiometry() -> AppProtectionMethodViewModel.MethodType? {
        switch SupportedBiometry.configuredOnDevice(context: laContext()) {
        case .none:
            nil
        case .faceID:
            .faceID
        case .touchID:
            .touchID
        }
    }

    @MainActor
    private func biometricAuthDidSucceed() async -> Bool {
        await biometricAuthenticator.authenticate().isSuccess
    }
}
