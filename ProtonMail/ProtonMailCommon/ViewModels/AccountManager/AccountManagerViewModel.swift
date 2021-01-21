//
//  MenuViewModelImpl.swift
//  ProtonMail - Created - on 11/20/17.
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
import CoreData
import UIKit
import PromiseKit


enum AccountSection {
    case users
    case add
    case disconnected
}

class AccountManagerViewModel {
    
    var textForFooter: String {
        return "You can be simultaneously logged into an unlimited number of paid ProtonMail accounts and one free account."
    }
    
    func user(at: Int) -> UserManager? {
        return self.usersManager.user(at: at)
    }
    
    func user(at indexPath: IndexPath) -> UserManager? {
        switch self.section(at: indexPath.section) {
        case .users:
            if let user = self.user(at: indexPath.row) {
                return user
            }
        default:
            break
        }
        return nil
    }
    
    func nextUser(at indexPath: IndexPath) -> UserManager? {
        switch self.section(at: indexPath.section) {
        case .users:
            if let user = self.user(at: indexPath.row + 1) {
                return user
            }
        default:
            break
        }
        return nil
    }
    
    func handle(at index: Int) -> UsersManager.DisconnectedUserHandle? {
        return self.usersManager.disconnectedUser(at: index)
    }
    
    func remove(at indexPath: IndexPath) -> Promise<Void> {
        switch self.section(at: indexPath.section) {
        case .users:
            if let user = self.user(at: indexPath.row) {
                return self.usersManager.logout(user: user)
            }
        case .disconnected:
            if let handle = self.handle(at: indexPath.row) {
                self.usersManager.removeDisconnectedUser(handle)

            }
        default: break
        }
        return Promise()
    }
    
    var currentUser: UserManager? {
        get {
            return self.usersManager.firstUser
        }
    }
    
    var usersCount: Int {
        get {
            return self.usersManager.count
        }
    }
    
    var loggedOutCount: Int {
        get {
            return self.usersManager.disconnectedUsers.count
        }
    }
    
    //menu sections
    private var sections : [AccountSection] = [.users, .disconnected, .add]

    private var showingUsers: Bool = false
    
    //
    private let usersManager : UsersManager
    
    
    init(usersManager : UsersManager) {
        self.usersManager = usersManager
    }
    
    func activateUser(at indexPath: IndexPath) {
        self.usersManager.active(index: indexPath.row)
    }
    
    func signOut() -> Promise<Void> {
        return self.usersManager.loggedOutAll()
    }

    func sectionCount() -> Int {
        return self.sections.count
    }
    
    func section(at: Int) -> AccountSection {
        if at < self.sectionCount() {
            return sections[at]
        }
        return .users
    }
        
    func rowCount(at section : Int) -> Int {
        let s = sections[section]
        
        switch s {
        case .users:
            return self.usersCount
        case .disconnected:
            return self.loggedOutCount
        case .add:
            return 1
        }
    }
    
    func isCurrentUserHasQueuedMessage() -> Bool {
        if let currentUser = self.currentUser {
            return currentUser.messageService.isAnyQueuedMessage(userId: currentUser.userInfo.userId)
        }
        return false
    }
    
    func isUserHasQueuedMessage(userId: String) -> Bool {
        if let currentUser = self.currentUser {
            return currentUser.messageService.isAnyQueuedMessage(userId: userId)
        }
        return false
    }
    
    func removeAllQueuedMessage(userId: String) {
        if let currentUser = self.currentUser {
            currentUser.messageService.removeQueuedMessage(userId: userId)
        }
    }
}
