//
//  TwoFactorViewController.swift
//  PMLogin - Created on 30.11.2020.
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
import Foundation
import UIKit
import ProtonCore_CoreTranslation
import ProtonCore_Foundations
import ProtonCore_UIFoundations

protocol TwoFactorViewControllerDelegate: NavigationDelegate & LoginStepsDelegate {
    func twoFactorViewControllerDidFinish(data: LoginData)
    func twoFactorViewControllerDidFail(error: LoginError)
}

final class TwoFactorViewController: UIViewController, AccessibleView, Focusable {

    // MARK: - Outlets

    @IBOutlet private weak var authenticateButton: ProtonButton!
    @IBOutlet private weak var recoveryCodeButton: ProtonButton!
    @IBOutlet private weak var codeTextField: PMTextField!
    @IBOutlet private weak var scrollView: UIScrollView!

    // MARK: - Properties

    weak var delegate: TwoFactorViewControllerDelegate?
    var viewModel: TwoFactorViewModel!

    var focusNoMore: Bool = false
    private let navigationBarAdjuster = NavigationBarAdjustingScrollViewDelegate()

    // MARK: - Setup

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        setupBinding()
        setupDelegates()
        setupNotifications()

        setUpBackArrow(action: #selector(TwoFactorViewController.goBack(_:)))

        generateAccessibilityIdentifiers()
    }

    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        navigationBarAdjuster.setUp(for: scrollView, parent: parent)
    }

    private func setupUI() {
        view.backgroundColor = UIColorManager.BackgroundNorm
        recoveryCodeButton.setMode(mode: .text)

        authenticateButton.setTitle(CoreString._ls_login_2fa_action_button_title, for: .normal)
    }

    private func setupDelegates() {
        codeTextField.delegate = self
    }

    private func setupBinding() {
        viewModel.mode.bind { [weak self] mode in
            self?.codeTextField.set(mode: mode)
            self?.recoveryCodeButton.setTitle(mode == TwoFactorViewModel.Mode.twoFactorCode ? CoreString._ls_login_2fa_recovery_button_title : CoreString._ls_login_2fa_2fa_button_title, for: .normal)
        }
        viewModel.error.bind { [weak self] error in
            switch error {
            case .invalidCredentials, .invalidAccessToken:
                self?.delegate?.twoFactorViewControllerDidFail(error: error)
            case .invalid2FACode:
                self?.showError(error: error)
            default:
                self?.showError(error: error)
            }
        }
        viewModel.isLoading.bind { [weak self] isLoading in
            self?.view.isUserInteractionEnabled = !isLoading
            self?.authenticateButton.isSelected = isLoading
        }
        viewModel.finished.bind { [weak self] result in
            switch result {
            case let .done(data):
                self?.delegate?.twoFactorViewControllerDidFinish(data: data)
            case .mailboxPasswordNeeded:
                self?.delegate?.mailboxPasswordNeeded()
            case let .createAddressNeeded(data):
                self?.delegate?.createAddressNeeded(data: data)
            }
        }
    }

    private func setupNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(adjustKeyboard), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(adjustKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        focusOnce(view: codeTextField)
    }

    // MARK: - Keyboard

    @objc private func adjustKeyboard(notification: NSNotification) {
        guard navigationController?.topViewController === self else { return }
        scrollView.adjustForKeyboard(notification: notification)
    }

    // MARK: - Errors

    private func clearErrors() {
        PMBanner.dismissAll(on: self)
        clearError(textField: codeTextField)
    }

    // MARK: - Actions

    @objc private func goBack(_ sender: Any) {
        delegate?.userDidRequestGoBack()
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

    var bannerPosition: PMBannerPosition { .top }
}
