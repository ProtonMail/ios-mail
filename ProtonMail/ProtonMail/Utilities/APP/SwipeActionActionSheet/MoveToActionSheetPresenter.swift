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

import ProtonCoreUIFoundations
import UIKit

final class MoveToActionSheetPresenter {

    func present(
        on viewController: UIViewController,
        listener: PMActionSheetEventsListener? = nil,
        viewModel: MoveToActionSheetViewModel,
        hasNewFolderButton: Bool = true,
        addNewFolder: @escaping () -> Void,
        selected: @escaping (MenuLabel, Bool) -> Void,
        cancel: @escaping () -> Void
    ) {
        let rows = viewModel.menuLabels.getNumberOfRows()
        var folderActions: [PMActionSheetItem] = []
        for i in 0..<rows {
            guard let menuLabel = viewModel.menuLabels.getFolderItem(at: i) else {
                continue
            }

            var icon: UIImage
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
            let item = PMActionSheetItem(
                components: [
                    PMActionSheetIconComponent(
                        icon: icon.withRenderingMode(.alwaysTemplate),
                        iconColor: iconColor,
                        edge: [nil, nil, nil, 16]
                    ),
                    PMActionSheetTextComponent(text: .left(menuLabel.name), edge: [nil, 16, nil, 12])
                ],
                indentationLevel: menuLabel.indentationLevel,
                markType: .none,
                handler: { item in
                    let isSelected = item.markType != .none
                    selected(menuLabel, isSelected)
                })
            folderActions.append(item)
        }

        let headerView = PMActionSheetHeaderView(
            title: LocalString._move_to_title,
            leftItem: .right(IconProvider.cross),
            rightItem: nil,
            leftItemHandler: { cancel() },
            rightItemHandler: nil
        )

        let add = PMActionSheetItem(
            components: [
                PMActionSheetIconComponent(
                    icon: IconProvider.plus,
                    iconColor: ColorProvider.TextWeak,
                    edge: [nil, nil, nil, 16]
                ),
                PMActionSheetTextComponent(
                    text: .left(LocalString._new_folder),
                    textColor: ColorProvider.TextWeak,
                    edge: [nil, 16, nil, 12]
                )
            ]) { _ in
                addNewFolder()
            }
        let addFolderGroup = PMActionSheetItemGroup(items: [add], style: .clickable)

        let foldersGroup = PMActionSheetItemGroup(items: folderActions, style: .singleSelection)
        var itemGroups: [PMActionSheetItemGroup] = [foldersGroup]
        if hasNewFolderButton {
            itemGroups.insert(addFolderGroup, at: 0)
        }
        let actionSheet = PMActionSheet(headerView: headerView, itemGroups: itemGroups) /*, maximumOccupy: 0.7) */
        actionSheet.eventsListener = listener
        actionSheet.presentAt(viewController, hasTopConstant: false, animated: true)
        delay(0.3) {
            if UIAccessibility.isVoiceOverRunning {
                UIAccessibility.post(notification: .screenChanged, argument: actionSheet)
            }
        }
    }
}
