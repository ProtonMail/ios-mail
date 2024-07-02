//
//  SignupCoordinator.swift
//  ProtonCore-Login - Created on 11/03/2021.
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

import UIKit
import ProtonCoreLogin
import ProtonCoreNetworking
import ProtonCoreUIFoundations
import ProtonCorePayments
import ProtonCorePaymentsUI
import ProtonCoreHumanVerification
import ProtonCoreFoundations
import ProtonCoreLog

enum FlowStartKind {
    case over(UIViewController, UIModalTransitionStyle)
    case inside(LoginNavigationViewController)
    case unmanaged
}

protocol SignupCoordinatorDelegate: AnyObject {
    func userDidDismissSignupCoordinator(signupCoordinator: SignupCoordinator)
    func signupCoordinatorDidFinish(signupCoordinator: SignupCoordinator, signupState: SignupState)
    func userSelectedSignin(email: String?, navigationViewController: LoginNavigationViewController)
}

protocol SignupAccountTypeManagerProtocol {
    var accountType: SignupAccountType { get }
    func setSignupAccountType(type: SignupAccountType)
}

final class SignupAccountTypeManager: SignupAccountTypeManagerProtocol {
    var accountType: SignupAccountType = .internal

    func setSignupAccountType(type: SignupAccountType) {
        accountType = type
    }
}

final class SignupCoordinator {

    weak var delegate: SignupCoordinatorDelegate?

    private let container: Container
    private let minimumAccountType: AccountType
    private let isCloseButton: Bool
    private let signupAvailability: SignupAvailability
    private var signupParameters: SignupParameters?
    private var navigationController: LoginNavigationViewController? {
        didSet {
            navigationController?.overrideUserInterfaceStyle = customization.inAppTheme().userInterfaceStyle
        }
    }
    private var signupViewController: SignupViewController?
    private var recoveryViewController: RecoveryViewController?
    private var countryPickerViewController: CountryPickerViewController?
    private var countryPicker = PMCountryPicker(searchBarPlaceholderText: LUITranslation.sms_search_placeholder.l10n)
    private var completeViewModel: CompleteViewModel?

    private let signupAccountTypeManager: SignupAccountTypeManagerProtocol
    private var name: String?
    private var password: String?
    private var verifyToken: String?
    private var tokenType: String?
    private var loginData: LoginData?
    private let customization: LoginCustomizationOptions
    private let externalLinks: ExternalLinks
    private let longTermTask = LongTermTask()

    // Payments
    private let paymentsAvailability: PaymentsAvailability
    private let paymentsManager: PaymentsManager?

    init(container: Container,
         minimumAccountType: AccountType,
         isCloseButton: Bool,
         paymentsAvailability: PaymentsAvailability,
         signupAvailability: SignupAvailability,
         customization: LoginCustomizationOptions,
         signupAccountTypeManager: SignupAccountTypeManagerProtocol = SignupAccountTypeManager()) {
        self.container = container
        self.minimumAccountType = minimumAccountType
        self.isCloseButton = isCloseButton
        self.signupAvailability = signupAvailability
        self.customization = customization
        self.paymentsAvailability = paymentsAvailability
        self.signupAccountTypeManager = signupAccountTypeManager
        if case .available(let paymentParameters) = paymentsAvailability {
            self.paymentsManager = container.makePaymentsCoordinator(
                for: paymentParameters.listOfIAPIdentifiers,
                shownPlanNames: paymentParameters.listOfShownPlanNames,
                customization: PaymentsUICustomizationOptions(
                    inAppTheme: customization.inAppTheme,
                    customPlansDescription: paymentParameters.customPlansDescription
                ),
                reportBugAlertHandler: paymentParameters.reportBugAlertHandler
            )
        } else {
            self.paymentsManager = nil
        }
        externalLinks = container.makeExternalLinks()
    }

