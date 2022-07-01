//
//  RecoveryViewController.swift
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
import typealias ProtonCore_Login.AccountType

protocol RecoveryViewControllerDelegate: AnyObject {
    func recoveryBackButtonPressed()
    func recoveryFinish(email: String?, phoneNumber: String?, completionHandler: (() -> Void)?)
    func termsAndConditionsLinkPressed()
    func recoveryCountryPickerPressed()
}

class RecoveryViewController: UIViewController, AccessibleView, Focusable {

    enum RecoveryMethod: Int {
        case email = 0
        case phoneNumber
    }

    weak var delegate: RecoveryViewControllerDelegate?
    var viewModel: RecoveryViewModel!
    var minimumAccountType: AccountType?
    private var countryCode: String = ""
    
    override var preferredStatusBarStyle: UIStatusBarStyle { darkModeAwarePreferredStatusBarStyle() }

    // MARK: Outlets

    @IBOutlet weak var recoveryMethodTitleLabel: UILabel! {
        didSet {
            recoveryMethodTitleLabel.textColor = ColorProvider.TextNorm
        }
    }
    @IBOutlet weak var recoveryMethodDescriptionLabel: UILabel! {
        didSet {
            recoveryMethodDescriptionLabel.textColor = ColorProvider.TextWeak
        }
    }
    @IBOutlet weak var recoveryEmailTextField: PMTextField! {
        didSet {
            recoveryEmailTextField.title = CoreString._su_recovery_email_field_title
            recoveryEmailTextField.delegate = self
            recoveryEmailTextField.keyboardType = .emailAddress
            recoveryEmailTextField.textContentType = .emailAddress
            recoveryEmailTextField.autocorrectionType = .no
            recoveryEmailTextField.autocapitalizationType = .none
            recoveryEmailTextField.spellCheckingType = .no
        }
    }
    @IBOutlet weak var recoveryPhoneTextField: PMTextFieldCombo! {
        didSet {
            recoveryPhoneTextField.title = CoreString._su_recovery_phone_field_title
            recoveryPhoneTextField.placeholder = "XX XXX XX XX"
            recoveryPhoneTextField.delegate = self
            recoveryPhoneTextField.keyboardType = .phonePad
            recoveryPhoneTextField.textContentType = .telephoneNumber
            recoveryPhoneTextField.autocorrectionType = .no
            recoveryPhoneTextField.autocapitalizationType = .none
            recoveryPhoneTextField.spellCheckingType = .no
            updateCountryCode(viewModel.initialCountryCode)
        }
    }
    @IBOutlet weak var methodStackView: UIStackView!
    @IBOutlet weak var methodSegmenedControl: PMSegmentedControl! {
        didSet {
            if #available(iOS 13.0, *) {
                methodSegmenedControl.setImage(image: IconProvider.envelope,
                                               withText: CoreString._su_recovery_seg_email,
                                               forSegmentAt: 0)
                methodSegmenedControl.setImage(image: IconProvider.mobile,
                                               withText: CoreString._su_recovery_seg_phone,
                                               forSegmentAt: 1)
            } else {
                // don't show icons for the version below iOS 13
                methodSegmenedControl.setTitle(CoreString._su_recovery_seg_email, forSegmentAt: 0)
                methodSegmenedControl.setTitle(CoreString._su_recovery_seg_phone, forSegmentAt: 1)
            }
        }
    }
    @IBOutlet weak var nextButton: ProtonButton! {
        didSet {
            nextButton.setTitle(CoreString._su_next_button, for: .normal)
            nextButton.isEnabled = false
        }
    }
    @IBOutlet weak var termsTextView: UITextView! {
        didSet {
            termsTextView.delegate = self
            termsTextView.attributedText = viewModel?.termsAttributedString(textView: termsTextView)
            let foregroundColor: UIColor = ColorProvider.BrandNorm
            termsTextView.linkTextAttributes = [.foregroundColor: foregroundColor]
            termsTextView.backgroundColor = ColorProvider.BackgroundNorm
            termsTextView.textColor = ColorProvider.TextWeak
        }
    }

    @IBOutlet weak var scrollView: UIScrollView!

    var focusNoMore: Bool = false
    private let navigationBarAdjuster = NavigationBarAdjustingScrollViewDelegate()

    // MARK: View controller life cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = ColorProvider.BackgroundNorm
        if minimumAccountType == .username {
            methodStackView.subviews.forEach { $0.isHidden = true }
            recoveryMethodDescriptionLabel.text = CoreString._su_recovery_email_only_view_desc
            recoveryMethodTitleLabel.text = CoreString._su_recovery_view_title
        } else {
            recoveryMethodDescriptionLabel.text = CoreString._su_recovery_view_desc
            recoveryMethodTitleLabel.text = CoreString._su_recovery_view_title_optional
            let skipButton = UIBarButtonItem(title: CoreString._su_skip_button,
                                             style: .done,
                                             target: self,
                                             action: #selector(RecoveryViewController.onSkipButtonTap(_:)))
            skipButton.tintColor = ColorProvider.BrandNorm
            navigationItem.rightBarButtonItem = skipButton
        }
        setUpBackArrow(action: #selector(RecoveryViewController.onBackButtonTap))
        setupGestures()
        setupNotifications()
        recoveryPhoneTextField.isHidden = true
        generateAccessibilityIdentifiers()
        navigationItem.assignNavItemIndentifiers()
        try? recoveryEmailTextField.setUpChallenge(viewModel.challenge, type: .recoveryMail)
        try? recoveryPhoneTextField.setUpChallenge(viewModel.challenge, type: .recoveryPhone)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        switch methodSegmenedControl.selectedSegmentIndex {
        case RecoveryMethod.email.rawValue: focusOnce(view: recoveryEmailTextField)
        case RecoveryMethod.phoneNumber.rawValue: focusOnce(view: recoveryPhoneTextField)
        default: break
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        navigationBarAdjuster.setUp(for: scrollView, parent: parent)
        scrollView.adjust(forKeyboardVisibilityNotification: nil)
    }
    
    func updateCountryCode(_ responseCode: Int) {
        countryCode = "+\(responseCode)"
        recoveryPhoneTextField.buttonTitleText = countryCode
    }
    
    func countryPickerDissmised() {
        recoveryPhoneTextField.pickerButton(isActive: false)
    }

    // MARK: Actions

    @IBAction func onMethodSegmentedTap(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case RecoveryMethod.email.rawValue:
            recoveryEmailTextField.isHidden = false
            recoveryPhoneTextField.isHidden = true
            _ = recoveryEmailTextField.becomeFirstResponder()
        case RecoveryMethod.phoneNumber.rawValue:
            recoveryEmailTextField.isHidden = true
            recoveryPhoneTextField.isHidden = false
            _ = recoveryPhoneTextField.becomeFirstResponder()
        default:
            break
        }
        validateNextButton()
    }

    @objc func onBackButtonTap(_ sender: UIButton) {
        delegate?.recoveryBackButtonPressed()
    }

    @objc func onSkipButtonTap(_ sender: UIButton) {
        PMBanner.dismissAll(on: self)
        showSkipRecoveryAlert()
    }

    @IBAction func onNextButtonTap(_ sender: ProtonButton) {
        PMBanner.dismissAll(on: self)
        switch methodSegmenedControl.selectedSegmentIndex {
        case RecoveryMethod.email.rawValue:
            nextButton.isSelected = true
            lockUI()
            validateEmailServerSide()
        case RecoveryMethod.phoneNumber.rawValue:
            nextButton.isSelected = true
            lockUI()
            validatePhoneNumberServerSide()
        default: break
        }
    }
    
    private func validateEmailServerSide() {
        let email = recoveryEmailTextField.value
        guard !email.isEmpty else { return }
        viewModel.validateEmailServerSide(email: email) { [weak self] result in
            switch result {
            case .success:
                self?.pressNextButton(email: email, phoneNumber: nil)
            case .failure(let error):
                self?.unlockUI()
                self?.nextButton.isSelected = false
                self?.showError(error: error)
            }
        }
    }
    
    private func validatePhoneNumberServerSide() {
        let phoneNumber = countryCode + recoveryPhoneTextField.value
        guard !phoneNumber.isEmpty else { return }
        viewModel.validatePhoneNumberServerSide(number: phoneNumber) { [weak self] result in
            switch result {
            case .success:
                self?.pressNextButton(email: nil, phoneNumber: phoneNumber)
            case .failure(let error):
                self?.unlockUI()
                self?.nextButton.isSelected = false
                self?.showError(error: error)
            }
        }
    }
    
    private func pressNextButton(email: String?, phoneNumber: String?) {
        self.delegate?.recoveryFinish(email: email, phoneNumber: phoneNumber) {
            self.unlockUI()
            self.nextButton.isSelected = false
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
        if recoveryEmailTextField.isFirstResponder {
            _ = recoveryEmailTextField.resignFirstResponder()
        }

        if recoveryPhoneTextField.isFirstResponder {
            _ = recoveryPhoneTextField.resignFirstResponder()
        }
    }

    private func showSkipRecoveryAlert() {
        let title = CoreString._su_recovery_skip_title
        let message = CoreString._su_recovery_skip_desc
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let skipAction = UIAlertAction(title: CoreString._su_skip_button, style: .default, handler: { _ in
            self.nextButton.isSelected = true
            self.nextButton.isEnabled = true
            self.lockUI()
            self.delegate?.recoveryFinish(email: nil, phoneNumber: nil) {
                self.unlockUI()
                self.nextButton.isSelected = false
                self.validateNextButton()
            }
        })
        skipAction.accessibilityLabel = "DialogSkipButton"
        alertController.addAction(skipAction)
        let recoveryMethodAction = UIAlertAction(title: CoreString._su_recovery_method_button, style: .default)
        recoveryMethodAction.accessibilityLabel = "DialogRecoveryMethodButton"
        alertController.addAction(recoveryMethodAction)
        present(alertController, animated: true, completion: nil)
    }

    private func validateNextButton() {
        switch methodSegmenedControl.selectedSegmentIndex {
        case RecoveryMethod.email.rawValue:
            nextButton.isEnabled = viewModel.isValidEmail(email: recoveryEmailTextField.value)
        case RecoveryMethod.phoneNumber.rawValue:
            nextButton.isEnabled = viewModel.isValidPhoneNumber(number: recoveryPhoneTextField.value)
        default:
            nextButton.isEnabled = false
        }
    }

    // MARK: - Keyboard

    private func setupNotifications() {
        NotificationCenter.default
            .setupKeyboardNotifications(target: self, show: #selector(keyboardWillShow), hide: #selector(keyboardWillHide))
    }

    @objc private func keyboardWillShow(notification: NSNotification) {
        adjust(scrollView, notification: notification,
               topView: topView(of: recoveryEmailTextField, recoveryPhoneTextField),
               bottomView: termsTextView)
    }

    @objc private func keyboardWillHide(notification: NSNotification) {
        adjust(scrollView, notification: notification, topView: recoveryMethodTitleLabel, bottomView: termsTextView)
    }
}

extension RecoveryViewController: PMTextFieldDelegate {
    func didChangeValue(_ textField: PMTextField, value: String) {
        validateNextButton()
    }

    func didEndEditing(textField: PMTextField) {
        validateNextButton()
    }

    func textFieldShouldReturn(_ textField: PMTextField) -> Bool {
        dismissKeyboard()
        return true
    }

    func didBeginEditing(textField: PMTextField) {

    }
}

extension RecoveryViewController: PMTextFieldComboDelegate {
    func didChangeValue(_ textField: PMTextFieldCombo, value: String) {
        validateNextButton()
    }

    func didEndEditing(textField: PMTextFieldCombo) {
        validateNextButton()
    }

    func textFieldShouldReturn(_ textField: PMTextFieldCombo) -> Bool {
        dismissKeyboard()
        return true
    }

    func userDidRequestDataSelection(button: UIButton) {
        delegate?.recoveryCountryPickerPressed()
        recoveryPhoneTextField.pickerButton(isActive: true)
    }
}

extension RecoveryViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        delegate?.termsAndConditionsLinkPressed()
        return false
    }
}

extension RecoveryViewController: SignUpErrorCapable, LoginErrorCapable {
    var bannerPosition: PMBannerPosition { .top }
}
