// Copyright (c) 2022 Proton AG
//
// This file is part of Proton Mail.
//
// Proton Mail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Mail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Mail. If not, see https://www.gnu.org/licenses/.

import Foundation
import UIKit

final class ToolbarCustomizeViewModel<T: ToolbarAction> {
    private(set) var currentActions: [T]
    private let actionsNotAddableToToolbar: [T]
    private let allActions: [T]
    private let defaultActions: [T]
    var availableActions: [T] {
        return allActions
            .filter { !currentActions.contains($0) && !actionsNotAddableToToolbar.contains($0) }
    }

    var reloadTableView: (() -> Void)?
    var shouldShowInfoBubbleView: Bool {
        !infoBubbleViewStatusProvider.shouldHideToolbarCustomizeInfoBubbleView
    }
    let numberOfSections = 2
    private let infoBubbleViewStatusProvider: ToolbarCustomizationInfoBubbleViewStatusProvider
    let alertTitle = LocalString._toolbar_customize_reset_alert_title
    let alertContent = LocalString._toolbar_customize_reset_alert_content

    init(currentActions: [T],
         allActions: [T],
         actionsNotAddableToToolbar: [T],
         defaultActions: [T],
         infoBubbleViewStatusProvider: ToolbarCustomizationInfoBubbleViewStatusProvider) {
        self.currentActions = currentActions
        self.allActions = allActions
        self.defaultActions = defaultActions
        self.actionsNotAddableToToolbar = actionsNotAddableToToolbar
        self.infoBubbleViewStatusProvider = infoBubbleViewStatusProvider
    }

    func numberOfRowsInSection(section: Int) -> Int {
        switch section {
        case 0:
            return currentActions.count
        case 1:
            return availableActions.count
        default:
            return 0
        }
    }

    func toolbarAction(at indexPath: IndexPath) -> T? {
        switch indexPath.section {
        case 0:
            return currentActions[safeIndex: indexPath.row]
        case 1:
            return availableActions[safeIndex: indexPath.row]
        default:
            return nil
        }
    }

    func cellIsEnable(at indexPath: IndexPath) -> Bool {
        if currentActions.count >= 5, indexPath.section >= 1 {
            return false
        }
        return true
    }

    func isAnSelectedAction(of action: T) -> Bool {
        return currentActions.contains(action)
    }

    func handleCellAction(action: ToolbarCustomizeCell.Action, indexPath: IndexPath) {
        guard let toolbarAction = getAction(by: indexPath) else {
            return
        }

        if currentActions.count >= 5, indexPath.section == 1 {
            return
        }

        switch action {
        case .insert:
            if !currentActions.contains(toolbarAction) {
                currentActions.append(toolbarAction)
            }
        case .remove:
            currentActions.removeAll(where: { $0 == toolbarAction })
        }
        reloadTableView?()
    }

    func hideInfoBubbleView() {
        infoBubbleViewStatusProvider.shouldHideToolbarCustomizeInfoBubbleView = true
    }

    func moveAction(from source: IndexPath, to destination: IndexPath) {
        guard source.section == 0, destination.section == 0 else {
            return
        }
        guard currentActions.indices.contains(source.row),
              currentActions.indices.contains(destination.row) else {
            return
        }
        let removedItem = currentActions.remove(at: source.row)
        currentActions.insert(removedItem, at: destination.row)
    }

    func resetActionsToDefault() {
        currentActions = defaultActions
        reloadTableView?()
    }

    private func getAction(by indexPath: IndexPath) -> T? {
        switch indexPath.section {
        case 0:
            return currentActions[safeIndex: indexPath.row]
        case 1:
            return availableActions[safeIndex: indexPath.row]
        default:
            return nil
        }
    }

    #if DEBUG
    func setActions(actions: [T]) {
        self.currentActions = actions
    }
    #endif
}
