//
//  ContactsAndGroupsSharedCode.swift
//  ProtonMail - Created on 2018/9/13.
//
//
//  Copyright (c) 2019 Proton Technologies AG
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

import ProtonCore_UIFoundations
import ProtonCore_PaymentsUI

class ContactsAndGroupsSharedCode: ProtonMailViewController {

    var navigationItemRightNotEditing: [UIBarButtonItem]?
    var navigationItemLeftNotEditing: [UIBarButtonItem]?
    private var addBarButtonItem: UIBarButtonItem!
    private var user: UserManager?
    private var paymentsUI: PaymentsUI?

    let kAddContactSugue = "toAddContact"
    let kAddContactGroupSugue = "toAddContactGroup"
    let kSegueToImportView = "toImportContacts"

    var isOnMainView = true {
        didSet {
            if isOnMainView {
                self.tabBarController?.tabBar.isHidden = false
            } else {
                self.tabBarController?.tabBar.isHidden = true
            }
        }
    }

    func prepareNavigationItemRightDefault(_ user: UserManager) {
        self.user = user
        self.addBarButtonItem = Asset.menuPlus.image.toUIBarButtonItem(
            target: self,
            action: #selector(addButtonTapped),
            tintColor: ColorProvider.IconNorm,
            backgroundSquareSize: 40,
            isRound: true
        )
        self.addBarButtonItem.accessibilityLabel = LocalString._general_create_action

        let rightButtons: [UIBarButtonItem] = [self.addBarButtonItem]
        self.navigationItem.setRightBarButtonItems(rightButtons, animated: true)

        navigationItemLeftNotEditing = navigationItem.leftBarButtonItems
        navigationItemRightNotEditing = navigationItem.rightBarButtonItems
        self.navigationItem.assignNavItemIndentifiers()
        generateAccessibilityIdentifiers()
    }

    @objc private func addButtonTapped() {
        let cancelItem = PMActionSheetPlainItem(title: nil, icon: Asset.actionSheetClose.image) { [weak self] _ in
            let viewController = self?.tabBarController ?? self
            let subViews = viewController?.view.subviews
            let actionSheet = subViews?.compactMap { $0 as? PMActionSheet }.last
            actionSheet?.dismiss(animated: true)
        }
        let headerView =
            PMActionSheetHeaderView(title: LocalString._contacts_action_sheet_title,
                                    subtitle: nil,
                                    leftItem: cancelItem,
                                    rightItem: nil)
        let newContactAction =
            PMActionSheetPlainItem(title: LocalString._contacts_new_contact,
                                   icon: Asset.contactsNew.image,
                                   iconColor: ColorProvider.IconNorm) { _ in
                self.addContactTapped()
            }
        let newContactGroupAction =
            PMActionSheetPlainItem(title: LocalString._contact_groups_new,
                                   icon: Asset.contactGroupsNew.image,
                                   iconColor: ColorProvider.IconNorm) { _ in
                self.addContactGroupTapped()
            }
        let uploadDeviceContactAction =
            PMActionSheetPlainItem(title: LocalString._contacts_upload_device_contacts,
                                   icon: Asset.contactDeviceUpload.image,
                                   iconColor: ColorProvider.IconNorm) { _ in
                self.importButtonTapped()
            }
        let actionsGroup = PMActionSheetItemGroup(items: [newContactAction,
                                                          newContactGroupAction,
                                                          uploadDeviceContactAction],
                                                  style: .clickable)
        let actionSheet = PMActionSheet(headerView: headerView, itemGroups: [actionsGroup])
        actionSheet.presentAt(self.tabBarController ?? self, animated: true)
    }

    private func importButtonTapped() {
        let alertController = UIAlertController(title: LocalString._contacts_title,
                                                message: LocalString._upload_ios_contacts_to_protonmail,
                                                preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: LocalString._general_confirm_action,
                                                style: .default,
                                                handler: { (action) -> Void in
                                                    self.performSegue(withIdentifier: self.kSegueToImportView,
                                                                      sender: self)
        }))
        alertController.addAction(UIAlertAction(title: LocalString._general_cancel_button,
                                                style: .cancel,
                                                handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }

    private func addContactTapped() {
        self.performSegue(withIdentifier: kAddContactSugue, sender: self)
    }

    private func addContactGroupTapped() {
        if let user = self.user, user.hasPaidMailPlan {
            self.performSegue(withIdentifier: kAddContactGroupSugue, sender: self)
        } else {
            presentPlanUpgrade()
        }
    }

    private func presentPlanUpgrade() {
        guard let user = user else { return }
        self.paymentsUI = PaymentsUI(payments: user.payments, clientApp: .mail, shownPlanNames: Constants.shownPlanNames)
        self.paymentsUI?.showUpgradePlan(presentationType: .modal,
                                         backendFetch: true) { _ in }
    }

}
