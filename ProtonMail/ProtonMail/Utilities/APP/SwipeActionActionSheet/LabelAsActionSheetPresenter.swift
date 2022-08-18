//
//  LabelAsActionSheetPresenter.swift
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

class LabelAsActionSheetPresenter {
    func present(
        on viewController: UIViewController,
        listener: PMActionSheetEventsListener? = nil,
        viewModel: LabelAsActionSheetViewModel,
        hasNewLabelButton: Bool = true,
        addNewLabel: @escaping () -> Void,
        selected: @escaping (MenuLabel, Bool) -> Void,
        cancel: @escaping (_ isHavingUnsavedChanges: Bool) -> Void,
        done: @escaping (_ isArchive: Bool, _ currentOptionsStatus: [MenuLabel: PMActionSheetPlainItem.MarkType]) -> Void
    ) {
        var labelSelectionActionSheet: PMActionSheet?
        let labelItems = viewModel.menuLabels
        let rows = labelItems.count

        viewModel.initialLabelSelectionStatus.filter({ $0.value == .checkMark }).forEach({ selected($0.key, true) })

        var labelActions: [PMActionSheetPlainItem] = []
        for i in 0..<rows {
            let indexPath = IndexPath(row: i, section: 0)
            guard let menuLabel = labelItems.getFolderItem(by: indexPath) else {
                continue
            }
            var iconColor: UIColor = ColorProvider.IconNorm
            if let menuColor = menuLabel.iconColor {
                iconColor = UIColor(hexColorCode: menuColor)
            }
            let markType = viewModel.initialLabelSelectionStatus[menuLabel] ?? .none
            let isOn = markType != .none
            let item = PMActionSheetPlainItem(title: menuLabel.name,
                                              icon: IconProvider.circleFilled,
                                              iconColor: iconColor,
                                              isOn: isOn,
                                              markType: markType,
                                              indentationLevel: menuLabel.indentationLevel) { item in
                selected(menuLabel, item.isOn)
            }
            labelActions.append(item)
        }
        let archiveButton = PMActionSheetToggleItem(title: LocalString._label_as_also_archive,
                                                    icon: nil,
                                                    toggleColor: ColorProvider.BrandNorm)
        let doneButton = PMActionSheetPlainItem(title: LocalString._move_to_done_button_title,
                                                icon: nil,
                                                textColor: ColorProvider.BrandNorm) { _ in
            // Collect current label markType status of all options in the action sheet
            var currentMarkTypes = viewModel.initialLabelSelectionStatus
            let currentLabelOptions = labelSelectionActionSheet?.itemGroups?.last?.items.compactMap({ $0 as? PMActionSheetPlainItem })
            currentLabelOptions?.forEach({ item in
                if let option = currentMarkTypes.first(where: { key, _ in
                    key.name == item.title
                }) {
                    currentMarkTypes[option.key] = item.markType
                }
            })

            guard let toggleItem = labelSelectionActionSheet?.itemGroups?.first?.items.first else {
                done(false, currentMarkTypes)
                return
            }
            done(toggleItem.isOn, currentMarkTypes)
        }
        let cancelItem = PMActionSheetPlainItem(title: nil, icon: IconProvider.cross) { _ in
            // Collect current label markType status of all options in the action sheet
            var currentMarkTypes = viewModel.initialLabelSelectionStatus
            let currentLabelOptions = labelSelectionActionSheet?.itemGroups?.last?.items.compactMap({ $0 as? PMActionSheetPlainItem })
            currentLabelOptions?.forEach({ item in
                if let option = currentMarkTypes.first(where: { key, _ in
                    key.name == item.title
                }) {
                    currentMarkTypes[option.key] = item.markType
                }
            })
            cancel(viewModel.initialLabelSelectionStatus != currentMarkTypes)
        }
        let headerView = PMActionSheetHeaderView(title: LocalString._label_as_title,
                                                 subtitle: nil,
                                                 leftItem: cancelItem,
                                                 rightItem: doneButton)
        let add = PMActionSheetPlainItem(title: LocalString._label_as_new_label,
                                         icon: IconProvider.plus,
                                         textColor: ColorProvider.TextWeak,
                                         iconColor: ColorProvider.TextWeak) { _ in
            addNewLabel()
        }
        let archiveGroup = PMActionSheetItemGroup(items: [archiveButton], style: .toggle)
        // TODO: observe item here
        let addFolderGroup = PMActionSheetItemGroup(items: [add], style: .clickable)

        let foldersGroup = PMActionSheetItemGroup(items: labelActions, style: .multiSelection)
        var itemGroups: [PMActionSheetItemGroup] = [archiveGroup, foldersGroup]
        if hasNewLabelButton {
            itemGroups.insert(addFolderGroup, at: 1)
        }
        let actionSheet = PMActionSheet(headerView: headerView, itemGroups: itemGroups, maximumOccupy: 0.7)
        actionSheet.presentAt(viewController, hasTopConstant: false, animated: true)
        actionSheet.eventsListener = listener
        labelSelectionActionSheet = actionSheet
        delay(0.3) {
            if UIAccessibility.isVoiceOverRunning {
                UIAccessibility.post(notification: .screenChanged, argument: actionSheet)
            }
        }
    }
}
