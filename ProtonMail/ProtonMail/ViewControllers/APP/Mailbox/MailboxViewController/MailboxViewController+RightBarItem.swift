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
import ProtonCoreUIFoundations
import UIKit

private enum BarButtonType: Int {
    case cancel = 1000
    case search, storageExceeded, composer, ellipsis, upsell
}

extension MailboxViewController {
    func setupRightButtons(_ editingMode: Bool, isStorageExceeded: Bool) {
        let items: [UIBarButtonItem]
        let isUpsellButtonVisible = viewModel.isUpsellButtonVisible

        if editingMode {
            items = [
                setupCancelBarItem()
            ]
        } else if self.viewModel.isTrashOrSpam {
            items = [
                setupEllipsisMenuBarItem(),
                setupSearchBarItem(),
                isUpsellButtonVisible ? setupUpsellBarButtonItem() : nil
            ].compactMap { $0 }
        } else {
            items = [
                isStorageExceeded ? setupStorageExceededBarItem() : setupComposerBarItem(),
                setupSearchBarItem(),
                isUpsellButtonVisible ? setupUpsellBarButtonItem() : nil
            ].compactMap { $0 }
        }

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
        let item = IconProvider.magnifier.toUIBarButtonItem(
            target: self,
            action: #selector(searchButtonTapped),
            tintColor: ColorProvider.IconNorm
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
        let item = IconProvider.penSquare.toUIBarButtonItem(
            target: self,
            action: #selector(storageExceededButtonTapped),
            tintColor: ColorProvider.Shade50
        )
        item.accessibilityLabel = LocalString._storage_exceeded
        item.tag = BarButtonType.storageExceeded.rawValue
        return item
    }

    private func setupComposerBarItem() -> UIBarButtonItem {
        let item = IconProvider.penSquare.toUIBarButtonItem(
            target: self,
            action: #selector(composeButtonTapped),
            tintColor: ColorProvider.IconNorm
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
            let menu = self.setupEllipsisMenu()
        let item = UIBarButtonItem(title: nil, image: IconProvider.threeDotsHorizontal, primaryAction: nil, menu: menu)
        item.accessibilityLabel = "MailboxViewController.ellipsisMenuBarItem"
        item.tag = BarButtonType.ellipsis.rawValue
        return item
    }

    private func setupEllipsisMenu() -> UIMenu {
        let composeAction = UIAction(title: LocalString._compose_message, image: IconProvider.penSquare, state: .off) { [weak self]_ in
            self?.composeButtonTapped()
        }
        let isTrashFolder = self.viewModel.labelID == LabelLocation.trash.labelID
        let title = isTrashFolder ? LocalString._empty_trash: LocalString._empty_spam
        let emptyIcon = IconProvider.trash.toTemplateUIImage()
        let emptyAction = UIAction(title: title, image: emptyIcon, state: .off) { [weak self] _ in
            guard self?.isAllowedEmptyFolder() ?? false else { return }
            self?.clickEmptyFolderAction()
        }
        let id: UIMenu.Identifier = .init(rawValue: "com.protonmail.menu.ellipsis")
        let menu = UIMenu(title: "", image: nil, identifier: id, options: [], children: [composeAction, emptyAction])
        return menu
    }

    private func setupUpsellBarButtonItem() -> UIBarButtonItem {
        let item = UIBarButtonItem(
            image: Asset.upsellButton.image,
            style: .plain,
            target: self,
            action: #selector(upsellButtonTapped)
        )
        item.accessibilityLabel = L10n.AutoDeleteUpsellSheet.upgradeButtonTitle
        item.tag = BarButtonType.upsell.rawValue
        return item
    }
}