    func start(kind: FlowStartKind) {
        switch signupAvailability {
        case .notAvailable:
            assertionFailure("Signup flow should never be presented when it's not available")
            navigationController?.dismiss(animated: true)
            delegate?.userDidDismissSignupCoordinator(signupCoordinator: self)
        case .available(let parameters):
            signupParameters = parameters
            showSignupViewController(kind: kind, signupParameters: parameters)
        }
    }

    // MARK: - View controller internal account presentation methods

    func createSignupViewController(signupParameters: SignupParameters) -> SignupViewController {

        switch minimumAccountType {
        case .username, .external:
            signupAccountTypeManager.setSignupAccountType(type: .external)
        case .internal:
            signupAccountTypeManager.setSignupAccountType(type: .internal)
        }

        let signupViewController = UIStoryboard.instantiateInSignup(SignupViewController.self, inAppTheme: customization.inAppTheme)
        signupViewController.viewModel = container.makeSignupViewModel()
        signupViewController.customErrorPresenter = customization.customErrorPresenter
        signupViewController.delegate = self
        self.signupViewController = signupViewController

        switch minimumAccountType {
        case .internal:
            signupViewController.showOtherAccountButton = false
        case .username, .external:
            signupViewController.showOtherAccountButton = true
        }
        signupViewController.showSeparateDomainsButton = signupParameters.separateDomainsButton
        signupViewController.showCloseButton = isCloseButton
        signupViewController.minimumAccountType = minimumAccountType
        signupViewController.signupAccountType = signupAccountTypeManager.accountType

        signupViewController.onDohTroubleshooting = { [weak self] in
            guard let self = self else { return }
            self.container.executeDohTroubleshootMethodFromApiDelegate()

            guard let nav = self.navigationController else { return }
            self.container.troubleShootingHelper.showTroubleShooting(over: nav)
        }
        return signupViewController
    }

    private func showSignupViewController(kind: FlowStartKind, signupParameters: SignupParameters) {

        let signupViewController = createSignupViewController(signupParameters: signupParameters)

        switch kind {
        case .unmanaged:
            assertionFailure("we do not support the unmanaged signup showing")
        case let .over(viewController, modalTransitionStyle):
            let navigationController = LoginNavigationViewController(rootViewController: signupViewController)
            self.navigationController = navigationController
            navigationController.modalTransitionStyle = modalTransitionStyle
            viewController.present(navigationController, animated: true, completion: nil)
        case .inside(let navigationViewController):
            self.navigationController = navigationViewController
            navigationViewController.setViewControllers([signupViewController], animated: true)
        }
    }

    private func showPasswordViewController() {
        guard let signupParameters = signupParameters else { return }
        let passwordViewController = UIStoryboard.instantiateInSignup(PasswordViewController.self, inAppTheme: customization.inAppTheme)
        passwordViewController.viewModel = container.makePasswordViewModel()
        passwordViewController.customErrorPresenter = customization.customErrorPresenter
        passwordViewController.delegate = self
        passwordViewController.signupAccountType = signupAccountTypeManager.accountType
        passwordViewController.signupPasswordRestrictions = signupParameters.passwordRestrictions
        passwordViewController.onDohTroubleshooting = { [weak self] in
            guard let self = self else { return }
            self.container.executeDohTroubleshootMethodFromApiDelegate()

            guard let nav = self.navigationController else { return }
            self.container.troubleShootingHelper.showTroubleShooting(over: nav)
        }

        navigationController?.pushViewController(passwordViewController, animated: true)
    }

    private func showRecoveryViewController() {
        let recoveryViewController = UIStoryboard.instantiateInSignup(RecoveryViewController.self, inAppTheme: customization.inAppTheme)
        recoveryViewController.viewModel = container.makeRecoveryViewModel(initialCountryCode: countryPicker.getInitialCode())
        recoveryViewController.delegate = self
        recoveryViewController.minimumAccountType = minimumAccountType
        recoveryViewController.onDohTroubleshooting = { [weak self] in
            guard let self = self else { return }
            self.container.executeDohTroubleshootMethodFromApiDelegate()

            guard let nav = self.navigationController else { return }
            self.container.troubleShootingHelper.showTroubleShooting(over: nav)
        }
        self.recoveryViewController = recoveryViewController

        navigationController?.pushViewController(recoveryViewController, animated: true)
    }

