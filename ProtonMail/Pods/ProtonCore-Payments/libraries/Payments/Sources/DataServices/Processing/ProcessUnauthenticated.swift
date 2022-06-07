//
//  ProcessUnauthenticated.swift
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

/*

 General overview of transforming IAP into Proton product in the signup flow

 The process consists of two parts — before the user account is created and after the user account is created

 The first part — before the user account is created:
 0. Let the user choose and buy the IAP through native system UI
 1. Get informed about unfinished IAP transactions from StoreKit's payment queue
 2. Determine what product has been purchased via IAP and what is this product's Proton price
 3. Obtain the StoreKit receipt that hopefully confirms the IAP purchase (we don't check this locally)
    * on error: we throw the error to the caller. It should finish the transaction and report the error to the user,
                because no receipt means there's no way we can recover on our own, and leaving the StoreKit transaction
                unfinished will result in never-ending tries.
 4. Exchange the receipt for a token that's worth product's Proton price amount of money
    * on error: we just ignore it and skip the rest of the steps. We assume the token will be properly obtained in step 9.
 5. Wait until the token is ready for consumption (status `chargeable`)
    * on error: we just ignore it and skip the rest of the steps. We assume the token will be properly obtained in step 9.
 6. Store the token and finish the part of the process that happens before the user account being created

 Please note that these steps process transaction during the signup flow, before the user account is created and authenticated.
 Because the user doesn't exist nor is authenticated, we cannot assign neither product nor the credits to the account.

 The second part — after the user account is created
 7. User account is authenticated (happens just after the creation)
 8. Kick off processing the unfinished IAP transactions from StoreKit's payment queue
 9. Retrieve the token worth product's Proton price of money from the storage. If the token is not available we effectively repeat steps 3-4:
    * we obtain the StoreKit receipt that hopefully confirms the IAP purchase (we don't check this locally)
    * we exchange the receipt for a token that's worth product's Proton price amount of money
    * we repeat step 9.
 10. Wait until the token is ready for consumption (status `chargeable`)
    * on error: throw away the token and get back to step 9. to kick off its error handling process
 11. Try exchanging the token for the Proton product
    * on error other then product not available or price mismatch: we give the user the ability to repeat the process from step 9.
                                                                   or to finish the Store Kit transaction and report the bug to the customer support
 12. If it fails because product is no longer available or its price changed, try exchanging the token for the equivalent amount of credits
    * on error other then product not available or price mismatch: we give the user the ability to repeat the process from step 9.
                                                                    or to finish the Store Kit transaction and report the bug to the customer support
 13. Finish the IAP transaction

 These steps happen only after the user is authenticated, so we can assign the product or credits to their account.
 
*/

final class ProcessUnauthenticated: ProcessUnathenticatedProtocol {

    unowned let dependencies: ProcessDependencies

    init(dependencies: ProcessDependencies) {
        self.dependencies = dependencies
    }

    let queue = DispatchQueue(label: "ProcessUnauthenticated async queue", qos: .userInitiated)
    
    // MARK: - This code is performed before the user account has been created and authenticated during signup process
    
    func process(
        transaction: SKPaymentTransaction, plan: PlanToBeProcessed, completion: @escaping ProcessCompletionCallback
    ) throws {
        guard Thread.isMainThread == false else {
            assertionFailure("This is a blocking network request, should never be called from main thread")
            throw AwaitInternalError.synchronousCallPerformedFromTheMainThread
        }
        
        #if DEBUG
        guard TemporaryHacks.simulateBackendPlanPurchaseFailure == false else {
            TemporaryHacks.simulateBackendPlanPurchaseFailure = false
            throw StoreKitManager.Errors.invalidPurchase
        }
        #endif
        
        // Step 3. Obtain the StoreKit receipt that hopefully confirms the IAP purchase (we don't check this locally)
        let receipt = try dependencies.getReceipt()
        do {
            
            // Step 4. Exchange the receipt for a token that's worth product's Proton price amount of money
            PMLog.debug("Making TokenRequest")
            let tokenApi = dependencies.paymentsApiProtocol.tokenRequest(
                api: dependencies.apiService, amount: plan.amount, receipt: receipt
            )
            let tokenRes = try tokenApi.awaitResponse(responseObject: TokenResponse())
            guard let token = tokenRes.paymentToken else { return }
            PMLog.debug("StoreKit: payment token created for signup")
            dependencies.tokenStorage.add(token)
            processUnauthenticated(withToken: token, transaction: transaction, plan: plan, completion: completion)
        } catch let error {
            PMLog.debug("StoreKit: Create token failed: \(error.userFacingMessageInPayments)")
            // Step 4. On error
            dependencies.tokenStorage.clear()
            finishWhenStillUnauthenticated(transaction: transaction, result: .withoutObtainingToken, completion: completion)
        }
    }

