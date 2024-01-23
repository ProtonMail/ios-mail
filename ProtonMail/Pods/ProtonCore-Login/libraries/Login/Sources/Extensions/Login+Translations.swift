//
//  Login+Translations.swift
//  ProtonCoreLogin - Created on 01/08/2023.
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

public enum LSTranslation: TranslationsExposing {

    public static var bundle: Bundle {
        #if SPM
        return Bundle.module
        #else
        return Bundle(path: Bundle(for: Handler.self).path(forResource: "Translations-Login", ofType: "bundle")!)!
        #endif
    }

    public static var prefixForMissingValue: String = ""

    case _loginservice_api_might_be_blocked_message
    case _loginservice_error_generic
    case _loginservice_external_accounts_not_supported_popup_local_desc
    case _loginservice_external_accounts_address_required_popup_title

    public var l10n: String {
        switch self {
        case ._loginservice_api_might_be_blocked_message:
            return localized(key: "The Proton servers are unreachable. It might be caused by wrong network configuration, Proton servers not working or Proton servers being blocked", comment: "Message shown when we suspect that the Proton servers are blocked")
        case ._loginservice_error_generic:
            return localized(key: "An error has occured", comment: "Generic error message when no better error can be displayed")
        case ._loginservice_external_accounts_not_supported_popup_local_desc:
            return localized(key: "Get a Proton Mail address linked to this account in your Proton web settings.", comment: "External accounts not supported popup local desc")
        case ._loginservice_external_accounts_address_required_popup_title:
            return localized(key: "Proton address required", comment: "External accounts address required popup title")
        }
    }
}
