//
//  VerifyViewModel.swift
//  ProtonCore-HumanVerification - Created on 20/01/21.
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

import Foundation
import ProtonCore_APIClient
import ProtonCore_Networking
import ProtonCore_Services

class VerifyViewModel {

    // MARK: - Private properties

    private var apiService: APIService

    // MARK: - Public properties and methods

    init(api: APIService) {
        self.apiService = api
    }

    func sendVerifyCode(method: VerifyMethod, destination: String, complete: @escaping SendResultCodeBlock) {
        let type: HumanVerificationToken.TokenType = method.predefinedMethod == .email ? .email : .sms
        let route = UserAPI.Router.code(type: type, receiver: destination)
        apiService.perform(request: route, response: Response()) { (_, response) in
            if response.responseCode != APIErrorCode.responseOK {
                complete(false, response.error)
            } else {
                complete(true, nil)
            }
        }
    }

    func isValidEmail(email: String) -> Bool {
        guard !email.isEmpty else { return false }
        return email.isValidEmail()
    }
}
