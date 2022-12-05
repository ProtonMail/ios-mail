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
        var actionSheetItems: [PMActionSheetPlainItem] = []
        for index in 0..<viewModel.getTotalRows() {
            let info = viewModel.cellForRow(at: IndexPath(row: index, section: 0))
            let item = PMActionSheetPlainItem(title: info.email, icon: nil, isOn: info.isSelected) { [weak self] item in
                if item.isOn {
                    self?.viewModel.select(indexPath: IndexPath(row: index, section: 0))
                } else {
                    self?.viewModel.deselect(indexPath: IndexPath(row: index, section: 0))
                }
            }
            actionSheetItems.append(item)
        }
        let cancelItem = PMActionSheetPlainItem(title: nil, icon: IconProvider.cross) { [weak self] _ in
            self?.actionSheet?.dismiss(animated: true)
        }

        let applyItem = PMActionSheetPlainItem(title: LocalString._general_apply_button,
                                               icon: nil,
                                               textColor: ColorProvider.BrandNorm) { [weak self] _ in
            guard let self = self else { return }
            self.callback?(self.viewModel.getCurrentlySelectedEmails())
            self.actionSheet?.dismiss(animated: true)
        }

        let headerView = PMActionSheetHeaderView(
            title: viewModel.getGroupName(),
            subtitle: nil,
            leftItem: cancelItem,
            rightItem: applyItem
        )

        self.actionSheet = PMActionSheet(headerView: headerView, itemGroups: [PMActionSheetItemGroup(items: actionSheetItems, style: .multiSelection)])
        self.actionSheet?.presentAt(sourceViewController, animated: true)
    }
}
