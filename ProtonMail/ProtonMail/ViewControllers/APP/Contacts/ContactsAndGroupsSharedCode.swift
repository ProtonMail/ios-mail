//
//  ContactsAndGroupsSharedCode.swift
//  Proton Mail - Created on 2018/9/13.
//
//
//  Copyright (c) 2019 Proton AG
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

import Contacts
import ProtonCore_UIFoundations
import ProtonCore_PaymentsUI

class ContactsAndGroupsSharedCode: ProtonMailViewController {

    var navigationItemRightNotEditing: [UIBarButtonItem]?
    var navigationItemLeftNotEditing: [UIBarButtonItem]?
    private var addBarButtonItem: UIBarButtonItem!
    private var user: UserManager?
    private var paymentsUI: PaymentsUI?
    private let store: CNContactStore = CNContactStore()

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
        self.addBarButtonItem = IconProvider.plus.toUIBarButtonItem(
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
        let headerView =
            PMActionSheetHeaderView(title: LocalString._contacts_action_sheet_title,
                                    subtitle: nil,
                                    leftItem: .right(IconProvider.cross),
                                    rightItem: nil,
                                    leftItemHandler: { [weak self] in
                                        let viewController = self?.tabBarController ?? self
                                        let subViews = viewController?.view.subviews
                                        let actionSheet = subViews?.compactMap { $0 as? PMActionSheet }.last
                                        actionSheet?.dismiss(animated: true)
                                    })
        let newContactAction = PMActionSheetItem(
            style: .default(IconProvider.userPlus, LocalString._contacts_new_contact)
        ) { _ in
            self.addContactTapped()
        }
        let newContactGroupAction = PMActionSheetItem(
            style: .default(IconProvider.usersPlus, LocalString._contact_groups_new)
        ) { _ in
            self.addContactGroupTapped()
        }
        let uploadDeviceContactAction = PMActionSheetItem(
            style: .default(IconProvider.mobilePlus, LocalString._contacts_upload_device_contacts)
        ) { _ in
            self.importButtonTapped()
        }
        let actionsGroup = PMActionSheetItemGroup(items: [newContactAction,
                                                          newContactGroupAction,
                                                          uploadDeviceContactAction],
                                                  style: .clickable)
        let actionSheet = PMActionSheet(headerView: headerView, itemGroups: [actionsGroup]) /*, maximumOccupy: 0.7) */
        actionSheet.presentAt(self.tabBarController ?? self, animated: true)
    }

    private func importButtonTapped() {
        switch CNContactStore.authorizationStatus(for: .contacts) {
        case .notDetermined:
            self.requestContactPermission()
        case .restricted:
            "The application is not authorized to access contact data".alertToast()
        case .denied:
            "Contacts access denied, please allow access from settings".alertToast()
        case .authorized:
            self.showImportConfirmPopup()
        @unknown default:
            return
        }
    }

    private func showImportConfirmPopup() {
        let alertController = UIAlertController(title: LocalString._contacts_title,
                                                message: LocalString._upload_ios_contacts_to_protonmail,
                                                preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: LocalString._general_confirm_action,
                                                style: .default,
                                                handler: { [weak self] _ -> Void in
            self?.showContactImportView()
        }))
        alertController.addAction(UIAlertAction(title: LocalString._general_cancel_button,
                                                style: .cancel,
                                                handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }

    func addContactTapped() {
        fatalError("Needs implementation in subclass")
    }

    func showContactImportView() {
        fatalError("Needs implementation in subclass")
    }

    func addContactGroupTapped() {
        fatalError("Needs implementation in subclass")
    }

    func presentPlanUpgrade() {
        guard let user = user else { return }
        self.paymentsUI = PaymentsUI(payments: user.payments, clientApp: .mail, shownPlanNames: Constants.shownPlanNames)
        self.paymentsUI?.showUpgradePlan(presentationType: .modal,
                                         backendFetch: true) { _ in }
    }

    private func requestContactPermission() {
        self.store.requestAccess(for: .contacts) { [weak self] isAllowed, error in
            guard isAllowed else { return }
            DispatchQueue.main.async {
                self?.showImportConfirmPopup()
            }
        }
    }
}
