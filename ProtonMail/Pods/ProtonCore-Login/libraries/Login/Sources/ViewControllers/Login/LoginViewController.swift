//
//  LoginViewController.swift
//  PMLogin - Created on 03/11/2020.
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

import UIKit
import ProtonCore_CoreTranslation
import ProtonCore_Foundations
import ProtonCore_UIFoundations

protocol LoginStepsDelegate: AnyObject {
    func twoFactorCodeNeeded()
    func mailboxPasswordNeeded()
    func createAddressNeeded(data: CreateAddressData)
    func userAccountSetupNeeded()
    func firstPasswordChangeNeeded()
}

protocol LoginViewControllerDelegate: LoginStepsDelegate {
    func userDidDismissLoginViewController()
    func userDidRequestSignup()
    func userDidRequestHelp()
    func loginViewControllerDidFinish(data: LoginData)
}

final class LoginViewController: UIViewController, AccessibleView, Focusable {

    // MARK: - Outlets

    @IBOutlet private weak var scrollView: UIScrollView!
    @IBOutlet private weak var loginTextField: PMTextField!
    @IBOutlet private weak var passwordTextField: PMTextField!
    @IBOutlet private weak var signInButton: ProtonButton!
    @IBOutlet private weak var signUpButton: ProtonButton!
    @IBOutlet private weak var helpButton: ProtonButton!
    @IBOutlet private weak var subtitleLabel: UILabel!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var topConstraint: NSLayoutConstraint!
    @IBOutlet weak var separatorView: UIView!

    // MARK: - Properties

    weak var delegate: LoginViewControllerDelegate?
    var initialError: LoginError?
    var showCloseButton = true
    var isSignupAvailable = true

    var viewModel: LoginViewModel!
    var initialUsername: String?

    var focusNoMore: Bool = false
    private let navigationBarAdjuster = NavigationBarAdjustingScrollViewDelegate()

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        setupBinding()
        setupDelegates()
        setupNotifications()
        setupGestures()
        requestDomain()
        if let error = initialError {
            showError(error: error)
        }

        focusOnce(view: loginTextField, delay: .milliseconds(500))

