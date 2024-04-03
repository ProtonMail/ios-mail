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

import Foundation
import ProtonCoreDataModel

// sourcery: mock
protocol UnlockService {

    /// Call after the user unlocks the app to set up the correct app state
    /// - Returns: Expect `accessGranted` unless there is an unexpected inconsistency
    func start() async -> AppAccess
}

final class Unlock: UnlockService {
    typealias Dependencies = AnyObject
    & HasKeyMakerProtocol
    & HasLaunchService
    & HasAppAccessResolver
    & HasUsersManager
    & HasSetupCoreDataService
    & HasResumeAfterUnlock

    private unowned let dependencies: Dependencies

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    func start() async -> AppAccess {
        /// The main key might no be in memory yet if App Key is enabled
        if !dependencies.keyMaker.isMainKeyInMemory {
            _ = dependencies.keyMaker.mainKeyExists()
        }

        // If users could not be loaded because of App Key we do it now
        if dependencies.usersManager.users.isEmpty {
            dependencies.launchService.loadUserDataAfterUnlock()
        }

        // Confirm the app access is granted
        let appAccess = dependencies.appAccessResolver.evaluateAppAccessAtLaunch()
        guard appAccess == .accessGranted else {
            // after unlock, app access should be granted
            let message = "Unlock start \(appAccess)"
            SystemLogger.log(message: message, category: .appLock, isError: true)
            Analytics.shared.sendError(.appLockInconsistency(error: message))

            await dependencies.usersManager.clean()
            return appAccess
        }

        // Resume unfinished actions that couldn't be finished before the user unlocked
        dependencies.resumeAfterUnlock.resume()

        return appAccess
    }
}
