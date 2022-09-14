//
//  MailboxPasswordViewController.swift
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

import Foundation
import UIKit
import ProtonCore_CoreTranslation
import ProtonCore_Foundations
import ProtonCore_Login
import ProtonCore_UIFoundations

protocol MailboxPasswordViewControllerInStandaloneFlowDelegate: AnyObject {
    func userDidRequestPasswordReset()
    func mailboxPasswordViewControllerDidFinish(password: String)
}

protocol MailboxPasswordViewControllerDelegate: NavigationDelegate, LoginStepsDelegate {
    func userDidRequestPasswordReset()
    func mailboxPasswordViewControllerDidFinish(endLoading: @escaping () -> Void, data: LoginData)
    func mailboxPasswordViewControllerDidFail(error: LoginError)
}

final class MailboxPasswordViewController: UIViewController, AccessibleView, Focusable {

    // MARK: - Outlets

    @IBOutlet private weak var titleLabel: TitleLabel!
    @IBOutlet private weak var mailboxPasswordTextField: PMTextField!
    @IBOutlet private weak var unlockButton: ProtonButton!
    @IBOutlet private weak var forgetButton: ProtonButton!
    @IBOutlet private weak var scrollView: UIScrollView!

    // MARK: - Properties

    weak var delegate: MailboxPasswordViewControllerDelegate?
    var viewModel: MailboxPasswordViewModel!
    var customErrorPresenter: LoginErrorPresenter?
    var onDohTroubleshooting: () -> Void = {}
    
    override var preferredStatusBarStyle: UIStatusBarStyle { darkModeAwarePreferredStatusBarStyle() }

    var focusNoMore: Bool = false
    private let navigationBarAdjuster = NavigationBarAdjustingScrollViewDelegate()

    private weak var delegateInStandaloneFlow: MailboxPasswordViewControllerInStandaloneFlowDelegate?
    private var isStandaloneComponent = false

    func setupAsStandaloneComponent(delegate: MailboxPasswordViewControllerInStandaloneFlowDelegate) {
        delegateInStandaloneFlow = delegate
        isStandaloneComponent = true
    }

    // MARK: - Setup

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        setupBinding()
        setupDelegates()
        setupNotifications()
        generateAccessibilityIdentifiers()
    }

    private func setupUI() {
        view.backgroundColor = ColorProvider.BackgroundNorm
        titleLabel.text = CoreString._ls_login_mailbox_screen_title
        titleLabel.textColor = ColorProvider.TextNorm
        mailboxPasswordTextField.title = CoreString._ls_login_mailbox_field_title
        mailboxPasswordTextField.isPassword = true
        mailboxPasswordTextField.textContentType = .password

        forgetButton.setMode(mode: .text)

        unlockButton.setTitle(CoreString._ls_login_mailbox_button_title, for: .normal)
        forgetButton.setTitle(CoreString._ls_login_mailbox_forgot_password, for: .normal)

        if !isStandaloneComponent {
            setUpBackArrow(action: #selector(MailboxPasswordViewController.goBack(_:)))
        }
    }

    private func setupDelegates() {
        mailboxPasswordTextField.delegate = self
    }

    private func setupBinding() {
        // mailbox in the standalone flow doesn't use the login flow view model
        guard isStandaloneComponent == false else { return }

        viewModel.finished.bind { [weak self] result in
            switch result {
            case let .done(data):
                self?.delegate?.mailboxPasswordViewControllerDidFinish(endLoading: { [weak self] in self?.viewModel.isLoading.value = false }, data: data)
            case let .createAddressNeeded(data):
                self?.delegate?.createAddressNeeded(data: data)
            }
        }
        viewModel.error.bind { [weak self] error in
            guard let self = self else {
                return
            }

            switch error {
            case .invalidCredentials:
                self.delegate?.mailboxPasswordViewControllerDidFail(error: error)
            case .invalidSecondPassword:
                self.setError(textField: self.mailboxPasswordTextField, error: nil)
                if self.customErrorPresenter?.willPresentError(error: error, from: self) == true { } else { self.showError(error: error) }
            default:
                if self.customErrorPresenter?.willPresentError(error: error, from: self) == true { } else { self.showError(error: error) }
            }
        }
        viewModel.isLoading.bind { [weak self] isLoading in
            self?.view.isUserInteractionEnabled = !isLoading
            self?.unlockButton.isSelected = isLoading
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        navigationBarAdjuster.setUp(for: scrollView, shouldAdjustNavigationBar: !isStandaloneComponent, parent: parent)
        scrollView.adjust(forKeyboardVisibilityNotification: nil)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        focusOnce(view: mailboxPasswordTextField)
    }

    // MARK: - Keyboard

    private func setupNotifications() {
        NotificationCenter.default
            .setupKeyboardNotifications(target: self, show: #selector(keyboardWillShow), hide: #selector(keyboardWillHide))
    }

    @objc private func keyboardWillShow(notification: NSNotification) {
        adjust(scrollView, notification: notification, topView: mailboxPasswordTextField, bottomView: forgetButton)
    }

    @objc private func keyboardWillHide(notification: NSNotification) {
        adjust(scrollView, notification: notification, topView: titleLabel, bottomView: forgetButton)
    }

    // MARK: - Errors

    private func clearErrors() {
        PMBanner.dismissAll(on: self)
        clearError(textField: mailboxPasswordTextField)
    }

    // MARK: - Actions

    @objc private func goBack(_ sender: Any) {
        delegate?.userDidRequestGoBack()
    }

    @IBAction private func unlockPressed(_ sender: Any) {
        clearErrors()
        _ = mailboxPasswordTextField.resignFirstResponder()
        let password = mailboxPasswordTextField.value
        if isStandaloneComponent {
            delegateInStandaloneFlow?.mailboxPasswordViewControllerDidFinish(password: password)
        } else {
            viewModel.unlock(password: password)
        }
    }

    @IBAction private func forgetPressed(_ sender: Any) {
        delegate?.userDidRequestPasswordReset()
        delegateInStandaloneFlow?.userDidRequestPasswordReset()
    }
}

// MARK: - Additional errors handling

extension MailboxPasswordViewController: LoginErrorCapable {
    
    func onFirstPasswordChangeNeeded() {
        delegate?.firstPasswordChangeNeeded()
    }

    func onUserAccountSetupNeeded() {
        delegate?.userAccountSetupNeeded()
    }

    var bannerPosition: PMBannerPosition { .top }
}

// MARK: - Text field delegate

extension MailboxPasswordViewController: PMTextFieldDelegate {
    func didChangeValue(_ textField: PMTextField, value: String) {}

    func didBeginEditing(textField: PMTextField) {}

    func didEndEditing(textField: PMTextField) {}

    func textFieldShouldReturn(_ textField: PMTextField) -> Bool {
        _ = textField.resignFirstResponder()
        return true
    }
}
