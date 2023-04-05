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
        done: @escaping (_ isArchive: Bool, _ currentOptionsStatus: [MenuLabel: PMActionSheetItem.MarkType]) -> Void
    ) {
        var labelSelectionActionSheet: PMActionSheet?
        let labelItems = viewModel.menuLabels
        let rows = labelItems.count

        viewModel.initialLabelSelectionStatus.filter({ $0.value == .checkMark }).forEach({ selected($0.key, true) })

        var labelActions: [PMActionSheetItem] = []
        for i in 0..<rows {
            guard let menuLabel = labelItems.getFolderItem(at: i) else {
                continue
            }
            var iconColor: UIColor = ColorProvider.IconNorm
            if let menuColor = menuLabel.iconColor {
                iconColor = UIColor(hexColorCode: menuColor)
            }
            let markType = viewModel.initialLabelSelectionStatus[menuLabel] ?? .none
            let item = PMActionSheetItem(
                components: [
                    PMActionSheetIconComponent(
                        icon: IconProvider.circleFilled,
                        iconColor: iconColor,
                        edge: [nil, nil, nil, 16]
                    ),
                    PMActionSheetTextComponent(text: .left(menuLabel.name), edge: [nil, 16, nil, 12])
                ],
                indentationLevel: menuLabel.indentationLevel,
                markType: markType) { item in
                    let isSelected = item.markType != .none
                    selected(menuLabel, isSelected)
                }
            labelActions.append(item)
        }
        let archiveButton = PMActionSheetItem(style: .toggle(LocalString._label_as_also_archive, false), handler: nil)

        let headerView = PMActionSheetHeaderView(
            title: LocalString._label_as_title,
            leftItem: .right(IconProvider.cross),
            rightItem: .left(LocalString._move_to_done_button_title),
            leftItemHandler: { [weak self] in
                guard let self = self else { return }
                let currentMarkTypes = self.currentMarkTypes(
                    viewModel: viewModel,
                    labelSelectionActionSheet: labelSelectionActionSheet
                )
                cancel(viewModel.initialLabelSelectionStatus != currentMarkTypes)
            },
            rightItemHandler: { [weak self] in
                guard let self = self else { return }
                let currentMarkTypes = self.currentMarkTypes(
                    viewModel: viewModel,
                    labelSelectionActionSheet: labelSelectionActionSheet
                )

                guard let toggleItem = labelSelectionActionSheet?.itemGroups.first?.items.first else {
                    done(false, currentMarkTypes)
                    return
                }
                done(toggleItem.toggleState, currentMarkTypes)
            }
        )

        let add = PMActionSheetItem(
            components: [
                PMActionSheetIconComponent(
                    icon: IconProvider.plus,
                    iconColor: ColorProvider.TextWeak,
                    edge: [nil, nil, nil, 16]
                ),
                PMActionSheetTextComponent(
                    text: .left(LocalString._label_as_new_label),
                    textColor: ColorProvider.TextWeak,
                    edge: [nil, 16, nil, 12]
                )
            ]) { _ in
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
        let actionSheet = PMActionSheet(headerView: headerView, itemGroups: itemGroups) /*, maximumOccupy: 0.7) */
        actionSheet.presentAt(viewController, hasTopConstant: false, animated: true)
        actionSheet.eventsListener = listener
        labelSelectionActionSheet = actionSheet
        delay(0.3) {
            if UIAccessibility.isVoiceOverRunning {
                UIAccessibility.post(notification: .screenChanged, argument: actionSheet)
            }
        }
    }

    private func currentMarkTypes(
        viewModel: LabelAsActionSheetViewModel,
        labelSelectionActionSheet: PMActionSheet?
    ) -> [MenuLabel : PMActionSheetItem.MarkType] {
        // Collect current label markType status of all options in the action sheet
        var currentMarkTypes = viewModel.initialLabelSelectionStatus

        labelSelectionActionSheet?.itemGroups.last?.items
            .forEach { item in
                for component in item.components {
                    guard let textComponent = component as? PMActionSheetTextComponent else { continue }
                    var title = ""
                    switch textComponent.text {
                    case .left(let text):
                        title = text
                    case .right(let attributed):
                        title = attributed.string
                    }
                    if let option = currentMarkTypes.first(where: { $0.key.name == title }) {
                        currentMarkTypes[option.key] = item.markType
                    }
                }
            }
        return currentMarkTypes
    }
}