    private func finishSignupProcess(email: String? = nil, phoneNumber: String? = nil, completionHandler: (() -> Void)?) {
        guard let paymentsManager = paymentsManager, let signupViewController = signupViewController else {
            completionHandler?()
            showCompleteViewController(email: email, phoneNumber: phoneNumber)
            return
        }

        paymentsManager.startPaymentProcess(signupViewController: signupViewController,
                                            planShownHandler: completionHandler) { [weak self] result in
            switch result {
            case .success:
                self?.showCompleteViewController(email: email, phoneNumber: phoneNumber)
            case .failure(let error):
                self?.errorHandler(error: error)
            }
        }
    }

    private func showCompleteViewController(email: String? = nil, phoneNumber: String? = nil) {
        var initDisplaySteps: [DisplayProgressStep] = [.createAccount]
        if signupAccountTypeManager.accountType == .internal {
            initDisplaySteps += [.generatingAddress]
        }
        initDisplaySteps += [.generatingKeys]

        if !(paymentsManager?.selectedPlan?.isFreePlan ?? true) {
            initDisplaySteps += [.payment]
        }
        if let performBeforeFlow = customization.performBeforeFlow {
            initDisplaySteps += [.custom(performBeforeFlow.stepName)]
        }

        let completeViewController = UIStoryboard.instantiateInSignup(CompleteViewController.self, inAppTheme: customization.inAppTheme)
        completeViewModel = container.makeCompleteViewModel(initDisplaySteps: initDisplaySteps)
        completeViewController.viewModel = completeViewModel
        completeViewController.delegate = self
        completeViewController.signupAccountType = signupAccountTypeManager.accountType
        completeViewController.name = self.name
        completeViewController.password = self.password
        completeViewController.email = email
        completeViewController.phoneNumber = phoneNumber
        completeViewController.verifyToken = verifyToken
        completeViewController.tokenType = tokenType
        navigationController?.setUpShadowLessNavigationBar()
        navigationController?.pushViewController(completeViewController, animated: true)
    }

    private func showCountryPickerViewController() {
        let countryPickerViewController = countryPicker.getCountryPickerViewController(
            inAppTheme: customization.inAppTheme
        )
        countryPickerViewController.delegate = self
        countryPickerViewController.modalTransitionStyle = .coverVertical
        self.countryPickerViewController = countryPickerViewController

        navigationController?.present(countryPickerViewController, animated: true)
    }

    private func showTermsAndConditionsViewController() {
        let tcViewController = UIStoryboard.instantiateInSignup(TCViewController.self, inAppTheme: customization.inAppTheme)
        tcViewController.termsAndConditionsURL = externalLinks.termsAndConditions
        tcViewController.delegate = self

        let navigationVC = LoginNavigationViewController(rootViewController: tcViewController)
        navigationVC.modalPresentationStyle = .pageSheet
        navigationController?.present(navigationVC, animated: true)
    }

    // MARK: - View controller external account presentation methods

    private func showEmailVerificationViewController() {
        guard let email = name else {
            assertionFailure("email missing")
            return
        }
        let emailVerificationViewController = UIStoryboard.instantiateInSignup(EmailVerificationViewController.self, inAppTheme: customization.inAppTheme)
        let emailVerificationViewModel = container.makeEmailVerificationViewModel()
        emailVerificationViewModel.email = email
        emailVerificationViewController.viewModel = emailVerificationViewModel
        emailVerificationViewController.customErrorPresenter = customization.customErrorPresenter
        emailVerificationViewController.delegate = self
        emailVerificationViewController.onDohTroubleshooting = { [weak self] in
            guard let self = self else { return }
            self.container.executeDohTroubleshootMethodFromApiDelegate()

            guard let nav = self.navigationController else { return }
            self.container.troubleShootingHelper.showTroubleShooting(over: nav)
        }

        navigationController?.pushViewController(emailVerificationViewController, animated: true)
    }

