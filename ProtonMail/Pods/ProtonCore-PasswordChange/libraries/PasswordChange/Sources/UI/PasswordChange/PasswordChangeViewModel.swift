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
import ProtonCoreFeatureFlags
import ProtonCoreLog
import ProtonCoreLoginUI
import ProtonCoreNetworking
import ProtonCoreObservability
import ProtonCoreUIFoundations
import ProtonCoreUtilities
import ProtonCoreServices
import ProtonCoreAuthentication

public enum PasswordChangeViewError: Error {
    case passwordMinimumLength
    case passwordsNotEqual
}

extension PasswordChangeView {

    /// The `ObservableObject` that holds the model data for this View
    @MainActor
    public final class ViewModel: ObservableObject, PasswordValidator, PasswordChangeObservability {

        private let passwordChangeService: PasswordChangeService?
        private let authCredential: AuthCredential?
        private let userInfo: UserInfo?
        private var authInfo: AuthInfoResponse?
        private var passwordChangeCompletion: PasswordChangeCompletion?
        private let mode: PasswordChangeModule.PasswordChangeMode

        let showingDismissButton: Bool
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
            return userInfo.twoFactor > 0 &&
            authInfo?._2FA != nil
        }

        public init(
            mode: PasswordChangeModule.PasswordChangeMode,
            passwordChangeService: PasswordChangeService? = nil,
            authCredential: AuthCredential? = AuthCredential.none,
            userInfo: UserInfo? = .getDefault(),
            showingDismissButton: Bool,
            passwordChangeCompletion: PasswordChangeCompletion?
        ) {
            self.mode = mode
            self.passwordChangeService = passwordChangeService
            self.authCredential = authCredential
            self.userInfo = userInfo
            self.showingDismissButton = showingDismissButton
            self.passwordChangeCompletion = passwordChangeCompletion
            self.setupViews()
        }

