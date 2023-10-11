//
//  Service.swift
//  ProtonCore-Services - Created on 5/22/20.
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
import ProtonCoreUtilities

private class Handler {}

public enum SRTranslations: TranslationsExposing {
    
    public static var bundle: Bundle {
        #if SPM
        return Bundle.module
        #else
        return Bundle(path: Bundle(for: Handler.self).path(forResource: "Translations-Services", ofType: "bundle")!)!
        #endif
    }
    
    public static var prefixForMissingValue: String = ""
    
    case _core_external_accounts_address_required_popup_title
    case _core_external_accounts_update_required_popup_title
    case _core_api_might_be_blocked_message
    
    public var l10n: String {
        switch self {
        case ._core_external_accounts_address_required_popup_title:
            return localized(key: "Proton address required", comment: "External accounts address required popup title")
        case ._core_external_accounts_update_required_popup_title:
            return localized(key: "Update required", comment: "External accounts update required popup title")
        case ._core_api_might_be_blocked_message:
            return localized(key: "The Proton servers are unreachable. It might be caused by wrong network configuration, Proton servers not working or Proton servers being blocked", comment: "Message shown when we suspect that the Proton servers are blocked")
        }
    }
}
