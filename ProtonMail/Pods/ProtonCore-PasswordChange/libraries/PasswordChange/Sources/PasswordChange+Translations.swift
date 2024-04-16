//
//  PasswordChange+Translations.swift
//  ProtonCore-PasswordChange - Created on 27.03.2024.
//
//  Copyright (c) 2024 Proton Technologies AG
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
import ProtonCoreUtilities

private class Handler {}

public enum PCTranslation: TranslationsExposing {

    public static var bundle: Bundle {
        #if SPM
        return Bundle.module
        #else
        return Bundle(path: Bundle(for: Handler.self).path(forResource: "Translations-PasswordChange", ofType: "bundle")!)!
        #endif
    }

    public static var prefixForMissingValue: String = ""
    
    case settingsItem
    case accountPassword
    case currentPassword
    case newSignInPassword
    case confirmNewSignInPassword
    case newMailboxPassword
    case confirmNewMailboxPassword
    case passwordEmptyErrorDescription
    case passwordLeast8CharactersErrorDescription
    case passwordNotMatchErrorDescription
    case savePassword
    case passwordRecoveryButton
    case protonPasswordDescription

    case tfaTitle
    case tfaCode
    case enterDigitsCode
    case authenticate

    case errorInvalidUsername
    case errorInvalidModulusID
    case errorInvalidModulus
    case errorCantHashPassword
    case errorCantGenerateVerifier
    case errorCantGenerateSRPClient
    case errorKeyUpdateFailed
    case errorUpdatePasswordDefault

    public var l10n: String {
        switch self {
        case .settingsItem:
            return localized(key: "Account password", comment: "Settings item cell title")
        case .accountPassword:
            return localized(key: "Account password", comment: "Screen title")
        case .currentPassword:
            return localized(key: "Current sign-in password", comment: "TextField title")
        case .newSignInPassword:
            return localized(key: "New sign-in password", comment: "TextField title")
        case .confirmNewSignInPassword:
            return localized(key: "Confirm new sign-in password", comment: "TextField title")
        case .newMailboxPassword:
            return localized(key: "New mailbox password", comment: "TextField title")
        case .confirmNewMailboxPassword:
            return localized(key: "Confirm new mailbox password", comment: "TextField title")
        case .passwordEmptyErrorDescription:
            return localized(key: "Password cannot be empty", comment: "Textfield validation error")
        case .passwordLeast8CharactersErrorDescription:
            return localized(key: "Password must contain at least 8 characters", comment: "Textfield validation error")
        case .passwordNotMatchErrorDescription:
            return localized(key: "Password doesn't match", comment: "Textfield validation error")
        case .savePassword:
            return localized(key: "Save password", comment: "Action button")
        case .passwordRecoveryButton:
            return localized(key: "Don't know your current password?", comment: "Action button")
        case .protonPasswordDescription:
            return localized(key: "Proton's encryption technology means that nobody can access your password - not even us. Make sure you add a recovery method so that you can get back into your account if you forget your password. [Learn more](https://proton.me)", comment: "Password view description")
        case .tfaTitle:
            return localized(key: "Two-factor authentication", comment: "Screen title")
        case .tfaCode:
            return localized(key: "Two-factor code", comment: "Textfield title")
        case .enterDigitsCode:
            return localized(key: "Enter the 6-digit code.", comment: "Textfield footnote")
        case .authenticate:
            return localized(key: "Authenticate", comment: "Action button")
        case .errorInvalidUsername:
            return localized(key: "Invalid username!", comment: "Error message")
        case .errorInvalidModulusID:
            return localized(key: "Can't get a Modulus ID!", comment: "Error message")
        case .errorInvalidModulus:
            return localized(key: "Can't get a Modulus!", comment: "Error message")
        case .errorCantHashPassword:
            return localized(key: "Invalid hashed password!", comment: "Error message")
        case .errorCantGenerateVerifier:
            return localized(key: "Can't create an SRP verifier!", comment: "Error message")
        case .errorCantGenerateSRPClient:
            return localized(key: "Can't create an SRP Client", comment: "Error message")
        case .errorKeyUpdateFailed:
            return localized(key: "The private key update failed.", comment: "Error message")
        case .errorUpdatePasswordDefault:
            return localized(key: "Password update failed", comment: "Error message")
        }
    }
}
