//
//  LoginAndSignup.swift
//  ProtonCore-Login - Created on 12/11/2020.
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
import enum ProtonCore_DataModel.ClientApp
import ProtonCore_Doh
import ProtonCore_Login
import ProtonCore_Networking
import ProtonCore_Services
import typealias ProtonCore_Payments.ListOfIAPIdentifiers
import enum ProtonCore_Payments.StoreKitManagerErrors
import ProtonCore_UIFoundations
import ProtonCore_PaymentsUI
import UIKit

public enum ScreenVariant<SpecificScreenData, CustomScreenData> {
    case mail(SpecificScreenData)
    case calendar(SpecificScreenData)
    case drive(SpecificScreenData)
    case vpn(SpecificScreenData)
    case custom(CustomScreenData)
}

public struct WorkBeforeFlow {
    let stepName: String
    let completion: FlowCompletion
    
    public init(stepName: String, completion: @escaping FlowCompletion) {
        self.stepName = stepName
        self.completion = completion
    }
}

public protocol LoginErrorPresenter {
    func willPresentError(error: LoginError, from: UIViewController) -> Bool
    func willPresentError(error: SignupError, from: UIViewController) -> Bool
    func willPresentError(error: AvailabilityError, from: UIViewController) -> Bool
    func willPresentError(error: SetUsernameError, from: UIViewController) -> Bool
    func willPresentError(error: CreateAddressError, from: UIViewController) -> Bool
    func willPresentError(error: CreateAddressKeysError, from: UIViewController) -> Bool
    func willPresentError(error: StoreKitManagerErrors, from: UIViewController) -> Bool
    func willPresentError(error: ResponseError, from: UIViewController) -> Bool
    func willPresentError(error: Error, from: UIViewController) -> Bool
}

public typealias FlowCompletion = (LoginData, @escaping (Result<Void, Error>) -> Void) -> Void

public struct LoginCustomizationOptions {
    
    public static let empty: LoginCustomizationOptions = .init()
    
    let username: String?
    let performBeforeFlow: WorkBeforeFlow?
    let customErrorPresenter: LoginErrorPresenter?
    let initialError: String?
    let helpDecorator: ([[HelpItem]]) -> [[HelpItem]]
    
    public init(username: String? = nil,
                performBeforeFlow: WorkBeforeFlow? = nil,
                customErrorPresenter: LoginErrorPresenter? = nil,
                initialError: String? = nil,
                helpDecorator: @escaping ([[HelpItem]]) -> [[HelpItem]] = { $0 }) {
        self.username = username
        self.performBeforeFlow = performBeforeFlow
        self.customErrorPresenter = customErrorPresenter
        self.initialError = initialError
        self.helpDecorator = helpDecorator
    }
}

public protocol LoginAndSignupInterface {
    
    // older API
    
    func presentLoginFlow(over viewController: UIViewController,
                          customization: LoginCustomizationOptions,
                          completion: @escaping (LoginResult) -> Void)

    func presentSignupFlow(over viewController: UIViewController,
                           customization: LoginCustomizationOptions,
                           completion: @escaping (LoginResult) -> Void)

    func presentFlowFromWelcomeScreen(over viewController: UIViewController,
                                      welcomeScreen: WelcomeScreenVariant,
                                      customization: LoginCustomizationOptions,
                                      completion: @escaping (LoginResult) -> Void)

    func welcomeScreenForPresentingFlow(variant welcomeScreen: WelcomeScreenVariant,
                                        customization: LoginCustomizationOptions,
                                        completion: @escaping (LoginResult) -> Void) -> UIViewController
    
    // newer API
    
    func presentLoginFlow(over viewController: UIViewController,
                          customization: LoginCustomizationOptions,
                          updateBlock: @escaping (LoginAndSignupResult) -> Void)

    func presentSignupFlow(over viewController: UIViewController,
                           customization: LoginCustomizationOptions,
                           updateBlock: @escaping (LoginAndSignupResult) -> Void)

    func presentFlowFromWelcomeScreen(over viewController: UIViewController,
                                      welcomeScreen: WelcomeScreenVariant,
                                      customization: LoginCustomizationOptions,
                                      updateBlock: @escaping (LoginAndSignupResult) -> Void)