    private var activeViewController: UIViewController? {
        guard let viewControllers = navigationController?.viewControllers, !viewControllers.isEmpty else { return nil }
        guard viewControllers.count > 1 else { return viewControllers.first }
        var completeVCIndex: Int?
        for (index, vc) in viewControllers.enumerated() where vc is CompleteViewController {
            completeVCIndex = index - 1
        }
        guard let completeVCIndex = completeVCIndex, completeVCIndex >= 0, viewControllers.count > completeVCIndex else { return nil }
        return viewControllers[completeVCIndex]
    }

    private func finalizeAccountCreation(loginData: LoginData) {
        guard let paymentsManager = paymentsManager else {
            tryRefreshingLoginDataBeforeFinishingAccountCreation(loginData: loginData)
            return
        }

        if !(paymentsManager.selectedPlan?.isFreePlan ?? true) {
            completeViewModel?.progressStepWait(progressStep: .payment)
        }

        paymentsManager.finishPaymentProcess(loginData: loginData) { [weak self] result in
            switch result {
            case .success(let purchasedPlan):
                self?.tryRefreshingLoginDataBeforeFinishingAccountCreation(loginData: loginData, purchasedPlan: purchasedPlan)
            case .failure(let error):
                self?.errorHandler(error: error)
            }
        }
    }

    private func tryRefreshingLoginDataBeforeFinishingAccountCreation(loginData: LoginData, purchasedPlan: InAppPurchasePlan? = nil) {
        let login = container.login
        login.refreshCredentials { [weak self] credentialsResult in
            var possiblyRefreshedLoginData = loginData
            switch credentialsResult {
            case .success(let credential):
                possiblyRefreshedLoginData = possiblyRefreshedLoginData.updated(credential: credential)
            case .failure:
                break
            }

            guard possiblyRefreshedLoginData.getCredential.hasFullScope else {
                self?.finishAccountCreation(loginData: possiblyRefreshedLoginData, purchasedPlan: purchasedPlan)
                return
            }

            login.refreshUserInfo { [weak self] userResult in
                switch userResult {
                case .success(let user):
                    possiblyRefreshedLoginData = possiblyRefreshedLoginData.updated(user: user)
                case .failure: break
                }
                self?.finishAccountCreation(loginData: possiblyRefreshedLoginData, purchasedPlan: purchasedPlan)
            }
        }
    }

    private func finishAccountCreation(loginData: LoginData, purchasedPlan: InAppPurchasePlan? = nil) {
        longTermTask.inProgress = false
        DispatchQueue.main.async { [weak self] in
            guard let performBeforeFlow = self?.customization.performBeforeFlow else {
                self?.summarySignupFlow(data: loginData, purchasedPlan: purchasedPlan)
                return
            }
            self?.completeViewModel?.progressStepWait(progressStep: .custom(performBeforeFlow.stepName))
            performBeforeFlow.completion(loginData) { [weak self] result in
                DispatchQueue.main.async { [weak self] in
                    switch result {
                    case .success:
                        self?.summarySignupFlow(data: loginData, purchasedPlan: purchasedPlan)
                    case .failure(let error):
                        self?.signinButtonPressed()
                        self?.errorHandler(error: error)
                    }
                }
            }
        }
    }

