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

// sourcery: mock
protocol LaunchService {

    /// Call at launch to set up the main key, Core Data and load users.
    ///
    /// Users will be loaded in `UsersManager` if App Key is disabled because the main key is needed.
    ///
    /// This function can throw errors related to the Core Data set up.
    func start() throws

    /// Loads the authenticated users into `UsersManager`.
    ///
    /// Call this function when you are sure the main key exists in memory
    func loadUserDataAfterUnlock()
}

final class Launch {
    typealias Dependencies = AnyObject
    & HasSetupCoreDataService
    & HasAppAccessResolver
    & HasUsersManager
    & HasKeyMakerProtocol

    private unowned let dependencies: Dependencies

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    private func setupCoreData() throws {
        try dependencies.setupCoreDataService.setup()
    }

    private func loadUserData() {
        let usersManager = dependencies.usersManager
        usersManager.tryRestore()

        #if !APP_EXTENSION
        DispatchQueue.global().async {
            usersManager.users.forEach {
                $0.messageService.injectTransientValuesIntoMessages()
            }
        }
        #endif
    }

    private func loadUsersIfMainKeyAvailable() {
        let appAccess = dependencies.appAccessResolver.evaluateAppAccessAtLaunch()
        if case .accessGranted = appAccess {
            loadUserData()
        }
    }

    private func setUpPrimaryUser() {
        guard let primaryUser = dependencies.usersManager.firstUser else { return }
#if !APP_EXTENSION
        primaryUser.payments.storeKitManager.retryProcessingAllPendingTransactions(finishHandler: nil)
    #if !DEBUG
        primaryUser.updateTelemetryAndCatchCrash()
    #endif
#endif
    }
}

extension Launch: LaunchService {

    func start() throws {
        /// Try to load the main key into memory. If App Key is enabled the main key
        /// will not be available until the user unlocks the application.
        _ = dependencies.keyMaker.mainKeyExists()

        /// Set up Core Data
        try setupCoreData()

        /// If we have the main key in memory we can already load the users into `UsersManager`
        loadUsersIfMainKeyAvailable()

        setUpPrimaryUser()

        #if !APP_EXTENSION
        if let hasPushNotificationService = dependencies as? HasPushNotificationService {
            hasPushNotificationService.pushService.resumePendingTasks()
        }
        #endif
    }

    func loadUserDataAfterUnlock() {
        SystemLogger.log(message: "Launch: load users data after unlock", category: .appLock)
        loadUserData()
    }
}
