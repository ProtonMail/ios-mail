//
//  SignupCoordinator.swift
//  ProtonCore-Login - Created on 11/03/2021.
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

#if canImport(UIKit)
import UIKit
import ProtonCore_CoreTranslation
import ProtonCore_Networking
import ProtonCore_UIFoundations
import ProtonCore_Payments
import ProtonCore_PaymentsUI

enum FlowStartKind {
    case over(UIViewController, UIModalTransitionStyle)
    case inside(LoginNavigationViewController)
    case unmanaged
}

protocol SignupCoordinatorDelegate: AnyObject {
    func userDidDismissSignupCoordinator(signupCoordinator: SignupCoordinator)
    func signupCoordinatorDidFinish(signupCoordinator: SignupCoordinator, loginData: LoginData)
    func userSelectedSignin(email: String?, navigationViewController: LoginNavigationViewController)
}

final class SignupCoordinator {
    
    weak var delegate: SignupCoordinatorDelegate?
    
    private let container: Container
    private let isCloseButton: Bool
    private let signupAvailability: SignupAvailability
    private var signupParameters: SignupParameters?
    private var navigationController: LoginNavigationViewController?
    private var signupViewController: SignupViewController?
    private var recoveryViewController: RecoveryViewController?
    private var countryPickerViewController: CountryPickerViewController?
    private var countryPicker = PMCountryPicker(searchBarPlaceholderText: CoreString._hv_sms_search_placeholder)
    private var completeViewModel: CompleteViewModel?
    
    private var signupAccountType: SignupAccountType = .internal
    private var name: String?
    private var deviceToken: String?
    private var password: String?
    private var verifyToken: String?
    private var loginData: LoginData?
    private var performBeforeFlow: WorkBeforeFlow?
    
    // Payments
    private var paymentsManager: PaymentsManager?

    init(container: Container,
         isCloseButton: Bool,
         paymentsAvailability: PaymentsAvailability,
         signupAvailability: SignupAvailability,
         performBeforeFlow: WorkBeforeFlow?) {
        self.container = container
        self.isCloseButton = isCloseButton
        self.signupAvailability = signupAvailability
        self.performBeforeFlow = performBeforeFlow
        if case .available(let paymentParameters) = paymentsAvailability {
            self.paymentsManager = container.makePaymentsCoordinator(
                for: paymentParameters.listOfIAPIdentifiers, reportBugAlertHandler: paymentParameters.reportBugAlertHandler
            )
        }
    }
    
    func start(kind: FlowStartKind) {
        switch signupAvailability {
        case .notAvailable:
            assertionFailure("Signup flow should never be presented when it's not available")
            navigationController?.dismiss(animated: true)
            delegate?.userDidDismissSignupCoordinator(signupCoordinator: self)
        case .available(let parameters):
            signupParameters = parameters
            switch parameters.mode {
            case .internal, .both(.internal):
                signupAccountType = .internal
            case .external, .both(.external):
                signupAccountType = .external
            }
            showSignupViewController(kind: kind)
        }
    }
    
    // MARK: - View controller internal account presentation methods
    
    private func showSignupViewController(kind: FlowStartKind) {
        guard let signupParameters = signupParameters else { return }
        let signupViewController = UIStoryboard.instantiate(SignupViewController.self)
        signupViewController.viewModel = container.makeSignupViewModel()
        signupViewController.delegate = self
        self.signupViewController = signupViewController
        if case .internal = signupParameters.mode {
            signupViewController.showOtherAccountButton = false
        } else if case .external = signupParameters.mode {
            signupViewController.showOtherAccountButton = false
        } else if case .both = signupParameters.mode {
            signupViewController.showOtherAccountButton = true
        }
        signupViewController.showCloseButton = isCloseButton
        signupViewController.signupAccountType = signupAccountType

        switch kind {
        case .unmanaged:
            assertionFailure("we do not support the unmanaged signup showing")
        case let .over(viewController, modalTransitionStyle):
            let navigationController = LoginNavigationViewController(rootViewController: signupViewController)
            self.navigationController = navigationController
            container.setupHumanVerification(viewController: navigationController)
            navigationController.modalTransitionStyle = modalTransitionStyle
            viewController.present(navigationController, animated: true, completion: nil)
        case .inside(let navigationViewController):
            self.navigationController = navigationViewController
            container.setupHumanVerification(viewController: navigationViewController)
            navigationViewController.setViewControllers([signupViewController], animated: true)
        }
    }
    
