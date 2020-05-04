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

class MenuViewModelImpl : MenuViewModel {
    private let kMenuCellHeight: CGFloat = 44.0
    private let kUserCellHeight: CGFloat = 60.0
    
    func cellHeight(at: Int) -> CGFloat {
        let section = self.section(at: at)
        switch section {
        case .users:
            return kUserCellHeight
        case .disconnectedUsers:
            return kUserCellHeight
        default:
            return kMenuCellHeight
        }
    }
    
    func user(at: Int) -> UserManager? {
        return self.usersManager.user(at: at)
    }
    
    func disconnectedUser(at: Int) -> UsersManager.DisconnectedUserHandle? {
        return self.usersManager.disconnectedUser(at: at)
    }
    
    var usersCount: Int {
        get {
            return self.usersManager.count
        }
    }
    
    var disconnectedUsersCount: Int {
        get {
            return self.usersManager.disconnectedUsers.count
        }
    }
    
    func showUsers() -> Bool {
        showingUsers = !showingUsers
        if showingUsers {
            self.sections = [.users, .disconnectedUsers, .accountManager]
        } else {
            self.sections = [.inboxes, .others, .labels]
        }
        return showingUsers
    }
    
    func hideUsers() {
        showingUsers = false
        self.sections = [.inboxes, .others, .labels]
    }
    
    func updateCurrent(row: Int) {
        self.currentUser = self.usersManager.user(at: row)
        self.usersManager.active(index: row)
    }
    
    func updateCurrent() {
        self.currentUser = self.usersManager.firstUser
    }
    
    //menu sections
    private var sections : [MenuSection] = [.inboxes, .others, .labels]
    
    //menu actions order by index
    private let inboxItems : [MenuItem] = [.inbox, .drafts, .sent, .starred,
                                               .archive, .spam, .trash, .allmail]
    //menu other actions rather than inboxes
    private var otherItems : [MenuItem] = []
    
    //fetch request result
    private var fetchedLabels: NSFetchedResultsController<NSFetchRequestResult>?
    
    private var showingUsers: Bool = false
    
    //
    let usersManager : UsersManager
    
    //
    lazy var labelDataService : LabelsDataService = self.currentUser!.labelService
    
    init(usersManager : UsersManager) {
        self.usersManager = usersManager
    }
    
    // user at the moment of creation of this MenuViewModel instance
    lazy var currentUser: UserManager? = {
        return self.usersManager.firstUser
    }()
    
    var users: UsersManager {
        get {
            return self.usersManager
        }
    }
    
    var secondUser: UserManager? {
        return self.usersManager.user(at: 1)
    }
    
    func updateMenuItems() {
        otherItems = [.contacts, .settings, .servicePlan, .bugs, .lockapp, .signout]
        if !userCachedStatus.isPinCodeEnabled, !userCachedStatus.isTouchIDEnabled {
            otherItems = otherItems.filter { $0 != .lockapp }
        }
        if let user = self.currentUser, !user.sevicePlanService.isIAPAvailable {
            otherItems = otherItems.filter { $0 != .servicePlan }
        }
    }
    
    func setupLabels(delegate: NSFetchedResultsControllerDelegate?) {
        guard let labelService = self.currentUser?.labelService else {
            return
        }
        self.labelDataService = labelService
        self.fetchedLabels = self.labelDataService.fetchedResultsController(.all)
        self.fetchedLabels?.delegate = delegate
        if let fetchedResultsController = fetchedLabels {
            do {
                try fetchedResultsController.performFetch()
            } catch let ex as NSError {
                PMLog.D("error: \(ex)")
            }
        }
        ///TODO::fixme not necessary
        self.labelDataService.fetchLabels()
    }
    
    func sectionCount() -> Int {
        return self.sections.count
    }
    
    func section(at: Int) -> MenuSection {
        if at < self.sectionCount() {
            return sections[at]
        }
        return .unknown
    }
    
    func count(by labelID: String, userID: String? = nil) -> Int {
        return labelDataService.unreadCount(by: labelID, userID: userID)
    }

    func inboxesCount() -> Int {
        return self.inboxItems.count
    }
    
    func othersCount() -> Int {
        return self.otherItems.count
    }
    
    func labelsCount() -> Int {
        return fetchedLabels?.numberOfRows(in: 0) ?? 0
    }
    
    func item(inboxes at: Int) -> MenuItem {
        if at < self.inboxesCount() {
            return inboxItems[at]
        }
        return .inbox
    }
    
    func item(others at: Int) -> MenuItem {
        if at < self.othersCount() {
            return otherItems[at]
        }
        return .settings
    }
    
    func label(at: Int) -> Label? {
        guard let count = self.fetchedLabels?.fetchedObjects?.count else {
            return nil
        }
        if at < count {
            return self.fetchedLabels?.object(at: IndexPath(row: at, section: 0)) as? Label
        }
        return nil
    }
    
    func find(section: MenuSection, item: MenuItem) -> IndexPath {
        let s = sections.firstIndex(of: section) ?? 0
        var r = 0
        switch section {
        case .inboxes:
            r = inboxItems.firstIndex(of: item) ?? 0
        case .others:
            r = otherItems.firstIndex(of: item) ?? 0
        default:
            break
        }
        return IndexPath(row: r, section: s)
    }
    
    func signOut() {
        if let currentUser = self.currentUser {
            self.usersManager.logout(user: currentUser)
        }
    }
    
    func isCurrentUserHasQueuedMessage() -> Bool {
        if let currentUser = self.currentUser {
            return currentUser.messageService.isAnyQueuedMessage(userId: currentUser.userInfo.userId)
        }
        return false
    }
    
    func removeAllQueuedMessageOfCurrentUser() {
        if let currentUser = self.currentUser {
            currentUser.messageService.removeQueuedMessage(userId: currentUser.userInfo.userId)
        }
    }
}