    func welcomeScreenForPresentingFlow(variant welcomeScreen: WelcomeScreenVariant,
                                        customization: LoginCustomizationOptions,
                                        updateBlock: @escaping (LoginAndSignupResult) -> Void) -> UIViewController
    
    // helper API

    func presentMailboxPasswordFlow(over viewController: UIViewController, completion: @escaping (String) -> Void)
    
    func logout(credential: AuthCredential, completion: @escaping (Result<Void, Error>) -> Void)
}

extension LoginAndSignupInterface {
    
    public func presentLoginFlow(over viewController: UIViewController,
                                 completion: @escaping (LoginResult) -> Void) {
        presentLoginFlow(over: viewController, customization: .empty, completion: completion)
    }
    
    public func presentSignupFlow(over viewController: UIViewController, completion: @escaping (LoginResult) -> Void) {
        presentSignupFlow(over: viewController, customization: .empty, completion: completion)
    }
    
    public func presentFlowFromWelcomeScreen(over viewController: UIViewController,
                                             welcomeScreen: WelcomeScreenVariant,
                                             completion: @escaping (LoginResult) -> Void) {
        presentFlowFromWelcomeScreen(over: viewController,
                                     welcomeScreen: welcomeScreen,
                                     customization: .empty,
                                     completion: completion)
    }
    
    public func welcomeScreenForPresentingFlow(variant welcomeScreen: WelcomeScreenVariant,
                                               completion: @escaping (LoginResult) -> Void) -> UIViewController {
        welcomeScreenForPresentingFlow(variant: welcomeScreen, customization: .empty, completion: completion)
    }
}

public final class LoginAndSignup {
    
    private let container: Container
    private let isCloseButtonAvailable: Bool
    private let minimumAccountType: AccountType
    private var loginCoordinator: LoginCoordinator?
    private var signupCoordinator: SignupCoordinator?
    private var mailboxPasswordCoordinator: MailboxPasswordCoordinator?
    private var viewController: UIViewController?
    private var paymentsAvailability: PaymentsAvailability
    private var signupAvailability: SignupAvailability
    private var customization: LoginCustomizationOptions = .empty
    private var loginAndSignupCompletion: (LoginAndSignupResult) -> Void = { _ in }
    private var loginDataTemporarilyCachedForOlderAPI: LoginData?
    private var mailboxPasswordCompletion: ((String) -> Void)?
    
    public init(appName: String,
                clientApp: ClientApp,
                doh: DoH & ServerConfig,
                apiServiceDelegate: APIServiceDelegate,
                forceUpgradeDelegate: ForceUpgradeDelegate,
                humanVerificationVersion: HumanVerificationVersion,
                minimumAccountType: AccountType,
                isCloseButtonAvailable: Bool = true,
                paymentsAvailability: PaymentsAvailability,
                signupAvailability: SignupAvailability = .notAvailable) {
        container = Container(appName: appName,
                              clientApp: clientApp,
                              doh: doh,
                              apiServiceDelegate: apiServiceDelegate,
                              forceUpgradeDelegate: forceUpgradeDelegate,
                              humanVerificationVersion: humanVerificationVersion,
                              minimumAccountType: minimumAccountType)
        self.isCloseButtonAvailable = isCloseButtonAvailable
        self.paymentsAvailability = paymentsAvailability
        self.signupAvailability = signupAvailability
        self.minimumAccountType = minimumAccountType
    }

    @discardableResult
    private func presentLogin(over viewController: UIViewController?,
                              welcomeScreen: WelcomeScreenVariant?,
                              customization: LoginCustomizationOptions,
                              completion: @escaping (LoginAndSignupResult) -> Void) -> UINavigationController {
        self.viewController = viewController
        self.customization = customization
        self.loginAndSignupCompletion = completion
        let shouldShowCloseButton = viewController == nil ? false : isCloseButtonAvailable
        let loginCoordinator = LoginCoordinator(container: container,
                                                isCloseButtonAvailable: shouldShowCloseButton,
                                                isSignupAvailable: !signupAvailability.isNotAvailable,
                                                customization: customization)
        self.loginCoordinator = loginCoordinator
        loginCoordinator.delegate = self
        if let welcomeScreen = welcomeScreen {
            if let viewController = viewController {
                return loginCoordinator.startFromWelcomeScreen(
                    viewController: viewController, variant: welcomeScreen, username: customization.username
                )
            } else {
                return loginCoordinator.startWithUnmanagedWelcomeScreen(
                    variant: welcomeScreen, username: customization.username
                )
            }
        } else {
            if let viewController = viewController {
                return loginCoordinator.start(.over(viewController, .coverVertical), username: customization.username)
            } else {
                return loginCoordinator.start(.unmanaged, username: customization.username)
            }
        }
    }

