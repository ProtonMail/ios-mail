//
//  PasswordViewController.swift
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

import UIKit
import ProtonCore_CoreTranslation
import ProtonCore_Foundations
import ProtonCore_UIFoundations

protocol PasswordViewControllerDelegate: AnyObject {
    func passwordIsShown()
    func validatedPassword(password: String, completionHandler: (() -> Void)?)
    func passwordBackButtonPressed()
}

class PasswordViewController: UIViewController, AccessibleView, Focusable {

    weak var delegate: PasswordViewControllerDelegate?
    var viewModel: PasswordViewModel!
    var customErrorPresenter: LoginErrorPresenter?
    var signupAccountType: SignupAccountType!
    var signupPasswordRestrictions: SignupPasswordRestrictions!
    
    var onDohTroubleshooting: () -> Void = { }
    
    override var preferredStatusBarStyle: UIStatusBarStyle { darkModeAwarePreferredStatusBarStyle() }

    // MARK: Outlets

    @IBOutlet weak var createPasswordTitleLabel: UILabel! {
        didSet {
            let title = signupAccountType == .internal ? CoreString._su_password_proton_view_title : CoreString._su_password_email_view_title
            createPasswordTitleLabel.text = title
            createPasswordTitleLabel.textColor = ColorProvider.TextNorm
            createPasswordTitleLabel.font = .adjustedFont(forTextStyle: .title2, weight: .bold)
            createPasswordTitleLabel.adjustsFontForContentSizeCategory = true
            createPasswordTitleLabel.adjustsFontSizeToFitWidth = false
        }
    }
    @IBOutlet weak var passwordTextField: PMTextField! {
        didSet {
            passwordTextField.title = CoreString._su_password_field_title
            passwordTextField.assistiveText = CoreString._su_password_field_hint
            passwordTextField.delegate = self
            passwordTextField.textContentType = .password
            passwordTextField.autocorrectionType = .no
            passwordTextField.autocapitalizationType = .none
        }
    }
    @IBOutlet weak var repeatPasswordTextField: PMTextField! {
        didSet {
            repeatPasswordTextField.title = CoreString._su_repeat_password_field_title
            repeatPasswordTextField.delegate = self
            repeatPasswordTextField.textContentType = .password
            repeatPasswordTextField.autocorrectionType = .no
            repeatPasswordTextField.autocapitalizationType = .none
        }
    }
    @IBOutlet weak var nextButton: ProtonButton! {
        didSet {
            nextButton.setTitle(CoreString._su_next_button, for: .normal)
        }
    }
    @IBOutlet weak var scrollView: UIScrollView!

    var focusNoMore: Bool = false
    private let navigationBarAdjuster = NavigationBarAdjustingScrollViewDelegate()

    // MARK: View controller life cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = ColorProvider.BackgroundNorm
        passwordTextField.returnKeyType = .next
        setUpBackArrow(action: #selector(PasswordViewController.onBackButtonTap(_:)))
        setupGestures()
        setupNotifications()
        generateAccessibilityIdentifiers()
        delegate?.passwordIsShown()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        focusOnce(view: passwordTextField)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        navigationBarAdjuster.setUp(for: scrollView, parent: parent)
        DispatchQueue.main.async {
            self.scrollView.adjust(forKeyboardVisibilityNotification: nil)
        }
    }

    // MARK: Actions

    @IBAction func onNextButtonTap(_ sender: ProtonButton) {
        PMBanner.dismissAll(on: self)
        validatePassword()
    }

    @objc func onBackButtonTap(_ sender: UIButton) {
        delegate?.passwordBackButtonPressed()
    }

    // MARK: Private methods

    private func validatePassword() {
        _ = passwordTextField.resignFirstResponder()
        _ = repeatPasswordTextField.resignFirstResponder()
        passwordTextField.isError = false
        repeatPasswordTextField.isError = false
        let result = viewModel.passwordValidationResult(for: signupPasswordRestrictions,
                                                        password: passwordTextField.value,
                                                        repeatParrword: repeatPasswordTextField.value)
        switch result {
        case .failure(let error):
            if self.customErrorPresenter?.willPresentError(error: error, from: self) == true { } else { self.showError(error: error) }
        case .success:
            nextButton.isSelected = true
            lockUI()
            delegate?.validatedPassword(password: passwordTextField.value) {
                self.nextButton.isSelected = false
                self.unlockUI()
            }
        }
    }

    private func setupGestures() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard (_:)))
        self.view.addGestureRecognizer(tapGesture)
    }

    @objc func dismissKeyboard(_ sender: UITapGestureRecognizer) {
        dismissKeyboard()
    }

    private func dismissKeyboard() {
        if passwordTextField.isFirstResponder {
            _ = passwordTextField.resignFirstResponder()
        }

        if repeatPasswordTextField.isFirstResponder {
            _ = repeatPasswordTextField.resignFirstResponder()
        }
    }

    // MARK: - Keyboard

    private func setupNotifications() {
        NotificationCenter.default
            .setupKeyboardNotifications(target: self, show: #selector(keyboardWillShow), hide: #selector(keyboardWillHide))

        NotificationCenter.default
            .addObserver(self,
                         selector: #selector(preferredContentSizeChanged(_:)),
                         name: UIContentSizeCategory.didChangeNotification,
                         object: nil)
    }

    @objc private func keyboardWillShow(notification: NSNotification) {
        adjust(scrollView, notification: notification,
               topView: topView(of: passwordTextField, repeatPasswordTextField),
               bottomView: nextButton)
    }

    @objc private func keyboardWillHide(notification: NSNotification) {
        adjust(scrollView, notification: notification, topView: createPasswordTitleLabel, bottomView: nextButton)
    }

    @objc
    private func preferredContentSizeChanged(_ notification: Notification) {
        createPasswordTitleLabel.font = .adjustedFont(forTextStyle: .title2, weight: .bold)
    }
}

extension PasswordViewController: PMTextFieldDelegate {
    func didChangeValue(_ textField: PMTextField, value: String) {

    }

    func didEndEditing(textField: PMTextField) {

    }

    func textFieldShouldReturn(_ textField: PMTextField) -> Bool {
        if textField == passwordTextField {
            _ = repeatPasswordTextField.becomeFirstResponder()
        } else {
            _ = textField.resignFirstResponder()
        }
        return true
    }

    func didBeginEditing(textField: PMTextField) {
        passwordTextField.isError = false
        repeatPasswordTextField.isError = false
    }
}

extension PasswordViewController: SignUpErrorCapable, LoginErrorCapable {

    var bannerPosition: PMBannerPosition { .top }

    func invalidPassword(reason: SignUpInvalidPasswordReason) {
        switch reason {
        case .notFulfilling(let restrictions):
            if restrictions.failedRestrictions(for: passwordTextField.value).isEmpty == false {
                passwordTextField.isError = true
            }
            if restrictions.failedRestrictions(for: repeatPasswordTextField.value).isEmpty == false {
                repeatPasswordTextField.isError = true
            }
        case .notEqual:
            passwordTextField.isError = true
            repeatPasswordTextField.isError = true
        }
    }
}
