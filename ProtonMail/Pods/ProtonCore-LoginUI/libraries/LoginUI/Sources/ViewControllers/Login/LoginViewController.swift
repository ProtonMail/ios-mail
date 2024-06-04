//
//  LoginViewController.swift
//  ProtonCore-Login - Created on 03/11/2020.
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
import WebKit
import ProtonCoreLogin
import ProtonCoreFoundations
import ProtonCoreUIFoundations
import ProtonCoreFeatureFlags
import ProtonCoreObservability
import ProtonCoreServices
import ProtonCoreTelemetry

protocol LoginStepsDelegate: AnyObject {
    func requestTOTPCode(username: String, password: String)
    @available(iOS 15.0, *)
    func requestKeySignature(challenge: Data, relyingPartyIdentifier: String, allowedCredentialIds: [Data])
    @available(iOS 15.0, *)
    func requestTOTPOrKeySignature(username: String, password: String, challenge: Data, relyingPartyIdentifier: String, allowedCredentialIds: [Data])
    func mailboxPasswordNeeded()
    func createAddressNeeded(data: CreateAddressData, defaultUsername: String?)
    func userAccountSetupNeeded()
    func firstPasswordChangeNeeded()
    func learnMoreAboutExternalAccountsNotSupported()
}

protocol LoginViewControllerDelegate: LoginStepsDelegate {
    func userDidDismissLoginViewController()
    func userDidRequestSignup()
    func userDidRequestHelp()
    func loginViewControllerDidFinish(endLoading: @escaping () -> Void, data: LoginData)
}

final class LoginViewController: UIViewController, AccessibleView, Focusable, ProductMetricsMeasurable {
    var productMetrics: ProductMetrics = .init(
        group: TelemetryMeasurementGroup.signUp.rawValue,
        flow: TelemetryFlow.signUpFull.rawValue,
        screen: .signin
    )

    enum MeasureConstants {
        static let resultFailure = "failure"
        static let resultSuccess = "success"
        static let hostAlternative = "alternative"
        static let hostStandard = "standard"
    }

    // MARK: - Outlets

    @IBOutlet private weak var scrollView: UIScrollView!
    @IBOutlet private weak var loginTextField: PMTextField!
    @IBOutlet private weak var passwordTextField: PMTextField!
    @IBOutlet private weak var signInButton: ProtonButton!
    @IBOutlet private weak var signUpButton: ProtonButton!
    @IBOutlet private weak var subtitleLabel: UILabel!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var brandImage: UIImageView!
    @IBOutlet weak var signInWithSSOButton: ProtonButton!

    // MARK: - Properties

    weak var delegate: LoginViewControllerDelegate?
    var initialError: LoginError?
    var showCloseButton = true
    var isSignupAvailable = true

    var viewModel: LoginViewModel!
    var customErrorPresenter: LoginErrorPresenter?
    var initialUsername: String?
    var onDohTroubleshooting: () -> Void = { }

    var focusNoMore: Bool = false
    private let navigationBarAdjuster = NavigationBarAdjustingScrollViewDelegate()
    private var webView: SSOViewController?
    private var isSSOEnabled: Bool {
        FeatureFlagsRepository.shared.isEnabled(CoreFeatureFlagType.externalSSO, reloadValue: true) &&
            viewModel.clientApp == .vpn
    }

