//
//  VerifyCheckViewModel.swift
//  ProtonMail - Created on 20/01/21.
//
//
//  Copyright (c) 2021 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail iindexs distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.

import Foundation
import PMCommon
import PMCoreTranslation

class VerifyCheckViewModel: BaseTokenViewModel {

    func getTitle() -> String {
        switch method {
        case .sms:
            return String(format: CoreString._hv_verification_enter_sms_code, destination)
        case .email:
            return String(format: CoreString._hv_verification_enter_email_code, destination)
        default: return ""
        }
    }

    func isValidCodeFormat(code: String) -> Bool {
        return code.sixDigits()
    }

    func isInvalidVerificationCode(error: NSError) -> Bool {
        return error.code == 12087
    }

    func getMsg() -> String {
        return String(format: CoreString._hv_verification_sent_banner, destination)
    }

}
