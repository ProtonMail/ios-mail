//
//  LoginAndSignup.swift
//  ProtonCore-Login - Created on 12/11/2020.
//
//  Copyright (c) 2019 Proton Technologies AG
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
import ProtonCore_Doh
import ProtonCore_Networking
import ProtonCore_Services
import ProtonCore_UIFoundations
import ProtonCore_PaymentsUI

@available(*, deprecated, renamed: "LoginAndSignupInterface")
public typealias LoginInterface = LoginAndSignupInterface

public typealias WorkBeforeFlowCompletion = (LoginData, @escaping (Result<Void, Error>) -> Void) -> Void

public protocol LoginAndSignupInterface {
    
    func presentLoginFlow(over viewController: UIViewController,
                          username: String?,
                          performBeforeFlowCompletion: WorkBeforeFlowCompletion?,
                          completion: @escaping (LoginResult) -> Void)

    func presentSignupFlow(over viewController: UIViewController,
                           performBeforeFlowCompletion: WorkBeforeFlowCompletion?,
                           completion: @escaping (LoginResult) -> Void)

    func presentMailboxPasswordFlow(over viewController: UIViewController, completion: @escaping (String) -> Void)

    func presentFlowFromWelcomeScreen(over viewController: UIViewController,
                                      welcomeScreen: WelcomeScreenVariant,
                                      username: String?,
                                      performBeforeFlowCompletion: WorkBeforeFlowCompletion?,
                                      completion: @escaping (LoginResult) -> Void)

    func welcomeScreenForPresentingFlow(variant welcomeScreen: WelcomeScreenVariant,
                                        username: String?,
                                        performBeforeFlowCompletion: WorkBeforeFlowCompletion?,
                                        completion: @escaping (LoginResult) -> Void) -> UIViewController
}

extension LoginAndSignupInterface {

    public func presentLoginFlow(over viewController: UIViewController,
                                 completion: @escaping (LoginResult) -> Void) {
        presentLoginFlow(over: viewController,
                         username: nil,
                         performBeforeFlowCompletion: nil,
                         completion: completion)
    }

    public func presentLoginFlow(over viewController: UIViewController,
                                 username: String?,
                                 completion: @escaping (LoginResult) -> Void) {
        presentLoginFlow(over: viewController,
                         username: username,
                         performBeforeFlowCompletion: nil,
                         completion: completion)
    }

    public func presentSignupFlow(over viewController: UIViewController, completion: @escaping (LoginResult) -> Void) {
        presentSignupFlow(over: viewController, performBeforeFlowCompletion: nil, completion: completion)
    }

    public func presentFlowFromWelcomeScreen(over viewController: UIViewController,
                                             welcomeScreen: WelcomeScreenVariant,
                                             completion: @escaping (LoginResult) -> Void) {
        presentFlowFromWelcomeScreen(over: viewController,
                                     welcomeScreen: welcomeScreen,
                                     username: nil,
                                     performBeforeFlowCompletion: nil,
                                     completion: completion)
    }

    public func presentFlowFromWelcomeScreen(over viewController: UIViewController,
                                             welcomeScreen: WelcomeScreenVariant,
                                             username: String?,
                                             completion: @escaping (LoginResult) -> Void) {
        presentFlowFromWelcomeScreen(over: viewController,
                                     welcomeScreen: welcomeScreen,
                                     username: username,
                                     performBeforeFlowCompletion: nil,
                                     completion: completion)
    }

    public func welcomeScreenForPresentingFlow(variant welcomeScreen: WelcomeScreenVariant,
                                               completion: @escaping (LoginResult) -> Void) -> UIViewController {
        welcomeScreenForPresentingFlow(variant: welcomeScreen,
                                       username: nil,
                                       performBeforeFlowCompletion: nil,
                                       completion: completion)
    }

    public func welcomeScreenForPresentingFlow(variant welcomeScreen: WelcomeScreenVariant,
                                               username: String?,
                                               completion: @escaping (LoginResult) -> Void) -> UIViewController {
        welcomeScreenForPresentingFlow(variant: welcomeScreen,
                                       username: username,
                                       performBeforeFlowCompletion: nil,
                                       completion: completion)
    }
}