    private func summarySignupFlow(data: LoginData, purchasedPlan: InAppPurchasePlan? = nil) {
        completeViewModel?.progressStepAllDone()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            switch self.signupParameters?.summaryScreenVariant {
            case .noSummaryScreen:
                self.completeSignupFlow(signupState: .dataIsAvailable(data))
                self.completeSignupFlow(signupState: .signupFinished)
            case .screenVariant:
                self.completeSignupFlow(signupState: .dataIsAvailable(data))
                self.showSummaryViewController(data: data, purchasedPlan: purchasedPlan)
            case .none:
                break
            }
        }
    }

    private func showSummaryViewController(data: LoginData, purchasedPlan: InAppPurchasePlan?) {
        guard let signupParameters = signupParameters else { return }
        self.loginData = data
        let summaryViewController = UIStoryboard.instantiateInSignup(SummaryViewController.self, inAppTheme: customization.inAppTheme)

        var planName: String?
        if let paymentsManager = paymentsManager {
            planName = paymentsManager.planTitle(plan: purchasedPlan)
        }
        summaryViewController.viewModel = container.makeSummaryViewModel(
            planName: planName,
            paymentsAvailability: paymentsAvailability,
            screenVariant: signupParameters.summaryScreenVariant
        )
        summaryViewController.delegate = self

        let navigationVC = LoginNavigationViewController(rootViewController: summaryViewController)
        navigationVC.modalPresentationStyle = .fullScreen
        navigationController?.present(navigationVC, animated: true)
    }

    private func completeSignupFlow(signupState: SignupState) {
        if case .signupFinished = signupState {
            navigationController?.presentingViewController?.dismiss(animated: true)
        }
        delegate?.signupCoordinatorDidFinish(signupCoordinator: self, signupState: signupState)
    }
}

// MARK: SignupViewControllerDelegate

extension SignupCoordinator: SignupViewControllerDelegate {
    func validatedName(name: String, signupAccountType: SignupAccountType) {
        self.name = name
        signupAccountTypeManager.setSignupAccountType(type: signupAccountType)
        if signupAccountType == .internal {
            updateLoginAccountType(accountType: .internal)
            showPasswordViewController()
        } else {
            updateLoginAccountType(accountType: .external)
            showEmailVerificationViewController()
        }
    }

    func validatedEmail(email: String, signupAccountType: SignupAccountType) {
        self.name = email
        self.verifyToken = container.token
        self.tokenType = container.tokenType
        signupAccountTypeManager.setSignupAccountType(type: signupAccountType)
        updateLoginAccountType(accountType: .external)
        showPasswordViewController()
    }

    func signupCloseButtonPressed() {
        // on leaving the signup flow, we need to restore the login's minimum account type requirement to original value
        updateLoginAccountType(accountType: minimumAccountType)
        navigationController?.dismiss(animated: true)
        delegate?.userDidDismissSignupCoordinator(signupCoordinator: self)
    }

    func signinButtonPressed() {
        // on leaving the signup flow, we need to restore the login's minimum account type requirement to original value
        updateLoginAccountType(accountType: minimumAccountType)
        guard let navigationController = navigationController else { return }
        delegate?.userSelectedSignin(email: nil, navigationViewController: navigationController)
    }

    func hvEmailAlreadyExists(email: String) {
        // on leaving the signup flow, we need to restore the login service's minimum account type requirement to original value
        updateLoginAccountType(accountType: minimumAccountType)
        guard let navigationController = navigationController else { return }
        delegate?.userSelectedSignin(email: email, navigationViewController: navigationController)
    }

    private func updateLoginAccountType(accountType: AccountType) {
        // updating the login service's minimum account type changes how the account setup is performed.
        // the account setup is shared between signup and login services, so the configuration must be updated.
        // for example, even if we allow the username accounts to sign in and we don't generate keys for them,
        // we want to generate keys if the user is signing up through the internal signup flow
        container.login.updateAccountType(accountType: accountType)
    }
}

// MARK: PasswordViewControllerDelegate

extension SignupCoordinator: PasswordViewControllerDelegate {
    func passwordIsShown() {

        if signupAccountTypeManager.accountType == .external {
            // if PasswordViewController is presented we need to remove HumanVerifyViewController from the navigation stack to don't allow to come back to it.
            HumanCheckHelper.removeHumanVerification(from: navigationController)
        }
    }

    func validatedPassword(password: String, completionHandler: (() -> Void)?) {
        self.password = password
        if signupAccountTypeManager.accountType == .internal {
            showRecoveryViewController()
            completionHandler?()
        } else {
            finishSignupProcess(completionHandler: completionHandler)
        }
    }

    func passwordBackButtonPressed() {
        navigationController?.popViewController(animated: true)
    }
}