    private func presentSignup(_ start: FlowStartKind, customization: LoginCustomizationOptions, completion: @escaping (LoginAndSignupResult) -> Void) {
        signupCoordinator = SignupCoordinator(container: container,
                                              isCloseButton: isCloseButtonAvailable,
                                              paymentsAvailability: paymentsAvailability,
                                              signupAvailability: signupAvailability,
                                              performBeforeFlow: customization.performBeforeFlow,
                                              customErrorPresenter: customization.customErrorPresenter)
        signupCoordinator?.delegate = self
        signupCoordinator?.start(kind: start)
    }
}

extension LoginAndSignup: LoginAndSignupInterface {
    
    public func presentLoginFlow(over viewController: UIViewController,
                                 customization: LoginCustomizationOptions,
                                 updateBlock: @escaping (LoginAndSignupResult) -> Void) {
        presentLogin(over: viewController, welcomeScreen: nil, customization: customization, completion: updateBlock)
    }

    public func presentSignupFlow(over viewController: UIViewController,
                                  customization: LoginCustomizationOptions,
                                  updateBlock: @escaping (LoginAndSignupResult) -> Void) {
        self.viewController = viewController
        self.customization = customization
        self.loginAndSignupCompletion = updateBlock
        presentSignup(.over(viewController, .coverVertical), customization: customization, completion: updateBlock)
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
                                             customization: LoginCustomizationOptions,
                                             updateBlock: @escaping (LoginAndSignupResult) -> Void) {
        presentLogin(over: viewController, welcomeScreen: welcomeScreen, customization: customization, completion: updateBlock)
    }
    
    public func welcomeScreenForPresentingFlow(variant welcomeScreen: WelcomeScreenVariant,
                                               customization: LoginCustomizationOptions,
                                               updateBlock: @escaping (LoginAndSignupResult) -> Void) -> UIViewController {
        presentLogin(over: nil, welcomeScreen: welcomeScreen, customization: customization, completion: updateBlock)
    }
    
    public func logout(credential: AuthCredential, completion: @escaping (Result<Void, Error>) -> Void) {
        container.login.logout(credential: credential, completion: completion)
    }
    
    // backwards compatibility
    
    public func presentLoginFlow(over viewController: UIViewController,
                                 customization: LoginCustomizationOptions,
                                 completion: @escaping (LoginResult) -> Void) {
        presentLoginFlow(over: viewController, customization: customization, updateBlock: transformedCompletion(completion))
    }

    public func presentSignupFlow(over viewController: UIViewController,
                                  customization: LoginCustomizationOptions,
                                  completion: @escaping (LoginResult) -> Void) {
        presentSignupFlow(over: viewController, customization: customization, updateBlock: transformedCompletion(completion))
    }

    public func presentFlowFromWelcomeScreen(over viewController: UIViewController,
                                             welcomeScreen: WelcomeScreenVariant,
                                             customization: LoginCustomizationOptions,
                                             completion: @escaping (LoginResult) -> Void) {
        presentFlowFromWelcomeScreen(over: viewController, welcomeScreen: welcomeScreen, customization: customization, updateBlock: transformedCompletion(completion))
    }

    public func welcomeScreenForPresentingFlow(variant welcomeScreen: WelcomeScreenVariant,
                                               customization: LoginCustomizationOptions,
                                               completion: @escaping (LoginResult) -> Void) -> UIViewController {
        welcomeScreenForPresentingFlow(variant: welcomeScreen, customization: customization, updateBlock: transformedCompletion(completion))
    }
    