    private func processUnauthenticated(withToken token: PaymentToken,
                                        transaction: SKPaymentTransaction,
                                        plan: PlanToBeProcessed,
                                        completion: @escaping ProcessCompletionCallback) {
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
                    guard let self = self else { return }
                    self.processUnauthenticated(withToken: token, transaction: transaction, plan: plan, completion: completion)
                }
                return
            case .chargeable:
                // Step 6. Store the token and finish the part of the process that happens before the user account being created
                finishWhenStillUnauthenticated(transaction: transaction, result: .withoutExchangingToken(token: token), completion: completion)
            default:
                PMLog.debug("StoreKit: token status: \(status)")
                // Step 5. On error
                dependencies.tokenStorage.clear()
                finishWhenStillUnauthenticated(transaction: transaction, result: .withoutObtainingToken, completion: completion)
            }
        } catch let error {
            PMLog.debug("StoreKit: Get token info failed: \(error.userFacingMessageInPayments)")
            // Step 5. On error
            dependencies.tokenStorage.clear()
            finishWhenStillUnauthenticated(transaction: transaction, result: .withoutObtainingToken, completion: completion)
        }
    }
    
    private func finishWhenStillUnauthenticated(transaction: SKPaymentTransaction,
                                                result: PaymentSucceeded,
                                                completion: @escaping ProcessCompletionCallback) {
        // Transaction will be marked finished after login, in finishWhenAuthenticated method
        dependencies.addTransactionsBeforeSignup(transaction: transaction)
        completion(.finished(result))
    }
    
    // MARK: - This code is performed after the user has been already authenticated during signup process

    func processAuthenticatedBeforeSignup(
        transaction: SKPaymentTransaction, plan: PlanToBeProcessed, completion: @escaping ProcessCompletionCallback
    ) throws {

        // Ask user if he wants to retry or fill a bug report
        let retryOnError = { [weak self] in
            guard let self = self else { return }
            try self.retryAlertView(transaction: transaction, plan: plan, completion: completion)
        }

        // Step 9. Retrieve the token worth product's Proton price of money from the storage.
        guard let token = dependencies.tokenStorage.get() else {
            PMLog.debug("StoreKit: No proton token found")
            // Step 9. If the token is not available we effectively repeat step 3: we obtain the StoreKit receipt that hopefully confirms the IAP purchase (we don't check this locally)
            let receipt = try dependencies.getReceipt()
            do {
                
                // Step 9. If the token is not available we effectively repeat step 4: we exchange the receipt for a token that's worth product's Proton price amount of money
                let tokenApi = dependencies.paymentsApiProtocol.tokenRequest(
                    api: dependencies.apiService, amount: plan.amount, receipt: receipt
                )
                let tokenRes = try tokenApi.awaitResponse(responseObject: TokenResponse())
                guard let token = tokenRes.paymentToken else {
                    throw StoreKitManager.Errors.transactionFailedByUnknownReason
                }
                dependencies.tokenStorage.add(token)
                try processAuthenticatedBeforeSignup(transaction: transaction, plan: plan, completion: completion)

            } catch let error {
                PMLog.debug("StoreKit: payment token was not (re)created: \(error.userFacingMessageInPayments)")
                try retryOnError()
            }

            return
        }

        do {
            // Step 10. Wait until the token is ready for consumption (status `chargeable`)
            try getTokenStatusAuthenticatedBeforeSignup(transaction: transaction,
                                                        plan: plan,
                                                        token: token,
                                                        retryOnError: retryOnError,
                                                        completion: completion)

        } catch let error {
            // Step 10. On error: throw away the token and get back to step 9. to kick off its error handling process
            PMLog.debug("StoreKit: Get token info failed: \(error.userFacingMessageInPayments)")
            if error.isNetworkIssueError {
                try retryOnError()
                return
            }
            PMLog.debug("StoreKit: will cleanup old token and restart procedure in \(dependencies.errorRetry) seconds")
            dependencies.tokenStorage.clear()
            queue.asyncAfter(deadline: .now() + dependencies.errorRetry) { [weak self] in
                do {
                    guard let self = self else { return }
                    try self.processAuthenticatedBeforeSignup(transaction: transaction, plan: plan, completion: completion)
                } catch {
                    completion(.erroredWithUnspecifiedError(error))
                }
            }
        }
    }

    private func getTokenStatusAuthenticatedBeforeSignup(transaction: SKPaymentTransaction,
                                                         plan: PlanToBeProcessed,
                                                         token: PaymentToken,
                                                         retryOnError: @escaping () throws -> Void?,
                                                         completion: @escaping ProcessCompletionCallback) throws {

        // Step 10. Wait until the token is ready for consumption (status `chargeable`)
        let tokenStatusApi = dependencies.paymentsApiProtocol.tokenStatusRequest(api: dependencies.apiService, token: token)
        let tokenStatusRes = try tokenStatusApi.awaitResponse(responseObject: TokenStatusResponse())
        let status = tokenStatusRes.paymentTokenStatus?.status ?? .failed
        switch status {
        case .pending:
            // Waiting for the token to get ready to be charged (should not happen with IAP)
            PMLog.debug("StoreKit: token not ready yet. Scheduling retry in \(dependencies.pendingRetry) seconds")
            queue.asyncAfter(deadline: .now() + dependencies.pendingRetry) { [weak self] in
                do {
                    guard let self = self else { return }
                    try self.getTokenStatusAuthenticatedBeforeSignup(transaction: transaction,
                                            plan: plan,
                                            token: token,
                                            retryOnError: retryOnError,
                                            completion: completion)

                } catch {
                    completion(.erroredWithUnspecifiedError(error))

                }
            }
            return
        case .chargeable:
            // Gr8 success, buy plan
            try buySubscription(transaction: transaction, plan: plan, token: token, retryOnError: retryOnError, completion: completion)
        case .failed:
            // Step 10. On error: throw away the token and get back to step 9. to kick off its error handling process
            PMLog.debug("StoreKit: token failed")
            dependencies.tokenStorage.clear()
            try processAuthenticatedBeforeSignup(transaction: transaction, plan: plan, completion: completion)
        case .consumed:
            // throw away token and receipt
            PMLog.debug("StoreKit: token already consumed")
            finishWhenAuthenticated(transaction: transaction, result: .withPurchaseAlreadyProcessed, completion: completion)
        case .notSupported:
            // Step 10. On error: throw away the token
            dependencies.tokenStorage.clear()
            try retryOnError()
        }
    }
    
    private func buySubscription(transaction: SKPaymentTransaction,
                                 plan: PlanToBeProcessed,
                                 token: PaymentToken,
                                 retryOnError: () throws -> Void?,
                                 completion: @escaping ProcessCompletionCallback) throws {
        // Step 11. Try exchanging the token for the Proton product
        do {
            let request = try dependencies.paymentsApiProtocol.buySubscriptionRequest(
                api: dependencies.apiService,
                planId: plan.protonIdentifier,
                amount: plan.amount,
                amountDue: plan.amountDue,
                paymentAction: .token(token: token.token)
            )
            let recieptRes = try request.awaitResponse(responseObject: SubscriptionResponse())
            PMLog.debug("StoreKit: success (2)")
            if let newSubscription = recieptRes.newSubscription {
                dependencies.updateSubscription(newSubscription)
                // Step 13. Finish the IAP transaction
                finishWhenAuthenticated(transaction: transaction, result: .resolvingIAPToSubscription, completion: completion)
            } else {
                throw StoreKitManager.Errors.noNewSubscriptionInSuccessfullResponse
            }
        } catch let error where error.isPaymentAmmountMismatchOrUnavailablePlanError {
            PMLog.debug("StoreKit: amount mismatch")
            try recoverByToppingUpCredits(
                plan: plan, token: token, transaction: transaction, retryOnError: retryOnError, completion: completion
            )
        } catch {
            PMLog.debug("StoreKit: Buy plan failed: \(error.userFacingMessageInPayments)")
            try retryOnError()
        }
    }
    
    private func recoverByToppingUpCredits(plan: PlanToBeProcessed,
                                           token: PaymentToken,
                                           transaction: SKPaymentTransaction,
                                           retryOnError: () throws -> Void?,
                                           completion: @escaping ProcessCompletionCallback) throws {
        // Step 12. If it fails because product is no longer available or its price changed, try exchanging the token for the equivalent amount of credits
        do {
            let serverUpdateApi = dependencies.paymentsApiProtocol.creditRequest(
                api: dependencies.apiService, amount: plan.amount, paymentAction: .token(token: token.token)
            )
            _ = try serverUpdateApi.awaitResponse(responseObject: CreditResponse())
            // Step 13. Finish the IAP transaction
            finishWhenAuthenticated(transaction: transaction, result: .resolvingIAPToCredits, completion: completion)
        } catch let error where error.isApplePaymentAlreadyRegisteredError {
            PMLog.debug("StoreKit: apple payment already registered")
            finishWhenAuthenticated(transaction: transaction, result: .withPurchaseAlreadyProcessed, completion: completion)
        } catch {
            PMLog.debug("StoreKit: Buy plan failed: \(error.userFacingMessageInPayments)")
            try retryOnError()
        }
    }

    private func finishWhenAuthenticated(transaction: SKPaymentTransaction,
                                         result: PaymentSucceeded,
                                         completion: @escaping ProcessCompletionCallback) {
        dependencies.finishTransaction(transaction)
        dependencies.removeTransactionsBeforeSignup(transaction: transaction)
        dependencies.tokenStorage.clear()
        NotificationCenter.default.post(name: Payments.transactionFinishedNotification, object: nil)
        completion(.finished(result))
    }

    // Alerts

    func retryAlertView(transaction: SKPaymentTransaction,
                        plan: PlanToBeProcessed,
                        completion: @escaping ProcessCompletionCallback) throws {
        dependencies.alertManager.retryAlert { [weak self] in
            guard let self = self else { return }
            self.queue.async { [weak self] in
                do {
                    guard let self = self else { return }
                    try self.processAuthenticatedBeforeSignup(transaction: transaction, plan: plan, completion: completion)
                } catch {
                    completion(.erroredWithUnspecifiedError(error))
                }
            }
        } cancelAction: { [weak self] in
            guard let self = self else { return }
            let receipt = try? self.dependencies.getReceipt()
            self.finishWhenAuthenticated(transaction: transaction, result: .cancelled, completion: completion)
            self.dependencies.bugAlertHandler?(receipt)
        }
    }
}
