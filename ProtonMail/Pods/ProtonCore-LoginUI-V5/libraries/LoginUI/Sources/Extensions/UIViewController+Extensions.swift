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

import Foundation
import UIKit
import ProtonCore_CoreTranslation
import ProtonCore_Login
import ProtonCore_UIFoundations

extension UIViewController {
    func showBanner(message: String, style: PMBannerNewStyle = .error, button: String? = nil, action: (() -> Void)? = nil, position: PMBannerPosition) {
        unlockUI()
        let banner = PMBanner(message: message, style: style, dismissDuration: Double.infinity)
        banner.addButton(text: button ?? CoreString._hv_ok_button) { _ in
            action?()
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
            showBanner(message: message, button: CoreString._net_api_might_be_blocked_button) { [weak self] in
                self?.onDohTroubleshooting()
            }
        case .externalAccountsNotSupported(let message, _):
            let alert = UIAlertController(title: CoreString._ls_external_eccounts_not_supported_popup_title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: CoreString._ls_external_eccounts_not_supported_popup_action_button, style: .default) { [weak self] _ in
                self?.onLearnMoreAboutExternalAccountsNotSupported()
            })
            alert.addAction(UIAlertAction(title: CoreString._hv_cancel_button, style: .cancel, handler: nil))
            present(alert, animated: true)
        case .invalidSecondPassword:
            showBanner(message: CoreString._ls_error_invalid_mailbox_password)
        case .invalidState:
            showBanner(message: CoreString._ls_error_generic)
        case .missingKeys:
            let alert = UIAlertController(title: CoreString._ls_error_missing_keys_title, message: CoreString._ls_error_missing_keys_text, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: CoreString._ls_error_missing_keys_text_button, style: .default) { [weak self] _ in
                self?.onUserAccountSetupNeeded()
            })
            alert.addAction(UIAlertAction(title: CoreString._hv_cancel_button, style: .cancel, handler: nil))
            present(alert, animated: true)
        case .needsFirstTimePasswordChange:
            let alert = UIAlertController(title: CoreString._login_username_org_dialog_title, message: CoreString._login_username_org_dialog_message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: CoreString._login_username_org_dialog_action_button, style: .default) { [weak self] _ in
                self?.onFirstPasswordChangeNeeded()
            })
            alert.addAction(UIAlertAction(title: CoreString._hv_cancel_button, style: .cancel, handler: nil))
            present(alert, animated: true)
        case .emailAddressAlreadyUsed:
            showBanner(message: CoreString._su_error_email_already_used)
        case .missingSubUserConfiguration:
            showBanner(message: CoreString._su_error_missing_sub_user_configuration)
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
            showBanner(message: CoreString._su_error_invalid_token_request)
        case .invalidVerificationCode(let message):
            invalidVerificationCodeAlert(title: message)
        case .validationToken:
            showBanner(message: CoreString._su_error_invalid_token)
        case .randomBits:
            showBanner(message: CoreString._su_error_create_user_failed)
        case .cantHashPassword:
            showBanner(message: CoreString._su_error_invalid_hashed_password)
        case .passwordEmpty:
            showBanner(message: CoreString._su_error_password_empty)
            self.invalidPassword(reason: .notFulfilling(.notEmpty))
        case .passwordShouldHaveAtLeastEightCharacters:
            showBanner(message: String(format: CoreString._su_error_password_too_short, NSNumber(8)))
            self.invalidPassword(reason: .notFulfilling(.atLeastEightCharactersLong))
        case .passwordNotEqual:
            showBanner(message: CoreString._su_error_password_not_equal)
            self.invalidPassword(reason: .notEqual)
        case let .generic(message: message, _, _):
            showBanner(message: message)
        case let .apiMightBeBlocked(message, _):
            showBanner(message: message, button: CoreString._net_api_might_be_blocked_button) { [weak self] in
                self?.onDohTroubleshooting()
            }
        case .generateVerifier:
            showBanner(message: CoreString._su_error_create_user_failed)
        case .unknown:
            showBanner(message: CoreString._error_occured)
        }
    }

    private func invalidVerificationCodeAlert(title: String) {
        self.invalidVerificationCode(reason: .enter)
        let message = CoreString._su_invalid_verification_alert_message

        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let resendAction = UIAlertAction(title: CoreString._hv_verification_error_alert_resend, style: .default, handler: { _ in
            self.invalidVerificationCode(reason: .resend)
        })
        resendAction.accessibilityLabel = "resendButton"
        alert.addAction(resendAction)
        let changeEmailAction = UIAlertAction(title: CoreString._su_invalid_verification_change_email_button, style: .default, handler: { _ in
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
