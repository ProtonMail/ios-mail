//
//  VerifyCheckViewModel.swift
//  ProtonCore-HumanVerification - Created on 20/01/21.
//
//  Copyright (c) 2020 Proton Technologies AG
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
import ProtonCore_CoreTranslation
import ProtonCore_Networking
import ProtonCore_Utilities

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

    func isInvalidVerificationCode(error: ResponseError) -> Bool {
        return error.responseCode == 12087
    }

    func getMsg() -> String {
        return String(format: CoreString._hv_verification_sent_banner, destination)
    }

}
