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

#if os(iOS)

import UIKit
import ProtonCoreFoundations
import ProtonCoreUIFoundations
import typealias ProtonCoreLogin.AccountType
import ProtonCoreObservability
import ProtonCoreTelemetry

protocol RecoveryViewControllerDelegate: AnyObject {
    func recoveryBackButtonPressed()
    func recoveryFinish(email: String?, phoneNumber: String?, completionHandler: (() -> Void)?)
    func termsAndConditionsLinkPressed()
    func recoveryCountryPickerPressed()
}

class RecoveryViewController: UIViewController, AccessibleView, Focusable, ProductMetricsMeasurable {
    var productMetrics: ProductMetrics = .init(
        group: TelemetryMeasurementGroup.signUp.rawValue,
        flow: TelemetryFlow.signUpFull.rawValue,
        screen: .recoveryMethod
    )

    enum RecoveryMethod: Int {
        case email = 0
        case phoneNumber
    }

    weak var delegate: RecoveryViewControllerDelegate?
    var viewModel: RecoveryViewModel!
    var minimumAccountType: AccountType?
    private var countryCode: String = ""
    var onDohTroubleshooting: () -> Void = {}

    override var preferredStatusBarStyle: UIStatusBarStyle { darkModeAwarePreferredStatusBarStyle() }

    // MARK: Outlets

    @IBOutlet weak var recoveryMethodTitleLabel: UILabel! {
        didSet {
            recoveryMethodTitleLabel.textColor = ColorProvider.TextNorm
            recoveryMethodTitleLabel.font = .adjustedFont(forTextStyle: .title2, weight: .bold)
            recoveryMethodTitleLabel.adjustsFontForContentSizeCategory = true
            recoveryMethodTitleLabel.adjustsFontSizeToFitWidth = false
        }
    }
    @IBOutlet weak var recoveryMethodDescriptionLabel: UILabel! {
        didSet {
            recoveryMethodDescriptionLabel.textColor = ColorProvider.TextWeak
            recoveryMethodDescriptionLabel.font = .adjustedFont(forTextStyle: .subheadline)
            recoveryMethodDescriptionLabel.adjustsFontForContentSizeCategory = true
            recoveryMethodDescriptionLabel.adjustsFontSizeToFitWidth = false
        }
    }
    @IBOutlet weak var recoveryEmailTextField: PMTextField! {
        didSet {
            recoveryEmailTextField.title = LUITranslation.recovery_email_field_title.l10n
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
            recoveryPhoneTextField.title = LUITranslation.recovery_phone_field_title.l10n
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
            configSegment()
        }
    }
    @IBOutlet weak var nextButton: ProtonButton! {
        didSet {
            nextButton.setTitle(LUITranslation.next_button.l10n, for: .normal)
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
            termsTextView.font = .adjustedFont(forTextStyle: .footnote)
            termsTextView.adjustsFontForContentSizeCategory = true
        }
    }

    @IBOutlet weak var scrollView: UIScrollView!

    var focusNoMore: Bool = false
    private let navigationBarAdjuster = NavigationBarAdjustingScrollViewDelegate()

    // MARK: View controller life cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = ColorProvider.BackgroundNorm

        recoveryMethodDescriptionLabel.text = LUITranslation.recovery_view_desc.l10n
        recoveryMethodTitleLabel.text = LUITranslation.recovery_view_title_optional.l10n
        let skipButton = UIBarButtonItem(title: LUITranslation.skip_button.l10n,
                                         style: .done,
                                         target: self,
                                         action: #selector(RecoveryViewController.onSkipButtonTap(_:)))
        skipButton.tintColor = ColorProvider.BrandNorm
        navigationItem.rightBarButtonItem = skipButton

        setUpBackArrow(action: #selector(RecoveryViewController.onBackButtonTap))
        setupGestures()
        setupNotifications()
        recoveryPhoneTextField.isHidden = true
        generateAccessibilityIdentifiers()
        navigationItem.assignNavItemIndentifiers()
        try? recoveryEmailTextField.setUpChallenge(viewModel.challenge, type: .recoveryMail)
        try? recoveryPhoneTextField.setUpChallenge(viewModel.challenge, type: .recoveryPhone)
        ObservabilityEnv.report(.screenLoadCountTotal(screenName: .setRecoveryMethod))
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        switch methodSegmenedControl.selectedSegmentIndex {
        case RecoveryMethod.email.rawValue: focusOnce(view: recoveryEmailTextField)
        case RecoveryMethod.phoneNumber.rawValue: focusOnce(view: recoveryPhoneTextField)
        default: break
        }
        measureOnViewDisplayed()
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
            measureOnViewClicked(item: "email")
        case RecoveryMethod.phoneNumber.rawValue:
            recoveryEmailTextField.isHidden = true
            recoveryPhoneTextField.isHidden = false
            _ = recoveryPhoneTextField.becomeFirstResponder()
            measureOnViewClicked(item: "phone")
        default:
            break
        }
        validateNextButton()
    }

