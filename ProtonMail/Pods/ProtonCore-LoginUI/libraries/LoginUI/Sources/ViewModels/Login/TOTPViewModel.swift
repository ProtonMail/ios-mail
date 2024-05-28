//
//  TOTPViewModel.swift
//  ProtonCore-LoginUI - Created on 8/5/24.
//
//  Copyright (c) 2024 Proton AG
//
//  This file is part of ProtonCore.
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

#if os(iOS)

import Foundation
import ProtonCoreUIFoundations
import ProtonCoreLogin
import ProtonCoreLog
import SwiftUI

extension TOTPView {
    @MainActor
    class ViewModel: ObservableObject {
        @Published var tfaFieldContent: PCTextFieldContent!
        @Published var bannerState: BannerState = .none
        weak var delegate: TwoFactorViewControllerDelegate?
        @Published var isLoading = false

        private let login: Login

        init(login: Login) {
            self.login = login

            tfaFieldContent = .init(
                title: LUITranslation.login_2fa_2fa_button_title.l10n,
                footnote: LUITranslation.login_2fa_field_info.l10n,
                keyboardType: .numberPad,
                textContentType: .oneTimeCode
            )
        }

        func startValidation() {
            isLoading = true
            let code = tfaFieldContent.text
            login.provide2FACode(code) { [weak self] result in
                self?.isLoading = false
                switch result {
                case let .failure(error): self?.bannerState = .error(content: .init(message: error.userFacingMessageInLogin))
                case let .success(status):
                    switch status {
                    case let .finished(data):
                        self?.delegate?.twoFactorViewControllerDidFinish(data: data) { }
                    case let .chooseInternalUsernameAndCreateInternalAddress(data):
                        self?.login.availableUsernameForExternalAccountEmail(email: data.email) { [weak self] username in
                            self?.delegate?.createAddressNeeded(data: data, defaultUsername: username)
                        }
                    case .askTOTP, .askAny2FA, .askFIDO2:
                        PMLog.error("Asking for 2FA validation after successful 2FA validation is an invalid state", sendToExternal: true)
                        self?.bannerState = .error(content: .init(message: LUITranslation.twofa_invalid_state_banner.l10n))
                    case .askSecondPassword:
                        self?.delegate?.mailboxPasswordNeeded()
                    case .ssoChallenge:
                        PMLog.error("Receiving SSO challenge after successful 2FA code is an invalid state", sendToExternal: true)
                        self?.bannerState = .error(content: .init(message: LUITranslation.twofa_invalid_state_banner.l10n))
                    }
                }
            }
        }
    }
}

#endif
