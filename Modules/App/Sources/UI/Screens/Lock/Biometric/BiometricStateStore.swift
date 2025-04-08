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

import InboxCore

struct BiometricState: Equatable, Copying {
    var displayUnlockButton: Bool
}

extension BiometricState {

    static var initial: Self {
        .init(displayUnlockButton: false)
    }

}

enum BiometricScreenAction {
    case onLoad
    case unlockTapped
}

import Combine
import LocalAuthentication

class BiometricStateStore: StateStore {
    @Published var state: BiometricState

    init(state: BiometricState) {
        self.state = state
    }

    @MainActor
    func handle(action: BiometricScreenAction) async {
        switch action {
        case .onLoad, .unlockTapped:
            let result = await authorize()
            switch result {
            case .authorized:
                break // FIXME: - Do something to authorize user
            case .failed:
                state = state
                    .copy(\.displayUnlockButton, to: true)
            }
        }
    }

    @MainActor
    private func authorize() async -> BiometricAuthorization.AuthorizationResult {
        do {
            return try await BiometricAuthorization.authorize()
        } catch {
            return .failed
        }
    }
}

enum BiometricAuthorization {
    static var context: () -> LAContext = LAContext.init

    enum AuthorizationResult {
        case authorized
        case failed
    }

    static func authorize() async throws -> AuthorizationResult {
        let context = Self.context()
        if !context.canEvaluatePolicy(.deviceOwnerAuthentication, error: nil) {
            return .failed
        }

        let reason = "Please authenticate to unlock your screen"
        return try await withCheckedThrowingContinuation { continuation in
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, error in
                if success {
                    continuation.resume(with: .success(AuthorizationResult.authorized))
                } else {
                    continuation.resume(with: .success(AuthorizationResult.failed))
                }
            }
        }
    }
}
