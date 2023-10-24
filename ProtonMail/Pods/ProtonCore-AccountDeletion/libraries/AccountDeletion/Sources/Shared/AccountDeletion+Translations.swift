//
//  AccountDeletion+Translations.swift
//  ProtonCore-AccountDeletion - Created on 01.08.23.
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

public enum ADTranslation: TranslationsExposing {
    
    public static var bundle: Bundle {
        #if SPM
        return Bundle.module
        #else
        return Bundle(path: Bundle(for: Handler.self).path(forResource: "Translations-AccountDeletion", ofType: "bundle")!)!
        #endif
    }
    
    public static var prefixForMissingValue: String = ""
    
    case general_ok_action
    case delete_account_title
    case delete_account_button
    case delete_account_message
    case delete_account_success
    case delete_close_button
    case delete_network_error
    case api_might_be_blocked_button
    case api_might_be_blocked_message

    
    public var l10n: String {
        switch self {
        case .delete_account_title:
            return localized(key: "Delete account", comment: "Delete account screen title")
        case .delete_account_button:
            return localized(key: "Delete account", comment: "Delete account button title")
        case .delete_account_message:
            return localized(key: "This will permanently delete your account and all of its data. You will not be able to reactivate this account.", comment: "Delete account explaination under button")
        case .delete_account_success:
            return localized(key: "Account deleted.\nLogging out...", comment: "Delete account success")
        case .delete_close_button:
            return localized(key: "Close", comment: "Button title shown when a error has occured, causes the screen to close")
        case .general_ok_action:
            return localized(key: "OK", comment: "Action")
        case .delete_network_error:
            return localized(key: "A networking error has occured", comment: "A generic error message when we have no better message from the backend")
        case .api_might_be_blocked_button:
            return localized(key: "Troubleshoot", comment: "Button for the error banner shown when we suspect that the Proton servers are blocked")
        case .api_might_be_blocked_message:
            return localized(key: "The Proton servers are unreachable. It might be caused by wrong network configuration, Proton servers not working or Proton servers being blocked", comment: "Message shown when we suspect that the Proton servers are blocked")
        }
    }
}
