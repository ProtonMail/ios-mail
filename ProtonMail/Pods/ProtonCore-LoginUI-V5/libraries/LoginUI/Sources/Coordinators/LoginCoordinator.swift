//
//  LoginCoordinator.swift
//  ProtonCore-Login - Created on 03/11/2020.
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

import Foundation
import UIKit
import ProtonCore_UIFoundations
import ProtonCore_Login

protocol LoginCoordinatorDelegate: AnyObject {
    func userDidDismissLoginCoordinator(loginCoordinator: LoginCoordinator)
    func loginCoordinatorDidFinish(loginCoordinator: LoginCoordinator, data: LoginData)
    func userSelectedSignup(navigationController: LoginNavigationViewController)
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
    private var navigationController: LoginNavigationViewController?
    private var childCoordinators: [ChildCoordinators: Any] = [:]
    private let externalLinks: ExternalLinks
    private var customization: LoginCustomizationOptions

    init(container: Container,
         isCloseButtonAvailable: Bool,
         isSignupAvailable: Bool,
         customization: LoginCustomizationOptions) {
        self.container = container
        self.isCloseButtonAvailable = isCloseButtonAvailable
        self.isSignupAvailable = isSignupAvailable
        self.customization = customization
        externalLinks = container.makeExternalLinks()
    }

    @discardableResult
    func start(_ kind: FlowStartKind, username: String? = nil) -> UINavigationController {
        showInitialViewController(kind, initialViewController: loginViewController(username: username))
    }

    func startFromWelcomeScreen(
        viewController: UIViewController, variant: WelcomeScreenVariant, username: String? = nil
    ) -> UINavigationController {
        let welcome = WelcomeViewController(variant: variant, delegate: self, username: username, signupAvailable: isSignupAvailable)
        return showInitialViewController(.over(viewController, .crossDissolve), initialViewController: welcome, navigationBarHidden: true)
    }

    func startWithUnmanagedWelcomeScreen(variant: WelcomeScreenVariant, username: String? = nil) -> UINavigationController {
        let welcome = WelcomeViewController(variant: variant, delegate: self, username: username, signupAvailable: isSignupAvailable)
        return showInitialViewController(.unmanaged, initialViewController: welcome, navigationBarHidden: true)
    }

    private func loginViewController(username: String?) -> UIViewController {
        let loginViewController = UIStoryboard.instantiate(LoginViewController.self)
        loginViewController.viewModel = container.makeLoginViewModel()
        loginViewController.customErrorPresenter = customization.customErrorPresenter
        loginViewController.initialUsername = username
        loginViewController.delegate = self
        loginViewController.showCloseButton = isCloseButtonAvailable
        loginViewController.initialError = initialError
        loginViewController.isSignupAvailable = isSignupAvailable
        return loginViewController
    }

    // MARK: - Actions
    private func showInitialViewController(
        _ kind: FlowStartKind,
        initialViewController: UIViewController,
        navigationBarHidden: Bool = false
    ) -> UINavigationController {
        switch kind {
        case .unmanaged:
            return embedInNavigationController(initialViewController: initialViewController,
                                               navigationBarHidden: navigationBarHidden)
        case let .over(viewController, modalTransitionStyle):
            let navigationController = embedInNavigationController(initialViewController: initialViewController,
                                                                   navigationBarHidden: navigationBarHidden)
            navigationController.modalTransitionStyle = modalTransitionStyle
            viewController.present(navigationController, animated: true, completion: nil)
            return navigationController
        case .inside(let navigationViewController):
            self.navigationController = navigationViewController
            container.setupHumanVerification(viewController: navigationViewController)
            navigationController?.setViewControllers([initialViewController], animated: true)
            return navigationViewController
        }
    }

    private func embedInNavigationController(initialViewController: UIViewController,
                                             navigationBarHidden: Bool) -> UINavigationController {
        let navigationController = LoginNavigationViewController(rootViewController: initialViewController,
                                                                 navigationBarHidden: navigationBarHidden)
        self.navigationController = navigationController
        container.setupHumanVerification(viewController: navigationController)
        return navigationController
    }

    private func showHelp() {
        let helpViewController = UIStoryboard.instantiate(HelpViewController.self)
        helpViewController.delegate = self
        helpViewController.viewModel = HelpViewModel(helpDecorator: customization.helpDecorator)
        navigationController?.present(helpViewController, animated: true, completion: nil)
    }

