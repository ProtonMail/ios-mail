//
//  UIViewController+Extensions.swift
//  ProtonCore-Login - Created on 26.11.2020.
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
import ProtonCoreLogin
import ProtonCoreUIFoundations

extension UIViewController {
    func showBanner(message: String, style: PMBannerNewStyle = .error, button: String? = nil, action: (() -> Void)? = nil, position: PMBannerPosition) {
        unlockUI()
        let banner = PMBanner(message: message, style: style, dismissDuration: Double.infinity)
        banner.addButton(text: button ?? LUITranslation._core_ok_button.l10n) { _ in
            action?()
            banner.dismiss()
        }
        banner.addLinkHandler { _, url in
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
            banner.dismiss()
        }
        PMBanner.dismissAll(on: self)
        banner.show(at: position, on: self)
    }

    func showBannerWithoutButton(message: String, style: PMBannerNewStyle = .error, position: PMBannerPosition) {
        unlockUI()
        let banner = PMBanner(message: message, style: style, dismissDuration: Double.infinity)
        PMBanner.dismissAll(on: self)
        banner.show(at: position, on: self)
    }
}

protocol ErrorCapable: UIViewController {
    var onDohTroubleshooting: () -> Void { get }
}

extension ErrorCapable {
    func setError(textField: PMTextField, error: (Error & CustomStringConvertible)?) {
        textField.isError = true
        textField.errorMessage = error?.description
    }

    func clearError(textField: PMTextField) {
        textField.isError = false
    }
}

protocol LoginErrorCapable: ErrorCapable {
    func showError(error: LoginError)
    func onUserAccountSetupNeeded()
    func onFirstPasswordChangeNeeded()
    func onLearnMoreAboutExternalAccountsNotSupported()
    func showInfo(message: String)

    var bannerPosition: PMBannerPosition { get }
}

extension LoginErrorCapable {
    func showError(error: LoginError) {
        switch error {
        case let .invalidCredentials(message: message):
            showBanner(message: message)
        case let .invalid2FACode(message: message):
            // TODO: should we have a dedicated 2FA message here? Server returns somewhat generic "Invalid credentials" message
            showBanner(message: message)
        case let .invalidAccessToken(message: message):
            showBanner(message: message)
        case let .initialError(message: message):
            showBanner(message: message)
        case let .generic(message: message, _, _):
            showBanner(message: message)
        case let .apiMightBeBlocked(message, _):
            showBanner(message: message, button: LUITranslation._core_api_might_be_blocked_button.l10n) { [weak self] in
                self?.onDohTroubleshooting()
            }
        case .externalAccountsNotSupported(let message, let title, _):
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: LUITranslation.external_accounts_not_supported_popup_action_button.l10n, style: .default) { [weak self] _ in
                self?.onLearnMoreAboutExternalAccountsNotSupported()
            })
            alert.addAction(UIAlertAction(title: LUITranslation._core_cancel_button.l10n, style: .default, handler: nil))
            present(alert, animated: true)
        case .invalidSecondPassword:
            showBanner(message: LUITranslation.error_invalid_mailbox_password.l10n)
        case .invalidState:
            showBanner(message: LSTranslation._loginservice_error_generic.l10n)
        case .missingKeys:
            let alert = UIAlertController(title: LUITranslation.error_missing_keys_title.l10n, message: LUITranslation.error_missing_keys_text.l10n, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: LUITranslation.error_missing_keys_text_button.l10n, style: .default) { [weak self] _ in
                self?.onUserAccountSetupNeeded()
            })
            alert.addAction(UIAlertAction(title: LUITranslation._core_cancel_button.l10n, style: .cancel, handler: nil))
            present(alert, animated: true)
        case .needsFirstTimePasswordChange:
            let alert = UIAlertController(title: LUITranslation.username_org_dialog_title.l10n, message: LUITranslation.username_org_dialog_message.l10n, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: LUITranslation.username_org_dialog_action_button.l10n, style: .default) { [weak self] _ in
                self?.onFirstPasswordChangeNeeded()
            })
            alert.addAction(UIAlertAction(title: LUITranslation._core_cancel_button.l10n, style: .cancel, handler: nil))
            present(alert, animated: true)
        case .emailAddressAlreadyUsed:
            showBanner(message: LUITranslation.error_email_already_used.l10n)
        case .missingSubUserConfiguration:
            showBanner(message: LUITranslation.error_missing_sub_user_configuration.l10n)
        }
    }

    func showInfo(message: String) {
        showBannerWithoutButton(message: message, style: .info, position: bannerPosition)
    }

    func showBanner(message: String, button: String? = nil, action: (() -> Void)? = nil) {
        showBanner(message: message, button: button, action: action, position: bannerPosition)
    }

    func onUserAccountSetupNeeded() {
    }

    func onFirstPasswordChangeNeeded() {
    }

    func onLearnMoreAboutExternalAccountsNotSupported() {
    }
}

