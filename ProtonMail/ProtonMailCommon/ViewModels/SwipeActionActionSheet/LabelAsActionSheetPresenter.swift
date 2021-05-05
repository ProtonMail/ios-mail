//
//  LabelAsActionSheetPresenter.swift
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

class LabelAsActionSheetPresenter {
    func present(
        on viewController: UIViewController,
        viewModel: LabelAsActionSheetViewModel,
        addNewLabel: @escaping () -> Void,
        selected: @escaping (MenuLabel, Bool) -> Void,
        cancel: @escaping () -> Void,
        done: @escaping (_ isArchive: Bool) -> Void
    ) {
        var folderSelection: PMActionSheet?
        let labelItems = viewModel.menuLabels
        let rows = labelItems.count

        viewModel.initialLabelSelectionStatus.filter({ $0.value }).forEach({ selected($0.key, true) })

        var labelActions: [PMActionSheetPlainItem] = []
        for i in 0..<rows {
            let indexPath = IndexPath(row: i, section: 0)
            guard let menuLabel = labelItems.getFolderItem(by: indexPath) else {
                continue
            }
            let item = PMActionSheetPlainItem(title: menuLabel.name,
                                              icon: Asset.mailUnreadIcon.image,
                                              iconColor:
                                                UIColor(hexColorCode: menuLabel.iconColor),
                                              isOn: viewModel.initialLabelSelectionStatus[menuLabel] ?? false,
                                              indentationLevel: menuLabel.indentationLevel) { item in
                selected(menuLabel, item.isOn)
            }
            labelActions.append(item)
        }
        let archiveButton = PMActionSheetToggleItem(title: LocalString._label_as_send_to_archive,
                                                    icon: nil,
                                                    toggleColor: UIColorManager.BrandNorm)
        let doneButton = PMActionSheetPlainItem(title: LocalString._move_to_done_button_title,
                                                icon: nil,
                                                textColor: UIColorManager.BrandNorm) { _ in
            guard let toggleItem = folderSelection?.itemGroups?.first?.items.first else {
                done(false)
                return
            }
            done(toggleItem.isOn)
        }
        let cancelItem = PMActionSheetPlainItem(title: nil, icon: Asset.actionSheetClose.image) { _ in
            cancel()
        }
        let headerView = PMActionSheetHeaderView(title: LocalString._label_as_title,
                                                 subtitle: nil,
                                                 leftItem: cancelItem,
                                                 rightItem: doneButton)
        let add = PMActionSheetPlainItem(title: LocalString._label_as_new_label,
                                         icon: Asset.menuPlus.image,
                                         textColor: UIColorManager.TextWeak,
                                         iconColor: UIColorManager.TextWeak) { _ in
            addNewLabel()
        }
        let archiveGroup = PMActionSheetItemGroup(items: [archiveButton], style: .toggle)
        //TODO: observe item here
        let addFolderGroup = PMActionSheetItemGroup(items: [add], style: .clickable)


        let foldersGroup = PMActionSheetItemGroup(items: labelActions, style: .multiSelection)
        let actionSheet = PMActionSheet(headerView: headerView, itemGroups: [archiveGroup, addFolderGroup, foldersGroup])
        actionSheet.presentAt(viewController, hasTopConstant: false, animated: true)
        folderSelection = actionSheet
    }
}
