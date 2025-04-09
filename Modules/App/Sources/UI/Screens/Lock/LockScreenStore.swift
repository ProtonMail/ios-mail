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

class LockScreenStore: StateStore {
    @Published var state: LockScreenState
    private let pinVerifier: PINVerifier
    private let lockOutput: (LockScreenOutput) -> Void

    init(
        state: LockScreenState,
        pinVerifier: PINVerifier,
        lockOutput: @escaping (LockScreenOutput) -> Void
    ) {
        self.state = state
        self.pinVerifier = pinVerifier
        self.lockOutput = lockOutput
    }

    @MainActor
    func handle(action: LockScreenAction) async {
        switch action {
        case .biometric(let output):
            switch output {
            case .authenticated:
                lockOutput(.authenticated)
            }
        case .pin(let output):
            switch output {
            case .logOut:
                lockOutput(.logOut)
            case .pin(let pin):
                await verify(pin: pin)
            }
        case .pinScreenLoaded:
            let numberOfAttempts = await readNumberOfAttempts()
            if numberOfAttempts <= 3 {
                state = state
                    .copy(\.pinError, to: pinErrorMessage(numberOfAttempts: numberOfAttempts))
            }
        }
    }

    @MainActor
    private func pinErrorMessage(numberOfAttempts: Int) -> String {
        if numberOfAttempts <= 3 {
            "\(numberOfAttempts) attempts remaining before sign-out." // FIXME: -
        } else {
            "Incorrect PIN. Try again." // FIXME: -
        }
    }

    @MainActor
    private func verify(pin: String) async {
        switch await pinVerifier.verifyPinCode(pin: pin) {
        case .ok:
            lockOutput(.authenticated)
        case .error:
            let numberOfAttempts = await readNumberOfAttempts()
            state = state
                .copy(\.pinError, to: pinErrorMessage(numberOfAttempts: numberOfAttempts))
        }
    }

    @MainActor
    private func readNumberOfAttempts() async -> Int {
        do {
            let attempts = try await pinVerifier.remainingPinAttempts().get() ?? 0
            return Int(attempts)
        } catch {
            fatalError() // FIXME: - Add logger here
        }
    }
}
