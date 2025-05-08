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
import proton_app_uniffi
import LocalAuthentication

class AppProtectionSelectionStore: StateStore {
    @Published var state: AppProtectionSelectionState
    private let router: Router<SettingsRoute>
    private let appSettingsRepository: AppSettingsRepository
    private let laContext: () -> LAContext

    init(
        state: AppProtectionSelectionState,
        router: Router<SettingsRoute>,
        appSettingsRepository: AppSettingsRepository = AppContext.shared.mailSession,
        laContext: @escaping () -> LAContext = { .init() }
    ) {
        self.state = state
        self.router = router
        self.appSettingsRepository = appSettingsRepository
        self.laContext = laContext
    }

    @MainActor
    func handle(action: AppProtectionSelectionAction) async {
        switch action {
        case .onAppear:
            let appProtection = await currentAppProtection()
            state = state.copy(\.availableAppProtectionMethods, to: availableAppProtectionMethods(selected: appProtection))
                .copy(\.selectedAppProtection, to: appProtection)
        case .selected(let selectedMethod):
            guard selectedMethod.appProtection != state.selectedAppProtection else { return }
            switch selectedMethod {
            case .none:
                break // FIXME: - To be added in the next MR
            case .pin:
                router.go(to: .setPIN)
            case .faceID, .touchID:
                break // FIXME: - To be added in the next MR
            }
        }
    }

    @MainActor
    private func currentAppProtection() async -> AppProtection? {
        do {
            return try await appSettingsRepository.getAppSettings().get().protection
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
        switch SupportedBiometry.onDevice(context: laContext()) {
        case .none:
            nil
        case .faceID:
            .faceID
        case .touchID:
            .touchID
        }
    }
}