@available(*, deprecated, renamed: "LoginAndSignup")
public typealias PMLogin = LoginAndSignup

public class LoginAndSignup: LoginAndSignupInterface {
    
    static var sessionId = "LoginModuleSessionId"
    private let container: Container
    private let signupMode: SignupMode
    private let signupPasswordRestrictions: SignupPasswordRestrictions
    private let isCloseButtonAvailable: Bool
    private let planTypes: PlanTypes?
    private var loginCoordinator: LoginCoordinator?
    private var signupCoordinator: SignupCoordinator?
    private var mailboxPasswordCoordinator: MailboxPasswordCoordinator?
    private var viewController: UIViewController?
    private var performBeforeFlowCompletion: WorkBeforeFlowCompletion?
    private var loginCompletion: (LoginResult) -> Void = { _ in }
    private var mailboxPasswordCompletion: ((String) -> Void)?

    @available(*, deprecated, message: "Use the initializer with planTypes parameter instead")
    public convenience init(appName: String,
                            doh: DoH & ServerConfig,
                            apiServiceDelegate: APIServiceDelegate,
                            forceUpgradeDelegate: ForceUpgradeDelegate,
                            minimumAccountType: AccountType,
                            signupMode: SignupMode = .both(initial: .internal),
                            signupPasswordRestrictions: SignupPasswordRestrictions = .default,
                            isCloseButtonAvailable: Bool = true,
                            isPlanSelectorAvailable: Bool) {
        self.init(appName: appName, doh: doh, apiServiceDelegate: apiServiceDelegate, forceUpgradeDelegate: forceUpgradeDelegate, minimumAccountType: minimumAccountType, signupMode: signupMode, signupPasswordRestrictions: signupPasswordRestrictions, isCloseButtonAvailable: isCloseButtonAvailable, planTypes: isPlanSelectorAvailable ? .mail : nil)
    }
    
    public init(appName: String,
                doh: DoH & ServerConfig,
                apiServiceDelegate: APIServiceDelegate,
                forceUpgradeDelegate: ForceUpgradeDelegate,
                minimumAccountType: AccountType,
                signupMode: SignupMode = .both(initial: .internal),
                signupPasswordRestrictions: SignupPasswordRestrictions = .default,
                isCloseButtonAvailable: Bool = true,
                planTypes: PlanTypes? = nil) {
        container = Container(appName: appName,
                              doh: doh,
                              apiServiceDelegate: apiServiceDelegate,
                              forceUpgradeDelegate: forceUpgradeDelegate,
                              minimumAccountType: minimumAccountType)
        self.signupMode = signupMode
        self.isCloseButtonAvailable = isCloseButtonAvailable
        self.signupPasswordRestrictions = signupPasswordRestrictions
        self.planTypes = planTypes
    }
    
    public func presentLoginFlow(over viewController: UIViewController,
                                 username: String? = nil,
                                 performBeforeFlowCompletion: WorkBeforeFlowCompletion?,
                                 completion: @escaping (LoginResult) -> Void) {
        presentLogin(over: viewController, username: username, welcomeScreen: nil,
                     performBeforeFlowCompletion: performBeforeFlowCompletion, completion: completion)
    }

    public func presentSignupFlow(over viewController: UIViewController,
                                  performBeforeFlowCompletion: WorkBeforeFlowCompletion?,
                                  completion: @escaping (LoginResult) -> Void) {
        self.viewController = viewController
        self.performBeforeFlowCompletion = performBeforeFlowCompletion
        self.loginCompletion = completion
        presentSignup(.over(viewController, .coverVertical), completion: completion)
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
                                             performBeforeFlowCompletion: WorkBeforeFlowCompletion?,
                                             completion: @escaping (LoginResult) -> Void) {
        presentLogin(over: viewController, username: username, welcomeScreen: welcomeScreen,
                     performBeforeFlowCompletion: performBeforeFlowCompletion, completion: completion)
    }

    public func welcomeScreenForPresentingFlow(variant welcomeScreen: WelcomeScreenVariant,
                                               username: String?,
                                               performBeforeFlowCompletion: WorkBeforeFlowCompletion?,
                                               completion: @escaping (LoginResult) -> Void) -> UIViewController {
        presentLogin(over: nil, welcomeScreen: welcomeScreen,
                     performBeforeFlowCompletion: performBeforeFlowCompletion, completion: completion)
    }
    
