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
import LocalAuthentication
import SwiftUI

class BiometricLockStore: StateStore {
    @Published var state: BiometricLockState
    private let output: (BiometricLockScreenOutput) -> Void
    private let biometricAuthenticator: BiometricAuthenticator
    private let laContext: () -> LAContext

    init(
        state: BiometricLockState,
        method: BiometricAuthenticator.AuthenticationMethod,
        laContext: @escaping () -> LAContext = { LAContext() },
        output: @escaping (BiometricLockScreenOutput) -> Void
    ) {
        self.state = state
        self.biometricAuthenticator = .init(method: method)
        self.laContext = laContext
        self.output = output
    }

    @MainActor
    func handle(action: BiometricLockScreenAction) async {
        switch action {
        case .onLoad, .unlockTapped:
            let result = await biometricAuthenticator.authenticate()
            switch result {
            case .success:
                output(.authenticated)
            case .failure(let policyUnavailable):
                state =
                    state
                    .copy(\.displayUnlockButton, to: true)
                    .copy(\.alert, to: policyUnavailable ? policyUnavailableAlert : nil)
            }
        }
    }

    @MainActor
    private func handle(alertAction: PolicyUnavailableAlertAction) async {
        switch alertAction {
        case .ok:
            break
        case .signInAgain:
            output(.logOut)
        }
        state = state.copy(\.alert, to: nil)
    }

    private var policyUnavailableAlert: AlertModel {
        AlertModel.policyUnavailableAlert(
            action: { [weak self] action in await self?.handle(alertAction: action) },
            laContext: laContext
        )
    }
}
