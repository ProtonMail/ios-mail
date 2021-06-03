//
//  PMTextField+TwoFactor.swift
//  PMLogin - Created on 01.12.2020.
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
import ProtonCore_CoreTranslation
import ProtonCore_UIFoundations

extension PMTextField {
    func set(mode: TwoFactorViewModel.Mode) {
        switch mode {
        case .twoFactorCode:
            title = CoreString._ls_login_2fa_field_title
            keyboardType = .numberPad
            if #available(iOS 12.0, *) {
                textContentType = .oneTimeCode
            }
            assistiveText = CoreString._ls_login_2fa_field_info
        case .recoveryCode:
            title = CoreString._ls_login_2fa_recovery_field_title
            allowOnlyNumbers = false
            textContentType = .none
            keyboardType = .default
            assistiveText = CoreString._ls_login_2fa_recovery_field_info
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
