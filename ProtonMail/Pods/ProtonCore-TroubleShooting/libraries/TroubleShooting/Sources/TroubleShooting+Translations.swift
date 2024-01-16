//
//  TroubleShooting+Translations.swift
//  ProtonCore-TroubleShooting - Created on 01/08/2023
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

public enum TSTranslation: TranslationsExposing {

    public static var bundle: Bundle {
        #if SPM
        return Bundle.module
        #else
        return Bundle(path: Bundle(for: Handler.self).path(forResource: "Translations-TroubleShooting", ofType: "bundle")!)!
        #endif
    }

    public static var prefixForMissingValue: String = ""

    case _troubleshooting_title
    case _allow_alternative_routing
    case _no_internet_connection
    case _isp_problem
    case _gov_block
    case _antivirus_interference
    case _firewall_interference
    case _proton_is_down
    case _no_solution
    case _allow_alternative_routing_description
    case _allow_alternative_routing_action_title
    case _no_internet_connection_description
    case _isp_problem_description
    case _gov_block_description
    case _antivirus_interference_description
    case _firewall_interference_description
    case _proton_is_down_description
    case _proton_is_down_action_title
    case _no_solution_description
    case _troubleshooting_support_from
    case _troubleshooting_email_title
    case _troubleshooting_twitter_title
    case _troubleshoot_support_subject
    case _troubleshoot_support_body
    case _general_back_action

    public var l10n: String {
        switch self {
        case ._troubleshooting_title:
            return localized(key: "Troubleshooting", comment: "Network troubleshooting view title")
        case ._allow_alternative_routing:
            return localized(key: "Allow alternative routing", comment: "Network troubleshooting cell title")
        case ._no_internet_connection:
            return localized(key: "No internet connection", comment: "Network troubleshooting cell title")
        case ._isp_problem:
            return localized(key: "Internet Service Provider (ISP) problem", comment: "Network troubleshooting cell title")
        case ._gov_block:
            return localized(key: "Government block", comment: "Network troubleshooting cell title")
        case ._antivirus_interference:
            return localized(key: "Antivirus interference", comment: "Network troubleshooting cell title")
        case ._firewall_interference:
            return localized(key: "Proxy/Firewall interference", comment: "Network troubleshooting cell title")
        case ._proton_is_down:
            return localized(key: "Proton is down", comment: "Network troubleshooting cell title")
        case ._no_solution:
            return localized(key: "Still can't find a solution", comment: "Network troubleshooting cell title shown after all other troubleshooing ideas.")
        case ._allow_alternative_routing_description:
            return localized(key: "In case Proton sites are blocked, this setting allows the app to try alternative network routing to reach Proton, which can be useful for bypassing firewalls or network issues. We recommend keeping this setting on for greater reliability. %1$@", comment: "alternative routing description")
        case ._allow_alternative_routing_action_title:
            return localized(key: "Learn more", comment: "alternative routing link name in description")
        case ._no_internet_connection_description:
            return localized(key: "Please make sure that your internet connection is working.", comment: "no internet connection description")
        case ._isp_problem_description:
            return localized(key: "Try connecting to Proton from a different network (or use %1$@ or %2$@).", comment: "ISP problem description")
        case ._gov_block_description:
            return localized(key: "Your country may be blocking access to Proton. Try using %1$@ (or any other VPN) or %2$@ to access Proton.", comment: "Goverment blocking description")
        case ._antivirus_interference_description:
            return localized(key: "Temporarily disable or remove your antivirus software.", comment: "Antivirus interference description.")
        case ._firewall_interference_description:
            return localized(key: "Disable any proxies or firewalls, or contact your network administrator.", comment: "Firewall interference description.")
        case ._proton_is_down_description:
            return localized(key: "Check Proton Status for our system status.", comment: "Proton is down description.")
        case ._proton_is_down_action_title:
            return localized(key: "Proton Status", comment: "Name of the link of Proton Status")
        case ._no_solution_description:
            return localized(key: "Contact us directly through our support form, email (support@protonmail.zendesk.com), or Twitter.", comment: "No other solution description.")
        case ._troubleshooting_support_from:
            return localized(key: "support form", comment: "Hyperlink text linking to the support form")
        case ._troubleshooting_email_title:
            return localized(key: "email", comment: "Hyperlink text that will open an email editor")
        case ._troubleshooting_twitter_title:
            return localized(key: "Twitter", comment: "Hyperlink text that will link to Proton's twitter page")
        case ._troubleshoot_support_subject:
            return localized(key: "Subject...", comment: "The subject of the email draft created in the network troubleshoot view.")
        case ._troubleshoot_support_body:
            return localized(key: "Please share your problem.", comment: "The body of the email draft created in the network troubleshoot view.")
        case ._general_back_action:
            return localized(key: "Back", comment: "top left back button")
        }
    }

}
