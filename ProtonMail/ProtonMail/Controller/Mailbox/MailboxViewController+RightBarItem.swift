// Copyright (c) 2021 Proton Technologies AG
//
// This file is part of ProtonMail.
//
// ProtonMail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// ProtonMail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with ProtonMail. If not, see https://www.gnu.org/licenses/.

import Foundation
import ProtonCore_UIFoundations
import UIKit

private enum BarButtonType: Int {
    case cancel = 1000
    case search, storageExceeded, composer, ellipsis
}

// MARK: Setup right bar items
extension MailboxViewController {
    func setupRightButtons(_ editingMode: Bool) {
        if editingMode {
            let cancelBarItem = self.setupCancelBarItem()
            self.updateRightButtonsIfNeeded(items: [cancelBarItem])
            return
        }

        if self.viewModel.isTrashOrSpam {
            let items = [
                setupEllipsisMenuBarItem(),
                setupSearchBarItem()
            ]
            self.updateRightButtonsIfNeeded(items: items)
            return
        }

        let item: UIBarButtonItem = self.viewModel.user.isStorageExceeded ? setupStorageExceededBarItem(): setupComposerBarItem()
        let items = [item, setupSearchBarItem()]
        self.updateRightButtonsIfNeeded(items: items)
    }

    private func updateRightButtonsIfNeeded(items: [UIBarButtonItem]) {
        let itemTags = items.map({ $0.tag }).sorted()
        let oldItemTags = self.navigationItem.rightBarButtonItems?
            .compactMap({ $0.tag })
            .sorted()
        guard itemTags != oldItemTags else { return }
        self.navigationItem.setRightBarButtonItems(items, animated: false)
    }

    private func setupCancelBarItem() -> UIBarButtonItem {
        let item = UIBarButtonItem(title: LocalString._general_cancel_button,
                                   style: UIBarButtonItem.Style.plain,
                                   target: self,
                                   action: #selector(cancelButtonTapped))
        item.tintColor = ColorProvider.BrandNorm
        item.accessibilityLabel = LocalString._general_cancel_button
        item.tag = BarButtonType.cancel.rawValue
        return item
    }

    private func setupSearchBarItem() -> UIBarButtonItem {
        let item = Asset.searchIcon.image.toUIBarButtonItem(
            target: self,
            action: #selector(searchButtonTapped),
            tintColor: ColorProvider.IconNorm,
            backgroundSquareSize: 40
        )
        #if DEBUG
        item.accessibilityLabel = "MailboxViewController.searchBarButtonItem"
        #else
        item.accessibilityLabel = LocalString._general_search_placeholder
        #endif
        item.tag = BarButtonType.search.rawValue
        return item
    }

    private func setupStorageExceededBarItem() -> UIBarButtonItem {
        let item = Asset.composeIcon.image.toUIBarButtonItem(
            target: self,
            action: #selector(storageExceededButtonTapped),
            tintColor: ColorProvider.Shade50,
            backgroundSquareSize: 40
        )
        item.accessibilityLabel = LocalString._storage_exceeded
        item.tag = BarButtonType.storageExceeded.rawValue
        return item
    }

    private func setupComposerBarItem() -> UIBarButtonItem {
        let item = Asset.composeIcon.image.toUIBarButtonItem(
            target: self,
            action: #selector(composeButtonTapped),
            tintColor: ColorProvider.IconNorm,
            backgroundSquareSize: 40
        )
        #if DEBUG
        item.accessibilityLabel = "MailboxViewController.composeBarButtonItem"
        #else
        item.accessibilityLabel = LocalString._composer_compose_action
        #endif
        item.tag = BarButtonType.composer.rawValue
        return item
    }

    private func setupEllipsisMenuBarItem() -> UIBarButtonItem {
        let item: UIBarButtonItem
        if #available(iOS 14.0, *) {
            let menu = self.setupEllipsisMenu()
            item = UIBarButtonItem(title: nil, image: Asset.messageExpandCollapse.image, primaryAction: nil, menu: menu)
        } else {
            item = Asset.messageExpandCollapse.image.toUIBarButtonItem(
                target: self,
                action: #selector(ellipsisMenuTapped(sender:)),
                tintColor: ColorProvider.IconNorm,
                backgroundSquareSize: 40)
        }
        item.accessibilityLabel = "MailboxViewController.ellipsisMenuBarItem"
        item.tag = BarButtonType.ellipsis.rawValue
        return item
    }

    @available(iOS 14.0, *)
    private func setupEllipsisMenu() -> UIMenu {
        let composeAction = UIAction(title: LocalString._compose_message, image: Asset.composeIcon.image, state: .off) { [weak self]_ in
            self?.composeButtonTapped()
        }
        let isTrashFolder = self.viewModel.labelID == LabelLocation.trash.labelID
        let title = isTrashFolder ? LocalString._empty_trash: LocalString._empty_spam
        let emptyIcon = Asset.topTrash.image.toTemplateUIImage()
        let emptyAction = UIAction(title: title, image: emptyIcon, state: .off) { [weak self] _ in
            guard self?.isAllowedEmptyFolder() ?? false else { return }
            self?.clickEmptyFolderAction()
        }
        let id: UIMenu.Identifier = .init(rawValue: "com.protonmail.menu.ellipsis")
        let menu = UIMenu(title: "", image: nil, identifier: id, options: [], children: [composeAction, emptyAction])
        return menu
    }
}
