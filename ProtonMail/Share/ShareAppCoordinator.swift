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

import UIKit

let sharedInternetReachability: Reachability = Reachability.forInternetConnection()

/// Main entry point to the app
class ShareAppCoordinator {
    // navigation controller instance -- entry
    internal weak var navigationController: UINavigationController?
    private var nextCoordinator: ShareUnlockCoordinator?

    func start() {
        self.loadUnlockCheckView()

        let messageQueue = PMPersistentQueue(queueName: PMPersistentQueue.Constant.name)
        let miscQueue = PMPersistentQueue(queueName: PMPersistentQueue.Constant.miscName)
        let queueManager = QueueManager(messageQueue: messageQueue, miscQueue: miscQueue)
        sharedServices.add(QueueManager.self, for: queueManager)

        let usersManager = UsersManager(doh: DoHMail.default, delegate: self)
        sharedServices.add(UnlockManager.self, for: UnlockManager(cacheStatus: userCachedStatus, delegate: self))
        sharedServices.add(UsersManager.self, for: usersManager)
    }

    init(navigation: UINavigationController?) {
        self.navigationController = navigation
    }

    ///
    private func loadUnlockCheckView() {
        // create next coordinator
        self.nextCoordinator = ShareUnlockCoordinator(navigation: navigationController, services: sharedServices)
        self.nextCoordinator?.start()
    }
}

extension ShareAppCoordinator: UsersManagerDelegate {

}

extension ShareAppCoordinator: UnlockManagerDelegate {
    func isUserStored() -> Bool {
        return isUserCredentialStored
    }

    func cleanAll() {
        sharedServices.get(by: UsersManager.self).clean().cauterize()
        keymaker.wipeMainKey()
        keymaker.mainKeyExists()
    }

    var isUserCredentialStored: Bool {
        sharedServices.get(by: UsersManager.self).hasUsers()
    }

    func isMailboxPasswordStored(forUser uid: String?) -> Bool {
        guard let _ = uid else {
            return sharedServices.get(by: UsersManager.self).isMailboxPasswordStored
        }
        return !(sharedServices.get(by: UsersManager.self).users.last?.mailboxPassword ?? "").isEmpty
    }
}
