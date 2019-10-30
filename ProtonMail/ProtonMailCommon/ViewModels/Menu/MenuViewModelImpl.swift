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
    //menu sections
    private let sections : [MenuSection] = [.inboxes, .others, .labels]
    
    //menu actions order by index
    private let inboxItems : [MenuItem] = [.inbox, .drafts, .sent, .starred,
                                               .archive, .spam, .trash, .allmail]
    //menu other actions rather than inboxes
    private var otherItems : [MenuItem] = []
    
    //fetch request result
    private var fetchedLabels: NSFetchedResultsController<NSFetchRequestResult>?
    
    
    func updateMenuItems() {
        otherItems = [.contacts, .settings, .servicePlan, .bugs, .lockapp, .signout]
        if !userCachedStatus.isPinCodeEnabled, !userCachedStatus.isTouchIDEnabled {
            otherItems = otherItems.filter { $0 != .lockapp }
        }
        if !ServicePlanDataService.shared.isIAPAvailable {
            otherItems = otherItems.filter { $0 != .servicePlan }
        }
    }
    
    func setupLabels(delegate: NSFetchedResultsControllerDelegate?) {
        self.fetchedLabels = sharedLabelsDataService.fetchedResultsController(.all)
        self.fetchedLabels?.delegate = delegate
        if let fetchedResultsController = fetchedLabels {
            do {
                try fetchedResultsController.performFetch()
            } catch let ex as NSError {
                PMLog.D("error: \(ex)")
            }
        }
        ///TODO::fixme not necessary
        sharedLabelsDataService.fetchLabels()
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
    
}
