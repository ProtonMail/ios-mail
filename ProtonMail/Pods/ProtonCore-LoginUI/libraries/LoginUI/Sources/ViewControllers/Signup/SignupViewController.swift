//
//  SignupViewController.swift
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

import UIKit
import ProtonCore_CoreTranslation
import ProtonCore_Foundations
import ProtonCore_UIFoundations
import ProtonCore_Login
import ProtonCore_HumanVerification
import ProtonCore_Services

protocol SignupViewControllerDelegate: AnyObject {
    func validatedName(name: String, signupAccountType: SignupAccountType)
    func validatedEmail(email: String, signupAccountType: SignupAccountType)
    func signupCloseButtonPressed()
    func signinButtonPressed()
}

enum SignupAccountType {
    case `internal`
    case external
}

class SignupViewController: UIViewController, AccessibleView, Focusable {

    weak var delegate: SignupViewControllerDelegate?
    var viewModel: SignupViewModel!
    var customErrorPresenter: LoginErrorPresenter?
    var signupAccountType: SignupAccountType!
    var showOtherAccountButton = true
    var showCloseButton = true
    var domain: String? { didSet { configureDomainSuffix() } }

    // MARK: Outlets

    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var createAccountTitleLabel: UILabel! {
        didSet {
            createAccountTitleLabel.text = CoreString._su_main_view_title
            createAccountTitleLabel.textColor = ColorProvider.TextNorm
        }
    }
    @IBOutlet weak var createAccountDescriptionLabel: UILabel! {
        didSet {
            createAccountDescriptionLabel.text = CoreString._su_main_view_desc
            createAccountDescriptionLabel.textColor = ColorProvider.TextWeak
        }
    }
    @IBOutlet weak var internalNameTextField: PMTextField! {
        didSet {
            internalNameTextField.title = CoreString._su_username_field_title
            internalNameTextField.keyboardType = .default
            internalNameTextField.textContentType = .username
            internalNameTextField.isPassword = false
            internalNameTextField.delegate = self
            internalNameTextField.autocorrectionType = .no
            internalNameTextField.autocapitalizationType = .none
            internalNameTextField.spellCheckingType = .no
        }
    }
    @IBOutlet weak var externalEmailTextField: PMTextField! {
        didSet {
            externalEmailTextField.title = CoreString._su_email_field_title
            externalEmailTextField.autocorrectionType = .no
            externalEmailTextField.keyboardType = .emailAddress
            externalEmailTextField.textContentType = .emailAddress
            externalEmailTextField.isPassword = false
            externalEmailTextField.delegate = self
            externalEmailTextField.autocapitalizationType = .none
            externalEmailTextField.spellCheckingType = .no
        }
    }
    var currentlyUsedTextField: PMTextField {
        switch signupAccountType {
        case .external:
            return externalEmailTextField
        case .internal:
            return internalNameTextField
        case .none:
            assertionFailure("signupAccountType should be configured during the segue")
            return internalNameTextField
        }
    }
    var currentlyNotUsedTextField: PMTextField {
        switch signupAccountType {
        case .external:
            return internalNameTextField
        case .internal:
            return externalEmailTextField
        case .none:
            assertionFailure("signupAccountType should be configured during the segue")
            return externalEmailTextField
        }
    }

    @IBOutlet weak var otherAccountButton: ProtonButton! {
        didSet {
            otherAccountButton.setMode(mode: .text)
        }
    }
    @IBOutlet weak var nextButton: ProtonButton! {
        didSet {
            nextButton.setTitle(CoreString._su_next_button, for: .normal)
            nextButton.isEnabled = false
        }
    }
    @IBOutlet weak var signinButton: ProtonButton! {
        didSet {
            signinButton.setMode(mode: .text)
            signinButton.setTitle(CoreString._su_signin_button, for: .normal)
        }
    }
    @IBOutlet weak var scrollView: UIScrollView!

    var focusNoMore: Bool = false
    private let navigationBarAdjuster = NavigationBarAdjustingScrollViewDelegate()

    // MARK: View controller life cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = ColorProvider.BackgroundNorm
        setupGestures()
        setupNotifications()
        otherAccountButton.isHidden = !showOtherAccountButton

        focusOnce(view: currentlyUsedTextField, delay: .milliseconds(750))

        setUpCloseButton(showCloseButton: showCloseButton, action: #selector(SignupViewController.onCloseButtonTap(_:)))
        requestDomain()
        configureAccountType()
        generateAccessibilityIdentifiers()
        
        try? internalNameTextField.setUpChallenge(viewModel.challenge, type: .username)
        try? externalEmailTextField.setUpChallenge(viewModel.challenge, type: .username_email)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        navigationBarAdjuster.setUp(for: scrollView, shouldAdjustNavigationBar: showCloseButton, parent: parent)
        scrollView.adjust(forKeyboardVisibilityNotification: nil)
    }

    // MARK: Actions

    @IBAction func onOtherAccountButtonTap(_ sender: ProtonButton) {
        cancelFocus()
        PMBanner.dismissAll(on: self)
        let isFirstResponder = currentlyUsedTextField.isFirstResponder
        if isFirstResponder { _ = currentlyUsedTextField.resignFirstResponder() }
        contentView.fadeOut(withDuration: 0.5) { [self] in
            self.contentView.fadeIn(withDuration: 0.5)
            self.currentlyUsedTextField.isError = false
            if self.signupAccountType == .internal {
                signupAccountType = .external
            } else {
                signupAccountType = .internal
            }
            configureAccountType()
            if isFirstResponder { _ = currentlyUsedTextField.becomeFirstResponder() }
        }
    }