    private func transformedCompletion(_ completion: @escaping (LoginResult) -> Void) -> (LoginAndSignupResult) -> Void {
        return { [unowned self] (result: LoginAndSignupResult) in
            switch result {
            case .dismissed: completion(.dismissed)
            case .loginStateChanged(.dataIsAvailable(let data)), .signupStateChanged(.dataIsAvailable(let data)):
                self.loginDataTemporarilyCachedForOlderAPI = data
            case .loginStateChanged(.loginFinished):
                guard let loginData = self.loginDataTemporarilyCachedForOlderAPI else {
                    preconditionFailure("Login data must be available at the point of login finish")
                }
                completion(.loggedIn(loginData))
            case .signupStateChanged(.signupFinished):
                guard let loginData = self.loginDataTemporarilyCachedForOlderAPI else {
                    preconditionFailure("Login data must be available at the point of signup finish")
                }
                completion(.signedUp(loginData))
            }
        }
    }
}

extension LoginAndSignup: LoginCoordinatorDelegate {
    func userDidDismissLoginCoordinator(loginCoordinator: LoginCoordinator) {
        loginAndSignupCompletion(.dismissed)
    }
    
    func loginCoordinatorDidFinish(loginCoordinator: LoginCoordinator, data: LoginData) {
        loginAndSignupCompletion(.loginStateChanged(.dataIsAvailable(data)))
        loginAndSignupCompletion(.loginStateChanged(.loginFinished))
    }

    func userSelectedSignup(navigationController: LoginNavigationViewController) {
        presentSignup(.inside(navigationController), customization: customization, completion: loginAndSignupCompletion)
    }
}

extension LoginAndSignup: SignupCoordinatorDelegate {
    func userDidDismissSignupCoordinator(signupCoordinator: SignupCoordinator) {
        loginAndSignupCompletion(.dismissed)
    }
    
    func signupCoordinatorDidFinish(signupCoordinator: SignupCoordinator, signupState: SignupState) {
        loginAndSignupCompletion(.signupStateChanged(signupState))
    }
    
