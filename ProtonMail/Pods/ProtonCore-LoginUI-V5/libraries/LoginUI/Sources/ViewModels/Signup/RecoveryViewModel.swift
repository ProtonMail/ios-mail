//
//  RecoveryViewModel.swift
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

import Foundation
import ProtonCore_Challenge
import ProtonCore_CoreTranslation
import ProtonCore_Login

class RecoveryViewModel {

    private let signupService: Signup
    let initialCountryCode: Int
    let challenge: PMChallenge

    init(signupService: Signup, initialCountryCode: Int, challenge: PMChallenge) {
        self.signupService = signupService
        self.initialCountryCode = initialCountryCode
        self.challenge = challenge
    }
    
    func isValidEmail(email: String) -> Bool {
        guard !email.isEmpty else { return false }
        return email.isValidEmail()
    }
    
    func validateEmailServerSide(email: String, completion: @escaping (Result<Void, SignupError>) -> Void) {
        signupService.validateEmailServerSide(email: email, completion: completion)
    }

    func isValidPhoneNumber(number: String) -> Bool {
        return !number.isEmpty
    }
    
    func validatePhoneNumberServerSide(number: String, completion: @escaping (Result<Void, SignupError>) -> Void) {
        signupService.validatePhoneNumberServerSide(number: number, completion: completion)
    }
    
    func termsAttributedString(textView: UITextView) -> NSAttributedString {
        var text = CoreString._su_recovery_t_c_desc
        let linkText = CoreString._su_recovery_t_c_link
        if ProcessInfo.processInfo.arguments.contains("RunningInUITests") {
            // Workaround for UI test automation to detect link in separated line
            let texts = text.components(separatedBy: linkText)
            if texts.count >= 2 {
                text = texts[0] + "\n" + linkText + texts[1]
            }
        }
        let attributedString = NSAttributedString.hyperlink(path: "", in: text, as: linkText, font: textView.font)
        return attributedString
    }
}