enum SignUpInvalidPasswordReason {
    case notEqual
    case notFulfilling(SignupPasswordRestrictions)
}

enum InvalidVerificationReson {
    case enter
    case resend
    case changeEmail
}

protocol SignUpErrorCapable: ErrorCapable {
    func showError(error: SignupError)
    func emailAddressAlreadyUsed()
    func invalidVerificationCode(reason: InvalidVerificationReson)
    func invalidPassword(reason: SignUpInvalidPasswordReason)
    var bannerPosition: PMBannerPosition { get }
}

extension SignUpErrorCapable {
    func showError(error: SignupError) {
        switch error {
        case .emailAddressAlreadyUsed:
            self.emailAddressAlreadyUsed()
        case .validationTokenRequest:
            showBanner(message: LUITranslation.error_invalid_token_request.l10n)
        case .invalidVerificationCode(let message):
            invalidVerificationCodeAlert(title: message)
        case .validationToken:
            showBanner(message: LUITranslation.error_invalid_token.l10n)
        case .randomBits:
            showBanner(message: LUITranslation.error_create_user_failed.l10n)
        case .cantHashPassword:
            showBanner(message: LUITranslation.error_invalid_hashed_password.l10n)
        case .passwordEmpty:
            showBanner(message: LUITranslation.error_password_empty.l10n)
            self.invalidPassword(reason: .notFulfilling(.notEmpty))
        case .passwordShouldHaveAtLeastEightCharacters:
            showBanner(message: String(format: LUITranslation.error_password_too_short.l10n, NSNumber(8)))
            self.invalidPassword(reason: .notFulfilling(.atLeastEightCharactersLong))
        case .passwordNotEqual:
            showBanner(message: LUITranslation.error_password_not_equal.l10n)
            self.invalidPassword(reason: .notEqual)
        case let .generic(message: message, _, _):
            showBanner(message: message)
        case let .apiMightBeBlocked(message, _):
            showBanner(message: message, button: LUITranslation._core_api_might_be_blocked_button.l10n) { [weak self] in
                self?.onDohTroubleshooting()
            }
        case .generateVerifier:
            showBanner(message: LUITranslation.error_create_user_failed.l10n)
        case .unknown:
            showBanner(message: LUITranslation.error_occured.l10n)
        }
    }

    private func invalidVerificationCodeAlert(title: String) {
        self.invalidVerificationCode(reason: .enter)
        let message = LUITranslation.invalid_verification_alert_message.l10n

        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let resendAction = UIAlertAction(title: LUITranslation.verification_error_alert_resend.l10n, style: .default, handler: { _ in
            self.invalidVerificationCode(reason: .resend)
        })
        resendAction.accessibilityLabel = "resendButton"
        alert.addAction(resendAction)
        let changeEmailAction = UIAlertAction(title: LUITranslation.invalid_verification_change_email_button.l10n, style: .default, handler: { _ in
            self.invalidVerificationCode(reason: .changeEmail)
        })
        changeEmailAction.accessibilityLabel = "changeEmailButton"
        alert.addAction(changeEmailAction)
        present(alert, animated: true, completion: nil)
    }

    func showBanner(message: String, button: String? = nil, action: (() -> Void)? = nil) {
        showBanner(message: message, button: button, action: action, position: bannerPosition)
    }

    func emailAddressAlreadyUsed() {
    }

    func invalidVerificationCode(reason: InvalidVerificationReson) {
    }

    func invalidPassword(reason: SignUpInvalidPasswordReason) {
    }
}

protocol Focusable: UIViewController {
    var focusNoMore: Bool { get set }
    func focusOnce(view: UIView, delay: DispatchTimeInterval?)
    func cancelFocus()
}

extension Focusable {
    func focusOnce(view: UIView, delay: DispatchTimeInterval? = nil) {
        guard !focusNoMore else { return }
        let focusClosure = { [weak self] in
            guard let self = self, !self.focusNoMore else { return }
            _ = view.becomeFirstResponder()
            self.focusNoMore = true
        }
        if let delay = delay {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: focusClosure)
        } else {
            DispatchQueue.main.async(execute: focusClosure)
        }
    }

    func cancelFocus() {
        self.focusNoMore = true
    }
}

#endif
