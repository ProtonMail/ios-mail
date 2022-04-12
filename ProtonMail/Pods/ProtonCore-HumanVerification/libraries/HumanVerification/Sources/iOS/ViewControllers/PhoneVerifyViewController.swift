//
//  PhoneVerifyViewController.swift
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
import ProtonCore_Foundations
import ProtonCore_UIFoundations
import ProtonCore_CoreTranslation
import ProtonCore_Networking

protocol PhoneVerifyViewControllerDelegate: AnyObject {
    func didVerifyPhoneCode(method: VerifyMethod, destination: String)
    func didSelectCountryPicker()
}

class PhoneVerifyViewController: BaseUIViewController, AccessibleView {

    // MARK: Outlets

    @IBOutlet weak var phoneNumberTextFieldView: PMTextFieldCombo!
    @IBOutlet weak var sendCodeButton: ProtonButton!
    @IBOutlet weak var scrollBottomPaddingConstraint: NSLayoutConstraint!
    @IBOutlet weak var topTitleLabel: UILabel!

    private var countryCode: String = ""
    private var isBannerShown = false { didSet { updateButtonStatus() } }

    weak var delegate: PhoneVerifyViewControllerDelegate?
    var viewModel: VerifyViewModel!
    var initialCountryCode: Int = 0

    // MARK: View controller life cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        generateAccessibilityIdentifiers()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        _ = phoneNumberTextFieldView.becomeFirstResponder()
    }

    override var bottomPaddingConstraint: CGFloat {
        didSet {
            scrollBottomPaddingConstraint.constant = bottomPaddingConstraint
        }
    }

    @IBAction func sendCodeAction(_ sender: UIButton) {
        sendCode()
    }

    @IBAction func tapAction(_ sender: UITapGestureRecognizer) {
        updateButtonStatus()
        dismissKeyboard()
    }

    func updateCountryCode(_ responseCode: Int) {
        countryCode = "+\(responseCode)"
        phoneNumberTextFieldView.buttonTitleText = countryCode
    }
    
    func countryPickerDissmised() {
        phoneNumberTextFieldView.pickerButton(isActive: false)
    }

    // MARK: Private interface

    private func dismissKeyboard() {
        _ = phoneNumberTextFieldView.resignFirstResponder()
    }

    private func configureUI() {
        view.backgroundColor = ColorProvider.BackgroundNorm
        topTitleLabel.text = CoreString._hv_sms_enter_label
        topTitleLabel.textColor = ColorProvider.TextWeak
        sendCodeButton.setTitle(CoreString._hv_email_verification_button, for: UIControl.State())
        phoneNumberTextFieldView.title = CoreString._hv_sms_label
        phoneNumberTextFieldView.placeholder = "XX XXX XX XX"
        phoneNumberTextFieldView.delegate = self
        phoneNumberTextFieldView.keyboardType = .phonePad
        phoneNumberTextFieldView.textContentType = .telephoneNumber
        phoneNumberTextFieldView.autocorrectionType = .no
        phoneNumberTextFieldView.autocapitalizationType = .none
        phoneNumberTextFieldView.spellCheckingType = .no
        sendCodeButton.setMode(mode: .solid)
        updateCountryCode(initialCountryCode)
        updateButtonStatus()
    }

    private func updateButtonStatus() {
        let phoneNumber = phoneNumberTextFieldView.value.trim()
        if !phoneNumber.isEmpty, !isBannerShown {
            sendCodeButton.isEnabled = true
        } else {
            sendCodeButton.isEnabled = false
        }
    }

    private func sendCode() {
        dismissKeyboard()
        let buildPhonenumber = "\(countryCode)\(phoneNumberTextFieldView.value)"
        sendCodeButton.isSelected = true
        viewModel.sendVerifyCode(method: VerifyMethod(predefinedMethod: .sms), destination: buildPhonenumber) { (isOK, error) -> Void in
            self.sendCodeButton.isSelected = false
            if isOK {
                self.delegate?.didVerifyPhoneCode(method: VerifyMethod(predefinedMethod: .sms), destination: buildPhonenumber)
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
}

// MARK: - PMTextFieldComboDelegate

extension PhoneVerifyViewController: PMTextFieldComboDelegate {
    func didChangeValue(_ textField: PMTextFieldCombo, value: String) {
        updateButtonStatus()
    }

    func didEndEditing(textField: PMTextFieldCombo) {
        updateButtonStatus()
    }

    func textFieldShouldReturn(_ textField: PMTextFieldCombo) -> Bool {
        updateButtonStatus()
        dismissKeyboard()
        sendCode()
        return true
    }

    func userDidRequestDataSelection(button: UIButton) {
        guard !isBannerShown else { return }
        delegate?.didSelectCountryPicker()
        phoneNumberTextFieldView.pickerButton(isActive: true)
    }
}
