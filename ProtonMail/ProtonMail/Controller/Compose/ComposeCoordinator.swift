//
//  ComposeCoordinator.swift
//  ProtonMail - Created on 10/29/18.
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

import UIKit

class ComposeCoordinator: DefaultCoordinator {
    typealias VC = ComposeViewController

    weak var viewController: ComposeViewController?
    weak var navigationController: UINavigationController?

    let viewModel: ComposeViewModel
    var services: ServiceFactory

    init(vc: ComposeViewController, vm: ComposeViewModel, services: ServiceFactory) {
        self.viewModel = vm
        self.viewController = vc
        self.services = services
    }

    weak var delegate: CoordinatorDelegate?

    enum Destination: String {
        case password          = "to_eo_password_segue"
        case expirationWarning = "expiration_warning_segue"
        case subSelection      = "toContactGroupSubSelection"
    }

    func navigate(from source: UIViewController, to destination: UIViewController, with identifier: String?, and sender: AnyObject?) -> Bool {
        guard let segueID = identifier, let dest = Destination(rawValue: segueID) else {
            return false //
        }

        switch dest {
        case .password:
            guard let popup = destination as? ComposePasswordViewController else {
                return false
            }

            guard let vc = viewController else {
                return false
            }

            popup.pwdDelegate = self
            // get this data from view model
            popup.setupPasswords(vc.encryptionPassword, confirmPassword: vc.encryptionConfirmPassword, hint: vc.encryptionPasswordHint)

        case .expirationWarning:
            guard let vc = viewController else {
                return false
            }
            let nonPMEmails = vc.encryptionPassword.count <= 0 ? vc.headerView.nonePMEmails : [String]()
            let pgpEmails = vc.headerView.pgpEmails
            guard nonPMEmails.count > 0 || pgpEmails.count > 0 else {
                vc.sendMessageStepTwo()
                return false
            }
            vc.showExpirationUnavailabilityAlert(nonPMEmails: nonPMEmails, pgpEmails: pgpEmails)
        case .subSelection:
            return false
        }
        return true
    }

    func start() {
        viewController?.set(viewModel: self.viewModel)
        viewController?.set(coordinator: self)

        if let navigation = self.navigationController, let vc = self.viewController {
            navigation.setViewControllers([vc], animated: true)
        }
    }

    func go(to dest: Destination) {
        if dest == .subSelection {
            presentGroupSubSelectionActionSheet()
        } else {
            self.viewController?.performSegue(withIdentifier: dest.rawValue, sender: nil)
        }
    }

    func presentGroupSubSelectionActionSheet() {
        guard let vc = viewController,
              let navVC = vc.navigationController,
              let group = vc.pickedGroup else {
            return
        }
        vc.groupSubSelectionPresenter = ContactGroupSubSelectionActionSheetPresenter(sourceViewController: navVC,
                                                                                     user: self.viewModel.getUser(),
                                                                                     group: group,
                                                                                     callback: vc.pickedCallback)
        vc.groupSubSelectionPresenter?.present()
    }
}

extension ComposeCoordinator: ComposePasswordViewControllerDelegate {

    func Cancelled() {

    }

    func Apply(_ password: String, confirmPassword: String, hint: String) {
        guard let vc = viewController else {
            return
        }
        vc.encryptionPassword = password
        vc.encryptionConfirmPassword = confirmPassword
        vc.encryptionPasswordHint = hint
        vc.updateEO()
    }

    func Removed() {
        guard let vc = viewController else {
            return
        }
        vc.encryptionPassword = ""
        vc.encryptionConfirmPassword = ""
        vc.encryptionPasswordHint = ""
        vc.updateEO()
    }
}
