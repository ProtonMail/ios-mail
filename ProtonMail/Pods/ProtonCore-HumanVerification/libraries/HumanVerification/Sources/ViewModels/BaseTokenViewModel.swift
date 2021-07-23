//
//  BaseTokenViewModel.swift
//  ProtonCore-HumanVerification - Created on 20/01/21.
//
//  Copyright (c) 2021 Proton Technologies AG
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
import ProtonCore_Networking
import ProtonCore_Services

struct TokenType {
    let destination: String?
    let verifyMethod: VerifyMethod?
    let token: String?
}

class BaseTokenViewModel {

    // MARK: - Private properties

    private var token: String?
    private var tokenMethod: VerifyMethod?

    // MARK: - Public properties and methods

    let apiService: APIService
    var method: VerifyMethod = .captcha
    var destination: String = ""
    var onVerificationCodeBlock: ((@escaping SendVerificationCodeBlock) -> Void)?

    init(api: APIService) {
        self.apiService = api
    }

    func finalToken(token: String, complete: @escaping SendVerificationCodeBlock) {
        self.token = token
        self.tokenMethod = self.method
        onVerificationCodeBlock?({ (res, error, finish) in
            complete(res, error, finish)
        })
    }

    func getToken() -> TokenType {
        return TokenType(destination: self.destination, verifyMethod: tokenMethod, token: token)
    }
}
