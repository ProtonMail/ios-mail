//
//  ValidationError.swift
//  ProtonCore-Login - Created on 04/11/2020.
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
import ProtonCore_CoreTranslation
import ProtonCore_Foundations
import ProtonCore_UIFoundations

enum LoginValidationError: Error, Equatable {
    case emptyUsername
    case emptyPassword
}

extension LoginValidationError: CustomStringConvertible {
    var description: String {
        switch self {
        case .emptyUsername:
            return CoreString._ls_validation_invalid_username
        case .emptyPassword:
            return CoreString._ls_validation_invalid_password
        }
    }
}
