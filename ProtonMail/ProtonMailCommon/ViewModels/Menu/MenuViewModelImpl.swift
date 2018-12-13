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

class MenuViewModelImpl : MenuViewModel {
    //menu sections
    private let sections : [MenuSection] = [.inboxes, .others, .labels]
    
    //menu actions order by index
    private let inboxItems : [MenuItem] = [.inbox, .drafts, .sent, .starred,
                                               .archive, .spam, .trash, .allmail]
    //menu other actions rather than inboxes
    private var otherItems : [MenuItem] = [.contacts, .settings, .servicePlan, .bugs, /*MenuItem.feedback,*/ .lockapp, .signout]
    
    //fetch request result
    private var fetchedLabels: NSFetchedResultsController<NSFetchRequestResult>?
    
    
    func setupMenu() {
        if !userCachedStatus.isPinCodeEnabled, !userCachedStatus.isTouchIDEnabled {
            otherItems = otherItems.filter { $0 != .lockapp }
        }
        if !ServicePlanDataService.shared.isIAPAvailable || Bundle.main.bundleIdentifier != "ch.protonmail.protonmail" {
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
        if at < self.fetchedLabels?.fetchedObjects?.count {
            return self.fetchedLabels?.object(at: IndexPath(row: at, section: 0)) as? Label
        }
        return nil
    }
    
    func find(section: MenuSection, item: MenuItem) -> IndexPath {
        let s = sections.index(of: section) ?? 0
        var r = 0
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