    private func showTwoFactorCode() {
        let twoFactorViewController = UIStoryboard.instantiate(TwoFactorViewController.self)
        twoFactorViewController.viewModel = container.makeTwoFactorViewModel()
        twoFactorViewController.customErrorPresenter = customization.customErrorPresenter
        twoFactorViewController.delegate = self
        navigationController?.pushViewController(twoFactorViewController, animated: true)
    }

    private func showMailboxPassword() {
        let mailboxPasswordViewController = UIStoryboard.instantiate(MailboxPasswordViewController.self)
        mailboxPasswordViewController.viewModel = container.makeMailboxPasswordViewModel()
        mailboxPasswordViewController.customErrorPresenter = customization.customErrorPresenter
        mailboxPasswordViewController.delegate = self
        navigationController?.pushViewController(mailboxPasswordViewController, animated: true)
    }

    private func showCreateAddress(data: CreateAddressData) {
        guard let navigationController = navigationController else {
            fatalError("Invalid call")
        }

        let coordinator = CreateAddressCoordinator(
            container: container, navigationController: navigationController,
            data: data, customErrorPresenter: customization.customErrorPresenter
        )
        coordinator.delegate = self
        childCoordinators[.createAddress] = coordinator
        coordinator.start()
    }

    private func finish(endLoading: @escaping () -> Void, data: LoginData) {
        guard let performBeforeFlow = customization.performBeforeFlow else {
            completeLoginFlow(data: data)
            return
        }
        DispatchQueue.main.async { [weak self] in
            performBeforeFlow.completion(data) { [weak self] result in
                DispatchQueue.main.async { [weak self] in
                    endLoading()
                    switch result {
                    case .success:
                        self?.completeLoginFlow(data: data)
                    case .failure(let error):
                        self?.popAndShowError(error: .generic(message: error.messageForTheUser, code: error.bestShotAtReasonableErrorCode, originalError: error))
                    }
                }
            }
        }
    }

    private func completeLoginFlow(data: LoginData) {
        navigationController?.dismiss(animated: true, completion: nil)
        delegate?.loginCoordinatorDidFinish(loginCoordinator: self, data: data)
    }

    private func popAndShowError(error: LoginError) {
        navigationController?.popToRootViewController(animated: true) {
            guard let viewController = self.navigationController?.topViewController else { return }
            if self.customization.customErrorPresenter?.willPresentError(error: error, from: viewController) == true {
                return
            }
            
            guard let errorCapable = viewController as? LoginErrorCapable else { return }
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

    func loginViewControllerDidFinish(endLoading: @escaping () -> Void, data: LoginData) {
        finish(endLoading: endLoading, data: data)
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
        case .staticText:
            break
        case .custom(_, _, let behaviour):
            guard let viewController = navigationController?.presentedViewController as? HelpViewController
            else { return }
            behaviour(viewController)
        }
    }
}

// MARK: - Create address delegate

extension LoginCoordinator: CreateAddressCoordinatorDelegate {
    func createAddressCoordinatorDidFinish(endLoading: @escaping () -> Void, createAddressCoordinator: CreateAddressCoordinator, data: LoginData) {
        childCoordinators[.createAddress] = nil
        finish(endLoading: endLoading, data: data)
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

    func mailboxPasswordViewControllerDidFinish(endLoading: @escaping () -> Void, data: LoginData) {
        finish(endLoading: endLoading, data: data)
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

    func twoFactorViewControllerDidFinish(endLoading: @escaping () -> Void, data: LoginData) {
        finish(endLoading: endLoading, data: data)
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
        guard let navigationController = navigationController else { return }
        navigationController.modalTransitionStyle = .coverVertical
        let login = loginViewController(username: username)
        navigationController.autoresettingNextTransitionStyle = .modalLike
        navigationController.setViewControllers([login], animated: true)
    }

    func userWantsToSignUp() {
        guard let navigationController = navigationController else { return }
        navigationController.modalTransitionStyle = .coverVertical
        navigationController.autoresettingNextTransitionStyle = .modalLike
        delegate?.userSelectedSignup(navigationController: navigationController)
    }
}
