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
 3. Get the payment token
 4. Try exchanging the token for the Proton product
 5. If it fails because product is no longer available or its price changed, try exchanging the token for the equivalent amount of credits
 6. Finish the IAP transaction
 
*/

final class ProcessAuthenticated: ProcessProtocol {

    unowned let dependencies: ProcessDependencies
    let tokenHandler: TokenHandler?

    init(dependencies: ProcessDependencies) {
        self.dependencies = dependencies
        self.tokenHandler = TokenHandler(dependencies: dependencies)
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
        
        // Step 3. Get the payment token
        try tokenHandler?.getToken(transaction: transaction, plan: plan, completion: completion, finishCompletion: { [weak self] result in
            self?.finish(transaction: transaction, result: result, completion: completion)
        }, tokenCompletion: { [weak self] token in
            try self?.buySubscription(transaction: transaction, plan: plan, token: token, completion: completion)
        })
    }

    fileprivate func recoverByToppingUpCredits(
        plan: PlanToBeProcessed, token: PaymentToken, transaction: SKPaymentTransaction, completion: @escaping ProcessCompletionCallback
    ) {
        // Step 5. If it fails because product is no longer available or its price changed, try exchanging the token for the equivalent amount of credits
        do {
            let serverUpdateApi = dependencies.paymentsApiProtocol.creditRequest(
                api: dependencies.apiService, amount: plan.amount, paymentAction: .token(token: token.token)
            )
            _ = try serverUpdateApi.awaitResponse(responseObject: CreditResponse())
            finish(transaction: transaction, result: .finished(.resolvingIAPToCreditsCausedByError), completion: completion)
            
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
            // Step 4. Try exchanging the token for the Proton product
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
    
    private func finish(transaction: SKPaymentTransaction, result: ProcessCompletionResult, completion: @escaping ProcessCompletionCallback) {
        // Step 6. Finish the IAP transaction
        dependencies.finishTransaction(transaction) { [weak self] in
            self?.dependencies.tokenStorage.clear()
            completion(result)
            self?.dependencies.refreshCompletionHandler(result)
        }
    }
}
