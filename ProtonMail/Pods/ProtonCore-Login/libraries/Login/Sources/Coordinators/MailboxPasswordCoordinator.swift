//
//  MailboxPasswordCoordinator.swift
//  ProtonCore-Login
//
//  Created by Krzysztof Siejkowski on 30/04/2021.
//

import Foundation
import ProtonCore_DataModel
import ProtonCore_Networking

protocol MailboxPasswordCoordinatorDelegate: AnyObject {
    func mailboxPasswordCoordinatorDidFinish(mailboxPasswordCoordinator: MailboxPasswordCoordinator, mailboxPassword: String)
}

final class MailboxPasswordCoordinator {

    weak var delegate: MailboxPasswordCoordinatorDelegate?

    private var navigationController: UINavigationController?
    private let container: Container
    private let externalLinks: ExternalLinks

    init(container: Container, delegate: MailboxPasswordCoordinatorDelegate?) {
        self.container = container
        self.externalLinks = container.makeExternalLinks()
        self.delegate = delegate
    }

    func start(viewController: UIViewController) {
        let mailboxPasswordViewController = UIStoryboard.instantiate(MailboxPasswordViewController.self)
        mailboxPasswordViewController.setupAsStandaloneComponent(delegate: self)

        let navigationController = UINavigationController(rootViewController: mailboxPasswordViewController)
        navigationController.navigationBar.isHidden = true
        navigationController.modalPresentationStyle = .fullScreen
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

private extension UIStoryboard {
    static func instantiate<T: UIViewController>(_ controllerType: T.Type) -> T {
        self.instantiate(storyboardName: "PMLogin", controllerType: controllerType)
    }
}
