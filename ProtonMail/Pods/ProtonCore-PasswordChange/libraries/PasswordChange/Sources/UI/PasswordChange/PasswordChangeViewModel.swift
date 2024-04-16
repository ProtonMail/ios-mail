//
//  PasswordChangeViewModel.swift
//  ProtonCore-PasswordChange - Created on 27.03.2024.
//
//  Copyright (c) 2024 Proton Technologies AG
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
import SwiftUI
import ProtonCoreDataModel
import ProtonCoreLog
import ProtonCoreNetworking
import ProtonCoreObservability
import ProtonCoreUIFoundations
import ProtonCoreUtilities

public enum PasswordChangeViewError: Error {
    case passwordMinimumLength
    case passwordsNotEqual
}

extension PasswordChangeView {

    /// The `ObservableObject` that holds the model data for this View
    @MainActor
    public final class ViewModel: ObservableObject, PasswordValidator {

        private let passwordChangeService: PasswordChangeService?
        private let authCredential: AuthCredential?
        private let userInfo: UserInfo?
        private var passwordChangeCompletion: PasswordChangeCompletion?
        private let mode: PasswordChangeModule.PasswordChangeMode

        @Published var currentPasswordFieldContent: PCTextFieldContent!
        @Published var newPasswordFieldContent: PCTextFieldContent!
        @Published var confirmNewPasswordFieldContent: PCTextFieldContent!
        @Published var currentPasswordFieldStyle: PCTextFieldStyle!
        @Published var newPasswordFieldStyle: PCTextFieldStyle!
        @Published var confirmNewPasswordFieldStyle: PCTextFieldStyle!
        @Published var savePasswordIsLoading = false

        @Published var bannerState: BannerState = .none

        var needs2FA: Bool {
            guard let userInfo else { return false }
            return userInfo.twoFactor > 0
        }

        public init(
            mode: PasswordChangeModule.PasswordChangeMode,
            passwordChangeService: PasswordChangeService? = nil,
            authCredential: AuthCredential? = AuthCredential.none,
            userInfo: UserInfo? = .getDefault(),
            passwordChangeCompletion: PasswordChangeCompletion?
        ) {
            self.mode = mode
            self.passwordChangeService = passwordChangeService
            self.authCredential = authCredential
            self.userInfo = userInfo
            self.passwordChangeCompletion = passwordChangeCompletion
            self.setupViews()
        }

        func setupViews() {
            currentPasswordFieldContent = .init(
                title: PCTranslation.currentPassword.l10n,
                isSecureEntry: true
            )

            newPasswordFieldContent = .init(
                title: mode == .mailboxPassword ? PCTranslation.newMailboxPassword.l10n : PCTranslation.newSignInPassword.l10n,
                isSecureEntry: true
            )

            confirmNewPasswordFieldContent = .init(
                title: mode == .mailboxPassword ? PCTranslation.confirmNewMailboxPassword.l10n : PCTranslation.confirmNewSignInPassword.l10n,
                isSecureEntry: true
            )

            newPasswordFieldStyle = .init(mode: .idle)
            currentPasswordFieldStyle = .init(mode: .idle)
            confirmNewPasswordFieldStyle = .init(mode: .idle)
        }

        var screenLoadObservabilityEvent: ScreenName {
            switch mode {
            case .singlePassword, .loginPassword: return .changePassword
            case .mailboxPassword: return .changeMailboxPassword
            }
        }

        func savePasswordTapped() {
            do {
                try validate(
                    for: .default,
                    password: newPasswordFieldContent.text,
                    confirmPassword: confirmNewPasswordFieldContent.text
                )
                if needs2FA {
                    present2FA()
                } else {
                    updatePassword()
                }
            } catch let error as PasswordValidationError {
                displayPasswordError(error: error)
            } catch {
                PMLog.error(error)
                bannerState = .error(content: .init(message: error.localizedDescription))
            }
        }

