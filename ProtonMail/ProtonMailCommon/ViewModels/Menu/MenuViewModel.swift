//
//  MenuViewModel.swift
//  ProtonMail - Created on 11/20/17.
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
import PromiseKit

enum MenuSection {
    case inboxes    //general inbox list
    case others     //other options contacts, settings, signout
    case labels     //label inbox
    case unknown    //do nothing by default
    
    /// second screen
    case users    //
    case disconnectedUsers
    case accountManager //
}

protocol MenuViewModel : AnyObject {
    
    func showUsers() -> Bool
    func hideUsers()
    func updateCurrent(row: Int)
    func updateCurrent()
    func cellHeight(at: Int) -> CGFloat
    var usersCount: Int { get }
    var disconnectedUsersCount: Int { get }
    
    
    func updateMenuItems()
    func setupLabels(delegate: NSFetchedResultsControllerDelegate?, shouldFetchLabels: Bool)
    func sectionCount() -> Int
    func section(at: Int) -> MenuSection
    
    func inboxesCount() -> Int
    func othersCount() -> Int
    func labelsCount() -> Int
    func label(at : Int) -> Label?
    func count(by labelID: String, userID: String?) -> Promise<Int>
    func user(at : Int) -> UserManager?
    func disconnectedUser(at: Int) -> UsersManager.DisconnectedUserHandle?
    var currentUser: UserManager? { get set }
    var users: UsersManager { get }
    var secondUser: UserManager? { get }
    func item(inboxes at: Int ) ->MenuItem
    func item(others at: Int ) ->MenuItem
    
    func find( section : MenuSection, item : MenuItem) -> IndexPath
    
    func isCurrentUserHasQueuedMessage() -> Bool
    func removeAllQueuedMessageOfCurrentUser()
    
    func signOut() -> Promise<Void>
}
