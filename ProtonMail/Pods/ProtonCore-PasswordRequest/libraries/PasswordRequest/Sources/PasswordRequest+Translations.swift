//
//  PasswordVerifier.swift
//  ProtonCore-PasswordRequest - Created on 13.07.23.
//
//  Copyright (c) 2023 Proton Technologies AG
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
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore. If not, see https://www.gnu.org/licenses/.
//

import Foundation
import ProtonCoreUtilities

private class Handler {}

public enum PRTranslations: TranslationsExposing {

    public static var bundle: Bundle {
        #if SPM
        return Bundle.module
        #else
        return Bundle(path: Bundle(for: Handler.self).path(forResource: "Translations-PasswordRequest", ofType: "bundle")!)!
        #endif
    }

    public static var prefixForMissingValue: String = ""

    case validation_invalid_password
    case validation_enter_password
    case create_address_button_title
    case password_field_title

    public var l10n: String {
        switch self {
        case .validation_invalid_password:
            return localized(key: "Please enter your Proton Account password.", comment: "Invalid password hint")
        case .validation_enter_password:
            return localized(key: "Enter your password", comment: "Title of a page asking to enter your password.")
        case .create_address_button_title:
            return localized(key: "Continue", comment: "Action button title for picking Proton Mail username")
        case .password_field_title:
            return localized(key: "Password", comment: "Password field title")
        }
    }
}
