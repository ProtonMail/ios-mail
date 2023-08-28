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

import ProtonCore_Keymaker
import UIKit

/// Main entry point to the app
final class ShareAppCoordinator {
    // navigation controller instance -- entry
    private(set) weak var navigationController: UINavigationController?
    private var nextCoordinator: ShareUnlockCoordinator?

    private let dependencies = GlobalContainer.shared

    func start() {
        sharedServices.add(UserCachedStatus.self, for: dependencies.userCachedStatus)
        sharedServices.add(QueueManager.self, for: dependencies.queueManager)

        let keyMaker = dependencies.keyMaker
        sharedServices.add(Keymaker.self, for: keyMaker)
        sharedServices.add(KeyMakerProtocol.self, for: keyMaker)

        let unlockManager = dependencies.unlockManager
        unlockManager.delegate = self

        sharedServices.add(UsersManager.self, for: dependencies.usersManager)
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
    func setupCoreData() {
        do {
            try CoreDataStore.shared.initialize()
        } catch {
            fatalError("\(error)")
        }

        sharedServices.add(CoreDataContextProviderProtocol.self, for: CoreDataService.shared)
        sharedServices.add(CoreDataService.self, for: CoreDataService.shared)
        let lastUpdatedStore = dependencies.lastUpdatedStore
        sharedServices.add(LastUpdatedStore.self, for: lastUpdatedStore)
        sharedServices.add(LastUpdatedStoreProtocol.self, for: lastUpdatedStore)
    }

    func isUserStored() -> Bool {
        return isUserCredentialStored
    }

    func cleanAll(completion: @escaping () -> Void) {
        let keyMaker = sharedServices.get(by: KeyMakerProtocol.self)
        sharedServices.get(by: UsersManager.self)
            .clean()
            .ensure {
                keyMaker.wipeMainKey()
                _ = keyMaker.mainKeyExists()
                completion()
            }
            .cauterize()
    }

    var isUserCredentialStored: Bool {
        sharedServices.get(by: UsersManager.self).hasUsers()
    }

    func isMailboxPasswordStored(forUser uid: String?) -> Bool {
        guard uid != nil else {
            return sharedServices.get(by: UsersManager.self).isMailboxPasswordStored
        }
        return !(sharedServices.get(by: UsersManager.self).users.last?.mailboxPassword.value ?? "").isEmpty
    }

    func loadUserDataAfterUnlock() {
        let usersManager = sharedServices.get(by: UsersManager.self)
        usersManager.run()
        usersManager.tryRestore()
    }
}

extension GlobalContainer {
    static let shared = GlobalContainer()
}
