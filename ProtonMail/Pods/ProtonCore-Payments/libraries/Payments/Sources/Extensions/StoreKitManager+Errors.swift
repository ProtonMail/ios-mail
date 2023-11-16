//
//  StoreKitManager+Errors.swift
//  ProtonCore-Payments - Created on 2/12/20.
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

public enum StoreKitManagerErrors: LocalizedError {
    case unavailableProduct
    case invalidPurchase
    case receiptLost
    case haveTransactionOfAnotherUser
    case alreadyPurchasedPlanDoesNotMatchBackend
    case noActiveUsername
    case transactionFailedByUnknownReason
    case noNewSubscriptionInSuccessfulResponse
    case wrongTokenStatus(PaymentToken.Status)
    case notAllowed
    case unknown(code: Int, originalError: NSError)
    case appIsLocked
    case pleaseSignIn
    case apiMightBeBlocked(message: String, originalError: Error)

    @available(*, deprecated, message: "This is never returned anymore — the success callback with `.resolvingIAPToCreditsCausedByError` is returned instead")
    static var creditsApplied: StoreKitManagerErrors { .transactionFailedByUnknownReason }

    @available(*, deprecated, message: "This is never returned anymore — the success callback with `.cancelled` is returned instead")
    static var cancelled: StoreKitManagerErrors { .transactionFailedByUnknownReason }

    var isUnknown: Bool {
        switch self {
        case .unknown: return true
        default: return false
        }
    }

    public var errorDescription: String? {
        switch self {
        case .unavailableProduct: return PSTranslation._error_unavailable_product.l10n
        case .invalidPurchase: return PSTranslation._error_invalid_purchase.l10n
        case .receiptLost: return PSTranslation._error_receipt_lost.l10n
        case .haveTransactionOfAnotherUser: return PSTranslation._error_another_user_transaction.l10n
        case .alreadyPurchasedPlanDoesNotMatchBackend: return PSTranslation._error_backend_mismatch.l10n
        case .noActiveUsername: return PSTranslation._error_no_active_username_in_user_data_service.l10n
        case .transactionFailedByUnknownReason: return PSTranslation._error_transaction_failed_by_unknown_reason.l10n
        case .noNewSubscriptionInSuccessfulResponse: return PSTranslation._error_no_new_subscription_in_response.l10n
        case .appIsLocked: return PSTranslation._error_unlock_to_proceed_with_iap.l10n
        case .pleaseSignIn: return PSTranslation._error_please_sign_in_iap.l10n
        case .wrongTokenStatus: return PSTranslation._error_wrong_token_status.l10n
        case .notAllowed, .unknown: return nil
        case .apiMightBeBlocked(let message, _): return message
        }
    }
}

extension StoreKitManagerErrors: Equatable {
    public static func == (lhs: StoreKitManagerErrors, rhs: StoreKitManagerErrors) -> Bool {
        switch (lhs, rhs) {
        case (.unavailableProduct, .unavailableProduct),
            (.invalidPurchase, .invalidPurchase),
            (.receiptLost, .receiptLost),
            (.haveTransactionOfAnotherUser, .haveTransactionOfAnotherUser),
            (.alreadyPurchasedPlanDoesNotMatchBackend, .alreadyPurchasedPlanDoesNotMatchBackend),
            (.noActiveUsername, .noActiveUsername),
            (.transactionFailedByUnknownReason, .transactionFailedByUnknownReason),
            (.noNewSubscriptionInSuccessfulResponse, .noNewSubscriptionInSuccessfulResponse),
            (.notAllowed, .notAllowed),
            (.appIsLocked, .appIsLocked),
            (.pleaseSignIn, .pleaseSignIn):
            return true
        case let (.wrongTokenStatus(ltoken), .wrongTokenStatus(rtoken)):
            return ltoken == rtoken
        case let (.unknown(lcode, loriginalError), .unknown(rcode, roriginalError)):
            return lcode == rcode && loriginalError == roriginalError
        case let (.apiMightBeBlocked(lmessage, _), .apiMightBeBlocked(rmessage, _)):
            return lmessage == rmessage
        default:
            return false
        }
    }
}

extension Error {
    public var userFacingMessageInPayments: String {
        if let storeKitError = self as? StoreKitManagerErrors {
            return storeKitError.errorDescription ?? storeKitError.localizedDescription
        }
        return localizedDescription
    }
}
