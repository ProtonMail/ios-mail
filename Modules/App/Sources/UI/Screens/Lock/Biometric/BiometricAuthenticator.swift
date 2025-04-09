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

import LocalAuthentication

struct BiometricAuthenticator: Sendable {
    private let context: () -> LAContext

    init(context: @escaping () -> LAContext) {
        self.context = context
    }

    enum AuthenticationStatus {
        case success
        case failure
    }

    func authenticate() async throws -> AuthenticationStatus {
        let context = self.context()
        if !context.canEvaluatePolicy(.deviceOwnerAuthentication, error: nil) {
            return .failure
        }

        let reason = "Please authenticate to unlock your screen"
        return try await withCheckedThrowingContinuation { continuation in
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, _ in
                continuation.resume(with: .success(success ? AuthenticationStatus.success : .failure))
            }
        }
    }
}
