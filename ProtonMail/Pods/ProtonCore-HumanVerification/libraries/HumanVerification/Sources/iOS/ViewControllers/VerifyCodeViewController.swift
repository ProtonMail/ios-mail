//
//  VerifyCodeViewController.swift
//  ProtonCore-HumanVerification - Created on 2/1/16.
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
import ProtonCore_Networking
import ProtonCore_UIFoundations
import ProtonCore_Utilities

protocol VerifyCodeViewControllerDelegate: AnyObject {
    func didPressAnotherVerifyMethod()
    func didShowVerifyHelpViewController()
}

class VerifyCodeViewController: BaseUIViewController, AccessibleView {

    // MARK: - Outlets

    @IBOutlet weak var topTitleLabel: UILabel!
    @IBOutlet weak var verifyCodeTextFieldView: PMTextField!
    @IBOutlet weak var continueButton: ProtonButton!
    @IBOutlet weak var newCodeButton: ProtonButton!
    @IBOutlet weak var backBarbuttonItem: UIBarButtonItem!
    @IBOutlet weak var scrollBottomPaddingConstraint: NSLayoutConstraint!

    weak var delegate: VerifyCodeViewControllerDelegate?
    var viewModel: VerifyCheckViewModel!
    var verifyViewModel: VerifyViewModel!
    var viewTitle: String?

