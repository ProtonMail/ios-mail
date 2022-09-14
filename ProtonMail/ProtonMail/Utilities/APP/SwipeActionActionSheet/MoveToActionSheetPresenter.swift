//
//  MoveToActionSheetPresenter.swift
//  Proton Mail
//
//
//  Copyright (c) 2021 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import ProtonCore_UIFoundations
import UIKit

class MoveToActionSheetPresenter {

    func present(
        on viewController: UIViewController,
        listener: PMActionSheetEventsListener? = nil,
        viewModel: MoveToActionSheetViewModel,
        hasNewFolderButton: Bool = true,
        addNewFolder: @escaping () -> Void,
        selected: @escaping (MenuLabel, Bool) -> Void,
        cancel: @escaping (_ havingUnsaveChanges: Bool) -> Void,
        done: @escaping (_ havingUnsaveChanges: Bool) -> Void
    ) {
        var folderSelectionActionSheet: PMActionSheet?
        let doneButton = PMActionSheetPlainItem(title: LocalString._move_to_done_button_title,
                                                icon: nil,
                                                textColor: ColorProvider.BrandNorm) { _ in
            // Collect current label markType status of all options in the action sheet
            var currentMarkTypes = viewModel.initialLabelSelectionStatus
            let currentLabelOptions = folderSelectionActionSheet?.itemGroups?.last?.items.compactMap({ $0 as? PMActionSheetPlainItem })
            currentLabelOptions?.forEach({ item in
                if let option = currentMarkTypes.first(where: { key, _ in
                    key.name == item.title
                }) {
                    currentMarkTypes[option.key] = item.markType
                }
            })

            done(currentMarkTypes != viewModel.initialLabelSelectionStatus)
        }

        let cancelItem = PMActionSheetPlainItem(title: nil, icon: IconProvider.cross) { _ in
            // Collect current label markType status of all options in the action sheet
            var currentMarkTypes = viewModel.initialLabelSelectionStatus
            let currentLabelOptions = folderSelectionActionSheet?.itemGroups?.last?.items.compactMap({ $0 as? PMActionSheetPlainItem })
            currentLabelOptions?.forEach({ item in
                if let option = currentMarkTypes.first(where: { key, _ in
                    key.name == item.title
                }) {
                    currentMarkTypes[option.key] = item.markType
                }
            })

            cancel(currentMarkTypes != viewModel.initialLabelSelectionStatus)
        }

        let rows = viewModel.menuLabels.getNumberOfRows()
        var folderActions: [PMActionSheetPlainItem] = []
        for i in 0..<rows {
            guard let menuLabel = viewModel.menuLabels.getFolderItem(at: i) else {
                continue
            }

            var icon: UIImage?
            if let menuIcon = menuLabel.location.icon {
                icon = menuIcon
            } else {
                if menuLabel.subLabels.count > 0 {
                    icon = viewModel.isEnableColor ? IconProvider.foldersFilled: IconProvider.folders
                } else {
                    icon = viewModel.isEnableColor ? IconProvider.folderFilled: IconProvider.folder
                }
            }

            let iconColor = viewModel.getColor(of: menuLabel)

            let markType = viewModel.initialLabelSelectionStatus[menuLabel] ?? .none
            let isOn = markType != .none
            let item = PMActionSheetPlainItem(title: menuLabel.name,
                                              icon: icon?.withRenderingMode(.alwaysTemplate),
                                              iconColor: iconColor,
                                              isOn: isOn,
                                              markType: markType,
                                              indentationLevel: menuLabel.indentationLevel) { item in
                selected(menuLabel, item.isOn)
            }
            folderActions.append(item)
        }

        let headerView = PMActionSheetHeaderView(title: LocalString._move_to_title,
                                                 subtitle: nil,
                                                 leftItem: cancelItem,
                                                 rightItem: doneButton)
        let add = PMActionSheetPlainItem(title: LocalString._move_to_new_folder,
                                         icon: IconProvider.plus,
                                         textColor: ColorProvider.TextWeak) { _ in
            addNewFolder()
        }
        let addFolderGroup = PMActionSheetItemGroup(items: [add], style: .clickable)

        let foldersGroup = PMActionSheetItemGroup(items: folderActions, style: .singleSelection)
        var itemGroups: [PMActionSheetItemGroup] = [foldersGroup]
        if hasNewFolderButton {
            itemGroups.insert(addFolderGroup, at: 0)
        }
        let actionSheet = PMActionSheet(headerView: headerView, itemGroups: itemGroups, maximumOccupy: 0.7)
        actionSheet.eventsListener = listener
        actionSheet.presentAt(viewController, hasTopConstant: false, animated: true)
        folderSelectionActionSheet = actionSheet
        delay(0.3) {
            if UIAccessibility.isVoiceOverRunning {
                UIAccessibility.post(notification: .screenChanged, argument: actionSheet)
            }
        }
    }
}