    public func logout(credential: AuthCredential, completion: @escaping (Result<Void, Error>) -> Void) {
        container.login.logout(credential: credential, completion: completion)
    }

    @discardableResult
    private func presentLogin(over viewController: UIViewController?,
                              username: String? = nil,
                              welcomeScreen: WelcomeScreenVariant?,
                              performBeforeFlowCompletion: WorkBeforeFlowCompletion?,
                              completion: @escaping (LoginResult) -> Void) -> UINavigationController {
        self.viewController = viewController
        self.performBeforeFlowCompletion = performBeforeFlowCompletion
        self.loginCompletion = completion
        let shouldShowCloseButton = viewController == nil ? false : isCloseButtonAvailable
        let loginCoordinator = LoginCoordinator(container: container,
                                                isCloseButtonAvailable: shouldShowCloseButton,
                                                isSignupAvailable: signupMode != .notAvailable,
                                                performBeforeFlowCompletion: performBeforeFlowCompletion)
        self.loginCoordinator = loginCoordinator
        loginCoordinator.delegate = self
        if let welcomeScreen = welcomeScreen {
            if let viewController = viewController {
                return loginCoordinator.startFromWelcomeScreen(viewController: viewController, variant: welcomeScreen, username: username)
            } else {
                return loginCoordinator.startWithUnmanagedWelcomeScreen(variant: welcomeScreen, username: username)
            }
        } else {
            if let viewController = viewController {
                return loginCoordinator.start(.over(viewController, .coverVertical), username: username)
            } else {
                return loginCoordinator.start(.unmanaged, username: username)
            }
        }
    }

    private func presentSignup(_ start: FlowStartKind, completion: @escaping (LoginResult) -> Void) {
        signupCoordinator = SignupCoordinator(container: container,
                                              signupMode: signupMode,
                                              signupPasswordRestrictions: signupPasswordRestrictions,
                                              isCloseButton: isCloseButtonAvailable,
                                              planTypes: planTypes,
                                              performBeforeFlowCompletion: performBeforeFlowCompletion)
        signupCoordinator?.delegate = self
        signupCoordinator?.start(kind: start)
    }
}

extension LoginAndSignup: LoginCoordinatorDelegate {
    func userDidDismissLoginCoordinator(loginCoordinator: LoginCoordinator) {
        loginCompletion(.dismissed)
    }
    
    func loginCoordinatorDidFinish(loginCoordinator: LoginCoordinator, data: LoginData) {
        loginCompletion(.loggedIn(data))
    }

    func userSelectedSignup(navigationController: LoginNavigationViewController) { 
        presentSignup(.inside(navigationController), completion: loginCompletion)
    }
}

extension LoginAndSignup: SignupCoordinatorDelegate {
    func userDidDismissSignupCoordinator(signupCoordinator: SignupCoordinator) {
        loginCompletion(.dismissed)
    }
    
    func signupCoordinatorDidFinish(signupCoordinator: SignupCoordinator, loginData: LoginData) {
        loginCompletion(.loggedIn(loginData))
    }
    
    func userSelectedSignin(email: String?, navigationViewController: LoginNavigationViewController) {
        loginCoordinator = LoginCoordinator(container: container,
                                            isCloseButtonAvailable: isCloseButtonAvailable,
                                            isSignupAvailable: signupMode != .notAvailable,
                                            performBeforeFlowCompletion: performBeforeFlowCompletion)
        loginCoordinator?.delegate = self
        if email != nil {
            loginCoordinator?.initialError = LoginError.emailAddressAlreadyUsed
        }
        loginCoordinator?.start(.inside(navigationViewController), username: email)
    }
}

extension LoginAndSignup: MailboxPasswordCoordinatorDelegate {
    func mailboxPasswordCoordinatorDidFinish(mailboxPasswordCoordinator: MailboxPasswordCoordinator, mailboxPassword: String) {
        mailboxPasswordCompletion?(mailboxPassword)
    }
}
