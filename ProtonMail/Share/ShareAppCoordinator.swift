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

    func start() {
        sharedServices.add(UserCachedStatus.self, for: userCachedStatus)
        let messageQueue = PMPersistentQueue(queueName: PMPersistentQueue.Constant.name)
        let miscQueue = PMPersistentQueue(queueName: PMPersistentQueue.Constant.miscName)
        let queueManager = QueueManager(messageQueue: messageQueue, miscQueue: miscQueue)
        sharedServices.add(QueueManager.self, for: queueManager)

        let keyMaker = Keymaker(
            autolocker: Autolocker(lockTimeProvider: sharedServices.userCachedStatus),
            keychain: KeychainWrapper.keychain
        )
        sharedServices.add(Keymaker.self, for: keyMaker)
        sharedServices.add(KeyMakerProtocol.self, for: keyMaker)

        let usersManager = UsersManager(
            doh: BackendConfiguration.shared.doh,
            userDataCache: UserDataCache(keyMaker: keyMaker),
            coreKeyMaker: keyMaker
        )
        sharedServices.add(
            UnlockManager.self,
            for: UnlockManager(
                cacheStatus: keyMaker,
                delegate: self,
                keyMaker: keyMaker,
                pinFailedCountCache: sharedServices.userCachedStatus
            )
        )
        sharedServices.add(UsersManager.self, for: usersManager)
        self.loadUnlockCheckView()
    }

    init(navigation: UINavigationController?) {
        self.navigationController = navigation
    }

    private func loadUnlockCheckView() {
        // create next coordinator
        self.nextCoordinator = ShareUnlockCoordinator(navigation: navigationController, services: sharedServices)
        self.nextCoordinator?.start()
    }
}

extension ShareAppCoordinator: UnlockManagerDelegate {
    func setupCoreData() {
        sharedServices.add(CoreDataContextProviderProtocol.self, for: CoreDataService.shared)
        sharedServices.add(CoreDataService.self, for: CoreDataService.shared)
        let lastUpdatedStore = LastUpdatedStore(contextProvider: CoreDataService.shared)
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
