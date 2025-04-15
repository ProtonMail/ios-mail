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

class AppProtectionSelectionStore: StateStore {
    @Published var state: AppProtectionSelectionState

    init(state: AppProtectionSelectionState) {
        self.state = state
    }

    func handle(action: AppProtectionSelectionAction) async {
        switch action {
        case .viewLoaded:
            state = state
                .copy(
                    \.availableAppProtectionMethods,
                     to: availableAppProtectionMethods(selected: state.selectedAppProtection)
                )
        case .selected(let selectedMethod):
            state = state
                .copy(\.selectedAppProtection, to: selectedMethod.appProtection)
                .copy(
                    \.availableAppProtectionMethods,
                     to: availableAppProtectionMethods(selected: selectedMethod.appProtection)
                )
        }
    }

    private func availableAppProtectionMethods(selected: AppProtection) -> [AppProtectionMethodViewModel] {
        let availableMethods: [AppProtectionMethodViewModel.MethodType] =
            [.none, .pin] + [supportedBiometry()].compactMap { $0 }

        return availableMethods.map { type in
            .init(
                type: type,
                isSelected: type.appProtection == selected
            )
        }
    }

    private func supportedBiometry() -> AppProtectionMethodViewModel.MethodType? {
        switch SupportedBiometry.onDevice {
        case .none:
            nil
        case .faceID:
            .faceID
        case .touchID:
            .touchID
        }
    }
}
