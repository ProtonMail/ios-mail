//
//  AccountSwitcher+Translations.swift
//  ProtonCore-AccountSwitcher - Created on 01.08.2023
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
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore.  If not, see <https://www.gnu.org/licenses/>.

import Foundation
import ProtonCoreUtilities

private class Handler {}

public enum ASTranslation: TranslationsExposing {
    
    public static var bundle: Bundle {
        #if SPM
        return Bundle.module
        #else
        return Bundle(path: Bundle(for: Handler.self).path(forResource: "Translations-AccountSwitcher", ofType: "bundle")!)!
        #endif
    }
    
    public static var prefixForMissingValue: String = ""
    
    case switch_to_title
    case manage_accounts
    case signed_in_to_protonmail
    case signed_out_of_protonmail
    case signout
    case remove_button
    case remove_account_from_this_device
    case remove_account
    case remove_account_alert_text
    case signout_alert_text
    case dismiss_button
    case sign_in_button
    case cancel_button
    case sign_in_screen_title
    
    public var l10n: String {
        switch self {
        case .switch_to_title:
            return localized(key: "switch to", comment: "Section title of account switcher")
        case .manage_accounts:
            return localized(key: "Manage accounts", comment: "Manage accounts button")
        case .signed_in_to_protonmail:
            return localized(key: "Signed in to Proton Mail", comment: "Section title of account manager")
        case .signed_out_of_protonmail:
            return localized(key: "Signed out of Proton Mail", comment: "Section title of account manager")
        case .signout:
            return localized(key: "Sign out", comment: "Sign out button/ title")
        case .remove_button:
            return localized(key: "Remove", comment: "Remove button")
        case .remove_account_from_this_device:
            return localized(key: "Remove account from this device", value: ASTranslation.remove_button.l10n, comment: "remove account button in account manager")
        case .remove_account:
            return localized(key: "Remove account", comment: "old value of remove account button in account manager")
        case .remove_account_alert_text:
            return localized(key: "You will be signed out and all the data associated with this account will be removed from this device.", comment: "Alert message of remove account")
        case .signout_alert_text:
            return localized(key: "Are you sure you want to sign out %@?", comment: "Alert message of sign out the email address")
        case .dismiss_button:
            return localized(key: "Dismiss account switcher", comment: "Button for dismissing account switcher")
        case .sign_in_button:
            return localized(key: "Sign in to another account", comment: "Button for signing into another account")
        case .cancel_button:
            return localized(key: "Cancel", comment: "Cancel button")
        case .sign_in_screen_title:
            return localized(key: "Sign in", comment: "Login screen title")
        }
    }
}
