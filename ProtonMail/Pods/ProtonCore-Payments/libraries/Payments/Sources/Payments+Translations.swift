//
//  Payments+Translations.swift
//  ProtonCore-Payments - Created on 01/08/2023.
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

public enum PSTranslation: TranslationsExposing {

    public static var bundle: Bundle {
        #if SPM
        return Bundle.module
        #else
        return Bundle(path: Bundle(for: Handler.self).path(forResource: "Translations-Payments", ofType: "bundle")!)!
        #endif
    }

    public static var prefixForMissingValue: String = ""

    case _core_general_ok_action
    case _core_retry
    case _core_api_might_be_blocked_message
    case _error_apply_payment_on_registration_support
    case _error_unavailable_product
    case _error_invalid_purchase
    case _error_receipt_lost
    case _error_another_user_transaction
    case _error_backend_mismatch
    case _error_no_active_username_in_user_data_service
    case _error_transaction_failed_by_unknown_reason
    case _error_no_new_subscription_in_response
    case _error_unlock_to_proceed_with_iap
    case _error_please_sign_in_iap
    case _error_wrong_token_status
    case do_you_want_to_bypass_validation
    case yes_bypass_validation
    case no_dont_bypass_validation
    case popup_credits_applied_message
    case popup_credits_applied_confirmation
    case popup_credits_applied_cancellation
    case error_apply_payment_on_registration_title
    case error_apply_payment_on_registration_message

    public var l10n: String {
        switch self {
        case ._core_general_ok_action:
            return localized(key: "OK", comment: "Action")
        case ._core_retry:
            return localized(key: "Retry", comment: "Button in some alerts")
        case ._core_api_might_be_blocked_message:
            return localized(key: "The Proton servers are unreachable. It might be caused by wrong network configuration, Proton servers not working or Proton servers being blocked", comment: "Message shown when we suspect that the Proton servers are blocked")
        case ._error_apply_payment_on_registration_support:
            return localized(key: "Contact customer support", comment: "Error applying credit after registration alert")
        case ._error_unavailable_product:
            return localized(key: "Failed to get list of available products from App Store.", comment: "Error message")
        case ._error_invalid_purchase:
            return localized(key: "Purchase is not possible.", comment: "Error message")
        case ._error_receipt_lost:
            return localized(key: "Apple informed us you've upgraded the service plan, but some technical data was missing. Please fill in the bug report and our customer support team will contact you.", comment: "Error message")
        case ._error_another_user_transaction:
            return localized(key: "Apple informed us you've upgraded the service plan, but we detected you have logged out of the account since then.", comment: "Error message")
        case ._error_backend_mismatch:
            return localized(key: "It wasn't possible to match your purchased App Store product to any products on our server. Please fill in the bug report and our customer support team will contact you.", comment: "Error message")
        case ._error_no_active_username_in_user_data_service:
            return localized(key: "Please log in to the Proton Mail account you're upgrading the service plan for so we can complete the purchase.", comment: "Error message")
        case ._error_transaction_failed_by_unknown_reason:
            return localized(key: "Apple informed us they could not process the purchase.", comment: "Error message")
        case ._error_no_new_subscription_in_response:
            return localized(key: "We have successfully activated your subscription. Please relaunch the app to start using your new service plan.", comment: "Error message")
        case ._error_unlock_to_proceed_with_iap:
            return localized(key: "Please unlock the app to proceed with your service plan activation", comment: "Error message")
        case ._error_please_sign_in_iap:
            return localized(key: "Please log in to the Proton Mail account you're upgrading the service plan for so we can complete the service plan activation.", comment: "Error message")
        case ._error_wrong_token_status:
            return localized(key: "Wrong payment token status. Please relaunch the app. If error persists, contact support.", comment: "In App Purchase error")
        case .do_you_want_to_bypass_validation:
            return localized(key: "Do you want to activate the purchase for %@ address?", comment: "Question is user wants to bypass username validation and activate plan for current username")
        case .yes_bypass_validation:
            return localized(key: "Yes, activate it for ", comment: "Warning message option to bypass validation and activate plan for current username")
        case .no_dont_bypass_validation:
            return localized(key: "No, for another Proton Mail account", comment: "Warning message option when user want to relogin to another account")
        case .popup_credits_applied_message:
            return localized(key: "We were unable to upgrade your account to the plan you selected, so we added your payment as credits to your account. For more information and to complete your upgrade, please contact Support.", comment: "Message shown to the user if we had to top up the account with credits instead of purchasing a plan")
        case .popup_credits_applied_confirmation:
            return localized(key: "Contact Support", comment: "Confirmation for the credits applied popup, will result in showing customer support contact form")
        case .popup_credits_applied_cancellation:
            return localized(key: "Dismiss", comment: "Cancellation for the credits applied popup")
        case .error_apply_payment_on_registration_title:
            return localized(key: "Payment failed", comment: "Error applying credit after registration alert")
        case .error_apply_payment_on_registration_message:
            return localized(key: "You have successfully registered but your payment was not processed. To resend your payment information, click Retry. You will only be charged once. If the problem persists, please contact customer support.", comment: "Error applying credit after registration alert")
        }
    }
}
