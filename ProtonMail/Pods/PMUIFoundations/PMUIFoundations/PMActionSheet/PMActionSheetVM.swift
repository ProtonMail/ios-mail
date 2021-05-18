//
//  PMActionSheetError.swift
//  ProtonMail - Created on 26.07.20.
//
//  Copyright (c) 2020 Proton Technologies AG
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
//

import UIKit

protocol PMActionSheetVMProtocol {
    var itemGroups: [PMActionSheetItemGroup]? {get}
    var value: PMActionSheetValueStore {get}

    func selectRowAt(_ indexPath: IndexPath)
    func calcTableViewHeight() -> CGFloat
    func calcGridCellHeightAt(_ section: Int) -> CGFloat
}

/// Provide value and cached
struct PMActionSheetValueStore {
    let PLAIN_CELL_NAME = "PMACTIONPLAINCELL"
    let TOGGLE_CELL_NAME = "PMACTIONTOGGLECELL"
    let GRID_CELL_NAME = "PMACTIONGRIDCELL"
    let HEADER_HEIGHT: CGFloat = 64
    let SECTION_HEADER_HEIGHT: CGFloat = 56
    let TOGGLE_CELL_HEIGHT: CGFloat = 48
    let PLAIN_CELL_HEIGHT: CGFloat = 64
    let GRID_ROW_HEIGHT: CGFloat = 100
    let BOTTOM_PADDING: CGFloat = 35
    let RADIUS: CGFloat = 6
    let DURATION: TimeInterval = 0.25

    var tableViewHeight: CGFloat = -1
    var gridCellHeight: [Int: CGFloat] = [:]
}

class PMActionSheetVM: PMActionSheetVMProtocol {

    weak private(set) var actionsheet: PMActionSheetProtocol?
    private(set) var itemGroups: [PMActionSheetItemGroup]?
    private(set) var value: PMActionSheetValueStore

    init(actionsheet: PMActionSheetProtocol, itemGroups: [PMActionSheetItemGroup]) {
        self.actionsheet = actionsheet
        self.itemGroups = itemGroups
        self.value = PMActionSheetValueStore()
    }

    /// Handle tableview selected event
    func selectRowAt(_ indexPath: IndexPath) {
        guard let groups = self.itemGroups else {
            return
        }
        let group = groups[indexPath.section]
        switch group.style {
        case .clickable:
            self.handleClickableEvent(group, at: indexPath)
        case .singleSelection:
            self.handleSingleSelectionEventAt(indexPath)
        case .multiSelection:
            self.handleMultiSelectionEventAt(indexPath)
        default:
            break
        }
    }

    /// Calculate tableview height through given itemGroups
    func calcTableViewHeight() -> CGFloat {
        if self.value.tableViewHeight != -1 {
            return self.value.tableViewHeight
        }

        var height: CGFloat = 0
        guard let groups = self.itemGroups else {return 0}
        for (idx, group) in groups.enumerated() {
            let groupHeaderHeight = group.title != nil ? value.SECTION_HEADER_HEIGHT : 0
            height += groupHeaderHeight
            switch group.style {
            case .clickable, .singleSelection, .multiSelection:
                height += CGFloat(group.items.count) * self.value.PLAIN_CELL_HEIGHT
            case .toggle:
                height += CGFloat(group.items.count) * self.value.TOGGLE_CELL_HEIGHT
            case .grid:
                height += self.calcGridCellHeightAt(idx)
            }
        }

        self.value.tableViewHeight = height
        return height
    }

    /// Calculate grid cell height
    func calcGridCellHeightAt(_ section: Int) -> CGFloat {
        if let height = self.value.gridCellHeight[section] {
            return height
        }

        guard let groups = self.itemGroups else {return 0}
        let group =  groups[section]
        let numberOfRow: CGFloat = CGFloat((group.items.count + 1) / 2)
        let height = numberOfRow * self.value.GRID_ROW_HEIGHT
        self.value.gridCellHeight[section] = height
        return height
    }
}

// MARK: Handle tableview cell click event
extension PMActionSheetVM {
    private func handleClickableEvent(_ group: PMActionSheetItemGroup, at indexPath: IndexPath) {
        guard let item = group.items[indexPath.row] as? PMActionSheetPlainItem else {
            return
        }
        item.handler?(item)
        self.actionsheet?.dismiss(animated: true)
    }

    private func handleSingleSelectionEventAt(_ indexPath: IndexPath) {
        guard self.itemGroups != nil else {return}

        let count = self.itemGroups![indexPath.section].items.count
        for i in 0..<count {
            let isOn = i == indexPath.row
            if var itemToUpdate = itemGroups![indexPath.section].items[i] as? PMActionSheetPlainItem {
                itemToUpdate.isOn = isOn
                itemToUpdate.markType = isOn ? .checkMark : .none
                self.itemGroups![indexPath.section].items[i] = itemToUpdate
            } else {
                self.itemGroups![indexPath.section].items[i].isOn = isOn
            }
            if i == indexPath.row,
               let _item = self.itemGroups![indexPath.section].items[i] as? PMActionSheetPlainItem {
                _item.handler?(_item)
            }
        }
        self.actionsheet?.reloadSection(indexPath.section)
    }

    private func handleMultiSelectionEventAt(_ indexPath: IndexPath) {
        guard self.itemGroups != nil else {return}

        let section = indexPath.section
        let row = indexPath.row
        if var _item = self.itemGroups![section].items[row] as? PMActionSheetPlainItem {
            if _item.markType == .none {
                _item.markType = .checkMark
                self.itemGroups![section].items[row] = _item
            } else {
                _item.markType = .none
                self.itemGroups![section].items[row] = _item
            }
            _item.handler?(_item)
        } else {
            let isOn = self.itemGroups![section].items[row].isOn
            self.itemGroups![section].items[row].isOn = !isOn
        }
        self.actionsheet?.reloadRows(at: [indexPath])
    }
}

extension PMActionSheetVM: PMActionSheetToggleDelegate {
    func toggleTriggeredAt(indexPath: IndexPath) {
        self.handleMultiSelectionEventAt(indexPath)
    }
}

extension PMActionSheetVM: PMActionSheetGridDelegate {
    func tapGridItemAt(section: Int, row: Int) {
        guard let groups = self.itemGroups else {return}
        guard let item = groups[section].items[row] as? PMActionSheetPlainItem else {return}
        item.handler?(item)
        self.actionsheet?.dismiss(animated: true)
    }
}
