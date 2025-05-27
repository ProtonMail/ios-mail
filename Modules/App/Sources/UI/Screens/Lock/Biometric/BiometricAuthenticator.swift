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
import LocalAuthentication

struct BiometricAuthenticator: Sendable {
    private let method: AuthenticationMethod

    init(method: AuthenticationMethod) {
        self.method = method
    }

    enum AuthenticationMethod: Sendable {
        case builtIn(@Sendable () -> LAContext)
        case external(@Sendable () async throws -> Void)
    }

    enum AuthenticationStatus {
        case success
        case failure(policyUnavailable: Bool)

        var isSuccess: Bool {
            switch self {
            case .success:
                true
            case .failure:
                false
            }
        }
    }

    func authenticate() async -> AuthenticationStatus {
        switch method {
        case .builtIn(let context):
            await authenticate(with: context())
        case .external(let block):
            await authenticateByExecuting(block: block)
        }
    }

    private func authenticate(with context: LAContext) async -> AuthenticationStatus {
        if !context.canEvaluatePolicy(.deviceOwnerAuthentication, error: nil) {
            return .failure(policyUnavailable: true)
        }

        let reason = L10n.BiometricLock.biometryUnlockRationale.string
        return await withCheckedContinuation { continuation in
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, _ in
                continuation.resume(
                    with: .success(success ? AuthenticationStatus.success : .failure(policyUnavailable: false))
                )
            }
        }
    }

    private func authenticateByExecuting(block: () async throws -> Void) async -> AuthenticationStatus {
        do {
            try await block()
            return .success
        } catch {
            AppLogger.log(error: error, category: .appSettings)
            return .failure(policyUnavailable: false)
        }
    }
}