// MARK: RecoveryViewControllerDelegate

extension SignupCoordinator: RecoveryViewControllerDelegate {

    func recoveryFinish(email: String?, phoneNumber: String?, completionHandler: (() -> Void)?) {
        finishSignupProcess(email: email, phoneNumber: phoneNumber, completionHandler: completionHandler)
    }

    func recoveryBackButtonPressed() {
        navigationController?.popViewController(animated: true)
    }

    func termsAndConditionsLinkPressed() {
        showTermsAndConditionsViewController()
    }

    func recoveryCountryPickerPressed() {
        showCountryPickerViewController()
    }
}

// MARK: CountryPickerViewControllerDelegate

extension SignupCoordinator: CountryPickerViewControllerDelegate {
    func didSelectCountryCode(countryCode: CountryCode) {
        countryPickerViewController?.dismiss(animated: true)
        recoveryViewController?.updateCountryCode(countryCode.phone_code)
    }

    func didCountryPickerClose() {
        countryPickerViewController?.dismiss(animated: true)
    }

    func didCountryPickerDissmised() {
        recoveryViewController?.countryPickerDissmised()
    }
}

// MARK: CompleteViewControllerDelegate

extension SignupCoordinator: CompleteViewControllerDelegate {
    func accountCreationStart() {
        longTermTask.inProgress = true
    }

    func accountCreationFinish(loginData: LoginData) {
        finalizeAccountCreation(loginData: loginData)
    }

    func accountCreationError(error: Error) {
        errorHandler(error: error)
    }

