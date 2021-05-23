//
//  EmailVerifyViewController.swift
//  ProtonMail - Created on 2/1/16.
//
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
import ProtonCore_Foundations
import ProtonCore_Networking

protocol EmailVerifyViewControllerDelegate: AnyObject {
    func didVerifyEmailCode(method: VerifyMethod, destination: String)
}

class EmailVerifyViewController: BaseUIViewController, AccessibleView {

    // MARK: Outlets

    @IBOutlet weak var topTitleLabel: UILabel!
    @IBOutlet weak var emailTextFieldView: PMTextField!
    @IBOutlet weak var sendCodeButton: ProtonButton!
    @IBOutlet weak var scrollBottomPaddingConstraint: NSLayoutConstraint!

    private var isBannerShown = false { didSet { updateButtonStatus() } }

    weak var delegate: EmailVerifyViewControllerDelegate?
    var viewModel: VerifyViewModel!

    // MARK: View controller life cycle

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
        _ = emailTextFieldView.becomeFirstResponder()
    }

    override var bottomPaddingConstraint: CGFloat {
        didSet {
            scrollBottomPaddingConstraint.constant = bottomPaddingConstraint
        }
    }

    // MARK: Actions

    @IBAction func sendCodeAction(_ sender: UIButton) {
        sendEmail()
    }

    @IBAction func tapAction(_ sender: UITapGestureRecognizer) {
        updateButtonStatus()
        dismissKeyboard()
    }

    // MARK: Private interface

    private func configureUI() {
        view.backgroundColor = UIColorManager.BackgroundNorm
        topTitleLabel.text = CoreString._hv_email_enter_label
        topTitleLabel.textColor = UIColorManager.TextWeak
        emailTextFieldView.title = CoreString._hv_email_label
        emailTextFieldView.placeholder = "example@protonmail.com"
        emailTextFieldView.delegate = self
        emailTextFieldView.keyboardType = .emailAddress
        emailTextFieldView.textContentType = .emailAddress
        emailTextFieldView.autocorrectionType = .no
        emailTextFieldView.autocapitalizationType = .none
        emailTextFieldView.spellCheckingType = .no
        sendCodeButton.setMode(mode: .solid)
        sendCodeButton.setTitle(CoreString._hv_email_verification_button, for: .normal)
        updateButtonStatus()
    }

    private func sendEmail() {
        guard let email = validateEmailAddress else { return }
        dismissKeyboard()
        sendCodeButton.isSelected = true
        viewModel.sendVerifyCode(method: .email, destination: email) { (isOK, error) -> Void in
            self.sendCodeButton.isSelected = false
            if isOK {
                self.delegate?.didVerifyEmailCode(method: .email, destination: email)
            } else {
                if let description = error?.localizedDescription {
                    let banner = PMBanner(message: description, style: PMBannerNewStyle.error, dismissDuration: Double.infinity)
                    banner.addButton(text: CoreString._hv_ok_button) { _ in
                        self.isBannerShown = false
                        banner.dismiss()
                    }
                    banner.show(at: .topCustom(.baner), on: self)
                    self.isBannerShown = true
                }
            }
        }
    }

    private func dismissKeyboard() {
        _ = emailTextFieldView.resignFirstResponder()
    }

    private func updateButtonStatus() {
        if validateEmailAddress != nil, !isBannerShown {
            sendCodeButton.isEnabled = true
        } else {
            sendCodeButton.isEnabled = false
        }
    }

    private var validateEmailAddress: String? {
        let emailaddress = emailTextFieldView.value
        guard viewModel.isValidEmail(email: emailaddress) else { return nil }
        return emailaddress
    }
}

// MARK: - PMTextFieldDelegate

extension EmailVerifyViewController: PMTextFieldDelegate {
    func didChangeValue(_ textField: PMTextField, value: String) {
        updateButtonStatus()
    }

    func textFieldShouldReturn(_ textField: PMTextField) -> Bool {
        updateButtonStatus()
        dismissKeyboard()
        sendEmail()
        return true
    }

    func didEndEditing(textField: PMTextField) {
        updateButtonStatus()
    }

    func didBeginEditing(textField: PMTextField) {

    }
}

#endif