        func setupViews() {
            currentPasswordFieldContent = .init(
                title: mode == .mailboxPassword ? PCTranslation.currentSignInPassword.l10n : PCTranslation.currentPassword.l10n,
                isSecureEntry: true,
                textContentType: .password
            )

            newPasswordFieldContent = .init(
                title: mode == .mailboxPassword ? PCTranslation.newMailboxPassword.l10n : PCTranslation.newPassword.l10n,
                isSecureEntry: true,
                textContentType: .newPassword
            )

            confirmNewPasswordFieldContent = .init(
                title: mode == .mailboxPassword ? PCTranslation.confirmNewMailboxPassword.l10n : PCTranslation.confirmNewPassword.l10n,
                isSecureEntry: true,
                textContentType: .newPassword
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

        func dismissView() {
            PasswordChangeModule.initialViewController?.dismiss(animated: true)
        }

        func savePasswordTapped() {
            Task { @MainActor in
                guard let authInfo = try? await self.passwordChangeService?.fetchAuthInfo() else {
                    bannerState = .error(content: .init(message: LUITranslation.unavailable_authinfo.l10n))
                    return
                }
                self.authInfo = authInfo
                do {
                    resetTextFieldsErrors()
                    try validate(
                        for: .default,
                        password: newPasswordFieldContent.text,
                        confirmPassword: confirmNewPasswordFieldContent.text
                    )
                    if needs2FA {
                        present2FAAndUpdatePassword()
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
        }

        private func present2FAAndUpdatePassword() {
            guard let twoFA = authInfo?._2FA else {
                PMLog.error("2FA mutated from under us.")
                return
            }
            let canUseFIDO2 = FeatureFlagsRepository.shared.isEnabled(CoreFeatureFlagType.fidoKeys) && twoFA.enabled.contains(.webAuthn)
            if twoFA.enabled.contains(.totp) && !canUseFIDO2 {
                showTOTP(twoFA: twoFA)
            } else if twoFA.enabled.contains(.totp) && canUseFIDO2, #available(iOS 15.0, *),
                      let authOptions = twoFA.FIDO2?.authenticationOptions  {
                showTwoFactorChoice(authenticationOptions: authOptions)

            } else if twoFA.enabled == .webAuthn && canUseFIDO2, #available(iOS 15.0, *),
                      let authOptions = twoFA.FIDO2?.authenticationOptions {
                showKeySignature(authenticationOptions: authOptions)
            }
        }

        private func showTOTP(twoFA: AuthInfoResponse.TwoFA) {
            let viewModel = PasswordChange2FAView.ViewModel(
                mode: mode,
                passwordChangeService: passwordChangeService,
                authCredential: authCredential,
                userInfo: userInfo,
                twoFA: twoFA,
                loginPassword: currentPasswordFieldContent.text,
                newPassword: newPasswordFieldContent.text,
                passwordChangeCompletion: passwordChangeCompletion
            )
            let viewController = UIHostingController(rootView: PasswordChange2FAView(viewModel: viewModel))
            viewController.view.backgroundColor = ColorProvider.BackgroundNorm
            PasswordChangeModule.initialViewController?.navigationController?.show(viewController, sender: self)
        }

        @available(iOS 15.0, *)
        private func showKeySignature(authenticationOptions: AuthenticationOptions) {
            let viewModel = makeFido2ViewModel(authenticationOptions: authenticationOptions)
            viewModel.delegate = self
            let fido2View = Fido2View(viewModel: viewModel)
            let fido2ViewController = Fido2ViewController(rootView: fido2View)
            PasswordChangeModule.initialViewController?.navigationController?.pushViewController(fido2ViewController, animated: true)
        }

        @available(iOS 15.0, *)
        func showTwoFactorChoice(authenticationOptions: AuthenticationOptions) {
            let fido2ViewModel = makeFido2ViewModel(authenticationOptions: authenticationOptions)
            fido2ViewModel.delegate = self
            let totpViewModel = TOTPView.ViewModel()
            totpViewModel.delegate = self

            let choose2FAView = Choose2FAView(totpViewModel: totpViewModel, fido2ViewModel: fido2ViewModel)
            let choose2FAViewController = Choose2FAViewController(rootView: choose2FAView)

            PasswordChangeModule.initialViewController?.navigationController?.pushViewController(choose2FAViewController, animated: true)
        }

        private func updatePassword(existingAuthInfo: AuthInfoResponse? = nil,
                                    twoFAParams: TwoFAParams? = nil) {
            guard let passwordChangeService, let authCredential, let userInfo else {
                PMLog.error("PasswordChangeService, AuthCredential and UserInfo are required")
                assertionFailure()
                return
            }
            Task { @MainActor in
                PasswordChangeModule.initialViewController?.lockUI()
                savePasswordIsLoading.toggle()
                do {
                    try await updatePasswordRequest(
                        passwordChangeService: passwordChangeService,
                        authCredential: authCredential,
                        userInfo: userInfo,
                        authInfo: existingAuthInfo,
                        twoFAParams: twoFAParams
                    )
                    observabilityPasswordChangeSuccess(mode: mode, twoFAMode: twoFAParams?.observabilityMode ?? .disabled)
                    passwordChangeCompletion?(authCredential, userInfo)
                } catch {
                    PMLog.error(error)
                    bannerState = .error(content: .init(message: error.localizedDescription))
                    observabilityPasswordChangeError(mode: mode, error: error, twoFAMode: twoFAParams?.observabilityMode ?? .disabled)
                }
                PasswordChangeModule.initialViewController?.unlockUI()
                savePasswordIsLoading = false
            }
        }

        private func updatePasswordRequest(
            passwordChangeService: PasswordChangeService,
            authCredential: AuthCredential,
            userInfo: UserInfo,
            authInfo: AuthInfoResponse? = nil,
            twoFAParams: TwoFAParams? = nil
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
                    authInfo: authInfo,
                    loginPassword: currentPasswordFieldContent.text,
                    newPassword: .init(value: newPasswordFieldContent.text),
                    twoFAParams: twoFAParams,
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

        @available(iOS 15.0, *)
        func makeFido2ViewModel(authenticationOptions: AuthenticationOptions) -> Fido2View.ViewModel {
            .init(authenticationOptions: authenticationOptions)
        }
    }
}

extension PasswordChangeView.ViewModel: TwoFAProviderDelegate {
    public func userDidGoBack() {
        dismissView()
    }

    public func providerDidObtain(factor: String) async throws {
        try await updatePasswordWith(twoFAParams: .totp(factor))
    }

    public func providerDidObtain(factor: ProtonCoreAuthentication.Fido2Signature) async throws {
        try await updatePasswordWith(twoFAParams: .fido2(factor))
    }

    private func updatePasswordWith(twoFAParams: TwoFAParams) async throws {
        await MainActor.run {
            PasswordChangeModule.initialViewController?.navigationController?.popViewController(animated: true)
        }
        guard let authInfo else {
            PMLog.error("Attempted to change password without authInfo.")
            throw UpdatePasswordError.missingAuthInfo
        }

        updatePassword(existingAuthInfo: authInfo, twoFAParams: twoFAParams)
    }

}
#endif
