//
//  ShareCoordinator.swift
//  Share - Created on 10/31/18.
//
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.


import Foundation


/// Main entry point to the app
class ShareAppCoordinator: CoordinatorNew {
    // navigation controller instance -- entry
    internal weak var navigationController: UINavigationController?
    private var nextCoordinator: CoordinatorNew?
    
    func start() {
        self.loadUnlockCheckView()
        
        let usersManager = UsersManager(server: Server.live, delegate: self)
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
    func migrating() {
        
    }
    
    func session() {
        
    }
}

extension ShareAppCoordinator: UnlockManagerDelegate {
    func isUserStored() -> Bool {
        return isUserCredentialStored
    }
    
    func cleanAll() {
        sharedServices.get(by: UsersManager.self).clean()
        keymaker.wipeMainKey()
        keymaker.mainKeyExists()
    }
    
    func unlocked() {
        
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
