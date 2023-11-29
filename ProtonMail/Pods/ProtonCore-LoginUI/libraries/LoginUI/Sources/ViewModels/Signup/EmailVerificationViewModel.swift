//
//  EmailVerificationViewModel.swift
//  ProtonCore-Login - Created on 11/03/2021.
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
import ProtonCoreLogin
import ProtonCoreServices

class EmailVerificationViewModel {

    var signupService: Signup
    var email: String?

    init(signupService: Signup) {
        self.signupService = signupService
    }

    func isValidCodeFormat(code: String) -> Bool {
        return !code.isEmpty && code.count == 6
    }

    func checkValidationToken(email: String, token: String, completion: @escaping (Result<Void, SignupError>) -> Void) {
        signupService.checkValidationToken(email: email, token: token, completion: completion)
    }

    func requestValidationToken(completion: @escaping (Result<Void, SignupError>) -> Void) {
        guard let email = email else { return }
        signupService.requestValidationToken(email: email, completion: completion)
    }

    func getResendMessage() -> String? {
        guard let email = email else { return nil }
        return String(format: LUITranslation.verification_sent_banner.l10n, email)
    }
}

#endif
