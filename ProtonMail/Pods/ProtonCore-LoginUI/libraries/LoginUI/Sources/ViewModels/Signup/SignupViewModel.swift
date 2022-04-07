//
//  SignupViewModel.swift
//  ProtonCore-Login - Created on 11/03/2021.
//
//  Copyright (c) 2019 Proton Technologies AG
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
import DeviceCheck
import ProtonCore_Challenge
import ProtonCore_Login
import ProtonCore_Services

class SignupViewModel {

    var apiService: PMAPIService
    var signupService: Signup
    var loginService: Login
    let challenge: PMChallenge
    let humanVerificationVersion: HumanVerificationVersion
    var signUpDomain: String { return loginService.signUpDomain }

    init(apiService: PMAPIService,
         signupService: Signup,
         loginService: Login,
         challenge: PMChallenge,
         humanVerificationVersion: HumanVerificationVersion) {
        self.apiService = apiService
        self.signupService = signupService
        self.loginService = loginService
        self.challenge = challenge
        self.humanVerificationVersion = humanVerificationVersion
    }

    func isUserNameValid(name: String) -> Bool {
        return !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func isEmailValid(email: String) -> Bool {
        guard !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        return email.isValidEmail()
    }

    func updateAvailableDomain(result: @escaping (String?) -> Void) {
        loginService.updateAvailableDomain(type: .signup, result: result)
    }

    func checkUserName(username: String, completion: @escaping (Result<(), AvailabilityError>) -> Void) {

        challenge.appendCheckedUsername(username)
        loginService.checkAvailability(username: username) { result in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func checkEmail(email: String, completion: @escaping (Result<(), AvailabilityError>) -> Void, editEmail: @escaping () -> Void) {
        loginService.checkAvailabilityExternal(email: email) { result in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                if error.codeInLogin == APIErrorCode.humanVerificationEditEmail {
                    // transform internal HV error to editEmail closure
                    editEmail()
                } else {
                    completion(.failure(error))
                }
            }
        }
    }

    func requestValidationToken(email: String, completion: @escaping (Result<Void, SignupError>) -> Void) {
        signupService.requestValidationToken(email: email, completion: completion)
    }
}
