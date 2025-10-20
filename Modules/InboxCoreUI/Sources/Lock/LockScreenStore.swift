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

class LockScreenStore: StateStore {
    @Published var state: LockScreenState
    private let pinVerifier: PINVerifier
    private let biometricAuthorizationNotifier: BiometricAuthorizationNotifier
    private let signOutService: SignOutService
    private let dismissLock: () -> Void

    init(
        state: LockScreenState,
        pinVerifier: PINVerifier,
        biometricAuthorizationNotifier: BiometricAuthorizationNotifier,
        signOutService: SignOutService,
        dismissLock: @escaping () -> Void
    ) {
        self.state = state
        self.pinVerifier = pinVerifier
        self.signOutService = signOutService
        self.biometricAuthorizationNotifier = biometricAuthorizationNotifier
        self.dismissLock = dismissLock
    }

    func handle(action: LockScreenAction) async {
        switch action {
        case .biometric(let output):
            switch output {
            case .authenticated:
                biometricAuthorizationNotifier.biometricsCheckPassed()
                dismissLock()
            case .logOut:
                await signOutAllAccounts()
            }
        case .pin(let output):
            switch output {
            case .logOut:
                await signOutAllAccounts()
            case .pin(let pin):
                await verify(pin: pin)
            }
        case .pinScreenLoaded:
            let pinAttemptsRemaining = await readNumberOfAttempts()
            if pinAttemptsRemaining <= 3 {
                handlePinAuthenticationError(attemptsLeft: pinAttemptsRemaining)
            }
        }
    }

    private func signOutAllAccounts() async {
        do {
            try await signOutService.signOutAllAccounts()
            dismissLock()
        } catch {
            AppLogger.log(error: error, category: .appSettings)
        }
    }

    private func handlePinAuthenticationError(attemptsLeft: Int) {
        switch attemptsLeft {
        case 0:
            dismissLock()
        case 1...3:
            state =
                state
                .copy(\.pinAuthenticationError, to: .attemptsRemaining(attemptsLeft))
        default:
            state =
                state
                .copy(\.pinAuthenticationError, to: .custom(L10n.PINLock.invalidPIN.string))
        }
    }

    private func verify(pin: PIN) async {
        switch await pinVerifier.verifyPinCode(pin: pin.digits) {
        case .ok:
            dismissLock()
        case .error(let error) where error == .reason(.tooFrequentAttempts):
            state = state.copy(\.pinAuthenticationError, to: .tooFrequentAttempts)
        case .error:
            let pinAttemptsRemaining = await readNumberOfAttempts()
            handlePinAuthenticationError(attemptsLeft: pinAttemptsRemaining)
        }
    }

    private func readNumberOfAttempts() async -> Int {
        do {
            let attempts = try await pinVerifier.remainingPinAttempts().get() ?? 0
            return Int(attempts)
        } catch {
            AppLogger.log(error: error, category: .appSettings)
            return 0
        }
    }
}
