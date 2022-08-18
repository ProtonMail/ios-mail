//
//  ComposeCoordinator.swift
//  Proton Mail - Created on 10/29/18.
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

import UIKit

class ComposeCoordinator {
    private weak var viewController: ComposeViewController?

    private let viewModel: ComposeViewModel

    init(viewModel: ComposeViewModel) {
        self.viewModel = viewModel
    }

    enum Destination: String {
        case expirationWarning = "expiration_warning_segue"
        case subSelection      = "toContactGroupSubSelection"
    }

    private func presentExpirationUnavailabilityAlert() {
            guard let vc = viewController else {
                return
            }
            let nonPMEmails = vc.encryptionPassword.count <= 0 ? vc.headerView.nonePMEmails : [String]()
            let pgpEmails = vc.headerView.pgpEmails
            guard nonPMEmails.count > 0 || pgpEmails.count > 0 else {
                vc.sendMessageStepTwo()
                return
            }
            vc.showExpirationUnavailabilityAlert(nonPMEmails: nonPMEmails, pgpEmails: pgpEmails)
    }

    /// This coordinator is different in that its `start` method does not present anything.
    /// Instead, it returns a view controller that is then embedded as an editor.
    /// - returns: ContainableComposeViewController to embed
    func start() -> ContainableComposeViewController {
        let viewController = ContainableComposeViewController(coordinator: self)
        viewController.set(viewModel: self.viewModel)
        self.viewController = viewController
        return viewController
    }

    func go(to dest: Destination) {
        switch dest {
        case .subSelection:
            presentGroupSubSelectionActionSheet()
        case .expirationWarning:
            presentExpirationUnavailabilityAlert()
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
