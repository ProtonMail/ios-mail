//
//  PasswordViewModel.swift
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
import ProtonCore_Login

class PasswordViewModel {

    func passwordValidationResult(for restrictions: SignupPasswordRestrictions,
                                  password: String,
                                  repeatParrword: String) -> (Result<(), SignupError>) {

        let passwordFailedRestrictions = restrictions.failedRestrictions(for: password)
        let repeatPasswordFailedRestrictions = restrictions.failedRestrictions(for: repeatParrword)

        if passwordFailedRestrictions.contains(.notEmpty) && repeatPasswordFailedRestrictions.contains(.notEmpty) {
            return .failure(SignupError.passwordEmpty)
        }

        // inform the user
        if passwordFailedRestrictions.contains(.atLeastEightCharactersLong)
            && repeatPasswordFailedRestrictions.contains(.notEmpty) {
            return .failure(SignupError.passwordShouldHaveAtLeastEightCharacters)
        }

        guard password == repeatParrword else {
            return .failure(SignupError.passwordNotEqual)
        }

        if passwordFailedRestrictions.contains(.atLeastEightCharactersLong)
            && repeatPasswordFailedRestrictions.contains(.atLeastEightCharactersLong) {
            return .failure(SignupError.passwordShouldHaveAtLeastEightCharacters)
        }

        return .success
    }
}
