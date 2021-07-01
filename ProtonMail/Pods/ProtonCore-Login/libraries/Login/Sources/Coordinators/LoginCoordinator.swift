//
//  LoginCoordinator.swift
//  PMLogin - Created on 03/11/2020.
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

import Foundation
import UIKit

protocol LoginCoordinatorDelegate: AnyObject {
    func userDidDismissLoginCoordinator(loginCoordinator: LoginCoordinator)
    func loginCoordinatorDidFinish(loginCoordinator: LoginCoordinator, data: LoginData)
    func userSelectedSignup(navigationController: UINavigationController)
}

final class LoginCoordinator {
    enum ChildCoordinators {
        case createAddress
    }

    weak var delegate: LoginCoordinatorDelegate?
    var initialError: LoginError?

    private let container: Container
    private let isCloseButtonAvailable: Bool
    private let isSignupAvailable: Bool
    private var navigationController: UINavigationController?
    private var childCoordinators: [ChildCoordinators: Any] = [:]
    private let externalLinks: ExternalLinks

    init(container: Container, isCloseButtonAvailable: Bool, isSignupAvailable: Bool) {
        self.container = container
        self.isCloseButtonAvailable = isCloseButtonAvailable
        self.isSignupAvailable = isSignupAvailable
        externalLinks = container.makeExternalLinks()
    }

    func start(_ kind: FlowStartKind, username: String? = nil) {
        showInitialViewController(kind, initialViewController: loginViewController(username: username))
    }

    func startFromWelcomeScreen(viewController: UIViewController, variant: WelcomeScreenVariant, username: String? = nil) {
        let welcome = WelcomeViewController(variant: variant, delegate: self, username: username, signupAvailable: isSignupAvailable)
        showInitialViewController(.over(viewController), initialViewController: welcome)
    }

    private func loginViewController(username: String?) -> UIViewController {
        let loginViewController = UIStoryboard.instantiate(LoginViewController.self)
        loginViewController.viewModel = container.makeLoginViewModel()
        loginViewController.initialUsername = username
        loginViewController.delegate = self
        loginViewController.showCloseButton = isCloseButtonAvailable
        loginViewController.initialError = initialError
        loginViewController.isSignupAvailable = isSignupAvailable
        return loginViewController
    }

    // MARK: - Actions

    private func showInitialViewController(_ kind: FlowStartKind, initialViewController: UIViewController) {
        switch kind {
        case .over(let viewController):
            let navigationController = UINavigationController(rootViewController: initialViewController)
            navigationController.navigationBar.isHidden = true
            navigationController.modalPresentationStyle = .fullScreen
            self.navigationController = navigationController
            container.setupHumanVerification(viewController: navigationController)
            viewController.present(navigationController, animated: true, completion: nil)
        case .inside(let navigationViewController):
            self.navigationController = navigationViewController
            container.setupHumanVerification(viewController: navigationViewController)
            navigationController?.setViewControllers([initialViewController], animated: true)
        }
    }

    private func showHelp() {
        let helpViewController = UIStoryboard.instantiate(HelpViewController.self)
        helpViewController.delegate = self
        navigationController?.present(helpViewController, animated: true, completion: nil)
    }

    private func showTwoFactorCode() {
        let twoFactorViewController = UIStoryboard.instantiate(TwoFactorViewController.self)
        twoFactorViewController.viewModel = container.makeTwoFactorViewModel()
        twoFactorViewController.delegate = self
        navigationController?.pushViewController(twoFactorViewController, animated: true)
    }

    private func showMailboxPassword() {
        let mailboxPasswordViewController = UIStoryboard.instantiate(MailboxPasswordViewController.self)
        mailboxPasswordViewController.viewModel = container.makeMailboxPasswordViewModel()
        mailboxPasswordViewController.delegate = self
        navigationController?.pushViewController(mailboxPasswordViewController, animated: true)
    }

    private func showCreateAddress(data: CreateAddressData) {
        guard let navigationController = navigationController else {
            fatalError("Invalid call")
        }

        let coordinator = CreateAddressCoordinator(container: container, navigationController: navigationController, data: data)
        coordinator.delegate = self
        childCoordinators[.createAddress] = coordinator
        coordinator.start()
    }

    private func finish(data: LoginData) {
        navigationController?.dismiss(animated: true, completion: nil)
        delegate?.loginCoordinatorDidFinish(loginCoordinator: self, data: data)
    }

    private func popAndShowError(error: LoginError) {
        navigationController?.popToRootViewController(animated: true) {
            guard let errorCapable = self.navigationController?.topViewController as? LoginErrorCapable else {
                return
            }

            errorCapable.showError(error: error)
        }
    }
}

