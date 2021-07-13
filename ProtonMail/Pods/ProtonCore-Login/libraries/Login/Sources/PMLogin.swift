//
//  PMLogin.swift
//  PMLogin - Created on 12/11/2020.
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
import ProtonCore_Doh
import ProtonCore_Networking
import ProtonCore_Services
import ProtonCore_UIFoundations

public protocol LoginInterface {
    
    func presentLoginFlow(over viewController: UIViewController,
                          username: String?,
                          completion: @escaping (LoginResult) -> Void)

    func presentSignupFlow(over viewController: UIViewController,
                           receipt: String?,
                           completion: @escaping (LoginResult) -> Void)

    func presentMailboxPasswordFlow(over viewController: UIViewController,
                                    completion: @escaping (String) -> Void)

    func presentFlowFromWelcomeScreen(over viewController: UIViewController,
                                      welcomeScreen: WelcomeScreenVariant,
                                      username: String?,
                                      completion: @escaping (LoginResult) -> Void)
}

extension LoginInterface {
    public func presentLoginFlow(over viewController: UIViewController,
                                 completion: @escaping (LoginResult) -> Void) {
        presentLoginFlow(over: viewController, username: nil, completion: completion)
    }

    public func presentFlowFromWelcomeScreen(over viewController: UIViewController,
                                             welcomeScreen: WelcomeScreenVariant,
                                             completion: @escaping (LoginResult) -> Void) {
        presentFlowFromWelcomeScreen(over: viewController, welcomeScreen: welcomeScreen, username: nil, completion: completion)
    }
}

public class PMLogin: LoginInterface {
    
    static var sessionId = "LoginModuleSessionId"
    private let container: Container
    private let signupMode: SignupMode
    private let signupPasswordRestrictions: SignupPasswordRestrictions
    private let isCloseButtonAvailable: Bool
    private let isPlanSelectorAvailable: Bool
    private var loginCoordinator: LoginCoordinator?
    private var signupCoordinator: SignupCoordinator?
    private var mailboxPasswordCoordinator: MailboxPasswordCoordinator?
    private var viewController: UIViewController?
    private var loginCompletion: ((LoginResult) -> Void)?
    private var mailboxPasswordCompletion: ((String) -> Void)?
    
    public init(appName: String,
                doh: DoH,
                apiServiceDelegate: APIServiceDelegate,
                forceUpgradeDelegate: ForceUpgradeDelegate,
                minimumAccountType: AccountType,
                signupMode: SignupMode = .both(initial: .internal),
                signupPasswordRestrictions: SignupPasswordRestrictions = .default,
                isCloseButtonAvailable: Bool = true,
                isPlanSelectorAvailable: Bool = false) {
        container = Container(appName: appName,
                              doh: doh,
                              apiServiceDelegate: apiServiceDelegate,
                              forceUpgradeDelegate: forceUpgradeDelegate,
                              minimumAccountType: minimumAccountType)
        self.signupMode = signupMode
        self.isCloseButtonAvailable = isCloseButtonAvailable
        self.signupPasswordRestrictions = signupPasswordRestrictions
        self.isPlanSelectorAvailable = isPlanSelectorAvailable
    }
    
    public func presentLoginFlow(over viewController: UIViewController,
                                 username: String? = nil,
                                 completion: @escaping (LoginResult) -> Void) {
        presentLogin(over: viewController, username: username, welcomeScreen: nil, completion: completion)
    }

    public func presentSignupFlow(over viewController: UIViewController, receipt: String? = nil, completion: @escaping (LoginResult) -> Void) {
        self.viewController = viewController
        self.loginCompletion = completion

        presentSignup(.over(viewController, .coverVertical), receipt: receipt, completion: completion)
    }
    
