//
//  PMTextField+TwoFactor.swift
//  ProtonCore-Login - Created on 01.12.2020.
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
import ProtonCoreUIFoundations

extension PMTextField {
    func set(mode: TwoFactorViewModel.Mode) {
        switch mode {
        case .twoFactorCode:
            title = LUITranslation.login_2fa_field_title.l10n
            keyboardType = .numberPad
            textContentType = .oneTimeCode
            assistiveText = LUITranslation.login_2fa_field_info.l10n
        case .recoveryCode:
            title = LUITranslation.login_2fa_recovery_field_title.l10n
            allowOnlyNumbers = false
            textContentType = .none
            keyboardType = .default
            assistiveText = LUITranslation.login_2fa_recovery_field_info.l10n
        }
        value = ""

        guard isFirstResponder else {
            return
        }

        DispatchQueue.main.async {
            _ = self.resignFirstResponder()
            DispatchQueue.main.async {
                _ = self.becomeFirstResponder()
            }
        }
    }
}

#endif
