//
//  PasswordChange2FAViewModel.swift
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
import ProtonCoreDataModel
import ProtonCoreLog
import ProtonCoreNetworking
import ProtonCoreObservability
import ProtonCoreUIFoundations
import UIKit

extension PasswordChange2FAView {

    /// The `ObservableObject` that holds the model data for this View
    @MainActor
    public final class ViewModel: ObservableObject, PasswordChangeObservability {

        private let passwordChangeService: PasswordChangeService?
        private let authCredential: AuthCredential?
        private let userInfo: UserInfo?
        private var passwordChangeCompletion: PasswordChangeCompletion?
        private let mode: PasswordChangeModule.PasswordChangeMode

        private let loginPassword: String
        private let newPassword: String

        @Published var tfaFieldContent: PCTextFieldContent!
        @Published var authenticateIsLoading = false

        @Published var bannerState: BannerState = .none

        public init(
            mode: PasswordChangeModule.PasswordChangeMode,
            passwordChangeService: PasswordChangeService? = nil,
            authCredential: AuthCredential? = AuthCredential.none,
            userInfo: UserInfo? = .getDefault(),
            loginPassword: String,
            newPassword: String,
            passwordChangeCompletion: PasswordChangeCompletion?
        ) {
            self.mode = mode
            self.passwordChangeService = passwordChangeService
            self.authCredential = authCredential
            self.userInfo = userInfo
            self.loginPassword = loginPassword
            self.newPassword = newPassword
            self.passwordChangeCompletion = passwordChangeCompletion
            self.setupViews()
        }

        func setupViews() {
            tfaFieldContent = .init(
                title: PCTranslation.tfaCode.l10n,
                footnote: PCTranslation.enterDigitsCode.l10n,
                keyboardType: .numberPad,
                textContentType: .oneTimeCode
            )
        }

        func authenticateTapped() {
            guard let passwordChangeService, let authCredential, let userInfo else {
                PMLog.error("PasswordChangeService, AuthCredential and UserInfo are required")
                assertionFailure()
                return
            }
            Task { @MainActor in
                PasswordChangeModule.initialViewController?.lockUI()
                do {
                    authenticateIsLoading = true
                    try await updatePasswordRequest(
                        passwordChangeService: passwordChangeService,
                        authCredential: authCredential,
                        userInfo: userInfo
                    )
                    observabilityPasswordChangeSuccess(mode: mode, twoFAEnabled: true)
                    passwordChangeCompletion?(authCredential, userInfo)
                } catch {
                    PMLog.error(error)
                    bannerState = .error(content: .init(message: error.localizedDescription))
                    observabilityPasswordChangeError(mode: mode, error: error, twoFAEnabled: true)
                }
                PasswordChangeModule.initialViewController?.unlockUI()
                authenticateIsLoading = false
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
                    loginPassword: loginPassword,
                    newPassword: .init(value: newPassword),
                    twoFACode: tfaFieldContent.text
                )
            case .singlePassword, .mailboxPassword:
                try await passwordChangeService.updateUserPassword(
                    auth: authCredential,
                    userInfo: userInfo,
                    loginPassword: loginPassword,
                    newPassword: .init(value: newPassword),
                    twoFACode: tfaFieldContent.text,
                    buildAuth: mode == .singlePassword ? true : false
                )
            }
        }
    }
}
#endif