    public func presentMailboxPasswordFlow(over viewController: UIViewController, completion: @escaping (String) -> Void) {
        self.viewController = viewController
        self.mailboxPasswordCompletion = completion
        mailboxPasswordCoordinator = MailboxPasswordCoordinator(container: container, delegate: self)
        mailboxPasswordCoordinator?.start(viewController: viewController)
    }

    public func presentFlowFromWelcomeScreen(over viewController: UIViewController,
                                             welcomeScreen: WelcomeScreenVariant,
                                             username: String?,
                                             completion: @escaping (LoginResult) -> Void) {
        presentLogin(over: viewController, username: username, welcomeScreen: welcomeScreen, completion: completion)
    }
    
    public func logout(credential: AuthCredential, completion: @escaping (Result<Void, Error>) -> Void) {
        container.login.logout(credential: credential, completion: completion)
    }

    private func presentLogin(over viewController: UIViewController,
                              username: String? = nil,
                              welcomeScreen: WelcomeScreenVariant?,
                              completion: @escaping (LoginResult) -> Void) {
        self.viewController = viewController
        self.loginCompletion = completion

        loginCoordinator = LoginCoordinator(container: container,
                                            isCloseButtonAvailable: isCloseButtonAvailable,
                                            isSignupAvailable: signupMode != .notAvailable)
        loginCoordinator?.delegate = self
        if let welcomeScreen = welcomeScreen {
            loginCoordinator?.startFromWelcomeScreen(viewController: viewController, variant: welcomeScreen, username: username)
        } else {
            loginCoordinator?.start(.over(viewController, .coverVertical), username: username)
        }
    }

    private func presentSignup(_ start: FlowStartKind,
                               receipt: String?,
                               completion: @escaping (LoginResult) -> Void) {
        signupCoordinator = SignupCoordinator(container: container,
                                              signupMode: signupMode,
                                              signupPasswordRestrictions: signupPasswordRestrictions,
                                              isCloseButton: isCloseButtonAvailable,
                                              isPlanSelectorAvailable: isPlanSelectorAvailable,
                                              receipt: receipt)
        signupCoordinator?.delegate = self
        signupCoordinator?.start(kind: start)
    }
}

extension PMLogin: LoginCoordinatorDelegate {
    func userDidDismissLoginCoordinator(loginCoordinator: LoginCoordinator) {
        loginCompletion?(.dismissed)
    }
    
    func loginCoordinatorDidFinish(loginCoordinator: LoginCoordinator, data: LoginData) {
        loginCompletion?(.loggedIn(data))
    }

    func userSelectedSignup(navigationController: LoginNavigationViewController) {
        guard let loginCompletion = loginCompletion else { return }
        // TODO: update receipt when BE know what solution is best
        presentSignup(.inside(navigationController), receipt: nil, completion: loginCompletion)
    }
}

extension PMLogin: SignupCoordinatorDelegate {
    func userDidDismissSignupCoordinator(signupCoordinator: SignupCoordinator) {
        loginCompletion?(.dismissed)
    }
    
    func signupCoordinatorDidFinish(signupCoordinator: SignupCoordinator, loginData: LoginData) {
        loginCompletion?(.loggedIn(loginData))
    }
    
    func userSelectedSignin(email: String?, navigationViewController: LoginNavigationViewController) {
        loginCoordinator = LoginCoordinator(container: container,
                                            isCloseButtonAvailable: isCloseButtonAvailable,
                                            isSignupAvailable: signupMode != .notAvailable)
        loginCoordinator?.delegate = self
        if email != nil {
            loginCoordinator?.initialError = LoginError.emailAddressAlreadyUsed
        }
        loginCoordinator?.start(.inside(navigationViewController), username: email)
    }
}

extension PMLogin: MailboxPasswordCoordinatorDelegate {
    func mailboxPasswordCoordinatorDidFinish(mailboxPasswordCoordinator: MailboxPasswordCoordinator, mailboxPassword: String) {
        mailboxPasswordCompletion?(mailboxPassword)
    }
}
