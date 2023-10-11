//
//  ValidationError.swift
//  ProtonCore-Login - Created on 04/11/2020.
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
import ProtonCoreFoundations
import ProtonCoreUIFoundations

enum LoginValidationError: Error, Equatable {
    case emptyUsername
    case emptyPassword
}

extension LoginValidationError: CustomStringConvertible {
    var description: String {
        switch self {
        case .emptyUsername:
            return LUITranslation.validation_invalid_username.l10n
        case .emptyPassword:
            return LUITranslation._core_validation_invalid_password.l10n
        }
    }
}

#endif
