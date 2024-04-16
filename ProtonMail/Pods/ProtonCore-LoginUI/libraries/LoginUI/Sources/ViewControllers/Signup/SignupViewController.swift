//
//  SignupViewController.swift
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
import ProtonCoreHumanVerification
import ProtonCoreLogin
import ProtonCoreServices
import ProtonCoreUIFoundations
import ProtonCoreObservability
import ProtonCoreTelemetry

enum SignupAccountType: String {
    case `internal`
    case external
}

protocol SignupViewControllerDelegate: AnyObject {
    func validatedName(name: String, signupAccountType: SignupAccountType)
    func validatedEmail(email: String, signupAccountType: SignupAccountType)
    func signupCloseButtonPressed()
    func signinButtonPressed()
    func hvEmailAlreadyExists(email: String)
}

class SignupViewController: UIViewController, AccessibleView, Focusable, ProductMetricsMeasurable {
    var productMetrics: ProductMetrics = .init(
        group: TelemetryMeasurementGroup.signUp.rawValue,
        flow: TelemetryFlow.signUpFull.rawValue,
        screen: .signup
    )

    enum MeasureConstants {
        static let resultFailure = "failure"
        static let resultSuccess = "success"
    }

    weak var delegate: SignupViewControllerDelegate?
    var viewModel: SignupViewModel!
    var customErrorPresenter: LoginErrorPresenter?
    var signupAccountType: SignupAccountType!
    var showOtherAccountButton = true
    var showCloseButton = true
    var showSeparateDomainsButton = true
    var minimumAccountType: AccountType?
    var tapGesture: UITapGestureRecognizer?

    // MARK: Outlets

    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var createAccountTitleLabel: UILabel! {
        didSet {
            createAccountTitleLabel.text = LUITranslation.main_view_title.l10n
            createAccountTitleLabel.textColor = ColorProvider.TextNorm
            createAccountTitleLabel.font = .adjustedFont(forTextStyle: .title2, weight: .bold)
            createAccountTitleLabel.adjustsFontForContentSizeCategory = true
            createAccountTitleLabel.adjustsFontSizeToFitWidth = false
        }
    }
    @IBOutlet weak var createAccountDescriptionLabel: UILabel! {
        didSet {
            createAccountDescriptionLabel.text = LUITranslation.main_view_desc.l10n
            createAccountDescriptionLabel.textColor = ColorProvider.TextWeak
            createAccountDescriptionLabel.font = .adjustedFont(forTextStyle: .subheadline)
            createAccountDescriptionLabel.adjustsFontForContentSizeCategory = true
            createAccountDescriptionLabel.adjustsFontSizeToFitWidth = false
        }
    }
    @IBOutlet weak var internalNameTextField: PMTextField! {
        didSet {
            internalNameTextField.title = LUITranslation.username_field_title.l10n
            internalNameTextField.keyboardType = .default
            internalNameTextField.textContentType = .username
            internalNameTextField.isPassword = false
            internalNameTextField.delegate = self
            internalNameTextField.autocorrectionType = .no
            internalNameTextField.autocapitalizationType = .none
            internalNameTextField.spellCheckingType = .no
        }
    }
    @IBOutlet weak var domainsView: UIView!
    @IBOutlet weak var domainsLabel: UILabel!
    @IBOutlet weak var domainsButton: ProtonButton!
    @IBOutlet weak var usernameAndDomainsView: UIView!
    @IBOutlet weak var domainsBottomSeparatorView: UIView!
    @IBOutlet weak var externalEmailTextField: PMTextField! {
        didSet {
            externalEmailTextField.title = LUITranslation.email_field_title.l10n
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
            nextButton.setTitle(LUITranslation.next_button.l10n, for: .normal)
            nextButton.isEnabled = false
        }
    }
    @IBOutlet weak var signinButton: ProtonButton! {
        didSet {
            signinButton.setMode(mode: .text)
            signinButton.setTitle(LUITranslation.signin_button.l10n, for: .normal)
        }
    }
    @IBOutlet weak var scrollView: UIScrollView!

    @IBOutlet weak var brandLogo: UIImageView!

    var focusNoMore: Bool = false
    private let navigationBarAdjuster = NavigationBarAdjustingScrollViewDelegate()

    var onDohTroubleshooting: () -> Void = {}

    override var preferredStatusBarStyle: UIStatusBarStyle { darkModeAwarePreferredStatusBarStyle() }

    // MARK: View controller life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = ColorProvider.BackgroundNorm

        brandLogo.image = IconProvider.masterBrandGlyph
        brandLogo.isHidden = false
        setupDomainsView()
        setupGestures()
        setupNotifications()
        otherAccountButton.isHidden = !showOtherAccountButton

