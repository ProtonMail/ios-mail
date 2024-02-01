//
//  TwoFactorViewController.swift
//  ProtonCore-Login - Created on 30.11.2020.
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

import Foundation
import UIKit
import ProtonCoreFoundations
import ProtonCoreLogin
import ProtonCoreUIFoundations

protocol TwoFactorViewControllerDelegate: NavigationDelegate, LoginStepsDelegate {
    func twoFactorViewControllerDidFinish(endLoading: @escaping () -> Void, data: LoginData)
    func twoFactorViewControllerDidFail(error: LoginError)
}

final class TwoFactorViewController: UIViewController, AccessibleView, Focusable {

    // MARK: - Outlets

    @IBOutlet private weak var titleView: UILabel!
    @IBOutlet private weak var codeTextField: PMTextField!
    @IBOutlet private weak var authenticateButton: ProtonButton!
    @IBOutlet private weak var recoveryCodeButton: ProtonButton!
    @IBOutlet private weak var scrollView: UIScrollView!
    private var usernameTextField: UITextField?
    private var passwordTextField: UITextField?

    // MARK: - Properties

    weak var delegate: TwoFactorViewControllerDelegate?
    var viewModel: TwoFactorViewModel!
    var customErrorPresenter: LoginErrorPresenter?
    var onDohTroubleshooting: () -> Void = {}

    var focusNoMore: Bool = false
    private let navigationBarAdjuster = NavigationBarAdjustingScrollViewDelegate()

    override var preferredStatusBarStyle: UIStatusBarStyle { darkModeAwarePreferredStatusBarStyle() }

    // MARK: - Setup

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        setupBinding()
        setupDelegates()
        setupNotifications()

        setUpBackArrow(action: #selector(TwoFactorViewController.goBack(_:)))
        setUpAccountForAutoRemember()
        generateAccessibilityIdentifiers()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // No document support, my assumption after testing
        // One of condition to trigger KeyChain auto remember prompt is userName field or password field focus at least once
        // To trigger the prompt, focus on password
        passwordTextField?.becomeFirstResponder()
        // resign it so user won't see keyboard on the next screen 
        _ = passwordTextField?.resignFirstResponder()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        navigationBarAdjuster.setUp(for: scrollView, parent: parent)
        scrollView.adjust(forKeyboardVisibilityNotification: nil)
    }

    private func setupUI() {
        view.backgroundColor = ColorProvider.BackgroundNorm
        recoveryCodeButton.setMode(mode: .text)

        titleView.text = LUITranslation.login_2fa_screen_title.l10n
        titleView.textColor = ColorProvider.TextNorm
        authenticateButton.setTitle(LUITranslation.login_2fa_action_button_title.l10n, for: .normal)
    }

    // Set up username and password textField to enable keyChain auto remember password
    // TextFields seems like need to existing from viewDidLoad
    // If create textFields in `finished.bind`, the auto remember password prompt won't show
    private func setUpAccountForAutoRemember() {
        let usernameTextField = UITextField(frame: .zero)
        usernameTextField.textContentType = .username
        self.usernameTextField = usernameTextField

        let passwordTextField = UITextField(frame: .zero)
        passwordTextField.isSecureTextEntry = true
        passwordTextField.textContentType = .password
        self.passwordTextField = passwordTextField

        let views = [usernameTextField, passwordTextField]
        for sub in views {
            view.addSubview(sub)
            sub.translatesAutoresizingMaskIntoConstraints = false
            sub.alpha = 0.01
            sub.tag = 99
            NSLayoutConstraint.activate([
                sub.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                sub.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 10),
                sub.heightAnchor.constraint(equalToConstant: 1),
                sub.widthAnchor.constraint(equalToConstant: 1)
            ])
        }
    }

    private func fillInAccount() {
        usernameTextField?.text = viewModel.username
        passwordTextField?.text = viewModel.password
    }

    private func setupDelegates() {
        codeTextField.delegate = self
    }

    private func setupBinding() {
        viewModel.mode.bind { [weak self] mode in
            self?.codeTextField.set(mode: mode)
            self?.recoveryCodeButton.setTitle(mode == TwoFactorViewModel.Mode.twoFactorCode ? LUITranslation.login_2fa_recovery_button_title.l10n : LUITranslation.login_2fa_2fa_button_title.l10n, for: .normal)
        }
        viewModel.error.bind { [weak self] error in
            guard let self = self else { return }
            switch error {
            case .invalidCredentials, .invalidAccessToken:
                self.delegate?.twoFactorViewControllerDidFail(error: error)
            case .invalid2FACode:
                if self.customErrorPresenter?.willPresentError(error: error, from: self) == true { } else { self.showError(error: error) }
            default:
                if self.customErrorPresenter?.willPresentError(error: error, from: self) == true { } else { self.showError(error: error) }
            }
        }
        viewModel.isLoading.bind { [weak self] isLoading in
            self?.view.isUserInteractionEnabled = !isLoading
            self?.authenticateButton.isSelected = isLoading
        }
        viewModel.finished.bind { [weak self] result in
            self?.fillInAccount()
            switch result {
            case let .done(data):
                self?.delegate?.twoFactorViewControllerDidFinish(endLoading: { [weak self] in self?.viewModel.isLoading.value = false }, data: data)
            case .mailboxPasswordNeeded:
                self?.delegate?.mailboxPasswordNeeded()
            case let .createAddressNeeded(data, defaultUsername):
                self?.delegate?.createAddressNeeded(data: data, defaultUsername: defaultUsername)
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if focusNoMore {
            _ = codeTextField.becomeFirstResponder()
        } else {
            focusOnce(view: codeTextField)
        }
    }

    // MARK: - Keyboard

    private func setupNotifications() {
        NotificationCenter.default
            .setupKeyboardNotifications(target: self, show: #selector(keyboardWillShow), hide: #selector(keyboardWillHide))
    }

    @objc private func keyboardWillShow(notification: NSNotification) {
        adjust(scrollView, notification: notification, topView: codeTextField, bottomView: recoveryCodeButton)
    }

    @objc private func keyboardWillHide(notification: NSNotification) {
        adjust(scrollView, notification: notification, topView: titleView, bottomView: recoveryCodeButton)
    }

    // MARK: - Errors

    private func clearErrors() {
        PMBanner.dismissAll(on: self)
        clearError(textField: codeTextField)
    }

    // MARK: - Actions

    @objc private func goBack(_ sender: Any) {
        delegate?.userDidGoBack()
    }

    @IBAction private func recoveryPressed(_ sender: Any) {
        clearErrors()
        _ = codeTextField.resignFirstResponder()
        viewModel.toggleMode()
    }

    @IBAction private func authenticatePressed(_ sender: Any) {
        clearErrors()
        viewModel.authenticate(code: codeTextField.value)
    }
}

// MARK: - Text field delegate

extension TwoFactorViewController: PMTextFieldDelegate {
    func didChangeValue(_ textField: PMTextField, value: String) {}

    func didBeginEditing(textField: PMTextField) {}

    func didEndEditing(textField: PMTextField) {}

    func textFieldShouldReturn(_ textField: PMTextField) -> Bool {
        _ = textField.resignFirstResponder()
        return true
    }
}

// MARK: - Additional errors handling

extension TwoFactorViewController: LoginErrorCapable {
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

#endif
