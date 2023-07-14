//
//  PMActionSheetVM.swift
//  ProtonCore-UIFoundations-iOS - Created on 2023/1/18.
//
//  Copyright (c) 2022 Proton Technologies AG
//
//  This file is part of Proton Technologies AG and ProtonCore.
//
//  ProtonCore is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonCore is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore.  If not, see <https://www.gnu.org/licenses/>.

#if os(iOS)

import Foundation
import UIKit

/// Provide value and cached
struct PMActionSheetValueStore {
    var tableViewHeight: CGFloat {
        let groupHeight = tableGroupHeight.reduce(0) { partialResult, dict in
            return partialResult + dict.value
        }
        let headerHeight = tableHeaderHeight.reduce(0) { partialResult, dict in
            return partialResult + dict.value
        }
        let height = groupHeight + headerHeight
        if height == 0 {
            return -1
        } else {
            return height
        }
    }
    // [Section: height]
    // Height of a item group
    var tableGroupHeight: [Int: CGFloat] = [:]
    // [Section: height]
    // Height of section header
    var tableHeaderHeight: [Int: CGFloat] = [:]
}

final class PMActionSheetVM {
    private weak var actionSheet: PMActionSheetProtocolV2?
    private(set) var itemGroups: [PMActionSheetItemGroup]
    private(set) var value = PMActionSheetValueStore()

    init(actionSheet: PMActionSheetProtocolV2, itemGroups: [PMActionSheetItemGroup]) {
        self.actionSheet = actionSheet
        self.itemGroups = itemGroups
    }

    /// Calculate tableview height through given itemGroups
    func calcTableViewHeight(forceUpdate: Bool = false) -> CGFloat {
        if self.value.tableViewHeight != -1 && !forceUpdate {
            return self.value.tableViewHeight
        }
        value.tableGroupHeight = [:]
        value.tableHeaderHeight = [:]

        for (idx, group) in itemGroups.enumerated() {
            value.tableHeaderHeight[idx] = calcHeaderHeight(title: group.title)
            let config = PMActionSheetConfig.shared
            switch group.style {
            case .clickable, .singleSelection, .multiSelection, .singleSelectionNewStyle, .multiSelectionNewStyle:
                value.tableGroupHeight[idx] = CGFloat(group.items.count) * config.plainCellHeight
            case .toggle:
                value.tableGroupHeight[idx] = CGFloat(group.items.count) * config.plainCellHeight
            case .grid(let colInRow):
                value.tableGroupHeight[idx] = calcGridCellHeightAt(idx, colInRow: colInRow)
            }
        }

        return value.tableViewHeight
    }

    /// Calculate grid cell height
    func calcGridCellHeightAt(_ section: Int, colInRow: Int) -> CGFloat {
        if let height = value.tableGroupHeight[section] {
            return height
        }
        let config = PMActionSheetConfig.shared
        let group = itemGroups[section]
        let numberOfRow: CGFloat = ceil(CGFloat(group.items.count) / CGFloat(colInRow))
        let height = numberOfRow * gridCellHeight(group: group) + numberOfRow * config.gridLineSpacing
        value.tableGroupHeight[section] = height
        return height
    }

    private func gridCellHeight(group: PMActionSheetItemGroup) -> CGFloat {
        guard let item = group.items.first else { return PMActionSheetConfig.shared.gridRowHeight }
        var height: CGFloat = 0
        for (index, component) in item.components.enumerated() {
            let element = component.makeElement()
            element.sizeToFit()
            let topEdge = component.edge[0] ?? 14
            height += (topEdge + element.frame.size.height)
            if index == item.components.count - 1 {
                height += component.edge[2] ?? 11
            }
        }
        return height
    }

    private func calcHeaderHeight(title: String?) -> CGFloat {
        guard let title = title else { return 0 }
        guard DFSSetting.enableDFS else { return PMActionSheetConfig.shared.sectionHeaderHeight }
        let label = UILabel(
            title,
            font: PMActionSheetConfig.shared.sectionHeaderFont,
            textColor: nil
        )
        label.adjustsFontForContentSizeCategory = true
        label.sizeToFit()
        let topPadding: CGFloat = 24
        let bottomPadding: CGFloat = 8
        return topPadding + label.frame.height + bottomPadding
    }

    /// Handle tableview selected event
    func selectRowAt(_ indexPath: IndexPath) {
        let group = itemGroups[indexPath.section]
        switch group.style {
        case .clickable:
            handleClickableEvent(group, at: indexPath)
        case .singleSelection, .singleSelectionNewStyle:
            handleSingleSelectionEvent(at: indexPath)
        case .multiSelection, .multiSelectionNewStyle:
            handleMultiSelectionEvent(at: indexPath)
        default:
            break
        }
    }

    func triggerToggle(at indexPath: IndexPath) {
        let section = indexPath.section
        let row = indexPath.row
        guard let item = itemGroups[safeIndex: section]?.items[safeIndex: row] as? PMActionSheetItem else {
            return
        }
        item.toggleState = !item.toggleState
        item.handler?(item)
    }
}

// MARK: - Handle tableview cell click event
extension PMActionSheetVM {
    private func handleClickableEvent(_ group: PMActionSheetItemGroup, at indexPath: IndexPath) {
        guard let item = group.items[safeIndex: indexPath.row] else {
            return
        }
        item.handler?(item)
        self.actionSheet?.dismiss(animated: true)
    }

    private func handleSingleSelectionEvent(at indexPath: IndexPath) {
        var updateRows: [Int] = []
        let count = itemGroups[indexPath.section].items.count
        for i in 0..<count {
            let isSelected = i == indexPath.row
            guard let itemToUpdate = itemGroups[safeIndex: indexPath.section]?.items[i],
                  itemToUpdate.markType.isSelected != isSelected else {
                continue
            }
            updateRows.append(i)
            itemToUpdate.markType = isSelected ? .checkMark : .none
        }
        if let selectedItem = itemGroups[safeIndex: indexPath.section]?.items[safeIndex: indexPath.row] {
            selectedItem.handler?(selectedItem)
        }
        let updatePaths = updateRows
            .map { IndexPath(row: $0, section: indexPath.section) }
        actionSheet?.reloadRows(at: updatePaths)
    }

    private func handleMultiSelectionEvent(at indexPath: IndexPath) {
        let section = indexPath.section
        let row = indexPath.row
        guard let item = itemGroups[safeIndex: section]?.items[safeIndex: row] as? PMActionSheetItem else {
            return
        }
        if item.markType == .none {
            item.markType = .checkMark
        } else {
            item.markType = .none
        }
        item.handler?(item)
        actionSheet?.reloadRows(at: [indexPath])
    }
}

#endif
