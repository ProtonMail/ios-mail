// Copyright (c) 2021 Proton AG
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
import ProtonCore_UIFoundations

final class ContactGroupSubSelectionActionSheetPresenter {
    private var actionSheet: PMActionSheet?
    private let sourceViewController: UIViewController
    private let viewModel: ContactGroupSubSelectionViewModel
    private var callback: (([DraftEmailData]) -> Void)?

    init(sourceViewController: UIViewController,
         user: UserManager,
         group: ContactGroupVO,
         callback: (([DraftEmailData]) -> Void)?) {
        self.sourceViewController = sourceViewController
        self.viewModel = ContactGroupSubSelectionViewModelImpl(contactGroupName: group.contactTitle,
                                                               selectedEmails: group.getSelectedEmailData(),
                                                               labelsDataService: user.labelService)
        self.callback = callback
    }

    func present() {
        var actionSheetItems: [PMActionSheetItem] = []
        for index in 0..<viewModel.getTotalRows() {
            let info = viewModel.cellForRow(at: IndexPath(row: index, section: 0))
            let markType: PMActionSheetItem.MarkType = info.isSelected ? .checkMark : .none
            let item = PMActionSheetItem(style: .text(info.email), markType: markType) { [weak self] item in
                if item.markType == .checkMark {
                    self?.viewModel.select(indexPath: IndexPath(row: index, section: 0))
                } else {
                    self?.viewModel.deselect(indexPath: IndexPath(row: index, section: 0))
                }
            }
            actionSheetItems.append(item)
        }

        let headerView = PMActionSheetHeaderView(
            title: viewModel.getGroupName(),
            leftItem: .right(IconProvider.cross),
            rightItem: .left(LocalString._general_apply_button),
            leftItemHandler: { [weak self] in
                self?.actionSheet?.dismiss(animated: true)
            },
            rightItemHandler: { [weak self] in
                guard let self = self else { return }
                self.callback?(self.viewModel.getCurrentlySelectedEmails())
                self.actionSheet?.dismiss(animated: true)
            }
        )

        actionSheet = PMActionSheet(
            headerView: headerView,
            itemGroups: [PMActionSheetItemGroup(items: actionSheetItems, style: .multiSelection)]
        )
        actionSheet?.presentAt(sourceViewController, animated: true)
    }
}
