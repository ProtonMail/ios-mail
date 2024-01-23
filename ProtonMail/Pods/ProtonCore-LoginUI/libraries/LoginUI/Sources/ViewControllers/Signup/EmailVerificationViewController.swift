//
//  EmailVerificationViewController.swift
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
import ProtonCoreFoundations
import ProtonCoreUIFoundations
import ProtonCoreObservability

protocol EmailVerificationViewControllerDelegate: AnyObject {
    func validatedToken(verifyToken: String)
    func emailAlreadyExists(email: String)
    func emailVerificationBackButtonPressed()
}

class EmailVerificationViewController: UIViewController, AccessibleView, Focusable {

    weak var delegate: EmailVerificationViewControllerDelegate?
    var viewModel: EmailVerificationViewModel!
    var customErrorPresenter: LoginErrorPresenter?
    var onDohTroubleshooting: () -> Void = { }

    override var preferredStatusBarStyle: UIStatusBarStyle { darkModeAwarePreferredStatusBarStyle() }

    // MARK: Outlets

    @IBOutlet weak var emailVerificationTitleLabel: UILabel! {
    didSet {
        emailVerificationTitleLabel.text = LUITranslation.email_verification_view_title.l10n
        emailVerificationTitleLabel.textColor = ColorProvider.TextNorm
        }
    }
    @IBOutlet weak var emailVerificationDescriptionLabel: UILabel! {
    didSet {
        emailVerificationDescriptionLabel.text = String(format: LUITranslation.email_verification_view_desc.l10n, viewModel.email ?? "")
        emailVerificationDescriptionLabel.textColor = ColorProvider.TextWeak
        }
    }
    @IBOutlet weak var verificationCodeTextField: PMTextField! {
        didSet {
            verificationCodeTextField.title = LUITranslation.email_verification_code_name.l10n
            verificationCodeTextField.assistiveText = LUITranslation.email_verification_code_desc.l10n
            verificationCodeTextField.placeholder = "XXXXXX"
            verificationCodeTextField.delegate = self
            verificationCodeTextField.keyboardType = .numberPad
            verificationCodeTextField.autocorrectionType = .no
            verificationCodeTextField.autocapitalizationType = .none
            verificationCodeTextField.spellCheckingType = .no
            verificationCodeTextField.textContentType = .oneTimeCode
        }
    }
    @IBOutlet weak var nextButton: ProtonButton! {
        didSet {
            nextButton.setTitle(LUITranslation.next_button.l10n, for: .normal)
            nextButton.isEnabled = false
        }
    }
    @IBOutlet weak var notReceivedCodeButton: ProtonButton! {
        didSet {
            notReceivedCodeButton.setMode(mode: .text)
            notReceivedCodeButton.setTitle(LUITranslation.did_not_receive_code_button.l10n, for: .normal)
        }
    }
    @IBOutlet weak var scrollView: UIScrollView!

    var focusNoMore: Bool = false
    private let navigationBarAdjuster = NavigationBarAdjustingScrollViewDelegate()

    // MARK: View controller life cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = ColorProvider.BackgroundNorm
        setUpBackArrow(action: #selector(EmailVerificationViewController.onBackButtonTap(_:)))
        setupGestures()
        setupNotifications()
        generateAccessibilityIdentifiers()
        ObservabilityEnv.report(.screenLoadCountTotal(screenName: .emailVerification))
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        focusOnce(view: verificationCodeTextField)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        navigationBarAdjuster.setUp(for: scrollView, parent: parent)
        scrollView.adjust(forKeyboardVisibilityNotification: nil)
    }

    // MARK: Actions

    @IBAction func onNextButtonTap(_ sender: ProtonButton) {
        PMBanner.dismissAll(on: self)
        sendCode()
    }

    @IBAction func onNotReceivedCodeButtonTap(_ sender: ProtonButton) {
        PMBanner.dismissAll(on: self)
        requestCodeDialog()
    }

    @objc func onBackButtonTap(_ sender: UIButton) {
        delegate?.emailVerificationBackButtonPressed()
    }

    // MARK: Private methods

