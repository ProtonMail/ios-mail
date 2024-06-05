//
//  ShareCoordinator.swift
//  Share - Created on 10/31/18.
//
//
//  Copyright (c) 2019 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import ProtonCoreKeymaker
import UIKit

/// Main entry point to the app
final class ShareAppCoordinator {
    // navigation controller instance -- entry
    private(set) weak var navigationController: UINavigationController?
    private var nextCoordinator: ShareUnlockCoordinator?

    private let dependencies = GlobalContainer()

    func start() {
        let unlockManager = dependencies.unlockManager
        unlockManager.delegate = self

        self.loadUnlockCheckView()
    }

    init(navigation: UINavigationController?) {
        self.navigationController = navigation
    }

    private func loadUnlockCheckView() {
        // create next coordinator
        nextCoordinator = ShareUnlockCoordinator(
            navigation: navigationController,
            dependencies: dependencies
        )
        self.nextCoordinator?.start()
    }
}

extension ShareAppCoordinator: UnlockManagerDelegate {
    func setupCoreData() throws {
        // this is done in LaunchService
    }

    func isUserStored() -> Bool {
        return isUserCredentialStored
    }

    func cleanAll(completion: @escaping () -> Void) {
        let keyMaker = dependencies.keyMaker
        dependencies.usersManager
            .clean()
            .ensure {
                keyMaker.wipeMainKey()
                _ = keyMaker.mainKeyExists()
                completion()
            }
            .cauterize()
    }

    var isUserCredentialStored: Bool {
        dependencies.usersManager.hasUsers()
    }

    func isMailboxPasswordStoredForActiveUser() -> Bool {
        return !(dependencies.usersManager.users.last?.mailboxPassword.value ?? "").isEmpty
    }

    func loadUserDataAfterUnlock() {
        dependencies.launchService.loadUserDataAfterUnlock()
    }
}