    // MARK: - View controller life cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        generateAccessibilityIdentifiers()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.default
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        _ = verifyCodeTextFieldView.becomeFirstResponder()
    }

    override var bottomPaddingConstraint: CGFloat {
        didSet {
            scrollBottomPaddingConstraint.constant = bottomPaddingConstraint
        }
    }

    // MARK: - Actions

    @IBAction func verifyCodeAction(_ sender: Any) {
        sendCode()
    }

    @IBAction func requestReplacementAction(_ sender: Any) {
        let alert = UIAlertController(title: CoreString._hv_verification_new_alert_title, message: String(format: CoreString._hv_verification_new_alert_message, viewModel.destination), preferredStyle: .alert)
        alert.addAction(.init(title: CoreString._hv_verification_new_alert_button, style: .default, handler: { _ in
            self.resendCode()
        }))
        alert.addAction(.init(title: CoreString._hv_cancel_button, style: .cancel))
        present(alert, animated: true, completion: nil)
    }

    @IBAction func tapAction(_ sender: UITapGestureRecognizer) {
        updateButtonStatus()
        dismissKeyboard()
    }

    @IBAction func backButtonAction(_ sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
    }

    // MARK: - Private interface

    private func configureUI() {
        backBarbuttonItem.tintColor = ColorProvider.IconNorm
        backBarbuttonItem.image = IconProvider.arrowLeft
        view.backgroundColor = ColorProvider.BackgroundNorm
        title = viewTitle ?? CoreString._hv_title
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: CoreString._hv_help_button, style: .done, target: self, action: #selector(helpButtonTapped))
        navigationItem.rightBarButtonItem?.tintColor = ColorProvider.BrandNorm
        topTitleLabel.text = viewModel.getTitle()
        topTitleLabel.textColor = ColorProvider.TextWeak
        verifyCodeTextFieldView.title = CoreString._hv_verification_code
        verifyCodeTextFieldView.assistiveText = CoreString._hv_verification_code_hint
        verifyCodeTextFieldView.placeholder = "XXXXXX"
        verifyCodeTextFieldView.delegate = self
        verifyCodeTextFieldView.keyboardType = .numberPad
        verifyCodeTextFieldView.autocorrectionType = .no
        verifyCodeTextFieldView.autocapitalizationType = .none
        verifyCodeTextFieldView.spellCheckingType = .no
        if #available(iOS 12.0, *) {
            verifyCodeTextFieldView.textContentType = .oneTimeCode
        } else {
            verifyCodeTextFieldView.textContentType = .none
        }
        continueButton.setTitle(CoreString._hv_verification_verify_button, for: .normal)
        continueButton.setMode(mode: .solid)
        newCodeButton.setTitle(CoreString._hv_verification_not_receive_code_button, for: .normal)
        newCodeButton.setMode(mode: .text)
        updateButtonStatus()
    }

    private func sendCode() {
        let code = verifyCodeTextFieldView.value.trim()
        guard viewModel.isValidCodeFormat(code: code) else { return }

        _ = verifyCodeTextFieldView.resignFirstResponder()
        continueButton.isSelected = true
        verifyCodeTextFieldView.isError = false
        continueButton.setTitle(CoreString._hv_verification_verifying_button, for: .normal)
        viewModel.finalToken(token: code) { (res, error, finish) in
            DispatchQueue.main.async {
                self.verifyCodeTextFieldView.value = ""
                self.continueButton.isEnabled = true
                self.continueButton.isSelected = false
                self.continueButton.setTitle(CoreString._hv_verification_verify_button, for: .normal)
                if res {
                    self.verifyCodeTextFieldView.isError = false
                    self.navigationController?.dismiss(animated: true) {
                        finish?()
                    }
                } else {
                    if let error = error {
                        self.showErrorAlert(error: error)
                    }
                }
            }
        }
    }

    private func showErrorAlert(error: ResponseError) {
        if viewModel.isInvalidVerificationCode(error: error) {
            // Invalid verification code
            showInvalidVerificationCodeAlert()
            verifyCodeTextFieldView.isError = true
        } else if let message = error.userFacingMessage ?? error.underlyingError?.localizedDescription {
            let banner = PMBanner(message: message, style: PMBannerNewStyle.error, dismissDuration: Double.infinity)
            banner.addButton(text: CoreString._hv_ok_button) { _ in
                banner.dismiss()
            }
            banner.show(at: .topCustom(.baner), on: self)
        }
    }

    private func showInvalidVerificationCodeAlert() {
        let title = CoreString._hv_verification_error_alert_title
        let message = CoreString._hv_verification_error_alert_message
        let leftButton = CoreString._hv_verification_error_alert_resend
        let rightButton = CoreString._hv_verification_error_alert_other_method

        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: leftButton, style: .default, handler: { _ in
            self.resendCode()
        }))
        alert.addAction(UIAlertAction(title: rightButton, style: .cancel, handler: { _ in
            self.delegate?.didPressAnotherVerifyMethod()
        }))
        present(alert, animated: true, completion: nil)
    }

    private func resendCode() {
        continueButton.isEnabled = false
        newCodeButton.isEnabled = false
        verifyViewModel.sendVerifyCode(method: viewModel.method, destination: viewModel.destination) { (isOK, error) -> Void in
            self.updateButtonStatus()
            self.newCodeButton.isEnabled = true
            if isOK {
                let banner = PMBanner(message: self.viewModel.getMsg(), style: PMBannerNewStyle.success)
                banner.show(at: .topCustom(.baner), on: self)
            } else {
                if let description = error?.localizedDescription {
                    let banner = PMBanner(message: description, style: PMBannerNewStyle.error, dismissDuration: Double.infinity)
                    banner.addButton(text: CoreString._hv_ok_button) { _ in
                        banner.dismiss()
                    }
                    banner.show(at: .topCustom(.baner), on: self)
                }
            }
        }
    }

    @objc private func helpButtonTapped(sender: UIBarButtonItem) {
        delegate?.didShowVerifyHelpViewController()
    }

    private func dismissKeyboard() {
        _ = verifyCodeTextFieldView.resignFirstResponder()
    }

    private func updateButtonStatus() {
        let verifyCode = verifyCodeTextFieldView.value.trim()
        if viewModel.isValidCodeFormat(code: verifyCode) {
            continueButton.isEnabled = true
        } else {
            continueButton.isEnabled = false
        }
    }
}

// MARK: - PMTextFieldDelegate

extension VerifyCodeViewController: PMTextFieldDelegate {
    func didChangeValue(_ textField: PMTextField, value: String) {
        updateButtonStatus()
    }

    func textFieldShouldReturn(_ textField: PMTextField) -> Bool {
        updateButtonStatus()
        dismissKeyboard()
        sendCode()
        return true
    }

    func didEndEditing(textField: PMTextField) {
        updateButtonStatus()
    }

    func didBeginEditing(textField: PMTextField) {

    }
}
