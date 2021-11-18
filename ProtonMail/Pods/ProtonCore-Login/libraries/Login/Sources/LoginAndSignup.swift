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
import typealias ProtonCore_Payments.ListOfIAPIdentifiers
import ProtonCore_UIFoundations
import ProtonCore_PaymentsUI

@available(*, deprecated, renamed: "LoginAndSignupInterface")
public typealias LoginInterface = LoginAndSignupInterface

public struct WorkBeforeFlow {
    let waitingStepName: String
    let doneStepName: String
    let completion: FlowCompletion
    
    public init(waitingStepName: String, doneStepName: String, completion: @escaping FlowCompletion) {
        self.waitingStepName = waitingStepName
        self.doneStepName = doneStepName
        self.completion = completion
    }
}

public typealias FlowCompletion = (LoginData, @escaping (Result<Void, Error>) -> Void) -> Void

public protocol LoginAndSignupInterface {
    
    func presentLoginFlow(over viewController: UIViewController,
                          username: String?,
                          performBeforeFlow: WorkBeforeFlow?,
                          completion: @escaping (LoginResult) -> Void)

    func presentSignupFlow(over viewController: UIViewController,
                           performBeforeFlow: WorkBeforeFlow?,
                           completion: @escaping (LoginResult) -> Void)

    func presentMailboxPasswordFlow(over viewController: UIViewController, completion: @escaping (String) -> Void)

    func presentFlowFromWelcomeScreen(over viewController: UIViewController,
                                      welcomeScreen: WelcomeScreenVariant,
                                      username: String?,
                                      performBeforeFlow: WorkBeforeFlow?,
                                      completion: @escaping (LoginResult) -> Void)

    func welcomeScreenForPresentingFlow(variant welcomeScreen: WelcomeScreenVariant,
                                        username: String?,
                                        performBeforeFlow: WorkBeforeFlow?,
                                        completion: @escaping (LoginResult) -> Void) -> UIViewController
}

extension LoginAndSignupInterface {

    public func presentLoginFlow(over viewController: UIViewController,
                                 completion: @escaping (LoginResult) -> Void) {
        presentLoginFlow(over: viewController,
                         username: nil,
                         performBeforeFlow: nil,
                         completion: completion)
    }

    public func presentLoginFlow(over viewController: UIViewController,
                                 username: String?,
                                 completion: @escaping (LoginResult) -> Void) {
        presentLoginFlow(over: viewController,
                         username: username,
                         performBeforeFlow: nil,
                         completion: completion)
    }

    public func presentSignupFlow(over viewController: UIViewController, completion: @escaping (LoginResult) -> Void) {
        presentSignupFlow(over: viewController, performBeforeFlow: nil, completion: completion)
    }

    public func presentFlowFromWelcomeScreen(over viewController: UIViewController,
                                             welcomeScreen: WelcomeScreenVariant,
                                             completion: @escaping (LoginResult) -> Void) {
        presentFlowFromWelcomeScreen(over: viewController,
                                     welcomeScreen: welcomeScreen,
                                     username: nil,
                                     performBeforeFlow: nil,
                                     completion: completion)
    }

    public func presentFlowFromWelcomeScreen(over viewController: UIViewController,
                                             welcomeScreen: WelcomeScreenVariant,
                                             username: String?,
                                             completion: @escaping (LoginResult) -> Void) {
        presentFlowFromWelcomeScreen(over: viewController,
                                     welcomeScreen: welcomeScreen,
                                     username: username,
                                     performBeforeFlow: nil,
                                     completion: completion)
    }

    public func welcomeScreenForPresentingFlow(variant welcomeScreen: WelcomeScreenVariant,
                                               completion: @escaping (LoginResult) -> Void) -> UIViewController {
        welcomeScreenForPresentingFlow(variant: welcomeScreen,
                                       username: nil,
                                       performBeforeFlow: nil,
                                       completion: completion)
    }

    public func welcomeScreenForPresentingFlow(variant welcomeScreen: WelcomeScreenVariant,
                                               username: String?,
                                               completion: @escaping (LoginResult) -> Void) -> UIViewController {
        welcomeScreenForPresentingFlow(variant: welcomeScreen,
                                       username: username,
                                       performBeforeFlow: nil,
                                       completion: completion)
    }
}

@available(*, deprecated, renamed: "LoginAndSignup")
public typealias PMLogin = LoginAndSignup

public class LoginAndSignup: LoginAndSignupInterface {
    
    static var sessionId = "LoginModuleSessionId"
    private let container: Container
    private let isCloseButtonAvailable: Bool
    private let minimumAccountType: AccountType
    private var loginCoordinator: LoginCoordinator?
    private var signupCoordinator: SignupCoordinator?
    private var mailboxPasswordCoordinator: MailboxPasswordCoordinator?
    private var viewController: UIViewController?
    private var paymentsAvailability: PaymentsAvailability
    private var signupAvailability: SignupAvailability
    private var performBeforeFlow: WorkBeforeFlow?
    private var loginCompletion: (LoginResult) -> Void = { _ in }
    private var mailboxPasswordCompletion: ((String) -> Void)?

