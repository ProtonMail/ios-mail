//
//  MenuViewModelImpl.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 11/20/17.
//  Copyright © 2017 ProtonMail. All rights reserved.
//

import Foundation
import CoreData
import UIKit

class MenuViewModelImpl : MenuViewModel {
    
    //menu sections
    fileprivate let sections : [MenuSection] = [.inboxes, .others, .labels]
    
    //menu actions order by index
    fileprivate let inboxItems : [MenuItem] = [.inbox, .drafts, .sent, .starred,
                                               .archive, .spam, .trash, .allmail]
    //menu other actions rather than inboxes
    fileprivate var otherItems : [MenuItem] = [.contacts, .settings, .servicePlan, .bugs, /*MenuItem.feedback,*/ .lockapp, .signout]
    
    //fetch request result
    fileprivate var fetchedLabels: NSFetchedResultsController<NSFetchRequestResult>?
    
    override func setupMenu() {
        if (!userCachedStatus.isPinCodeEnabled || userCachedStatus.pinCode.isEmpty),
            (!userCachedStatus.isTouchIDEnabled || userCachedStatus.touchIDEmail.isEmpty)
        {
            otherItems = otherItems.filter { $0 != .lockapp }
        }
        if !ServicePlanDataService.shared.isIAPAvailable || Bundle.main.bundleIdentifier != "ch.protonmail.protonmail" {
            otherItems = otherItems.filter { $0 != .servicePlan }
        }
    }
    
    override func setupLabels(delegate: NSFetchedResultsControllerDelegate?) {
        self.fetchedLabels = sharedLabelsDataService.fetchedResultsController(.all)
        self.fetchedLabels?.delegate = delegate
        if let fetchedResultsController = fetchedLabels {
            do {
                try fetchedResultsController.performFetch()
            } catch let ex as NSError {
                PMLog.D("error: \(ex)")
            }
        }
    }
    
    override func sectionCount() -> Int {
        return sections.count
    }
    
    override func section(at: Int) -> MenuSection {
        if at < self.sectionCount() {
            return sections[at]
        }
        return .unknown
    }
    
    override func inboxesCount() -> Int {
        return inboxItems.count
    }
    
    override func othersCount() -> Int {
        return otherItems.count
    }
    
    override func item(inboxes at: Int) -> MenuItem {
        if at < self.inboxesCount() {
            return inboxItems[at]
        }
        return .inbox
    }
    
    override func item(others at: Int) -> MenuItem {
        if at < self.othersCount() {
            return otherItems[at]
        }
        return .settings
    }
    
    override func labelsCount() -> Int {
        return fetchedLabels?.numberOfRows(in: 0) ?? 0
    }
    
    override func label(at: Int) -> Label? {
        if at < self.fetchedLabels?.fetchedObjects?.count {
            return self.fetchedLabels?.object(at: IndexPath(row: at, section: 0)) as? Label
        }
        return nil
    }
    
    override func find( section : MenuSection, item : MenuItem) -> IndexPath {
        var s = 0
        var r = 0
        s = sections.index(of: section) ?? 0
        switch section {
        case .inboxes:
            r = inboxItems.index(of: item) ?? 0
        case .others:
            r = otherItems.index(of: item) ?? 0
        default:
            break
        }
        return IndexPath(row: r, section: s)
    }
    
}
