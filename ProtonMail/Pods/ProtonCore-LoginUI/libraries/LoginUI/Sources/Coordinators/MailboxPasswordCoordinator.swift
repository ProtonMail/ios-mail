//
//  MailboxPasswordCoordinator.swift
//  ProtonCore-Login - Created on 30/04/2021.
//
//  Copyright (c) 2022 Proton Technologies AG
//
//  This file is part of Proton Technologies AG and ProtonCore.
//
//  ProtonCore is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonCore is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore.  If not, see <https://www.gnu.org/licenses/>.

#if os(iOS)

import Foundation
import UIKit
import ProtonCoreDataModel
import ProtonCoreNetworking
import ProtonCoreUIFoundations

protocol MailboxPasswordCoordinatorDelegate: AnyObject {
    func mailboxPasswordCoordinatorDidFinish(mailboxPasswordCoordinator: MailboxPasswordCoordinator, mailboxPassword: String)
}

final class MailboxPasswordCoordinator {

    weak var delegate: MailboxPasswordCoordinatorDelegate?

    private var navigationController: LoginNavigationViewController?
    private let container: Container
    private let externalLinks: ExternalLinks
    private let inAppTheme: InAppTheme

    init(container: Container,
         delegate: MailboxPasswordCoordinatorDelegate?,
         inAppTheme: InAppTheme) {
        self.container = container
        self.externalLinks = container.makeExternalLinks()
        self.delegate = delegate
        self.inAppTheme = inAppTheme
    }

    func start(viewController: UIViewController) {
        let inAppTheme = inAppTheme
        let mailboxPasswordViewController = UIStoryboard.instantiateInLogin(MailboxPasswordViewController.self, inAppTheme: { inAppTheme })
        mailboxPasswordViewController.setupAsStandaloneComponent(delegate: self)

        let navigationController = LoginNavigationViewController(rootViewController: mailboxPasswordViewController)
        self.navigationController = navigationController

        viewController.present(navigationController, animated: true, completion: nil)
    }

    private func finish(password: String) {
        delegate?.mailboxPasswordCoordinatorDidFinish(mailboxPasswordCoordinator: self, mailboxPassword: password)
    }
}

// MARK: - Mailbox password delegate

extension MailboxPasswordCoordinator: MailboxPasswordViewControllerInStandaloneFlowDelegate {

    func mailboxPasswordViewControllerDidFinish(password: String) {
        navigationController?.dismiss(animated: true)
        finish(password: password)
    }

    func userDidRequestPasswordReset() {
        UIApplication.openURLIfPossible(externalLinks.passwordReset)
    }
}

#endif
