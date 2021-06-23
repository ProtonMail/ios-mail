//
//  SignupCoordinator.swift
//  PMLogin - Created on 11/03/2021.
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

#if canImport(UIKit)
import UIKit
import ProtonCore_CoreTranslation
import ProtonCore_UIFoundations
import ProtonCore_Payments

protocol SignupCoordinatorDelegate: AnyObject {
    func userDidDismissSignupCoordinator(signupCoordinator: SignupCoordinator)
    func signupCoordinatorDidFinish(signupCoordinator: SignupCoordinator, loginData: LoginData)
    func userSelectedSignin(email: String?)
}

class SignupCoordinator {
    
    weak var delegate: SignupCoordinatorDelegate?
    
    private let container: Container
    private let signupMode: SignupMode
    private let signupPasswordRestrictions: SignupPasswordRestrictions
    private let isCloseButton: Bool
    private let isPlanSelectorAvailable: Bool
    private weak var viewController: UIViewController?
    private var navigationController: UINavigationController?
    private var signupViewController: SignupViewController?
    private var recoveryViewController: RecoveryViewController?
    private var tcViewController: TCViewController?
    private var countryPickerViewController: CountryPickerViewController?
    private var countryPicker = PMCountryPicker(searchBarPlaceholderText: CoreString._hv_sms_search_placeholder)
    
    var signupAccountType: SignupAccountType = .internal
    var name: String?
    var deviceToken: String?
    var password: String?
    var verifyToken: String?
    
    // Payments
    private var paymentsCoordinator: PaymentsCoordinator?

    init(container: Container, signupMode: SignupMode, signupPasswordRestrictions: SignupPasswordRestrictions, isCloseButton: Bool, isPlanSelectorAvailable: Bool, receipt: String?) {
        self.container = container
        self.signupMode = signupMode
        self.signupPasswordRestrictions = signupPasswordRestrictions
        self.isCloseButton = isCloseButton
        self.isPlanSelectorAvailable = isPlanSelectorAvailable
        if isPlanSelectorAvailable {
            self.paymentsCoordinator = container.makePaymentsCoordinator(receipt: receipt)
        }
    }
    
    func start(viewController: UIViewController) {
        self.viewController = viewController
        switch signupMode {
        case .notAvailable:
            assertionFailure("Signup flow should never be presented when it's not available")
            signupViewController?.dismiss(animated: true)
            delegate?.userDidDismissSignupCoordinator(signupCoordinator: self)
        case .internal, .both(.internal):
            signupAccountType = .internal
        case .external, .both(.external):
            signupAccountType = .external
        }
        showSignupViewController()
    }
    
    // MARK: - View controller internal account presentation methods
    
    private func showSignupViewController() {
        let signupViewController = UIStoryboard.instantiate(SignupViewController.self)
        signupViewController.viewModel = container.makeSignupViewModel()
        signupViewController.delegate = self
        self.signupViewController = signupViewController
        if case .internal = signupMode {
            signupViewController.showOtherAccountButton = false
        } else if case .external = signupMode {
            signupViewController.showOtherAccountButton = false
        } else if case .both = signupMode {
            signupViewController.showOtherAccountButton = true
        }
        signupViewController.showCloseButton = isCloseButton
        signupViewController.signupAccountType = signupAccountType
        
        let navigationController = UINavigationController(rootViewController: signupViewController)
        navigationController.navigationBar.isHidden = true
        navigationController.modalPresentationStyle = .fullScreen
        self.navigationController = navigationController
        
        container.setupHumanVerification()
        viewController?.present(navigationController, animated: true, completion: nil)
    }
    
    private func showPasswordViewController() {
        let passwordViewController = UIStoryboard.instantiate(PasswordViewController.self)
        passwordViewController.viewModel = container.makePasswordViewModel()
        passwordViewController.delegate = self
        passwordViewController.signupAccountType = signupAccountType
        passwordViewController.signupPasswordRestrictions = signupPasswordRestrictions
        
        signupViewController?.navigationController?.pushViewController(passwordViewController, animated: true)
    }
    
    private func showRecoveryViewController() {
        let recoveryViewController = UIStoryboard.instantiate(RecoveryViewController.self)
        recoveryViewController.viewModel = container.makeRecoveryViewModel(initialCountryCode: countryPicker.getInitialCode())
        recoveryViewController.delegate = self
        self.recoveryViewController = recoveryViewController
        
        signupViewController?.navigationController?.pushViewController(recoveryViewController, animated: true)
    }
    
    private func finishSignupProcess(email: String? = nil, phoneNumber: String? = nil, completionHandler: (() -> Void)?) {
        if isPlanSelectorAvailable {
            paymentsCoordinator?.startPaymentProcess(signupViewController: signupViewController, planShownHandler: completionHandler, completionHandler: { result in
                switch result {
                case .success:
                    self.showCompleteViewController(email: email, phoneNumber: phoneNumber)
                case .failure(let error):
                    self.errorHandler(error: error)
                }
            })
        } else {
            completionHandler?()
            showCompleteViewController(email: email, phoneNumber: phoneNumber)
        }
    }

