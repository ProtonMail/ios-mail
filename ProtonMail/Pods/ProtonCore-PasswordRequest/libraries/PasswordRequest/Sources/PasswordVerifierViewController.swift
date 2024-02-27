//
//  PasswordVerifierViewController.swift
//  ProtonCore-PasswordRequest - Created on 14.07.23.
//
//  Copyright (c) 2023 Proton Technologies AG
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
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore. If not, see https://www.gnu.org/licenses/.
//

#if os(iOS)

import UIKit
import ProtonCoreServices
import ProtonCoreNetworking
import ProtonCoreUIFoundations

public protocol PasswordVerifierViewControllerDelegate: AnyObject {
    func userUnlocked()
    func didCloseVerifyPassword()
    func didCloseWithError(code: Int, description: String)
}

public final class PasswordVerifierViewController: UIViewController {
    private let titleLabel = UILabel(frame: .zero)
    private let headerLabel = UILabel(frame: .zero)
    private let passwordTextField = PMTextField(frame: .zero)
    private let submitButton = ProtonButton(frame: .zero)
    private let scrollView = UIScrollView(frame: .zero)

    public var viewModel: PasswordVerifier?
    public weak var delegate: PasswordVerifierViewControllerDelegate?

    override public func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupButton()
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        _ = passwordTextField.becomeFirstResponder()
    }

    private func setupUI() {
        titleLabel.lineBreakMode = .byWordWrapping
        titleLabel.numberOfLines = 0
        titleLabel.tintColor = ColorProvider.TextNorm
        titleLabel.textAlignment = .center
        titleLabel.font = .adjustedFont(forTextStyle: .body, weight: .bold)

        headerLabel.lineBreakMode = .byWordWrapping
        headerLabel.numberOfLines = 0
        headerLabel.tintColor = ColorProvider.TextWeak
        headerLabel.textAlignment = .left
        headerLabel.font = .adjustedFont(forTextStyle: .footnote, weight: .light)

        passwordTextField.placeholder = PRTranslations.password_field_title.l10n
        passwordTextField.isPassword = true
        passwordTextField.textContentType = .password

        setTitles(isAccountRecoveryEnabled: viewModel?.missingScopeMode == .accountRecovery)

        view.backgroundColor = ColorProvider.BackgroundNorm
        view.addSubview(scrollView)

        scrollView.addConstraints {
            [
                $0.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                $0.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                $0.topAnchor.constraint(equalTo: view.topAnchor),
                $0.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ]
        }

        let containerView = UIView(frame: .zero)
        containerView.addSubviews(titleLabel, headerLabel, passwordTextField, submitButton)
        scrollView.addSubview(containerView)

        containerView.addConstraints {
            [
                $0.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
                $0.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
                $0.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
                $0.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
                $0.topAnchor.constraint(equalTo: scrollView.topAnchor)
            ]
        }

        titleLabel.addConstraints {
            [
                $0.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
                $0.bottomAnchor.constraint(equalTo: headerLabel.topAnchor, constant: -12),
                $0.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
                $0.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16)
            ]
        }

        headerLabel.addConstraints {
            [
                $0.bottomAnchor.constraint(equalTo: passwordTextField.topAnchor, constant: -12),
                $0.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
                $0.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16)
            ]
        }

        passwordTextField.addConstraints {
            [
                $0.bottomAnchor.constraint(equalTo: submitButton.topAnchor, constant: -12),
                $0.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
                $0.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16)
            ]
        }

        submitButton.addConstraints {
            [
                $0.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
                $0.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
                $0.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -8)
            ]
        }
    }

    private func setTitles(isAccountRecoveryEnabled: Bool) {
        if isAccountRecoveryEnabled {
            titleLabel.text = NSLocalizedString("Cancel password reset?", comment: "")
            submitButton.setTitle(NSLocalizedString("Cancel password reset", comment: "Button cancelling the password request"), for: .normal)
            headerLabel.text = NSLocalizedString("Enter your current password to cancel the password reset process. No other changes will take effect.", comment: "")
            headerLabel.isHidden = false
            passwordTextField.title = NSLocalizedString("Current password", comment: "")
        } else {
            titleLabel.text = PRTranslations.validation_enter_password.l10n
            submitButton.setTitle(PRTranslations.create_address_button_title.l10n, for: .normal)
            headerLabel.isHidden = true
            passwordTextField.title = PRTranslations.password_field_title.l10n
        }
    }

    private func setupButton() {
        submitButton.addTarget(self, action: #selector(verifyPasswordWithAuth), for: .touchUpInside)
        let image: UIImage = IconProvider.cross
        navigationItem.leftBarButtonItem = .button(on: self, action: #selector(dissmissTapped), image: image)
    }

    @objc private func dissmissTapped() {
        dismiss(animated: true, completion: delegate?.didCloseVerifyPassword)
    }

    @objc private func verifyPasswordWithAuth() {
        let password = passwordTextField.value
        passwordTextField.isEnabled = false
        passwordTextField.isError = false
        submitButton.isSelected = true

        if let authInfo = viewModel?.authInfo {
            verifyPassword(password: password, authInfo: authInfo)
        } else {
            viewModel?.fetchAuthInfo { [weak self] result in
                switch result {
                case .success(let authInfo):
                    self?.verifyPassword(password: password, authInfo: authInfo)
                case .failure(let authError):
                    self?.handleAuthError(error: authError)
                }
            }
        }
    }

    private func verifyPassword(password: String, authInfo: AuthInfoResponse) {
        viewModel?.verifyPassword(password: password, authInfo: authInfo) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .failure(let authError):
                    self?.handleAuthError(error: authError)
                case .success:
                    self?.dismiss(
                        animated: true,
                        completion: { [weak self] in
                            self?.delegate?.userUnlocked()
                        }
                    )
                }
            }
        }
    }

    private func handleAuthError(error: AuthErrors) {
        submitButton.isSelected = false
        passwordTextField.isEnabled = true
        switch error {
        case .wrongPassword:
            passwordTextField.isError = true
            passwordTextField.errorMessage = PRTranslations.validation_invalid_password.l10n
        default:
            dismiss(
                animated: true,
                completion: { [weak self] in
                    self?.delegate?.didCloseWithError(code: error.codeInNetworking, description: error.localizedDescription)
                }
            )
        }
    }
}

#endif