        focusOnce(view: currentlyUsedTextField, delay: .milliseconds(750))

        setUpCloseButton(showCloseButton: showCloseButton, action: #selector(SignupViewController.onCloseButtonTap(_:)))
        requestDomain()
        configureAccountType(nil)
        generateAccessibilityIdentifiers()

        try? internalNameTextField.setUpChallenge(viewModel.challenge, type: .username)
        try? externalEmailTextField.setUpChallenge(viewModel.challenge, type: .username_email)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        navigationBarAdjuster.setUp(for: scrollView, shouldAdjustNavigationBar: showCloseButton, parent: parent)
        scrollView.adjust(forKeyboardVisibilityNotification: nil)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        measureOnViewDisplayed(additionalDimensions: [.accountType(signupAccountType.rawValue)])
    }

    // MARK: Actions

    @IBAction func onOtherAccountButtonTap(_ sender: ProtonButton) {
        switchSignupAccountFlow(prefilledUsernameOrEmail: nil)
        let switchingAccountType = signupAccountType == .internal ? "switch_external" : "switch_internal"
        measureOnViewClicked(
            item: switchingAccountType,
            additionalDimensions: [.accountType(signupAccountType.rawValue)]
        )
    }

    @IBAction func onNextButtonTap(_ sender: ProtonButton) {
        cancelFocus()
        PMBanner.dismissAll(on: self)
        nextButton.isSelected = true
        currentlyUsedTextField.isError = false
        if signupAccountType == .internal {
            checkUsernameWithinDomain(userName: currentlyUsedTextField.value)
        } else {
            checkEmail(email: currentlyUsedTextField.value)
        }
        measureOnViewClicked(
            item: "next",
            additionalDimensions: [.accountType(signupAccountType.rawValue)]
        )
    }

    @IBAction func onSignInButtonTap(_ sender: ProtonButton) {
        cancelFocus()
        PMBanner.dismissAll(on: self)
        delegate?.signinButtonPressed()
    }

    @IBAction private func onDomainsButtonTapped() {
        dismissKeyboard()
        var sheet: PMActionSheet?
        let currentDomain = viewModel.currentlyChosenSignUpDomain
        let items = viewModel.allSignUpDomains.map { [weak self] domain in
            let isOn = domain == currentDomain
            return PMActionSheetItem(style: .text("@\(domain)"), markType: isOn ? .checkMark : .none) { [weak self] _ in
                sheet?.dismiss(animated: true)
                self?.viewModel.currentlyChosenSignUpDomain = domain
                self?.configureDomainSuffix()
            }
        }
        let header = PMActionSheetHeaderView(
            title: LUITranslation.domains_sheet_title.l10n,
            subtitle: nil,
            leftItem: .right(IconProvider.crossSmall),
            rightItem: nil,
            showDragBar: false,
            hasSeparator: false,
            leftItemHandler: {
                sheet?.dismiss(animated: true)
            },
            rightItemHandler: nil
        )
        let itemGroup = PMActionSheetItemGroup(items: items, style: .singleSelection)
        sheet = PMActionSheet(headerView: header, itemGroups: [itemGroup])
        sheet?.eventsListener = self
        sheet?.presentAt(self, animated: true)
        measureOnViewClicked(
            item: "domain",
            additionalDimensions: [.accountType(signupAccountType.rawValue)]
        )
    }

    @objc func onCloseButtonTap(_ sender: UIButton) {
        cancelFocus()
        delegate?.signupCloseButtonPressed()
        measureOnViewClosed()
    }

    // MARK: Private methods
    private func requestDomain() {
        viewModel.updateAvailableDomain { [weak self] _ in
            self?.configureDomainSuffix()
        }
    }