    override var preferredStatusBarStyle: UIStatusBarStyle { darkModeAwarePreferredStatusBarStyle() }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        setupBinding()
        setupDelegates()
        setupNotifications()
        setupGestures()
        setUpHelpButton(action: #selector(needHelpPressed))
        requestDomain()
        if let error = initialError {
            if self.customErrorPresenter?.willPresentError(error: error, from: self) == true { } else { showError(error: error) }
        }

        focusOnce(view: loginTextField, delay: .milliseconds(750))

        setUpCloseButton(showCloseButton: showCloseButton, action: #selector(closePressed))

        generateAccessibilityIdentifiers()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        navigationBarAdjuster.setUp(for: scrollView, shouldAdjustNavigationBar: showCloseButton, parent: parent)
        scrollView.adjust(forKeyboardVisibilityNotification: nil)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        measureOnViewDisplayed()
    }

    // MARK: - Setup

    private func showWebView() -> SSOViewController {
        let ssoVC = SSOViewController()
        ssoVC.webViewDelegate = self
        let webViewNav = DarkModeAwareNavigationViewController(rootViewController: ssoVC)
        webViewNav.overrideUserInterfaceStyle = self.overrideUserInterfaceStyle
        webViewNav.navigationBar.backgroundColor = ColorProvider.BackgroundNorm
        self.navigationController?.present(webViewNav, animated: true)
        return ssoVC
    }

    private func setupUI() {
        brandImage.image = IconProvider.masterBrandGlyph
        brandImage.isHidden = false
        titleLabel.text = viewModel.titleLabel
        titleLabel.textColor = ColorProvider.TextNorm
        subtitleLabel.text = viewModel.subtitleLabel
        subtitleLabel.textColor = ColorProvider.TextWeak
        titleLabel.font = .adjustedFont(forTextStyle: .title2, weight: .bold)
        subtitleLabel.font = .adjustedFont(forTextStyle: .subheadline)
        loginTextField.title = viewModel.loginTextFieldTitle
        passwordTextField.title = viewModel.passwordTextFieldTitle

        view.backgroundColor = ColorProvider.BackgroundNorm

        signInButton.setTitle(viewModel.signInButtonTitle, for: .normal)
        signInButton.addTarget(self, action: #selector(signInPressed), for: .touchUpInside)

        signUpButton.setMode(mode: .text)
        signUpButton.addTarget(self, action: #selector(signUpPressed), for: .touchUpInside)
        signUpButton.isHidden = !isSignupAvailable || isSSOEnabled
        signUpButton.setTitle(viewModel.signUpButtonTitle, for: .normal)

        loginTextField.autocorrectionType = .no
        loginTextField.autocapitalizationType = .none
        loginTextField.textContentType = .username
        loginTextField.keyboardType = .emailAddress
        loginTextField.returnKeyType = .next

        passwordTextField.autocorrectionType = .no
        passwordTextField.autocapitalizationType = .none
        passwordTextField.textContentType = .password

        loginTextField.value = initialUsername ?? ""

        signInWithSSOButton.isHidden = !isSSOEnabled
        signInWithSSOButton.setTitle(viewModel.signInWithSSOButtonTitle, for: .normal)
        signInWithSSOButton.setMode(mode: .text)
        signInWithSSOButton.addTarget(self, action: #selector(signInWithSSO), for: .touchUpInside)
    }

    private func requestDomain() {
        viewModel.updateAvailableDomain()
    }

    private func setupGestures() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard (_:)))
        self.view.addGestureRecognizer(tapGesture)
    }

    func setUpHelpButton(action: Selector) {
        let helpButton = UIBarButtonItem(title: LUITranslation._core_help_button.l10n, style: .plain, target: self, action: action)
        helpButton.tintColor = ColorProvider.InteractionNorm
        navigationItem.setHidesBackButton(true, animated: false)
        navigationItem.setRightBarButton(helpButton, animated: true)
        navigationItem.assignNavItemIndentifiers()
    }

    private func setupDelegates() {
        loginTextField.delegate = self
        passwordTextField.delegate = self
    }

    private func setupBinding() {
        viewModel.error.bind { [weak self] error in
            guard let self else { return }
            switch error {
            case .invalidCredentials:
                self.setError(textField: self.passwordTextField, error: nil)
                self.setError(textField: self.loginTextField, error: nil)
                if self.customErrorPresenter?.willPresentError(error: error, from: self) == true { } else { self.showError(error: error) }
            default:
                if self.customErrorPresenter?.willPresentError(error: error, from: self) == true { } else { self.showError(error: error) }
            }
            self.measureLoginFailure(httpCode: error.codeInLogin)
        }
        viewModel.finished.bind { [weak self] result in
            switch result {
            case let .done(data):
                self?.delegate?.loginViewControllerDidFinish(endLoading: { [weak self] in self?.viewModel.isLoading.value = false }, data: data)
                self?.measureLoginSuccess()
            case .totpCodeNeeded:
                guard
                    let username = self?.loginTextField.value,
                    let password = self?.passwordTextField.value
                else { return }
                // Clean username and password before leaving this page
                // To eliminate KeyChain auto remember prompt
                self?.clearAccount()
                self?.delegate?.requestTOTPCode(username: username, password: password)
                self?.measureLoginSuccess()
            case let .fido2KeyNeeded(context):
                self?.clearAccount()
                guard #available(iOS 15.0, *) else {
                    self?.showBanner(message: "FIDO2 security keys are not supported in iOS versions prior to 15.0", style: .error)
                    self?.measureLoginFailure(httpCode: 426)
                    return
                }
                let challenge = context.authenticationOptions.publicKey.challenge
                let relyingPartyIdentifier = context.authenticationOptions.publicKey.rpId
                let allowedCredentialIds = context.authenticationOptions.publicKey.allowCredentials.map(\.id)

                self?.delegate?.requestKeySignature(challenge: challenge,
                                                    relyingPartyIdentifier: relyingPartyIdentifier,
                                                    allowedCredentialIds: allowedCredentialIds)
            case let .anyOfFido2TotpNeeded(context):
                self?.clearAccount()
                guard #available(iOS 15.0, *) else {
                    if let username = self?.loginTextField.value,
                       let password = self?.passwordTextField.value {
                        self?.delegate?.requestTOTPCode(username: username, password: password)
                        self?.measureLoginSuccess()
                    }
                    return
                }
                let challenge = context.authenticationOptions.publicKey.challenge
                let relyingPartyIdentifier = context.authenticationOptions.publicKey.rpId
                let allowedCredentialIds = context.authenticationOptions.publicKey.allowCredentials.map(\.id)

                guard let username = self?.loginTextField.value,
                      let password = self?.passwordTextField.value
                else {
                    self?.delegate?.requestKeySignature(challenge: challenge,
                                                        relyingPartyIdentifier: relyingPartyIdentifier,
                                                        allowedCredentialIds: allowedCredentialIds)
                    return
                }

                self?.delegate?.requestTOTPOrKeySignature(username: username,
                                                          password: password,
                                                          challenge: challenge,
                                                          relyingPartyIdentifier: relyingPartyIdentifier,
                                                          allowedCredentialIds: allowedCredentialIds)
            case .mailboxPasswordNeeded:
                self?.delegate?.mailboxPasswordNeeded()
                self?.measureLoginSuccess()
            case let .createAddressNeeded(data, defaultUsername):
                self?.delegate?.createAddressNeeded(data: data, defaultUsername: defaultUsername)
                self?.measureLoginSuccess()
            case .ssoChallenge(let ssoChallengeResponse):
                self?.webView = self?.showWebView()
                Task {
                    let ssoRequestResult = await self?.viewModel.getSSORequest(challenge: ssoChallengeResponse)
                    if let error = ssoRequestResult?.error {
                        self?.webView?.dismiss(animated: true)
                        self?.showBanner(message: error)
                        return
                    } else if let request = ssoRequestResult?.request {
                        self?.webView?.loadRequest(request: request)
                    }
                }
                self?.measureLoginSuccess()
            case .switchToSSOLogin(let info):
                self?.showBanner(message: info, style: .info)
                self?.signInWithSSO()
                self?.measureLoginFailure(httpCode: APIErrorCode.switchToSSOError)
            }
        }
        viewModel.isLoading.bind { [weak self] isLoading in
            self?.view.isUserInteractionEnabled = !isLoading
            self?.signInButton.isSelected = isLoading
        }
        viewModel.challenge.reset()
        try? self.loginTextField.setUpChallenge(viewModel.challenge, type: .username)

