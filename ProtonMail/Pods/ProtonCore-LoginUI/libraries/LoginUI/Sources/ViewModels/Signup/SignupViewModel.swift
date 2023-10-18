//
//  SignupViewModel.swift
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
import DeviceCheck
import ProtonCoreChallenge
import ProtonCoreLogin
import ProtonCoreServices

class SignupViewModel {

    var signupService: Signup
    var loginService: Login
    let challenge: PMChallenge
    var currentlyChosenSignUpDomain: String {
        get { loginService.currentlyChosenSignUpDomain }
        set { loginService.currentlyChosenSignUpDomain = newValue }
    }
    var allSignUpDomains: [String] { loginService.allSignUpDomains }

    init(signupService: Signup,
         loginService: Login,
         challenge: PMChallenge) {
        self.signupService = signupService
        self.loginService = loginService
        self.challenge = challenge
    }

    func isUserNameValid(name: String) -> Bool {
        return !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func isEmailValid(email: String) -> Bool {
        guard !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        return email.isValidEmail()
    }

    func updateAvailableDomain(result: @escaping ([String]?) -> Void) {
        loginService.updateAllAvailableDomains(type: .signup, result: result)
    }

    func checkUsernameAccount(username: String, completion: @escaping (Result<(), AvailabilityError>) -> Void) {
        challenge.appendCheckedUsername(username)
        loginService.checkAvailabilityForUsernameAccount(username: username, completion: completion)
    }
    
    func checkExternalEmailAccount(
        email: String,
        completion: @escaping (Result<(), AvailabilityError>) -> Void,
        editEmail: @escaping () -> Void,
        protonDomainUsedForExternalAccount: @escaping (String) -> Void
    ) {
        loginService.checkAvailabilityForExternalAccount(email: email) { [weak self] result in
            switch result {
            case .failure(.protonDomainUsedForExternalAccount(let username, let domain, _)):
                self?.currentlyChosenSignUpDomain = domain
                protonDomainUsedForExternalAccount(username)
            case .failure(let error) where error.codeInLogin == APIErrorCode.humanVerificationEditEmail:
                editEmail()
            case .success, .failure:
                completion(result)
            }
        }
    }
    
    func checkInternalAccount(username: String, completion: @escaping (Result<(), AvailabilityError>) -> Void) {
        challenge.appendCheckedUsername(username)
        loginService.checkAvailabilityForInternalAccount(username: username, completion: completion)
    }

    func requestValidationToken(email: String, completion: @escaping (Result<Void, SignupError>) -> Void) {
        signupService.requestValidationToken(email: email, completion: completion)
    }
}

#endif
