// Copyright (c) 2023 Proton Technologies AG
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
import ProtonCoreKeymaker

enum AppAccess: Equatable {
    case accessGranted
    case accessDenied(reason: DeniedAccessReason)

    var localizedDescription: String {
        switch self {
        case .accessGranted:
            return "App is unlocked."
        case .accessDenied(let reason):
            return "App is locked. \(reason.localizedDescription)"
        }
    }
}

enum DeniedAccessReason {
    // User has to sign in into an account
    case noAuthenticatedAccountFound
    // There is an autheticated account but the user has to pass the lock protection
    case lockProtectionRequired

    var localizedDescription: String {
        switch self {
        case .noAuthenticatedAccountFound:
            return "No account found."
        case .lockProtectionRequired:
            return "App needs to be unlocked by the user."
        }
    }
}

final class AppAccessResolver {
    typealias Dependencies = AnyObject
    & HasKeyMakerProtocol
    & HasLockPreventor
    & HasNotificationCenter
    & HasUsersManager

    private unowned let dependencies: Dependencies

    /// Subscribe to this publisher to receive events when the user access to the app should be denied.
    var deniedAccessPublisher: AnyPublisher<DeniedAccessReason, Never> {
        dependencies.notificationCenter
            .publisher(for: Keymaker.Const.removedMainKeyFromMemory)
            .compactMap { [unowned self] _ in
                // needs to go before throttle, otherwise we can't evaluate the LockPreventor condition
                self.evaluateAppAccessAfterMainKeyRemoved()
            }
            .throttle(
                for: .milliseconds(500),
                scheduler: DispatchQueue.global(qos: .userInteractive),
                latest: true
            )
            .eraseToAnyPublisher()
    }

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    /// Evaluates whether the user should be granted access to the app.
    ///
    /// This function will not trigger any event in `deniedAccessPublisher`
    func evaluateAppAccessAtLaunch() -> AppAccess {
        // 1. Determine whether there is any authenticated account
        guard appHasValidAccountCredentials else {
            return .accessDenied(reason: .noAuthenticatedAccountFound)
        }

        // 2. Determine whether the app is already accessible for the user
        guard isAppUnlocked else {
            return .accessDenied(reason: .lockProtectionRequired)
        }

        return .accessGranted
    }
}

// MARK: Private methods

extension AppAccessResolver {

    private var appHasValidAccountCredentials: Bool {
        dependencies.usersManager.hasUsers()
    }

    /// Returns `true` if there is no need to lock the access to the app
    private var isAppUnlocked: Bool {
        /**
         Currently the app is unlocked, meaning the user has access to it, if the `_mainKey` is loaded into memory.

         The `_mainKey` can only be loaded if there is no extra protection enabled or if the user already passed
         the extra protection lock screen.
         */
        dependencies.keyMaker.isMainKeyInMemory
    }

    private func evaluateAppAccessAfterMainKeyRemoved() -> DeniedAccessReason? {
        let lockIsNotSuppressed = !dependencies.lockPreventor.isLockSuppressed

        guard appHasValidAccountCredentials else {
            return .noAuthenticatedAccountFound
        }
        guard lockIsNotSuppressed else {
            return nil
        }
        return .lockProtectionRequired
    }
}