        setUpCloseButton(showCloseButton: showCloseButton, action: #selector(LoginViewController.closePressed(_:)))

        generateAccessibilityIdentifiers()
    }

    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        navigationBarAdjuster.setUp(for: scrollView, shouldAdjustNavigationBar: showCloseButton, parent: parent)
    }

    // MARK: - Setup

    private func setupUI() {
        titleLabel.text = CoreString._ls_screen_title
        subtitleLabel.text = CoreString._ls_screen_subtitle
        signUpButton.isHidden = !isSignupAvailable
        signUpButton.setTitle(CoreString._ls_create_account_button, for: .normal)
        helpButton.setTitle(CoreString._ls_help_button, for: .normal)
        signInButton.setTitle(CoreString._ls_sign_in_button, for: .normal)
        loginTextField.title = CoreString._ls_username_title
        passwordTextField.title = CoreString._ls_password_title

        view.backgroundColor = UIColorManager.BackgroundNorm
        separatorView.backgroundColor = UIColorManager.InteractionWeak
        signUpButton.setMode(mode: .text)
        helpButton.setMode(mode: .text)

        loginTextField.autocorrectionType = .no
        loginTextField.autocapitalizationType = .none
        loginTextField.textContentType = .username
        loginTextField.keyboardType = .emailAddress

        passwordTextField.autocorrectionType = .no
        passwordTextField.autocapitalizationType = .none
        passwordTextField.textContentType = .password

        loginTextField.value = initialUsername ?? ""

        topConstraint.constant = -1 * (UIApplication.getInstance()?.statusBarFrame.height ?? .zero)
    }

    private func requestDomain() {
        viewModel.updateAvailableDomain()
    }

    private func setupGestures() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard (_:)))
        self.view.addGestureRecognizer(tapGesture)
    }

    private func setupDelegates() {
        loginTextField.delegate = self
        passwordTextField.delegate = self
    }

    private func setupBinding() {
        viewModel.error.bind { [weak self] error in
            guard let self = self else {
                return
            }

            switch error {
            case .invalidCredentials:
                self.setError(textField: self.passwordTextField, error: nil)
                self.setError(textField: self.loginTextField, error: nil)
                self.showError(error: error)
            default:
                self.showError(error: error)
            }
        }
        viewModel.finished.bind { [weak self] result in
            switch result {
            case let .done(data):
                self?.delegate?.loginViewControllerDidFinish(data: data)
            case .twoFactorCodeNeeded:
                self?.delegate?.twoFactorCodeNeeded()
            case .mailboxPasswordNeeded:
                self?.delegate?.mailboxPasswordNeeded()
            case let .createAddressNeeded(data):
                self?.delegate?.createAddressNeeded(data: data)
            }
        }
        viewModel.isLoading.bind { [weak self] isLoading in
            self?.view.isUserInteractionEnabled = !isLoading
            self?.signInButton.isSelected = isLoading
        }
    }

    private func setupNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    // MARK: - Actions

    @IBAction private func signInPressed(_ sender: Any) {
        cancelFocus()
        dismissKeyboard()

        let usernameValid = validateUsername()
        let passwordValid = validatePassword()

        guard usernameValid, passwordValid else {
            return
        }

        clearErrors()
        viewModel.login(username: loginTextField.value, password: passwordTextField.value)
    }

    @IBAction func signUpPressed(_ sender: ProtonButton) {
        cancelFocus()
        delegate?.userDidRequestSignup()
    }

    @IBAction private func needHelpPressed(_ sender: Any) {
        cancelFocus()
        delegate?.userDidRequestHelp()
    }

    @objc private func closePressed(_ sender: Any) {
        cancelFocus()
        delegate?.userDidDismissLoginViewController()
    }

    @objc func dismissKeyboard(_ sender: UITapGestureRecognizer) {
        dismissKeyboard()
    }

    private func dismissKeyboard() {
        if loginTextField.isFirstResponder {
            _ = loginTextField.resignFirstResponder()
        }

        if passwordTextField.isFirstResponder {
            _ = passwordTextField.resignFirstResponder()
        }
    }

    // MARK: - Keyboard

    @objc private func keyboardWillShow(notification: NSNotification) {
        guard navigationController?.topViewController === self else { return }
        scrollView.adjustForKeyboard(notification: notification)

        let bottomOffset = CGPoint(x: 0, y: scrollView.contentSize.height - scrollView.bounds.size.height + scrollView.contentInset.bottom - 36)

        self.scrollView.setContentOffset(bottomOffset, animated: true)
    }

    @objc private func keyboardWillHide(notification: NSNotification) {
        guard navigationController?.topViewController === self else { return }
        scrollView.adjustForKeyboard(notification: notification)
    }

    // MARK: - Validation

    @discardableResult
    private func validateUsername() -> Bool {
        let usernameValid = viewModel.validate(username: loginTextField.value)
        switch usernameValid {
        case let .failure(error):
            setError(textField: loginTextField, error: error)
            return false
        case .success:
            clearError(textField: loginTextField)
            return true
        }
    }

    @discardableResult
    private func validatePassword() -> Bool {
        let passwordValid = viewModel.validate(password: passwordTextField.value)
        switch passwordValid {
        case let .failure(error):
            setError(textField: passwordTextField, error: error)
            return false
        case .success:
            clearError(textField: passwordTextField)
            return true
        }
    }

    // MARK: - Errors

    private func clearErrors() {
        PMBanner.dismissAll(on: self)
        clearError(textField: loginTextField)
        clearError(textField: passwordTextField)
    }
}

// MARK: - Text field delegate

extension LoginViewController: PMTextFieldDelegate {

    func didChangeValue(_ textField: PMTextField, value: String) {}

    func textFieldShouldReturn(_ textField: PMTextField) -> Bool {
        if textField == loginTextField {
            _ = passwordTextField.becomeFirstResponder()
        } else {
            _ = textField.resignFirstResponder()
        }
        return true
    }

    func didBeginEditing(textField: PMTextField) {}

    func didEndEditing(textField: PMTextField) {
        switch textField {
        case loginTextField:
            validateUsername()
        case passwordTextField:
            validatePassword()
        default:
            break
        }
    }
}

// MARK: - Additional errors handling

extension LoginViewController: LoginErrorCapable {
    func onUserAccountSetupNeeded() {
        delegate?.userAccountSetupNeeded()
    }

    func onFirstPasswordChangeNeeded() {
        delegate?.firstPasswordChangeNeeded()
    }

    var bannerPosition: PMBannerPosition { .top }
}