    private func showPasswordViewController() {
        guard let signupParameters = signupParameters else { return }
        let passwordViewController = UIStoryboard.instantiate(PasswordViewController.self)
        passwordViewController.viewModel = container.makePasswordViewModel()
        passwordViewController.delegate = self
        passwordViewController.signupAccountType = signupAccountType
        passwordViewController.signupPasswordRestrictions = signupParameters.passwordRestrictions
        
        navigationController?.pushViewController(passwordViewController, animated: true)
    }
    
    private func showRecoveryViewController() {
        let recoveryViewController = UIStoryboard.instantiate(RecoveryViewController.self)
        recoveryViewController.viewModel = container.makeRecoveryViewModel(initialCountryCode: countryPicker.getInitialCode())
        recoveryViewController.delegate = self
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
        guard let deviceToken = self.deviceToken else {
            assertionFailure("deviceToken missing")
            return
        }
        var initDisplaySteps: [DisplayProgressStep] = [.create, .login]
        if !(paymentsManager?.selectedPlan?.isFreePlan ?? true) {
            initDisplaySteps += [.payment]
        }
        if let performBeforeFlow = performBeforeFlow {
            initDisplaySteps += [.custom(performBeforeFlow.waitingStepName, performBeforeFlow.doneStepName)]
        }
        
        let completeViewController = UIStoryboard.instantiate(CompleteViewController.self)
        completeViewModel = container.makeCompleteViewModel(deviceToken: deviceToken, initDisplaySteps: initDisplaySteps)
        completeViewController.viewModel = completeViewModel
        completeViewController.delegate = self
        completeViewController.signupAccountType = signupAccountType
        completeViewController.name = self.name
        completeViewController.password = self.password
        completeViewController.email = email
        completeViewController.phoneNumber = phoneNumber
        completeViewController.verifyToken = verifyToken
        navigationController?.setUpShadowLessNavigationBar()
        navigationController?.pushViewController(completeViewController, animated: true)
    }
    
    private func showCountryPickerViewController() {
        let countryPickerViewController = countryPicker.getCountryPickerViewController()
        countryPickerViewController.delegate = self
        countryPickerViewController.modalTransitionStyle = .coverVertical
        self.countryPickerViewController = countryPickerViewController
        
        navigationController?.present(countryPickerViewController, animated: true)
    }
    
    private func showTermsAndConditionsViewController() {
        let tcViewController = UIStoryboard.instantiate(TCViewController.self)
        tcViewController.viewModel = container.makeTCViewModel()
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
        let emailVerificationViewController = UIStoryboard.instantiate(EmailVerificationViewController.self)
        let emailVerificationViewModel = container.makeEmailVerificationViewModel()
        emailVerificationViewModel.email = email
        emailVerificationViewController.viewModel = emailVerificationViewModel
        emailVerificationViewController.delegate = self
        
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
        if let paymentsManager = paymentsManager {
            if !(paymentsManager.selectedPlan?.isFreePlan ?? true) {
                completeViewModel?.processStepWaiting(step: .payment)
            }
            paymentsManager.finishPaymentProcess(loginData: loginData) { [weak self] result in
                DispatchQueue.main.async { [weak self] in
                    switch result {
                    case .success:
                        if !(paymentsManager.selectedPlan?.isFreePlan ?? true) {
                            self?.completeViewModel?.processStepDone(step: .payment)
                        }
                        self?.finishAccountCreation(loginData: loginData)
                    case .failure(let error):
                        self?.errorHandler(error: error)
                    }
                }
            }
        } else {
            finishAccountCreation(loginData: loginData)
        }
    }
    
    private func finishAccountCreation(loginData: LoginData) {
        guard let performBeforeFlow = performBeforeFlow else {
            summarySignupFlow(data: loginData)
            return
        }
        DispatchQueue.main.async { [weak self] in
            self?.completeViewModel?.processStepWaiting(step: .custom(performBeforeFlow.waitingStepName, performBeforeFlow.doneStepName))
            performBeforeFlow.completion(loginData) { [weak self] result in
                DispatchQueue.main.async { [weak self] in
                    switch result {
                    case .success:
                        self?.completeViewModel?.processStepDone(step: .custom(performBeforeFlow.waitingStepName, performBeforeFlow.doneStepName))
                        self?.summarySignupFlow(data: loginData)
                    case .failure(let error):
                        self?.signinButtonPressed()
                        self?.errorHandler(error: error)
                    }
                }
            }
        }
    }