    func userSelectedSignin(email: String?, navigationViewController: LoginNavigationViewController) {
        loginCoordinator = LoginCoordinator(container: container,
                                            isCloseButtonAvailable: isCloseButtonAvailable,
                                            isSignupAvailable: !signupAvailability.isNotAvailable,
                                            customization: customization)
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

// MARK: - Deprecations

@available(*, deprecated, renamed: "LoginAndSignupInterface")
public typealias LoginInterface = LoginAndSignupInterface

extension LoginAndSignupInterface {
    
    @available(*, deprecated, message: "Please switch to variant taking LoginCustomizationOptions parameter")
    public func presentLoginFlow(over viewController: UIViewController,
                                 username: String?,
                                 completion: @escaping (LoginResult) -> Void) {
        presentLoginFlow(over: viewController,
                         customization: LoginCustomizationOptions(username: username),
                         completion: completion)
    }
    
    @available(*, deprecated, message: "Please switch to variant taking LoginCustomizationOptions parameter")
    func presentLoginFlow(over viewController: UIViewController,
                          username: String?,
                          performBeforeFlow: WorkBeforeFlow?,
                          customErrorPresenter: LoginErrorPresenter?,
                          completion: @escaping (LoginResult) -> Void) {
        presentLoginFlow(over: viewController,
                         customization: LoginCustomizationOptions(
                            username: username,
                            performBeforeFlow: performBeforeFlow,
                            customErrorPresenter: customErrorPresenter
                         ),
                         completion: completion)
    }

    @available(*, deprecated, message: "Please switch to variant taking LoginCustomizationOptions parameter")
    func presentSignupFlow(over viewController: UIViewController,
                           performBeforeFlow: WorkBeforeFlow?,
                           customErrorPresenter: LoginErrorPresenter?,
                           completion: @escaping (LoginResult) -> Void) {
        presentSignupFlow(over: viewController,
                          customization: LoginCustomizationOptions(
                            performBeforeFlow: performBeforeFlow,
                            customErrorPresenter: customErrorPresenter
                          ),
                          completion: completion)
    }
    
    @available(*, deprecated, message: "Please switch to variant taking LoginCustomizationOptions parameter")
    public func presentFlowFromWelcomeScreen(over viewController: UIViewController,
                                             welcomeScreen: WelcomeScreenVariant,
                                             username: String?,
                                             completion: @escaping (LoginResult) -> Void) {
        presentFlowFromWelcomeScreen(over: viewController,
                                     welcomeScreen: welcomeScreen,
                                     customization: LoginCustomizationOptions(username: username),
                                     completion: completion)
    }

    @available(*, deprecated, message: "Please switch to variant taking LoginCustomizationOptions parameter")
    // swiftlint:disable:next function_parameter_count
    func presentFlowFromWelcomeScreen(over viewController: UIViewController,
                                      welcomeScreen: WelcomeScreenVariant,
                                      username: String?,
                                      performBeforeFlow: WorkBeforeFlow?,
                                      customErrorPresenter: LoginErrorPresenter?,
                                      completion: @escaping (LoginResult) -> Void) {
        presentFlowFromWelcomeScreen(over: viewController,
                                     welcomeScreen: welcomeScreen,
                                     customization: LoginCustomizationOptions(
                                        username: username,
                                        performBeforeFlow: performBeforeFlow,
                                        customErrorPresenter: customErrorPresenter
                                     ),
                                     completion: completion)
    }

    @available(*, deprecated, message: "Please switch to variant taking LoginCustomizationOptions parameter")
    func welcomeScreenForPresentingFlow(variant welcomeScreen: WelcomeScreenVariant,
                                        username: String?,
                                        performBeforeFlow: WorkBeforeFlow?,
                                        customErrorPresenter: LoginErrorPresenter?,
                                        completion: @escaping (LoginResult) -> Void) -> UIViewController {
        welcomeScreenForPresentingFlow(variant: welcomeScreen,
                                       customization: LoginCustomizationOptions(
                                        username: username,
                                        performBeforeFlow: performBeforeFlow,
                                        customErrorPresenter: customErrorPresenter
                                       ),
                                       completion: completion)
    }

    @available(*, deprecated, message: "Please switch to variant taking LoginCustomizationOptions parameter")
    public func welcomeScreenForPresentingFlow(variant welcomeScreen: WelcomeScreenVariant,
                                               username: String?,
                                               completion: @escaping (LoginResult) -> Void) -> UIViewController {
        welcomeScreenForPresentingFlow(variant: welcomeScreen,
                                       customization: LoginCustomizationOptions(username: username),
                                       completion: completion)
    }
}

@available(*, deprecated, renamed: "LoginAndSignup")
public typealias PMLogin = LoginAndSignup

extension LoginAndSignup {
    @available(*, deprecated, message: "Use the new initializer with payment plans for a particular app. Otherwise the no plans will be available.")
    public convenience init(appName: String,
                            clientApp: ClientApp,
                            doh: DoH & ServerConfig,
                            apiServiceDelegate: APIServiceDelegate,
                            forceUpgradeDelegate: ForceUpgradeDelegate,
                            minimumAccountType: AccountType,
                            isCloseButtonAvailable: Bool = true,
                            isPlanSelectorAvailable: Bool,
                            signupAvailability: SignupAvailability = .notAvailable) {
        self.init(appName: appName, clientApp: clientApp, doh: doh, apiServiceDelegate: apiServiceDelegate, forceUpgradeDelegate: forceUpgradeDelegate, minimumAccountType: minimumAccountType, isCloseButtonAvailable: isCloseButtonAvailable, paymentsAvailability: isPlanSelectorAvailable ? .available(parameters: .init(listOfIAPIdentifiers: [], listOfShownPlanNames: [], reportBugAlertHandler: nil)) : .notAvailable)
    }

    @available(*, deprecated, message: "Use the initializer that specifies the human verification version")
    public convenience init(appName: String,
                            clientApp: ClientApp,
                            doh: DoH & ServerConfig,
                            apiServiceDelegate: APIServiceDelegate,
                            forceUpgradeDelegate: ForceUpgradeDelegate,
                            minimumAccountType: AccountType,
                            isCloseButtonAvailable: Bool = true,
                            paymentsAvailability: PaymentsAvailability,
                            signupAvailability: SignupAvailability = .notAvailable) {
        self.init(appName: appName, clientApp: clientApp, doh: doh, apiServiceDelegate: apiServiceDelegate, forceUpgradeDelegate: forceUpgradeDelegate, humanVerificationVersion: .v2, minimumAccountType: minimumAccountType, isCloseButtonAvailable: isCloseButtonAvailable, paymentsAvailability: paymentsAvailability, signupAvailability: signupAvailability)
    }
}
