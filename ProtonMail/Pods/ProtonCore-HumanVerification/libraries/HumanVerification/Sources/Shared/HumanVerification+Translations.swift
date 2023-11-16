//
//  HumanVerification+Translations.swift
//  ProtonCore-HumanVerification - Created on 01/08/23.
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
#if canImport(ProtonCoreHumanVerificationResourcesiOS)
import ProtonCoreHumanVerificationResourcesiOS
#endif
#if canImport(ProtonCoreHumanVerificationResourcesmacOS)
import ProtonCoreHumanVerificationResourcesmacOS
#endif

private class Handler {}

public enum HVTranslation: TranslationsExposing {

    public static var bundle: Bundle {
        #if SPM
        return spmResourcesBundle
        #else
        return Bundle(path: Bundle(for: Handler.self).path(forResource: "Translations-HumanVerification", ofType: "bundle")!)!
        #endif
    }

    public static var prefixForMissingValue: String = ""

    case delete_network_error
    case help_button
    case ok_button
    case title
    case help_header
    case help_request_item_title
    case help_visit_item_title
    case help_request_item_message
    case help_visit_item_message
    case captha_method_name
    case sms_method_name
    case email_method_name
    case email_verification_button
    case verification_code
    case verification_verify_button

    public var l10n: String {
        switch self {
        case .delete_network_error:
            return localized(key: "A networking error has occured", comment: "A generic error message when we have no better message from the backend")
        case .help_button:
            return localized(key: "Help", comment: "Help button")
        case .ok_button:
            return localized(key: "OK", comment: "OK button")
        case .title:
            return localized(key: "Human Verification", comment: "Title")
        case .help_header:
            return localized(key: "Need help with human verification?", comment: "help header title")
        case .help_request_item_title:
            return localized(key: "Request an invite", comment: "request item title")
        case .help_visit_item_title:
            return localized(key: "Visit our Help Center", comment: "visit item title")
        case .help_request_item_message:
            return localized(key: "If you are having trouble creating your account, please request an invitation and we will respond within 1 business day.", comment: "request item message")
        case .help_visit_item_message:
            return localized(key: "Learn more about human verification and why we ask for it.", comment: "visit item message")
        case .captha_method_name:
            return localized(key: "CAPTCHA", comment: "captha method name")
        case .sms_method_name:
            return localized(key: "SMS", comment: "SMS method name")
        case .email_method_name:
            return localized(key: "Email", comment: "email method name")
        case .email_verification_button:
            return localized(key: "Get verification code", comment: "Verification button")
        case .verification_code:
            return localized(key: "Verification code", comment: "Verification code label")
        case .verification_verify_button:
            return localized(key: "Verify", comment: "Verify button")
        }
    }
}