    private func summarySignupFlow(data: LoginData) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.showSummaryViewController(data: data)
        }
    }
    
    private func showSummaryViewController(data: LoginData) {
        guard let signupParameters = signupParameters else { return }
        self.loginData = data
        let summaryViewController = UIStoryboard.instantiate(SummaryViewController.self)
        
        let planName: String?
        if let paymentsManager = paymentsManager, !(paymentsManager.selectedPlan?.isFreePlan ?? true) {
            planName = paymentsManager.planTitle
        } else {
            planName = nil
        }
        summaryViewController.viewModel = container.makeSummaryViewModel(planName: planName, screenVariant: signupParameters.summaryScreenVariant)
        summaryViewController.delegate = self

        let navigationVC = LoginNavigationViewController(rootViewController: summaryViewController)
        navigationVC.modalPresentationStyle = .fullScreen
        navigationController?.present(navigationVC, animated: true)
    }
    
    private func completeSignupFlow(data: LoginData) {
        navigationController?.presentingViewController?.dismiss(animated: true)
        delegate?.signupCoordinatorDidFinish(signupCoordinator: self, loginData: data)
    }
}

// MARK: SignupViewControllerDelegate

extension SignupCoordinator: SignupViewControllerDelegate {
    func validatedName(name: String, signupAccountType: SignupAccountType, deviceToken: String) {
        self.name = name
        self.deviceToken = deviceToken
        self.signupAccountType = signupAccountType
        if signupAccountType == .internal {
            updateAccountType(accountType: .internal)
            showPasswordViewController()
        } else {
            updateAccountType(accountType: .external)
            showEmailVerificationViewController()
        }
    }
    
    func signupCloseButtonPressed() {
        navigationController?.dismiss(animated: true)
        delegate?.userDidDismissSignupCoordinator(signupCoordinator: self)
    }
    
    func signinButtonPressed() {
        guard let navigationController = navigationController else { return }
        delegate?.userSelectedSignin(email: nil, navigationViewController: navigationController)
    }
    
    private func updateAccountType(accountType: AccountType) {
        // changing accountType to intenal, or external is causing key generation on login part. To avoid that we need to skip this when accountType is username
        if container.login.minimumAccountType == .username { return }
        container.login.updateAccountType(accountType: accountType)
    }
}

// MARK: PasswordViewControllerDelegate

extension SignupCoordinator: PasswordViewControllerDelegate {
    func validatedPassword(password: String, completionHandler: (() -> Void)?) {
        self.password = password
        if signupAccountType == .internal {
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
    func didCountryPickerClose() {
        countryPickerViewController?.dismiss(animated: true)
    }
    
    func didSelectCountryCode(countryCode: CountryCode) {
        countryPickerViewController?.dismiss(animated: true)
        recoveryViewController?.updateCountryCode(countryCode.phone_code)
    }
}

// MARK: CompleteViewControllerDelegate

extension SignupCoordinator: CompleteViewControllerDelegate {
    func accountCreationFinish(loginData: LoginData) {
        finalizeAccountCreation(loginData: loginData)
    }
    
    func accountCreationError(error: Error) {
        errorHandler(error: error)
    }
    
    private func errorHandler(error: Error) {
        let errorVC = activeViewController ?? navigationController?.viewControllers.last
        if let error = error as? LoginError {
            if let vc = errorVC as? LoginErrorCapable {
                vc.showError(error: error)
            }
        } else if let error = error as? SignupError {
            if let vc = errorVC as? SignUpErrorCapable {
                vc.showError(error: error)
            }
        } else if let error = error as? StoreKitManagerErrors {
            if let vc = errorVC as? PaymentErrorCapable {
                vc.showError(error: error)
            }
        } else if let error = error as? AvailabilityError {
            if let vc = errorVC as? SignUpErrorCapable {
                switch error {
                case .generic(let message), .notAvailable(let message):
                    vc.showError(error: SignupError.generic(message: message))
                }
            }
        } else if let error = error as? ResponseError, let message = error.userFacingMessage ?? error.underlyingError?.localizedDescription {
            if let vc = errorVC as? SignUpErrorCapable {
                vc.showError(error: SignupError.generic(message: message))
            }
        } else {
            if let vc = errorVC as? SignUpErrorCapable {
                vc.showError(error: SignupError.generic(message: error.messageForTheUser))
            } else if let vc = errorVC as? LoginErrorCapable {
                vc.showError(error: LoginError.generic(message: error.messageForTheUser))
            }
        }
        
        if activeViewController != nil {
            navigationController?.popViewController(animated: true)
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
        guard let loginData = loginData else { return }
        completeSignupFlow(data: loginData)
    }
}

private extension UIStoryboard {
    static func instantiate<T: UIViewController>(_ controllerType: T.Type) -> T {
        self.instantiate(storyboardName: "PMSignup", controllerType: controllerType)
    }
}

#endif
