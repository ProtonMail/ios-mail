//
//  ProcessAuthenticated.swift
//  ProtonCore-Payments - Created on 25/12/2020.
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

import StoreKit
import ProtonCore_Log
import ProtonCore_Networking
import ProtonCore_Services

/*

 General overview of receiving token:
 1. Obtain the StoreKit receipt that hopefully confirms the IAP purchase (we don't check this locally)
 2. Exchange the receipt for a token that's worth product's Proton price amount of money
 3. Wait until the token is ready for consumption (status `chargeable`)
 
*/

final class TokenHandler {

    unowned let dependencies: ProcessDependencies

    init(dependencies: ProcessDependencies) {
        self.dependencies = dependencies
    }

    let queue = DispatchQueue(label: "TokenHandler async queue", qos: .userInitiated)
    
    func getToken(transaction: SKPaymentTransaction,
                  plan: PlanToBeProcessed,
                  completion: @escaping ProcessCompletionCallback,
                  finishCompletion: @escaping (ProcessCompletionResult) -> Void,
                  tokenCompletion: @escaping (PaymentToken) throws -> Void) throws {
        
        // Create token
        guard let token = dependencies.tokenStorage.get() else {
            return try requestToken(transaction: transaction, plan: plan, completion: completion, finishCompletion: finishCompletion, tokenCompletion: tokenCompletion)
        }

        do {
            PMLog.debug("Making TokenRequestStatus")
            // Step 3. Wait until the token is ready for consumption (status `chargeable`)
            let tokenStatusApi = dependencies.paymentsApiProtocol.tokenStatusRequest(api: dependencies.apiService, token: token)
            let tokenStatusRes = try tokenStatusApi.awaitResponse(responseObject: TokenStatusResponse())
            let status = tokenStatusRes.paymentTokenStatus?.status ?? .failed
            switch status {
            case .pending:
                // Waiting for the token to get ready to be charged (should not happen with IAP)
                PMLog.debug("StoreKit: token not ready yet. Scheduling retry in \(dependencies.pendingRetry) seconds")
                queue.asyncAfter(deadline: .now() + dependencies.pendingRetry) { [weak self] in
                    do {
                        try self?.getToken(transaction: transaction, plan: plan, completion: completion, finishCompletion: finishCompletion, tokenCompletion: tokenCompletion)
                    } catch {
                        completion(.erroredWithUnspecifiedError(error))
                    }
                }
                return
            case .chargeable:
                // Gr8 success
                try tokenCompletion(token)
            case .failed, .notSupported:
                // throw away token and retry with the new one
                PMLog.debug("StoreKit: token \(status == .failed ? "failed" : "not supported")")
                dependencies.tokenStorage.clear()
                completion(.errored(.wrongTokenStatus(status)))
            case .consumed:
                // throw away token and receipt
                PMLog.debug("StoreKit: token already consumed")
                finishCompletion(.finished(.withPurchaseAlreadyProcessed))
            }
        } catch let error {
            PMLog.debug("StoreKit: Get token info failed: \(error.userFacingMessageInPayments)")
            completion(.erroredWithUnspecifiedError(error))
        }
    }

    private func requestToken(transaction: SKPaymentTransaction,
                              plan: PlanToBeProcessed,
                              completion: @escaping ProcessCompletionCallback,
                              finishCompletion: @escaping (ProcessCompletionResult) -> Void,
                              tokenCompletion: @escaping (PaymentToken) throws -> Void) throws {

        do {
            // Step 1. Obtain the StoreKit receipt that hopefully confirms the IAP purchase (we don't check this locally)
            let receipt = try dependencies.getReceipt()
            PMLog.debug("StoreKit: No proton token found")
            
            // Step 2. Exchange the receipt for a token that's worth product's Proton price amount of money
            let tokenApi = dependencies.paymentsApiProtocol.tokenRequest(
                api: dependencies.apiService, amount: plan.amount, receipt: receipt
            )
            PMLog.debug("Making TokenRequest")
            let tokenRes = try tokenApi.awaitResponse(responseObject: TokenResponse())
            guard let token = tokenRes.paymentToken else { throw StoreKitManagerErrors.transactionFailedByUnknownReason }
            dependencies.tokenStorage.add(token)
            try getToken(transaction: transaction, plan: plan, completion: completion, finishCompletion: finishCompletion, tokenCompletion: tokenCompletion) // Exception would've been thrown on the first call

        } catch let error where error.isSandboxReceiptError {
            // sandbox receipt sent to BE
            PMLog.debug("StoreKit: sandbox receipt sent to BE")
            finishCompletion(.erroredWithUnspecifiedError(error))

        } catch let error where error.isApplePaymentAlreadyRegisteredError {
            // Apple payment already registered
            PMLog.debug("StoreKit: apple payment already registered (2)")
            finishCompletion(.finished(.withPurchaseAlreadyProcessed))
        }
    }
}