// MARK: - Login steps delegate

extension LoginCoordinator: LoginStepsDelegate {
    func firstPasswordChangeNeeded() {
        UIApplication.openURLIfPossible(externalLinks.accountSetup)
    }

    func twoFactorCodeNeeded() {
        showTwoFactorCode()
    }

    func mailboxPasswordNeeded() {
        showMailboxPassword()
    }

    func createAddressNeeded(data: CreateAddressData) {
        showCreateAddress(data: data)
    }

    func userAccountSetupNeeded() {
        UIApplication.openURLIfPossible(externalLinks.accountSetup)
    }
}

// MARK: - Login VC delegate

extension LoginCoordinator: LoginViewControllerDelegate {
    func userDidDismissLoginViewController() {
        navigationController?.dismiss(animated: true, completion: nil)
        delegate?.userDidDismissLoginCoordinator(loginCoordinator: self)
    }

    func userDidRequestSignup() {
        guard let navigationController = navigationController else { return }
        delegate?.userSelectedSignup(navigationController: navigationController)
    }

    func userDidRequestHelp() {
        showHelp()
    }

    func loginViewControllerDidFinish(data: LoginData) {
        finish(data: data)
    }
}

// MARK: - Help VC delegate

extension LoginCoordinator: HelpViewControllerDelegate {
    func userDidDismissHelpViewController() {
        navigationController?.presentedViewController?.dismiss(animated: true, completion: nil)
    }

    func userDidRequestHelp(item: HelpItem) {
        switch item {
        case .forgotUsername:
            UIApplication.openURLIfPossible(externalLinks.forgottenUsername)
        case .forgotPassword:
            UIApplication.openURLIfPossible(externalLinks.passwordReset)
        case .otherIssues:
            UIApplication.openURLIfPossible(externalLinks.commonLoginProblems)
        case .support:
            UIApplication.openURLIfPossible(externalLinks.support)
        }
    }
}

// MARK: - Create address delegate

extension LoginCoordinator: CreateAddressCoordinatorDelegate {
    func createAddressCoordinatorDidFinish(createAddressCoordinator: CreateAddressCoordinator, data: LoginData) {
        childCoordinators[.createAddress] = nil
        navigationController?.dismiss(animated: true, completion: nil)
        delegate?.loginCoordinatorDidFinish(loginCoordinator: self, data: data)
    }
}

// MARK: - LoginCoordinator delegate

extension LoginCoordinator: NavigationDelegate {
    func userDidRequestGoBack() {

        guard navigationController?.viewControllers.contains(where: { $0 is TwoFactorViewController }) == false else {
            // Special case for situation in which we've already sent a valid 2FA code to server.
            // Once we do it, the user auth session on the backend is past the 2FA step and doesn't allow sending another 2FA code again.
            // The technical details are: the access token contains `twofactor` scope before `POST /auth/2fa` and doesn't contain it after.
            // It makes navigating back to two factor screen useless (user cannot send another code), so we navigate back to root screen instead.
            navigationController?.popToRootViewController(animated: true)
            return
        }

        navigationController?.popViewController(animated: true)
    }
}

// MARK: - Mailbox password delegate

extension LoginCoordinator: MailboxPasswordViewControllerDelegate {
    func mailboxPasswordViewControllerDidFail(error: LoginError) {
        popAndShowError(error: error)
    }

    func mailboxPasswordViewControllerDidFinish(data: LoginData) {
        finish(data: data)
    }

    func userDidRequestPasswordReset() {
        UIApplication.openURLIfPossible(externalLinks.passwordReset)
    }
}

// MARK: - TwoFactor delegate

extension LoginCoordinator: TwoFactorViewControllerDelegate {
    func twoFactorViewControllerDidFail(error: LoginError) {
        popAndShowError(error: error)
    }

    func twoFactorViewControllerDidFinish(data: LoginData) {
        finish(data: data)
    }
}

private extension UIStoryboard {
    static func instantiate<T: UIViewController>(_ controllerType: T.Type) -> T {
        self.instantiate(storyboardName: "PMLogin", controllerType: controllerType)
    }
}

// MARK: - Welcome screen delegate

extension LoginCoordinator: WelcomeViewControllerDelegate {

    func userWantsToLogIn(username: String?) {
        let login = loginViewController(username: username)
        navigationController?.setViewControllers([login], animated: true)
    }

    func userWantsToSignUp() {
        guard let navigationController = navigationController else { return }
        delegate?.userSelectedSignup(navigationController: navigationController)
    }
}