    // swiftlint:disable:next cyclomatic_complexity
    private func errorHandler(error: Error) {
        PMLog.error(error, sendToExternal: true)
        longTermTask.inProgress = false
        if activeViewController != nil {
            navigationController?.popViewController(animated: true)
        }
        let errorVC = activeViewController ?? navigationController?.viewControllers.last
        if let error = error as? LoginError {
            if let vc = errorVC, self.customization.customErrorPresenter?.willPresentError(error: error, from: vc) == true {
            } else if let vc = errorVC as? LoginErrorCapable {
                vc.showError(error: error)
            }
        } else if let error = error as? SignupError {
            if let vc = errorVC, self.customization.customErrorPresenter?.willPresentError(error: error, from: vc) == true {
            } else if let vc = errorVC as? SignUpErrorCapable {
                vc.showError(error: error)
            }
        } else if let error = error as? StoreKitManagerErrors {
            if let vc = errorVC, self.customization.customErrorPresenter?.willPresentError(error: error, from: vc) == true {
            } else if let vc = errorVC as? PaymentErrorCapable {
                vc.showError(error: error)
            }
        } else if let error = error as? AvailabilityError {
            if let vc = errorVC, self.customization.customErrorPresenter?.willPresentError(error: error, from: vc) == true {
            } else if let vc = errorVC as? SignUpErrorCapable {
                switch error {
                case .protonDomainUsedForExternalAccount:
                    // this error is not user-facing
                    break
                case .generic(let message, let code, let originalError):
                    vc.showError(error: SignupError.generic(message: message, code: code, originalError: originalError))
                case .apiMightBeBlocked(let message, let originalError):
                    vc.showError(error: SignupError.apiMightBeBlocked(message: message, originalError: originalError))
                case .notAvailable(let message):
                    vc.showError(error: SignupError.generic(message: message, code: error.bestShotAtReasonableErrorCode, originalError: error))
                }
            }
        } else if let error = error as? SetUsernameError {
            if let vc = errorVC, self.customization.customErrorPresenter?.willPresentError(error: error, from: vc) == true {
            } else if let vc = errorVC as? SignUpErrorCapable {
                switch error {
                case .generic(let message, let code, let originalError):
                    vc.showError(error: SignupError.generic(message: message, code: code, originalError: originalError))
                case .apiMightBeBlocked(let message, let originalError):
                    vc.showError(error: SignupError.apiMightBeBlocked(message: message, originalError: originalError))
                case .alreadySet(let message):
                    vc.showError(error: SignupError.generic(message: message, code: error.bestShotAtReasonableErrorCode, originalError: error))
                }
            }
        } else if let error = error as? CreateAddressError {
            if let vc = errorVC, self.customization.customErrorPresenter?.willPresentError(error: error, from: vc) == true {
            } else if let vc = errorVC as? SignUpErrorCapable {
                switch error {
                case .generic(let message, let code, let originalError):
                    vc.showError(error: SignupError.generic(message: message, code: code, originalError: originalError))
                case .apiMightBeBlocked(let message, let originalError):
                    vc.showError(error: SignupError.apiMightBeBlocked(message: message, originalError: originalError))
                case .cannotCreateInternalAddress, .alreadyHaveInternalOrCustomDomainAddress:
                    vc.showError(error: SignupError.generic(message: error.localizedDescription, code: error.bestShotAtReasonableErrorCode, originalError: error))
                }
            }
        } else if let error = error as? CreateAddressKeysError {
            if let vc = errorVC, self.customization.customErrorPresenter?.willPresentError(error: error, from: vc) == true {
            } else if let vc = errorVC as? SignUpErrorCapable {
                switch error {
                case .generic(let message, let code, let originalError):
                    vc.showError(error: SignupError.generic(message: message, code: code, originalError: originalError))
                case .apiMightBeBlocked(let message, let originalError):
                    vc.showError(error: SignupError.apiMightBeBlocked(message: message, originalError: originalError))
                case .alreadySet:
                    vc.showError(error: SignupError.generic(message: error.localizedDescription, code: error.bestShotAtReasonableErrorCode, originalError: error))
                }
            }
        } else if let error = error as? ResponseError, let message = error.userFacingMessage ?? error.underlyingError?.localizedDescription {
            if let vc = errorVC, self.customization.customErrorPresenter?.willPresentError(error: error, from: vc) == true {
            } else if let vc = errorVC as? SignUpErrorCapable {
                vc.showError(error: SignupError.generic(message: message, code: error.bestShotAtReasonableErrorCode, originalError: error))
            }
        } else {
            if let vc = errorVC, self.customization.customErrorPresenter?.willPresentError(error: error, from: vc) == true {
            } else if let vc = errorVC as? SignUpErrorCapable {
                vc.showError(error: SignupError.generic(message: error.localizedDescription, code: error.bestShotAtReasonableErrorCode, originalError: error))
            } else if let vc = errorVC as? LoginErrorCapable {
                vc.showError(error: LoginError.generic(message: error.localizedDescription, code: error.bestShotAtReasonableErrorCode, originalError: error))
            }
        }
        if let vc = errorVC as? PaymentsUIViewController {
            vc.planPurchaseError()
        }
    }
}

// MARK: TCViewControllerDelegate

extension SignupCoordinator: TCViewControllerDelegate {
    func termsAndConditionsClose() {
        navigationController?.dismiss(animated: true)
    }
}

extension SignupCoordinator: EmailVerificationViewControllerDelegate {
    func validatedToken(verifyToken: String) {
        self.verifyToken = verifyToken
        self.tokenType = VerifyMethod.PredefinedMethod.email.rawValue
        showPasswordViewController()
    }

    func emailVerificationBackButtonPressed() {
        navigationController?.popViewController(animated: true)
    }

    func emailAlreadyExists(email: String) {
        guard let navigationController = navigationController else { return }
        delegate?.userSelectedSignin(email: email, navigationViewController: navigationController)
    }
}

// MARK: SummaryViewControllerDelegate

extension SignupCoordinator: SummaryViewControllerDelegate {
    func startButtonTap() {
        completeSignupFlow(signupState: .signupFinished)
    }
}

private extension UIStoryboard {
    static func instantiateInSignup<T: UIViewController>(_ controllerType: T.Type, inAppTheme: () -> InAppTheme) -> T {
        self.instantiate(storyboardName: "PMSignup", controllerType: controllerType, inAppTheme: inAppTheme)
    }
}

#endif