        private func present2FA() {
            let viewModel = PasswordChange2FAView.ViewModel(
                mode: mode,
                passwordChangeService: passwordChangeService,
                authCredential: authCredential,
                userInfo: userInfo,
                loginPassword: currentPasswordFieldContent.text,
                newPassword: newPasswordFieldContent.text, 
                passwordChangeCompletion: passwordChangeCompletion
            )
            let viewController = UIHostingController(rootView: PasswordChange2FAView(viewModel: viewModel))
            viewController.view.backgroundColor = ColorProvider.BackgroundNorm
            PasswordChangeModule.initialViewController?.navigationController?.show(viewController, sender: self)
        }

        private func updatePassword() {
            guard let passwordChangeService, let authCredential, let userInfo else {
                PMLog.error("PasswordChangeService, AuthCredential and UserInfo are required")
                assertionFailure()
                return
            }
            Task { @MainActor in
                PasswordChangeModule.initialViewController?.lockUI()
                savePasswordIsLoading.toggle()
                resetTextFieldsErrors()
                do {
                    try await updatePasswordRequest(
                        passwordChangeService: passwordChangeService,
                        authCredential: authCredential,
                        userInfo: userInfo
                    )
                    observabilityPasswordChangeSuccess()
                    passwordChangeCompletion?(authCredential, userInfo)
                } catch {
                    PMLog.error(error)
                    bannerState = .error(content: .init(message: error.localizedDescription))
                    observabilityPasswordChangeError(error: error)
                }
                PasswordChangeModule.initialViewController?.unlockUI()
                savePasswordIsLoading = false
            }
        }

        private func updatePasswordRequest(
            passwordChangeService: PasswordChangeService,
            authCredential: AuthCredential,
            userInfo: UserInfo
        ) async throws {
            switch mode {
            case .loginPassword:
                try await passwordChangeService.updateLoginPassword(
                    auth: authCredential,
                    userInfo: userInfo,
                    loginPassword: currentPasswordFieldContent.text,
                    newPassword: .init(value: newPasswordFieldContent.text),
                    twoFACode: nil
                )
            case .singlePassword, .mailboxPassword:
                try await passwordChangeService.updateUserPassword(
                    auth: authCredential,
                    userInfo: userInfo,
                    loginPassword: currentPasswordFieldContent.text,
                    newPassword: .init(value: newPasswordFieldContent.text),
                    twoFACode: nil,
                    buildAuth: mode == .singlePassword ? true : false
                )
            }
        }

        private func resetTextFieldsErrors() {
            newPasswordFieldContent.footnote = ""
            newPasswordFieldContent.footnote = ""
            confirmNewPasswordFieldContent.footnote = ""
            newPasswordFieldStyle.mode = .idle
            newPasswordFieldStyle.mode = .idle
            confirmNewPasswordFieldStyle.mode = .idle
        }

        private func displayPasswordError(error: PasswordValidationError) {
            switch error {
            case .passwordEmpty:
                newPasswordFieldStyle.mode = .error
                newPasswordFieldContent.footnote = PCTranslation.passwordEmptyErrorDescription.l10n
            case .passwordShouldHaveAtLeastEightCharacters:
                newPasswordFieldStyle.mode = .error
                newPasswordFieldContent.footnote = PCTranslation.passwordLeast8CharactersErrorDescription.l10n
            case .passwordNotEqual:
                confirmNewPasswordFieldStyle.mode = .error
                confirmNewPasswordFieldContent.footnote = PCTranslation.passwordNotMatchErrorDescription.l10n
            }
        }

        private func observabilityPasswordChangeSuccess() {
            switch mode {
            case .singlePassword, .loginPassword:
                ObservabilityEnv.report(.updateLoginPassword(status: .http2xx, twoFactorMode: .disabled))
            case .mailboxPassword:
                ObservabilityEnv.report(.updateMailboxPassword(status: .http2xx, twoFactorMode: .disabled))
            }
        }

        private func observabilityPasswordChangeError(error: Error) {
            switch mode {
            case .singlePassword, .loginPassword:
                ObservabilityEnv.report(.updateLoginPassword(status: .http2xx, twoFactorMode: .disabled))
            case .mailboxPassword:
                ObservabilityEnv.report(.updateMailboxPassword(status: .http2xx, twoFactorMode: .disabled))
            }
        }
    }
}
#endif
