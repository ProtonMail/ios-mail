//
//  MenuViewModelImpl.swift
//  ProtonMail - Created - on 11/20/17.
//
//
//  The MIT License
//
//  Copyright (c) 2018 Proton Technologies AG
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.


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
        self.labelDataService = self.usersManager.firstUser.labelService
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