    private func showCompleteViewController(email: String? = nil, phoneNumber: String? = nil) {
        guard let deviceToken = self.deviceToken else {
            assertionFailure("deviceToken missing")
            return
        }
        
        let completeViewController = UIStoryboard.instantiate(CompleteViewController.self)
        let completeViewModel = container.makeCompleteViewModel(deviceToken: deviceToken)
        completeViewController.viewModel = completeViewModel
        completeViewController.delegate = self
        completeViewController.signupAccountType = signupAccountType
        completeViewController.name = self.name
        completeViewController.password = self.password
        completeViewController.email = email
        completeViewController.phoneNumber = phoneNumber
        completeViewController.verifyToken = verifyToken
        signupViewController?.navigationController?.pushViewController(completeViewController, animated: true)
    }
    
    private func showCountryPickerViewController() {
        let countryPickerViewController = countryPicker.getCountryPickerViewController()
        countryPickerViewController.delegate = self
        self.countryPickerViewController = countryPickerViewController
        
        signupViewController?.navigationController?.present(countryPickerViewController, animated: true)
    }
    
    private func showTermsAndConditionsViewController() {
        let tcViewController = UIStoryboard.instantiate(TCViewController.self)
        tcViewController.viewModel = container.makeTCViewModel()
        tcViewController.delegate = self
        self.tcViewController = tcViewController
        
        signupViewController?.navigationController?.present(tcViewController, animated: true)
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
        
        signupViewController?.navigationController?.pushViewController(emailVerificationViewController, animated: true)
    }

    private var activeViewController: UIViewController? {
        guard let viewControllers = navigationController?.viewControllers else { return nil }
        var completeVCIndex: Int?
        for (index, vc) in viewControllers.enumerated() where vc is CompleteViewController {
                completeVCIndex = index
        }
        guard let completeVCIndex = completeVCIndex, viewControllers.count >= completeVCIndex - 1 else { return nil }
        return  viewControllers[completeVCIndex - 1]
    }
    
    private func finalizeAccountCreation(loginData: LoginData) {
        if isPlanSelectorAvailable {
            paymentsCoordinator?.finishPaymentProcess(loginData: loginData) { result in
                switch result {
                case .success:
                    self.finishAccountCreation(loginData: loginData)
                case .failure(let error):
                    self.errorHandler(error: error)
                }
            }
        } else {
            finishAccountCreation(loginData: loginData)
        }
    }
    
    private func finishAccountCreation(loginData: LoginData) {
        DispatchQueue.main.async {
            self.signupViewController?.dismiss(animated: true)
            self.delegate?.signupCoordinatorDidFinish(signupCoordinator: self, loginData: loginData)
        }
    }
}

// MARK: SignupViewControllerDelegate

extension SignupCoordinator: SignupViewControllerDelegate {
    func validatedName(name: String, signupAccountType: SignupAccountType, deviceToken: String) {
        self.name = name
        self.deviceToken = deviceToken
        self.signupAccountType = signupAccountType
        if signupAccountType == .internal {
            container.login.updateAccountType(accountType: .internal)
            showPasswordViewController()
        } else {
            container.login.updateAccountType(accountType: .external)
            showEmailVerificationViewController()
        }
    }
    
    func signupCloseButtonPressed() {
        signupViewController?.dismiss(animated: true)
        delegate?.userDidDismissSignupCoordinator(signupCoordinator: self)
    }
    
    func signinButtonPressed() {
        signupViewController?.dismiss(animated: true)
        delegate?.userSelectedSignin(email: nil)
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
        signupViewController?.navigationController?.popViewController(animated: true)
    }
}

// MARK: RecoveryViewControllerDelegate

extension SignupCoordinator: RecoveryViewControllerDelegate {

    func recoveryFinish(email: String?, phoneNumber: String?, completionHandler: (() -> Void)?) {
        finishSignupProcess(email: email, phoneNumber: phoneNumber, completionHandler: completionHandler)
    }
    
    func recoveryBackButtonPressed() {
        signupViewController?.navigationController?.popViewController(animated: true)
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
        } else if let error = error as? StoreKitManager.Errors {
            if let vc = errorVC as? PaymentErrorCapable {
                vc.showError(error: error)
            }
        }
        if activeViewController != nil {
            signupViewController?.navigationController?.popViewController(animated: true)
        }
    }
}

// MARK: TCViewControllerDelegate

extension SignupCoordinator: TCViewControllerDelegate {
    func termsAndConditionsClose() {
        tcViewController?.dismiss(animated: true)
    }
}

extension SignupCoordinator: EmailVerificationViewControllerDelegate {
    func validatedToken(verifyToken: String) {
        self.verifyToken = verifyToken
        showPasswordViewController()
    }
    
    func emailVerificationBackButtonPressed() {
        signupViewController?.navigationController?.popViewController(animated: true)
    }
    
    func emailAlreadyExists(email: String) {
        signupViewController?.dismiss(animated: true)
        delegate?.userSelectedSignin(email: email)
    }
}

private extension UIStoryboard {
    static func instantiate<T: UIViewController>(_ controllerType: T.Type) -> T {
        self.instantiate(storyboardName: "PMSignup", controllerType: controllerType)
    }
}

#endif
