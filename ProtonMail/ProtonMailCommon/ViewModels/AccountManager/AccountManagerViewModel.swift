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


enum AccountSection {
    case users
    case add
}

class AccountManagerViewModel {
    private let kMenuCellHeight: CGFloat = 44.0
    private let kUserCellHeight: CGFloat = 60.0
    
    func cellHeight(at: Int) -> CGFloat {
        let section = self.section(at: at)
        switch section {
        case .users:
            return kUserCellHeight
        default:
            return kMenuCellHeight
        }
    }
    
    func user(at: Int) -> UserManager? {
        return self.usersManager.user(at: at)
    }
    
    var usersCount: Int {
        get {
            return self.usersManager.count
        }
    }
    
    //menu sections
    private var sections : [AccountSection] = [.users, .add]
    
    
    //fetch request result
    private var fetchedLabels: NSFetchedResultsController<NSFetchRequestResult>?
    
    private var showingUsers: Bool = false
    
    //
    let usersManager : UsersManager
    
    //
    let labelDataService : LabelsDataService
    
    init(usersManager : UsersManager) {
        self.usersManager = usersManager
        self.labelDataService = self.usersManager.firstUser!.labelService
    }
    
    func signOut() {
         self.usersManager.loggedOutAll()
    }
//    func updateMenuItems() {
//        otherItems = [.contacts, .settings, .servicePlan, .bugs, .lockapp, .signout]
//        if !userCachedStatus.isPinCodeEnabled, !userCachedStatus.isTouchIDEnabled {
//            otherItems = otherItems.filter { $0 != .lockapp }
//        }
//        if !ServicePlanDataService.shared.isIAPAvailable {
//            otherItems = otherItems.filter { $0 != .servicePlan }
//        }
//    }
    
    func setupLabels(delegate: NSFetchedResultsControllerDelegate?) {
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
        case .add:
            return 1
        }
    }
//
//    func othersCount() -> Int {
//        return self.otherItems.count
//    }
    
    func labelsCount() -> Int {
        return fetchedLabels?.numberOfRows(in: 0) ?? 0
    }
    
//    func item(inboxes at: Int) -> MenuItem {
//        if at < self.inboxesCount() {
//            return inboxItems[at]
//        }
//        return .inbox
//    }
    
//    func item(others at: Int) -> MenuItem {
//        if at < self.othersCount() {
//            return otherItems[at]
//        }
//        return .settings
//    }
//
//    func label(at: Int) -> Label? {
//        guard let count = self.fetchedLabels?.fetchedObjects?.count else {
//            return nil
//        }
//        if at < count {
//            return self.fetchedLabels?.object(at: IndexPath(row: at, section: 0)) as? Label
//        }
//        return nil
//    }
    
//    func find(section: MenuSection, item: MenuItem) -> IndexPath {
//        let s = sections.firstIndex(of: section) ?? 0
//        var r = 0
//        switch section {
//        case .inboxes:
//            r = inboxItems.firstIndex(of: item) ?? 0
//        case .others:
//            r = otherItems.firstIndex(of: item) ?? 0
//        default:
//            break
//        }
//        return IndexPath(row: r, section: s)
//    }
    
}