    @objc func onBackButtonTap(_ sender: UIButton) {
        delegate?.recoveryBackButtonPressed()
        measureOnViewClosed()
    }

    @objc func onSkipButtonTap(_ sender: UIButton) {
        PMBanner.dismissAll(on: self)
        showSkipRecoveryAlert()
        measureOnViewClicked(item: "skip")
    }

    @IBAction func onNextButtonTap(_ sender: ProtonButton) {
        PMBanner.dismissAll(on: self)
        measureOnViewClicked(item: "next")
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
                self?.measureOnViewAction(
                    action: .verify,
                    additionalValues: [.httpCode(error.codeInLogin)],
                    additionalDimensions: [.result("failure")]
                )
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
                self?.measureOnViewAction(
                    action: .verify,
                    additionalValues: [.httpCode(error.codeInLogin)],
                    additionalDimensions: [.result("failure")]
                )
            }
        }
    }

    private func pressNextButton(email: String?, phoneNumber: String?) {
        measureOnViewAction(
            action: .verify,
            additionalDimensions: [.result("success")]
        )
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
        let title = LUITranslation.recovery_skip_title.l10n
        let message = LUITranslation.recovery_skip_desc.l10n
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let skipAction = UIAlertAction(title: LUITranslation.skip_button.l10n, style: .default, handler: { _ in
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
        let recoveryMethodAction = UIAlertAction(title: LUITranslation.recovery_method_button.l10n, style: .default)
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

        NotificationCenter.default
            .addObserver(self,
                         selector: #selector(preferredContentSizeChanged(_:)),
                         name: UIContentSizeCategory.didChangeNotification,
                         object: nil)
    }

    @objc private func keyboardWillShow(notification: NSNotification) {
        adjust(scrollView, notification: notification,
               topView: topView(of: recoveryEmailTextField, recoveryPhoneTextField),
               bottomView: termsTextView)
    }

    @objc private func keyboardWillHide(notification: NSNotification) {
        adjust(scrollView, notification: notification, topView: recoveryMethodTitleLabel, bottomView: termsTextView)
    }

    @objc
    private func preferredContentSizeChanged(_ notification: Notification) {
        recoveryMethodTitleLabel.font = .adjustedFont(forTextStyle: .title2, weight: .bold)
        recoveryMethodDescriptionLabel.font = .adjustedFont(forTextStyle: .subheadline)
        termsTextView.font = .adjustedFont(forTextStyle: .footnote)
        configSegment()
    }

    private func configSegment() {
            methodSegmenedControl.setImage(image: IconProvider.envelope,
                                           withText: LUITranslation.recovery_seg_email.l10n,
                                           forSegmentAt: 0)
            methodSegmenedControl.setImage(image: IconProvider.mobile,
                                           withText: LUITranslation.recovery_seg_phone.l10n,
                                           forSegmentAt: 1)
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
        switch textField {
        case recoveryEmailTextField:
            measureOnViewFocused(item: "email")
        default:
            break
        }
    }
}

extension RecoveryViewController: PMTextFieldComboDelegate {
    func didChangeValue(_ textField: PMTextFieldCombo, value: String) {
        validateNextButton()
    }

    func didBeginEditing(textField: PMTextFieldCombo) {
        switch textField {
        case recoveryPhoneTextField:
            measureOnViewFocused(item: "phone")
        default:
            break
        }
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
        measureOnViewFocused(item: "phone_country")
    }
}

extension RecoveryViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        delegate?.termsAndConditionsLinkPressed()
        measureOnViewClicked(item: "terms")
        return false
    }
}

extension RecoveryViewController: SignUpErrorCapable, LoginErrorCapable {
    var bannerPosition: PMBannerPosition { .top }
}

#endif