    private func switchSignupAccountFlow(prefilledUsernameOrEmail: String?) {
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
            configureAccountType(prefilledUsernameOrEmail)
            if isFirstResponder { _ = currentlyUsedTextField.becomeFirstResponder() }
        }
    }

    private func configureAccountType(_ prefilledUsernameOrEmail: String?) {
        switch signupAccountType {
        case .external:
            ObservabilityEnv.report(.screenLoadCountTotal(screenName: .externalAccountAvailable))
            internalNameTextField.value = ""
            externalEmailTextField.value = prefilledUsernameOrEmail ?? ""
            externalEmailTextField.isHidden = false
            usernameAndDomainsView.isHidden = true
            domainsView.isHidden = true
            domainsBottomSeparatorView.isHidden = true
            internalNameTextField.isHidden = true
        case .internal:
            ObservabilityEnv.report(.screenLoadCountTotal(screenName: .protonAccountAvailable))
            internalNameTextField.value = prefilledUsernameOrEmail ?? ""
            externalEmailTextField.value = ""
            externalEmailTextField.isHidden = true
            usernameAndDomainsView.isHidden = false
            domainsView.isHidden = false
            domainsBottomSeparatorView.isHidden = showOtherAccountButton
            internalNameTextField.isHidden = false
        case .none: break
        }
        let title = signupAccountType == .internal ? LUITranslation.email_address_button.l10n
                                                   : LUITranslation.proton_address_button.l10n
        otherAccountButton.setTitle(title, for: .normal)
        configureDomainSuffix()
    }

    private func configureDomainSuffix() {
        guard showSeparateDomainsButton else {
            domainsView.isHidden = true
            domainsBottomSeparatorView.isHidden = true
            internalNameTextField.suffix = "@\(viewModel.currentlyChosenSignUpDomain)"
            return
        }

        domainsView.isHidden = false
        domainsButton.setTitle("@\(viewModel.currentlyChosenSignUpDomain)", for: .normal)
        if viewModel.allSignUpDomains.count > 1 {
            domainsButton.isUserInteractionEnabled = true
            domainsButton.setMode(mode: .image(type: .textWithChevron))
        } else {
            domainsButton.isUserInteractionEnabled = false
            domainsButton.setMode(mode: .image(type: .textWithImage(image: nil)))
        }
    }

    private func setupDomainsView() {
        domainsButton.setMode(mode: .image(type: .textWithImage(image: nil)))
        domainsLabel.textColor = ColorProvider.TextNorm
        domainsLabel.text = LUITranslation.domains_sheet_title.l10n
        domainsLabel.font = .adjustedFont(forTextStyle: .caption1, weight: .semibold)
        domainsLabel.adjustsFontForContentSizeCategory = true
    }

    private func setupGestures() {
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard(_:)))
        tapGesture?.delaysTouchesBegan = false
        tapGesture?.delaysTouchesEnded = false
        guard let tapGesture = tapGesture else { return }
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

    private func checkUsernameWithoutSpecifyingDomain(userName: String) {
        lockUI()
        viewModel.checkUsernameAccount(username: userName) { result in
            self.unlockUI()
            self.nextButton.isSelected = false
            switch result {
            case .success:
                ObservabilityEnv.report(.protonAccountAvailableSignupTotal(status: .successful))
                self.delegate?.validatedName(name: userName, signupAccountType: self.signupAccountType)
                self.measureAPIResult(
                    action: .createUser,
                    additionalDimensions: [
                        .result(MeasureConstants.resultSuccess),
                        .accountType(self.signupAccountType.rawValue)
                    ]
                )
            case .failure(let error):
                self.handleCheckFailure(error: error)
            }
        }
    }

    private func checkUsernameWithinDomain(userName: String) {
        lockUI()
        viewModel.checkInternalAccount(username: userName) { result in
            self.unlockUI()
            self.nextButton.isSelected = false
            switch result {
            case .success:
                ObservabilityEnv.report(.protonAccountAvailableSignupTotal(status: .successful))
                self.delegate?.validatedName(name: userName, signupAccountType: self.signupAccountType)
                self.measureAPIResult(
                    action: .createUser,
                    additionalDimensions: [
                        .result(MeasureConstants.resultSuccess),
                        .accountType(self.signupAccountType.rawValue)
                    ]
                )
            case .failure(let error):
                self.handleCheckFailure(error: error)
            }
        }
    }

    private func checkEmail(email: String) {
        lockUI()
        viewModel.checkExternalEmailAccount(email: email) { result in
            self.unlockUI()
            self.nextButton.isSelected = false
            switch result {
            case .success:
                ObservabilityEnv.report(.externalAccountAvailableSignupTotal(status: .successful))
                self.delegate?.validatedEmail(email: email, signupAccountType: self.signupAccountType)
                self.measureAPIResult(
                    action: .createUser,
                    additionalDimensions: [
                        .result(MeasureConstants.resultSuccess),
                        .accountType(self.signupAccountType.rawValue)
                    ]
                )
            case .failure(let error):
                self.handleCheckFailure(error: error, email: email, isExternalEmail: true)
            }
        } editEmail: {
            self.unlockUI()
            self.nextButton.isSelected = false
            _ = self.currentlyUsedTextField.becomeFirstResponder()
        } protonDomainUsedForExternalAccount: { username in
            self.unlockUI()
            self.nextButton.isSelected = false
            self.switchSignupAccountFlow(prefilledUsernameOrEmail: username)
        }
    }

    private func handleCheckFailure(error: AvailabilityError, email: String = "", isExternalEmail: Bool = false) {
        switch error {
        case .protonDomainUsedForExternalAccount:
            // this error is not user-facing
            measureFailureAPIResult(resultValue: "domain_invalid")
            return
        case .generic(let message, let code, _):
            if code == APIErrorCode.humanVerificationAddressAlreadyTaken {
                if isExternalEmail {
                    ObservabilityEnv.report(.externalAccountAvailableSignupTotal(status: .notAvailable))
                } else {
                    ObservabilityEnv.report(.protonAccountAvailableSignupTotal(status: .notAvailable))
                }
                measureFailureAPIResult(httpCode: code, resultValue: "username_used")
            } else {
                if isExternalEmail {
                    ObservabilityEnv.report(.externalAccountAvailableSignupTotal(status: .failed))
                } else {
                    ObservabilityEnv.report(.protonAccountAvailableSignupTotal(status: .failed))
                }
                measureFailureAPIResult(httpCode: code, resultValue: MeasureConstants.resultFailure)
            }

            if isExternalEmail, code == APIErrorCode.humanVerificationAddressAlreadyTaken {
                self.delegate?.hvEmailAlreadyExists(email: email)
            } else if self.customErrorPresenter?.willPresentError(error: error, from: self) == true { } else {
                self.showError(message: message)
            }
        case .notAvailable(let message):
            if isExternalEmail {
                ObservabilityEnv.report(.externalAccountAvailableSignupTotal(status: .notAvailable))
            } else {
                ObservabilityEnv.report(.protonAccountAvailableSignupTotal(status: .notAvailable))
            }
            self.currentlyUsedTextField.isError = true
            if self.customErrorPresenter?.willPresentError(error: error, from: self) == true { } else {
                self.showError(message: message)
            }
            measureFailureAPIResult(resultValue: "username_invalid")
        case let .apiMightBeBlocked(message, originalError):
            if isExternalEmail {
                ObservabilityEnv.report(.externalAccountAvailableSignupTotal(status: .apiMightBeBlocked))
            } else {
                ObservabilityEnv.report(.protonAccountAvailableSignupTotal(status: .apiMightBeBlocked))
            }
            if self.customErrorPresenter?.willPresentError(error: error, from: self) == true { } else {
                self.showError(message: message,
                               button: LUITranslation._core_api_might_be_blocked_button.l10n) { [weak self] in
                    self?.onDohTroubleshooting()
                }
            }
            measureFailureAPIResult(httpCode: originalError.httpCode, resultValue: MeasureConstants.resultFailure)
        }
    }

    private func measureFailureAPIResult(httpCode: Int? = nil, resultValue: String) {
        var additionalValues: [TelemetryValue] = []
        if let httpCode {
            additionalValues = [.httpCode(httpCode)]
        }
        measureAPIResult(
            action: .createUser,
            additionalValues: additionalValues,
            additionalDimensions: [
                .accountType(signupAccountType.rawValue),
                .result(resultValue)
            ]
        )
    }

    private func showError(message: String, button: String? = nil, action: (() -> Void)? = nil) {
        showBanner(message: message, button: button, action: action, position: PMBannerPosition.top)
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
        adjust(scrollView, notification: notification, topView: currentlyUsedTextField, bottomView: signinButton)
    }

    @objc private func keyboardWillHide(notification: NSNotification) {
        adjust(scrollView, notification: notification, topView: createAccountTitleLabel, bottomView: signinButton)
    }

    @objc
    private func preferredContentSizeChanged(_ notification: Notification) {
        createAccountTitleLabel.font = .adjustedFont(forTextStyle: .title2, weight: .bold)
        createAccountDescriptionLabel.font = .adjustedFont(forTextStyle: .subheadline)
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
        switch textField {
        case internalNameTextField:
            measureOnViewFocused(
                item: "username",
                additionalDimensions: [.accountType(signupAccountType.rawValue)]
            )
        case externalEmailTextField:
            measureOnViewFocused(
                item: "email",
                additionalDimensions: [.accountType(signupAccountType.rawValue)]
            )
        default:
            break
        }
    }
}

// MARK: - Additional errors handling

extension SignupViewController: SignUpErrorCapable {
    var bannerPosition: PMBannerPosition { .top }
}

extension SignupViewController: PMActionSheetEventsListener {
    func willPresent() {
        tapGesture?.cancelsTouchesInView = false
        domainsButton?.isSelected = true
    }

    func willDismiss() {
        tapGesture?.cancelsTouchesInView = true
        domainsButton?.isSelected = false
    }

    func didDismiss() { }
}

#endif
