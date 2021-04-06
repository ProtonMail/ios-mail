//
//  StoreKitManager+Errors.swift
//  PMPayments - Created on 2/12/20.
//
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.

import Foundation
import PMCoreTranslation

extension StoreKitManager {

    public enum Errors: LocalizedError, Equatable {
        case unavailableProduct
        case invalidPurchase
        case receiptLost
        case haveTransactionOfAnotherUser
        case alreadyPurchasedPlanDoesNotMatchBackend
        case sandboxReceipt
        case noActiveUsername
        case transactionFailedByUnknownReason
        case noNewSubscriptionInSuccessfullResponse
        case creditsApplied
        case wrongTokenStatus(PaymentToken.Status)
        case cancelled
        case appIsLocked                            // (mail only)
        case pleaseSignIn                           // (mail only)

        public var errorDescription: String? {
            switch self {
            case .unavailableProduct: return CoreString._error_unavailable_product
            case .invalidPurchase: return CoreString._error_invalid_purchase
            case .receiptLost: return CoreString._error_reciept_lost
            case .haveTransactionOfAnotherUser: return CoreString._error_another_user_transaction
            case .alreadyPurchasedPlanDoesNotMatchBackend: return CoreString._error_backend_mismatch
            case .sandboxReceipt: return CoreString._error_sandbox_receipt
            case .noActiveUsername: return CoreString._error_no_active_username_in_user_data_service
            case .transactionFailedByUnknownReason: return CoreString._error_transaction_failed_by_unknown_reason
            case .noNewSubscriptionInSuccessfullResponse: return CoreString._error_no_new_subscription_in_response
            case .appIsLocked: return CoreString._error_unlock_to_proceed_with_iap
            case .pleaseSignIn: return CoreString._error_please_sign_in_iap
            case .creditsApplied: return CoreString._error_credits_applied
            case .wrongTokenStatus: return CoreString._error_wrong_token_status
            case .cancelled: return nil
            }
        }
    }
}
