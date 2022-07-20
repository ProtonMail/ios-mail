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

 General overview of transforming IAP into Proton product when the user is already authorised when making the purchase:

 0. Let the user choose and buy the IAP through native system UI
 1. Get informed about unfinished IAP transactions from StoreKit's payment queue
 2. Determine what product has been purchased via IAP and what is this product's Proton price
 3. Obtain the StoreKit receipt that hopefully confirms the IAP purchase (we don't check this locally)
 4. Exchange the receipt for a token that's worth product's Proton price amount of money
 5. Wait until the token is ready for consumption (status `chargeable`)
 6. Try exchanging the token for the Proton product
 7. If it fails because product is no longer available or its price changed, try exchanging the token for the equivalent amount of credits
 8. Finish the IAP transaction
 
*/

final class ProcessAuthenticated: ProcessProtocol {

    unowned let dependencies: ProcessDependencies

    init(dependencies: ProcessDependencies) {
        self.dependencies = dependencies
    }

    let queue = DispatchQueue(label: "ProcessAuthenticated async queue", qos: .userInitiated)
    
    func process(transaction: SKPaymentTransaction,
                 plan: PlanToBeProcessed,
                 completion: @escaping ProcessCompletionCallback) throws {

        guard Thread.isMainThread == false else {
            assertionFailure("This is a blocking network request, should never be called from main thread")
            throw AwaitInternalError.synchronousCallPerformedFromTheMainThread
        }
        
        #if DEBUG_CORE_INTERNALS
        guard TemporaryHacks.simulateBackendPlanPurchaseFailure == false else {
            TemporaryHacks.simulateBackendPlanPurchaseFailure = false
            throw StoreKitManager.Errors.invalidPurchase
        }
        #endif
        
        // Create token
        guard let token = dependencies.tokenStorage.get() else {
            return try getToken(transaction: transaction, plan: plan, completion: completion)
        }

        do {
            PMLog.debug("Making TokenRequestStatus")
            // Step 5. Wait until the token is ready for consumption (status `chargeable`)
            let tokenStatusApi = dependencies.paymentsApiProtocol.tokenStatusRequest(api: dependencies.apiService, token: token)
            let tokenStatusRes = try tokenStatusApi.awaitResponse(responseObject: TokenStatusResponse())
            let status = tokenStatusRes.paymentTokenStatus?.status ?? .failed
            switch status {
            case .pending:
                // Waiting for the token to get ready to be charged (should not happen with IAP)
                PMLog.debug("StoreKit: token not ready yet. Scheduling retry in \(dependencies.pendingRetry) seconds")
                queue.asyncAfter(deadline: .now() + dependencies.pendingRetry) { [weak self] in
                    do {
                        try self?.process(transaction: transaction, plan: plan, completion: completion)
                    } catch {
                        completion(.erroredWithUnspecifiedError(error))
                    }
                }
                return
            case .chargeable:
                // Gr8 success
                try buySubscription(transaction: transaction, plan: plan, token: token, completion: completion)
            case .failed, .notSupported:
                // throw away token and retry with the new one
                PMLog.debug("StoreKit: token \(status == .failed ? "failed" : "not supported")")
                dependencies.tokenStorage.clear()
                completion(.errored(.wrongTokenStatus(status)))
            case .consumed:
                // throw away token and receipt
                PMLog.debug("StoreKit: token already consumed")
                finish(transaction: transaction, result: .finished(.withPurchaseAlreadyProcessed), completion: completion)
            }
        } catch let error {
            PMLog.debug("StoreKit: Get token info failed: \(error.userFacingMessageInPayments)")
            completion(.erroredWithUnspecifiedError(error))
        }
    }

    private func getToken(transaction: SKPaymentTransaction, plan: PlanToBeProcessed, completion: @escaping ProcessCompletionCallback) throws {

        do {
            // Step 3. Obtain the StoreKit receipt that hopefully confirms the IAP purchase (we don't check this locally)
            let receipt = try dependencies.getReceipt()
            PMLog.debug("StoreKit: No proton token found")
            
            // Step 4. Exchange the receipt for a token that's worth product's Proton price amount of money
            let tokenApi = dependencies.paymentsApiProtocol.tokenRequest(
                api: dependencies.apiService, amount: plan.amount, receipt: receipt
            )
            PMLog.debug("Making TokenRequest")
            let tokenRes = try tokenApi.awaitResponse(responseObject: TokenResponse())
            guard let token = tokenRes.paymentToken else { throw StoreKitManagerErrors.transactionFailedByUnknownReason }
            dependencies.tokenStorage.add(token)
            try process(transaction: transaction, plan: plan, completion: completion) // Exception would've been thrown on the first call

        } catch let error where error.isSandboxReceiptError {
            // sandbox receipt sent to BE
            PMLog.debug("StoreKit: sandbox receipt sent to BE")
            finish(transaction: transaction, result: .erroredWithUnspecifiedError(error), completion: completion)

        } catch let error where error.isApplePaymentAlreadyRegisteredError {
            // Apple payment already registered
            PMLog.debug("StoreKit: apple payment already registered (2)")
            finish(transaction: transaction, result: .finished(.withPurchaseAlreadyProcessed), completion: completion)
            
        }
    }

    fileprivate func recoverByToppingUpCredits(
        plan: PlanToBeProcessed, token: PaymentToken, transaction: SKPaymentTransaction, completion: ProcessCompletionCallback
    ) {
        // Step 7. If it fails because product is no longer available or its price changed, try exchanging the token for the equivalent amount of credits
        do {
            let serverUpdateApi = dependencies.paymentsApiProtocol.creditRequest(
                api: dependencies.apiService, amount: plan.amount, paymentAction: .token(token: token.token)
            )
            _ = try serverUpdateApi.awaitResponse(responseObject: CreditResponse())
            finish(transaction: transaction, result: .finished(.resolvingIAPToCredits), completion: completion)
            
        } catch let error where error.isApplePaymentAlreadyRegisteredError {
            PMLog.debug("StoreKit: apple payment already registered")
            finish(transaction: transaction, result: .finished(.withPurchaseAlreadyProcessed), completion: completion)
            
        } catch {
            completion(.erroredWithUnspecifiedError(error))
            
        }
    }
    
    private func buySubscription(transaction: SKPaymentTransaction,
                                 plan: PlanToBeProcessed,
                                 token: PaymentToken,
                                 completion: @escaping ProcessCompletionCallback) throws {
        do {
            // Step 6. Try exchanging the token for the Proton product
            let request = try dependencies.paymentsApiProtocol.buySubscriptionRequest(
                api: dependencies.apiService,
                planId: plan.protonIdentifier,
                amount: plan.amount,
                amountDue: plan.amountDue,
                paymentAction: .token(token: token.token)
            )
            let recieptRes = try request.awaitResponse(responseObject: SubscriptionResponse())
            PMLog.debug("StoreKit: success (1)")
            if let newSubscription = recieptRes.newSubscription {
                dependencies.updateCurrentSubscription { [weak self] in
                    self?.finish(transaction: transaction, result: .finished(.resolvingIAPToSubscription), completion: completion)
                    
                } failure: { [weak self] _ in
                    // if updateCurrentSubscription is failed for some reason, update subscription with newSubscription data
                    self?.dependencies.updateSubscription(newSubscription)
                    self?.finish(transaction: transaction, result: .finished(.resolvingIAPToSubscription), completion: completion)
                    
                }
            } else {
                throw StoreKitManager.Errors.noNewSubscriptionInSuccessfullResponse
            }

        } catch let error where error.isPaymentAmmountMismatchOrUnavailablePlanError {
            PMLog.debug("StoreKit: amount mismatch")
            recoverByToppingUpCredits(plan: plan, token: token, transaction: transaction, completion: completion)

        } catch let error as ResponseError where error.toRequestErrors == RequestErrors.subscriptionDecode {
            throw StoreKitManager.Errors.noNewSubscriptionInSuccessfullResponse

        } catch {
            completion(.erroredWithUnspecifiedError(error))
        }
    }
    
    private func finish(transaction: SKPaymentTransaction, result: ProcessCompletionResult, completion: ProcessCompletionCallback) {
        // Step 8. Finish the IAP transaction
        dependencies.finishTransaction(transaction)
        dependencies.tokenStorage.clear()
        completion(result)
    }
}