    @available(*, deprecated, message: "Use the new initializer with payment plans for a particular app. Otherwise the no plans will be available. init(appName:doh:apiServiceDelegate:forceUpgradeDelegate:minimumAccountType:signupMode:signupPasswordRestrictions:isCloseButtonAvailable:presentPaymentFlowFor:)")
    public convenience init(appName: String,
                            doh: DoH & ServerConfig,
                            apiServiceDelegate: APIServiceDelegate,
                            forceUpgradeDelegate: ForceUpgradeDelegate,
                            minimumAccountType: AccountType,
                            isCloseButtonAvailable: Bool = true,
                            isPlanSelectorAvailable: Bool,
                            signupAvailability: SignupAvailability = .notAvailable) {
        self.init(appName: appName, doh: doh, apiServiceDelegate: apiServiceDelegate, forceUpgradeDelegate: forceUpgradeDelegate, minimumAccountType: minimumAccountType, isCloseButtonAvailable: isCloseButtonAvailable, paymentsAvailability: isPlanSelectorAvailable ? .available(parameters: .init(listOfIAPIdentifiers: [], reportBugAlertHandler: nil)) : .notAvailable)
    }

    public init(appName: String,
                doh: DoH & ServerConfig,
                apiServiceDelegate: APIServiceDelegate,
                forceUpgradeDelegate: ForceUpgradeDelegate,
                minimumAccountType: AccountType,
                isCloseButtonAvailable: Bool = true,
                paymentsAvailability: PaymentsAvailability,
                signupAvailability: SignupAvailability = .notAvailable) {
        container = Container(appName: appName,
                              doh: doh,
                              apiServiceDelegate: apiServiceDelegate,
                              forceUpgradeDelegate: forceUpgradeDelegate,
                              minimumAccountType: minimumAccountType)
        self.isCloseButtonAvailable = isCloseButtonAvailable
        self.paymentsAvailability = paymentsAvailability
        self.signupAvailability = signupAvailability
        self.minimumAccountType = minimumAccountType
    }
    
    public func presentLoginFlow(over viewController: UIViewController,
                                 username: String? = nil,
                                 performBeforeFlow: WorkBeforeFlow?,
                                 completion: @escaping (LoginResult) -> Void) {
        presentLogin(over: viewController, username: username, welcomeScreen: nil,
                     performBeforeFlow: performBeforeFlow, completion: completion)
    }

    public func presentSignupFlow(over viewController: UIViewController,
                                  performBeforeFlow: WorkBeforeFlow?,
                                  completion: @escaping (LoginResult) -> Void) {
        self.viewController = viewController
        self.performBeforeFlow = performBeforeFlow
        self.loginCompletion = completion
        presentSignup(.over(viewController, .coverVertical), completion: completion)
    }
    
    public func presentMailboxPasswordFlow(over viewController: UIViewController,
                                           completion: @escaping (String) -> Void) {
        self.viewController = viewController
        self.mailboxPasswordCompletion = completion
        mailboxPasswordCoordinator = MailboxPasswordCoordinator(container: container, delegate: self)
        mailboxPasswordCoordinator?.start(viewController: viewController)
    }

    public func presentFlowFromWelcomeScreen(over viewController: UIViewController,
                                             welcomeScreen: WelcomeScreenVariant,
                                             username: String?,
                                             performBeforeFlow: WorkBeforeFlow?,
                                             completion: @escaping (LoginResult) -> Void) {
        presentLogin(over: viewController, username: username, welcomeScreen: welcomeScreen,
                     performBeforeFlow: performBeforeFlow, completion: completion)
    }

    public func welcomeScreenForPresentingFlow(variant welcomeScreen: WelcomeScreenVariant,
                                               username: String?,
                                               performBeforeFlow: WorkBeforeFlow?,
                                               completion: @escaping (LoginResult) -> Void) -> UIViewController {
        presentLogin(over: nil, welcomeScreen: welcomeScreen,
                     performBeforeFlow: performBeforeFlow, completion: completion)
    }
    
    public func logout(credential: AuthCredential, completion: @escaping (Result<Void, Error>) -> Void) {
        container.login.logout(credential: credential, completion: completion)
    }

    @discardableResult
    private func presentLogin(over viewController: UIViewController?,
                              username: String? = nil,
                              welcomeScreen: WelcomeScreenVariant?,
                              performBeforeFlow: WorkBeforeFlow?,
                              completion: @escaping (LoginResult) -> Void) -> UINavigationController {
        self.viewController = viewController
        self.performBeforeFlow = performBeforeFlow
        self.loginCompletion = completion
        let shouldShowCloseButton = viewController == nil ? false : isCloseButtonAvailable
        let loginCoordinator = LoginCoordinator(container: container,
                                                isCloseButtonAvailable: shouldShowCloseButton,
                                                isSignupAvailable: !signupAvailability.isNotAvailable,
                                                performBeforeFlow: performBeforeFlow)
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
                                              isCloseButton: isCloseButtonAvailable,
                                              paymentsAvailability: paymentsAvailability,
                                              signupAvailability: signupAvailability,
                                              performBeforeFlow: performBeforeFlow)
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
                                            isSignupAvailable: !signupAvailability.isNotAvailable,
                                            performBeforeFlow: performBeforeFlow)
        loginCoordinator?.delegate = self
        if email != nil {
            loginCoordinator?.initialError = LoginError.emailAddressAlreadyUsed
        }
        loginCoordinator?.start(.inside(navigationViewController), username: email)
        container.login.updateAccountType(accountType: minimumAccountType)
    }
}

extension LoginAndSignup: MailboxPasswordCoordinatorDelegate {
    func mailboxPasswordCoordinatorDidFinish(mailboxPasswordCoordinator: MailboxPasswordCoordinator, mailboxPassword: String) {
        mailboxPasswordCompletion?(mailboxPassword)
    }
}