    private func setupGestures() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard (_:)))
        self.view.addGestureRecognizer(tapGesture)
    }

    @objc func dismissKeyboard(_ sender: UITapGestureRecognizer) {
        dismissKeyboard()
    }

    private func dismissKeyboard() {
        if verificationCodeTextField.isFirstResponder {
            _ = verificationCodeTextField.resignFirstResponder()
        }
    }

    private func validateNextButton() {
        let verifyCode = verificationCodeTextField.value
        nextButton.isEnabled = isValidCode(code: verifyCode)
    }

    private func isValidCode(code: String) -> Bool {
        return viewModel.isValidCodeFormat(code: code)
    }

    private func sendCode() {
        _ = verificationCodeTextField.resignFirstResponder()
        let verifyCode = verificationCodeTextField.value
        guard let email = viewModel.email, isValidCode(code: verifyCode) else { return }
        nextButton.isSelected = true
        lockUI()
        viewModel?.checkValidationToken(email: email, token: verifyCode, completion: { result in
            self.unlockUI()
            self.nextButton.isSelected = false
            switch result {
            case .success:
                self.delegate?.validatedToken(verifyToken: verifyCode)
            case .failure(let error):
                if self.customErrorPresenter?.willPresentError(error: error, from: self) == true { } else { self.showError(error: error) }
            }
        })
    }

    private func requestCodeDialog() {
        guard let email = viewModel.email else { return }
        let alert = UIAlertController(title: LUITranslation.verification_new_alert_title.l10n, message: String(format: LUITranslation.verification_new_alert_message.l10n, email), preferredStyle: .alert)
        let newCodeAction = UIAlertAction(title: LUITranslation.verification_new_alert_button.l10n, style: .default, handler: { _ in
            self.requestCode()
        })
        newCodeAction.accessibilityLabel = "newCodeButton"
        alert.addAction(newCodeAction)
        let cancelAction = UIAlertAction(title: LUITranslation._core_cancel_button.l10n, style: .default)
        cancelAction.accessibilityLabel = "cancelButton"
        alert.addAction(cancelAction)
        present(alert, animated: true, completion: nil)
    }

    private func requestCode() {
        notReceivedCodeButton.isEnabled = false
        nextButton.isEnabled = false
        viewModel?.requestValidationToken(completion: { result in
            self.notReceivedCodeButton.isEnabled = true
            switch result {
            case .success:
                guard let message = self.viewModel?.getResendMessage() else { return }
                let banner = PMBanner(message: message, style: PMBannerNewStyle.success)
                banner.show(at: .topCustom(.baner), on: self)
            case .failure(let error):
                if self.customErrorPresenter?.willPresentError(error: error, from: self) == true { } else { self.showError(error: error) }
            }
        })
    }

    // MARK: - Keyboard

    private func setupNotifications() {
        NotificationCenter.default
            .setupKeyboardNotifications(target: self, show: #selector(keyboardWillShow), hide: #selector(keyboardWillHide))
    }

    @objc private func keyboardWillShow(notification: NSNotification) {
        adjust(scrollView, notification: notification, topView: verificationCodeTextField, bottomView: notReceivedCodeButton)
    }

    @objc private func keyboardWillHide(notification: NSNotification) {
        adjust(scrollView, notification: notification, topView: emailVerificationTitleLabel, bottomView: notReceivedCodeButton)
    }
}

extension EmailVerificationViewController: PMTextFieldDelegate {
    func didChangeValue(_ textField: PMTextField, value: String) {
        validateNextButton()
    }

    func textFieldShouldReturn(_ textField: PMTextField) -> Bool {
        validateNextButton()
        dismissKeyboard()
        sendCode()
        return true
    }

    func didEndEditing(textField: PMTextField) {
        validateNextButton()
    }

    func didBeginEditing(textField: PMTextField) {

    }
}

// MARK: - Additional errors handling

extension EmailVerificationViewController: SignUpErrorCapable {

    var bannerPosition: PMBannerPosition { .top }

    func emailAddressAlreadyUsed() {
        guard let email = viewModel.email else { return }
        delegate?.emailAlreadyExists(email: email)
    }

    func invalidVerificationCode(reason: InvalidVerificationReson) {
        switch reason {
        case .enter:
            verificationCodeTextField.isError = true
        case .resend:
            verificationCodeTextField.value = ""
            requestCode()
        case .changeEmail:
            verificationCodeTextField.isError = false
            verificationCodeTextField.value = ""
            delegate?.emailVerificationBackButtonPressed()
        }
    }
}

#endif
