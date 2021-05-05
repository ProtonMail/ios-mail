//
//  MoveToActionSheetPresenter.swift
//  ProtonMail
//
//
//  Copyright (c) 2021 Proton Technologies AG
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

import PMUIFoundations
import UIKit

class MoveToActionSheetPresenter {

    func present(
        on viewController: UIViewController,
        viewModel: MoveToActionSheetViewModel,
        addNewFolder: @escaping () -> Void,
        selected: @escaping (MenuLabel, Bool) -> Void,
        cancel: @escaping () -> Void,
        done: @escaping () -> Void
    ) {
        let doneButton = PMActionSheetPlainItem(title: LocalString._move_to_done_button_title,
                                                icon: nil,
                                                textColor: UIColorManager.BrandNorm) { _ in
            done()
        }

        let cancelItem = PMActionSheetPlainItem(title: nil, icon: Asset.actionSheetClose.image) { _ in
            cancel()
        }

        let rows = viewModel.menuLabels.getNumberOfRows()
        var folderActions: [PMActionSheetPlainItem] = []
        for i in 0..<rows {
            let indexPath = IndexPath(row: i, section: 0)
            guard let menuLabel = viewModel.menuLabels.getFolderItem(by: indexPath) else {
                continue
            }

            var icon: UIImage?
            if let menuIcon = menuLabel.location.icon {
                icon = menuIcon
            } else {
                if menuLabel.subLabels.count > 0 {
                    icon = viewModel.isEnableColor ? Asset.icFolderMultipleFilled.image: Asset.menuFolderMultiple.image
                } else {
                    icon = viewModel.isEnableColor ? Asset.icFolderFilled.image: Asset.menuFolder.image
                }
            }

            let iconColor = viewModel.getColor(of: menuLabel)

            let item = PMActionSheetPlainItem(title: menuLabel.name,
                                              icon: icon,
                                              iconColor: iconColor,
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
                                         icon: Asset.menuPlus.image,
                                         textColor: UIColorManager.TextWeak) { _ in
            addNewFolder()
        }
        let addFolderGroup = PMActionSheetItemGroup(items: [add], style: .clickable)


        let foldersGroup = PMActionSheetItemGroup(items: folderActions, style: .singleSelection)
        let folderSelection = PMActionSheet(headerView: headerView, itemGroups: [addFolderGroup, foldersGroup])
        folderSelection.presentAt(viewController, hasTopConstant: false, animated: true)
    }
}
