//
//  RecoveryViewModel.swift
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
import ProtonCore_Challenge
import ProtonCore_CoreTranslation

class RecoveryViewModel {

    let initialCountryCode: Int
    let challenge: PMChallenge

    init(initialCountryCode: Int, challenge: PMChallenge) {
        self.initialCountryCode = initialCountryCode
        self.challenge = challenge
    }

    func isValidEmail(email: String) -> Bool {
        guard !email.isEmpty else { return false }
        return email.isValidEmail()
    }

    func isValidPhoneNumber(number: String) -> Bool {
        return !number.isEmpty
    }
    
    func termsAttributedString(textView: UITextView) -> NSAttributedString {
        var text = CoreString._su_recovery_t_c_desc
        let linkText = CoreString._su_recovery_t_c_link
        if ProcessInfo.processInfo.arguments.contains("testMode") {
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