        NotificationCenter.default
            .addObserver(self,
                         selector: #selector(preferredContentSizeChanged(_:)),
                         name: UIContentSizeCategory.didChangeNotification,
                         object: nil)
    }

    // MARK: - Actions

    @objc private func signInWithSSO() {
        viewModel.isSsoUIEnabled = true
        passwordTextField.isHidden = viewModel.isSsoUIEnabled
        loginTextField.title = viewModel.loginTextFieldTitle
        titleLabel.text = viewModel.titleLabel
        signInWithSSOButton.setTitle(viewModel.signInWithSSOButtonTitle, for: .normal)
        signInWithSSOButton.removeTarget(self, action: #selector(signInWithSSO), for: .touchUpInside)
        signInWithSSOButton.addTarget(self, action: #selector(signInWithEmail), for: .touchUpInside)
    }

    @objc private func signInWithEmail() {
        viewModel.isSsoUIEnabled = false
        passwordTextField.isHidden = viewModel.isSsoUIEnabled
        loginTextField.title = viewModel.loginTextFieldTitle
        titleLabel.text = viewModel.titleLabel
        signInWithSSOButton.setTitle(viewModel.signInWithSSOButtonTitle, for: .normal)
        signInWithSSOButton.removeTarget(self, action: #selector(signInWithEmail), for: .touchUpInside)
        signInWithSSOButton.addTarget(self, action: #selector(signInWithSSO), for: .touchUpInside)
    }

    @objc private func signInPressed(_ sender: Any) {
        cancelFocus()
        dismissKeyboard()

        let usernameValid = setAddressTextFieldError()
        let passwordValid = validatePassword()

        guard usernameValid else {
            return
        }

        guard (passwordTextField.isHidden == false && passwordValid) || isSSOEnabled else {
            return
        }

        PMBanner.dismissAll(on: self)
        viewModel.login(username: loginTextField.value, password: passwordTextField.value)
    }

    @objc private func signUpPressed(_ sender: ProtonButton) {
        cancelFocus()
        clearAccount()
        delegate?.userDidRequestSignup()
        measureOnViewClicked(item: "sign_up")
    }

    @objc private func needHelpPressed() {
        cancelFocus()
        delegate?.userDidRequestHelp()
        measureOnViewClicked(item: "help")
    }

    @objc private func closePressed(_ sender: Any) {
        cancelFocus()
        delegate?.userDidDismissLoginViewController()
        measureOnViewClosed()
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

    private func clearAccount() {
        passwordTextField.value = ""
        loginTextField.value = ""
    }

    @objc
    private func preferredContentSizeChanged(_ notification: Notification) {
        guard DFSSetting.enableDFS else { return }
        titleLabel.font = .adjustedFont(forTextStyle: .title2, weight: .bold)
        subtitleLabel.font = .adjustedFont(forTextStyle: .subheadline)
    }

    // MARK: - Keyboard

    private func setupNotifications() {
        NotificationCenter.default
            .setupKeyboardNotifications(target: self, show: #selector(keyboardWillShow), hide: #selector(keyboardWillHide))
    }

    @objc private func keyboardWillShow(notification: NSNotification) {
        adjust(scrollView, notification: notification,
               topView: topView(of: loginTextField, passwordTextField),
               bottomView: signUpButton)
    }

    @objc private func keyboardWillHide(notification: NSNotification) {
        adjust(scrollView, notification: notification, topView: titleLabel, bottomView: signUpButton)
    }

    // MARK: - Validation

    @discardableResult
    private func setAddressTextFieldError() -> Bool {
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

    func didBeginEditing(textField: PMTextField) {
        switch textField {
        case loginTextField:
            measureOnViewFocused(item: "username")
        case passwordTextField:
            measureOnViewFocused(item: "password")
        default:
            break
        }
    }

    func didEndEditing(textField: PMTextField) {
        switch textField {
        case loginTextField:
            setAddressTextFieldError()
        case passwordTextField:
            validatePassword()
        default:
            break
        }
    }
}

// MARK: - WKNavigationDelegate
extension LoginViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let responseToken = viewModel.getSSOTokenFromURL(url: navigationAction.request.url) {
            decisionHandler(.cancel)
            self.webView?.dismiss(animated: true)
            viewModel.processResponseToken(idpEmail: loginTextField.value, responseToken: responseToken)
        } else {
            decisionHandler(.allow)
        }
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse,
                 decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {

        if let response = navigationResponse.response as? HTTPURLResponse {
            handleNetworkResponse(response: response)
        }

        decisionHandler(.allow)
    }

    private func handleNetworkResponse(response: HTTPURLResponse) {
        let isProtonPage = viewModel.isProtonPage(url: response.url)
        switch ObservabilityEvent.ssoWebPageLoadCountTotal(responseStatusCode: response.statusCode,
                                                           isProtonPage: isProtonPage) {
        case .left(let event)?:
            ObservabilityEnv.report(event)
        case .right(let event)?:
            ObservabilityEnv.report(event)
        case nil:
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

    func onLearnMoreAboutExternalAccountsNotSupported() {
        delegate?.learnMoreAboutExternalAccountsNotSupported()
    }

    var bannerPosition: PMBannerPosition { .top }
}

// MARK: - Product Metrics

extension LoginViewController {
    private func measureLoginSuccess() {
        measureAPIResult(
            action: .auth,
            additionalDimensions: [
                .result(MeasureConstants.resultSuccess),
                .hostType(viewModel.isCurrentlyUsingProxyDomain ? MeasureConstants.hostAlternative : MeasureConstants.hostStandard)
            ]
        )
    }

    private func measureLoginFailure(httpCode: Int) {
        measureAPIResult(
            action: .auth,
            additionalValues: [.httpCode(httpCode)],
            additionalDimensions: [
                .result(MeasureConstants.resultFailure),
                .hostType(viewModel.isCurrentlyUsingProxyDomain ? MeasureConstants.hostAlternative : MeasureConstants.hostStandard)
            ]
        )
    }
}
#endif