    @IBAction func onNextButtonTap(_ sender: ProtonButton) {
        cancelFocus()
        PMBanner.dismissAll(on: self)
        nextButton.isSelected = true
        currentlyUsedTextField.isError = false
        lockUI()
        if signupAccountType == .internal {
            checkUsername(userName: self.currentlyUsedTextField.value)
        } else {
            if TemporaryHacks.isV3 {
                checkEmail(email: self.currentlyUsedTextField.value)
            } else {
                requestValidationToken(email: self.currentlyUsedTextField.value)
            }
        }
    }

    @IBAction func onSignInButtonTap(_ sender: ProtonButton) {
        cancelFocus()
        PMBanner.dismissAll(on: self)
        delegate?.signinButtonPressed()
    }

    @objc func onCloseButtonTap(_ sender: UIButton) {
        cancelFocus()
        delegate?.signupCloseButtonPressed()
    }

    // MARK: Private methods

    private func requestDomain() {
        viewModel.updateAvailableDomain { _ in
            self.domain = "@\(self.viewModel.signUpDomain)"
        }
    }

    private func configureAccountType() {
        internalNameTextField.value = ""
        externalEmailTextField.value = ""
        currentlyUsedTextField.isHidden = false
        currentlyNotUsedTextField.isHidden = true
        let title = signupAccountType == .internal ? CoreString._su_email_address_button
                                                   : CoreString._su_proton_address_button
        otherAccountButton.setTitle(title, for: .normal)
        configureDomainSuffix()
    }

    private func configureDomainSuffix() {
        internalNameTextField.suffix = domain ?? "@\(viewModel.signUpDomain)"
    }
    
    private func setupGestures() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard (_:)))
        self.view.addGestureRecognizer(tapGesture)
    }

    @objc func dismissKeyboard(_ sender: UITapGestureRecognizer) {
        dismissKeyboard()
    }

    private func dismissKeyboard() {
        if currentlyUsedTextField.isFirstResponder {
            _ = currentlyUsedTextField.resignFirstResponder()
        }
    }

    private func validateNextButton() {
        if signupAccountType == .internal {
            nextButton.isEnabled = viewModel.isUserNameValid(name: currentlyUsedTextField.value)
        } else {
            nextButton.isEnabled = viewModel.isEmailValid(email: currentlyUsedTextField.value)
        }
    }

    private func checkUsername(userName: String) {
        viewModel.checkUserName(username: userName) { result in
            self.nextButton.isSelected = false
            switch result {
            case .success:
                self.delegate?.validatedName(name: userName, signupAccountType: self.signupAccountType)
            case .failure(let error):
                self.unlockUI()
                switch error {
                case .generic(let message, _):
                    if self.customErrorPresenter?.willPresentError(error: error, from: self) == true { } else {
                        self.showError(message: message)
                    }
                case .notAvailable(let message):
                    self.currentlyUsedTextField.isError = true
                    if self.customErrorPresenter?.willPresentError(error: error, from: self) == true { } else {
                        self.showError(message: message)
                    }
                }
            }
        }
    }
    
    private func checkEmail(email: String) {
        viewModel.checkEmail(email: email) { result in
            self.nextButton.isSelected = false
            switch result {
            case .success:
                self.delegate?.validatedEmail(email: email, signupAccountType: self.signupAccountType)
            case .failure(let error):
                self.unlockUI()
                switch error {
                case .generic(let message, _):
                    if self.customErrorPresenter?.willPresentError(error: error, from: self) == true { } else {
                        self.showError(message: message)
                    }
                case .notAvailable(let message):
                    self.currentlyUsedTextField.isError = true
                    if self.customErrorPresenter?.willPresentError(error: error, from: self) == true { } else {
                        self.showError(message: message)
                    }
                }
            }
        } editEmail: {
            self.nextButton.isSelected = false
            self.unlockUI()
            _ = self.currentlyUsedTextField.becomeFirstResponder()
        }
    }

    private func showError(message: String) {
        showBanner(message: message, position: PMBannerPosition.top)
    }

    private func requestValidationToken(email: String) {
        viewModel?.requestValidationToken(email: email, completion: { result in
            self.nextButton.isSelected = false
            switch result {
            case .success:
                self.delegate?.validatedName(name: email, signupAccountType: self.signupAccountType)
            case .failure(let error):
                self.unlockUI()
                if self.customErrorPresenter?.willPresentError(error: error, from: self) == true { } else { self.showError(error: error) }
                self.currentlyUsedTextField.isError = true
            }
        })
    }

    // MARK: - Keyboard

    private func setupNotifications() {
        NotificationCenter.default
            .setupKeyboardNotifications(target: self, show: #selector(keyboardWillShow), hide: #selector(keyboardWillHide))
    }

    @objc private func keyboardWillShow(notification: NSNotification) {
        adjust(scrollView, notification: notification, topView: currentlyUsedTextField, bottomView: signinButton)
    }

    @objc private func keyboardWillHide(notification: NSNotification) {
        adjust(scrollView, notification: notification, topView: createAccountTitleLabel, bottomView: signinButton)
    }
}

extension SignupViewController: PMTextFieldDelegate {
    func didChangeValue(_ textField: PMTextField, value: String) {
        validateNextButton()
    }

    func didEndEditing(textField: PMTextField) {
        validateNextButton()
    }

    func textFieldShouldReturn(_ textField: PMTextField) -> Bool {
        _ = currentlyUsedTextField.resignFirstResponder()
        return true
    }

    func didBeginEditing(textField: PMTextField) {

    }
}

// MARK: - Additional errors handling

extension SignupViewController: SignUpErrorCapable {
    var bannerPosition: PMBannerPosition { .top }
}
