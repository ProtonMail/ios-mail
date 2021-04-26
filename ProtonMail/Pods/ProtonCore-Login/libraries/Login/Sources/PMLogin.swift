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

public protocol LoginInterface {

    func presentLoginFlow(over viewController: UIViewController,
                          username: String?,
                          completion: @escaping (LoginResult) -> Void)

    func presentSignupFlow(over viewController: UIViewController,
                           completion: @escaping (LoginResult) -> Void)

    func presentMailboxPasswordFlow(over viewController: UIViewController,
                                    completion: @escaping (String) -> Void)
}

extension LoginInterface {
    public func presentLoginFlow(over viewController: UIViewController,
                                 completion: @escaping (LoginResult) -> Void) {
        presentLoginFlow(over: viewController, username: nil, completion: completion)
    }
}

public class PMLogin: LoginInterface {

    static var sessionId = "LoginModuleSessionId"
    private let container: Container
    private let signupMode: SignupMode
    private let signupPasswordRestrictions: SignupPasswordRestrictions
    private let isCloseButtonAvailable: Bool
    private var loginCoordinator: LoginCoordinator?
    private var singnupCoordinator: SignupCoordinator?
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
                isCloseButtonAvailable: Bool = true) {
        container = Container(appName: appName,
                              doh: doh,
                              apiServiceDelegate: apiServiceDelegate,
                              forceUpgradeDelegate: forceUpgradeDelegate,
                              minimumAccountType: minimumAccountType)
        self.signupMode = signupMode
        self.isCloseButtonAvailable = isCloseButtonAvailable
        self.signupPasswordRestrictions = signupPasswordRestrictions
    }

    @available(*, unavailable, renamed: "presentLoginFlow(over:username:completion:)")
    public func login(viewController: UIViewController, username: String? = nil, isSignupAvailable _: Bool = true, completion: @escaping (LoginResult) -> Void) {
        presentLoginFlow(over: viewController, username: username, completion: completion)
    }

    public func presentLoginFlow(over viewController: UIViewController,
                                 username: String? = nil,
                                 completion: @escaping (LoginResult) -> Void) {
        self.viewController = viewController
        self.loginCompletion = completion

        loginCoordinator = LoginCoordinator(container: container,
                                            isCloseButtonAvailable: isCloseButtonAvailable,
                                            isSignupAvailable: signupMode != .notAvailable)
        loginCoordinator?.delegate = self
        loginCoordinator?.start(viewController: viewController, username: username)
    }

    @available(*, unavailable, renamed: "presentLoginFlow(over:completion:)")
    public func signup(viewController: UIViewController, completion: @escaping (LoginResult) -> Void) {
        presentSignupFlow(over: viewController, completion: completion)
    }

    public func presentSignupFlow(over viewController: UIViewController, completion: @escaping (LoginResult) -> Void) {
        self.viewController = viewController
        self.loginCompletion = completion

        singnupCoordinator = SignupCoordinator(container: container,
                                               signupMode: signupMode,
                                               signupPasswordRestrictions: signupPasswordRestrictions,
                                               isCloseButton: isCloseButtonAvailable)
        singnupCoordinator?.delegate = self
        singnupCoordinator?.start(viewController: viewController)
    }

    public func presentMailboxPasswordFlow(over viewController: UIViewController, completion: @escaping (String) -> Void) {
        self.viewController = viewController
        self.mailboxPasswordCompletion = completion
        mailboxPasswordCoordinator = MailboxPasswordCoordinator(container: container, delegate: self)
        mailboxPasswordCoordinator?.start(viewController: viewController)
    }

    public func logout(credential: AuthCredential, completion: @escaping (Result<Void, Error>) -> Void) {
        container.login.logout(credential: credential, completion: completion)
    }

    private func login(viewController: UIViewController,
                       username: String? = nil,
                       initialError: LoginError? = nil,
                       completion: @escaping (LoginResult) -> Void) {
        self.viewController = viewController
        self.loginCompletion = completion

        loginCoordinator = LoginCoordinator(container: container,
                                            isCloseButtonAvailable: isCloseButtonAvailable,
                                            isSignupAvailable: signupMode != .notAvailable)
        loginCoordinator?.delegate = self
        loginCoordinator?.initialError = initialError
        loginCoordinator?.start(viewController: viewController, username: username)
    }
}

extension PMLogin: LoginCoordinatorDelegate {
    func userDidDismissLoginCoordinator(loginCoordinator: LoginCoordinator) {
        loginCompletion?(.dismissed)
    }

    func loginCoordinatorDidFinish(loginCoordinator: LoginCoordinator, data: LoginData) {
        loginCompletion?(.loggedIn(data))
    }

    func userSelectedSignup() {
        guard let viewController = viewController, let loginCompletion = loginCompletion else { return }
        presentSignupFlow(over: viewController, completion: loginCompletion)
    }
}

extension PMLogin: SignupCoordinatorDelegate {
    func userDidDismissSignupCoordinator(signupCoordinator: SignupCoordinator) {
        loginCompletion?(.dismissed)
    }

    func signupCoordinatorDidFinish(signupCoordinator: SignupCoordinator, loginData: LoginData) {
        loginCompletion?(.loggedIn(loginData))
    }

    func userSelectedSignin(email: String?) {
        guard let viewController = viewController, let loginCompletion = loginCompletion else { return }
        if let email = email {
            let initialError = LoginError.emailAddressAlreadyUsed
            login(viewController: viewController, username: email, initialError: initialError, completion: loginCompletion)
        } else {
            login(viewController: viewController, initialError: nil, completion: loginCompletion)
        }
    }
}

extension PMLogin: MailboxPasswordCoordinatorDelegate {
    func mailboxPasswordCoordinatorDidFinish(mailboxPasswordCoordinator: MailboxPasswordCoordinator, mailboxPassword: String) {
        mailboxPasswordCompletion?(mailboxPassword)
    }
}
