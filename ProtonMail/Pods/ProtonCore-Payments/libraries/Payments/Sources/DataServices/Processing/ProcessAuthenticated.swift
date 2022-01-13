//
//  ProcessAuthenticated.swift
//  ProtonCore-Payments - Created on 25/12/2020.
//
//  Copyright (c) 2020 Proton Technologies AG
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
        
        // Create token
        guard let token = dependencies.tokenStorage.get() else {
            return try getToken(transaction: transaction, plan: plan, completion: completion)
        }

        do {
            PMLog.debug("Making TokenRequestStatus")
            let tokenStatusApi = dependencies.paymentsApiProtocol.tokenStatusRequest(api: dependencies.apiService, token: token)
            let tokenStatusRes = try tokenStatusApi.awaitResponse()
            let status = tokenStatusRes.paymentTokenStatus?.status ?? .failed
            switch status {
            case .pending:
                // Waiting for the token to get ready to be charged (should not happen with IAP)
                PMLog.debug("StoreKit: token not ready yet. Scheduling retry in \(dependencies.pendingRetry) seconds")
                queue.asyncAfter(deadline: .now() + dependencies.pendingRetry) { [weak self] in
                    do {
                        guard let self = self else { return }
                        try self.process(transaction: transaction, plan: plan, completion: completion)
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
                dependencies.finishTransaction(transaction)
                dependencies.tokenStorage.clear()
                completion(.finished)
            }
        } catch let error {
            PMLog.debug("StoreKit: Get token info failed: \(error.userFacingMessageInPayments)")
            completion(.erroredWithUnspecifiedError(error))
        }
    }

    private func getToken(transaction: SKPaymentTransaction, plan: PlanToBeProcessed, completion: @escaping ProcessCompletionCallback) throws {

        do {
            let receipt = try dependencies.getReceipt()
            PMLog.debug("StoreKit: No proton token found")
            let tokenApi = dependencies.paymentsApiProtocol.tokenRequest(
                api: dependencies.apiService, amount: plan.amount, receipt: receipt
            )
            PMLog.debug("Making TokenRequest")
            let tokenRes = try tokenApi.awaitResponse()
            guard let token = tokenRes.paymentToken else { throw StoreKitManagerErrors.transactionFailedByUnknownReason }
            dependencies.tokenStorage.add(token)
            try self.process(transaction: transaction, plan: plan, completion: completion) // Exception would've been thrown on the first call

        } catch let error where error.isSandboxReceiptError {
            // sandbox receipt sent to BE
            PMLog.debug("StoreKit: sandbox receipt sent to BE")
            dependencies.finishTransaction(transaction)
            dependencies.tokenStorage.clear()
            completion(.erroredWithUnspecifiedError(error))

        } catch let error where error.isApplePaymentAlreadyRegisteredError {
            // Apple payment already registered
            PMLog.debug("StoreKit: apple payment already registered (2)")
            dependencies.finishTransaction(transaction)
            dependencies.tokenStorage.clear()
            completion(.finished)

        }
    }

    private func buySubscription(transaction: SKPaymentTransaction,
                                 plan: PlanToBeProcessed,
                                 token: PaymentToken,
                                 completion: @escaping ProcessCompletionCallback) throws {
        do {
            // buy plan
            let request = try dependencies.paymentsApiProtocol.buySubscriptionRequest(
                api: dependencies.apiService,
                planId: plan.protonIdentifier,
                amount: plan.amount,
                amountDue: plan.amountDue,
                paymentAction: .token(token: token.token)
            )
            let recieptRes = try request.awaitResponse()
            PMLog.debug("StoreKit: success (1)")
            if let newSubscription = recieptRes.newSubscription {
                dependencies.updateSubscription(newSubscription)
                dependencies.finishTransaction(transaction)
                dependencies.tokenStorage.clear()
                completion(.finished)
            } else {
                throw StoreKitManager.Errors.noNewSubscriptionInSuccessfullResponse
            }

        } catch let error where error.isPaymentAmmountMismatchError {
            PMLog.debug("StoreKit: amount mismatch")
            // ammount mismatch
            do {
                let serverUpdateApi = dependencies.paymentsApiProtocol.creditRequest(
                    api: dependencies.apiService, amount: plan.amount, paymentAction: .token(token: token.token)
                )
                _ = try serverUpdateApi.awaitResponse()
                dependencies.finishTransaction(transaction)
                dependencies.tokenStorage.clear()
                completion(.errored(.creditsApplied))
            } catch let error where error.isApplePaymentAlreadyRegisteredError {
                PMLog.debug("StoreKit: apple payment already registered")
                dependencies.finishTransaction(transaction)
                dependencies.tokenStorage.clear()
                completion(.finished)
            }

        } catch let error as ResponseError where error.toRequestErrors == RequestErrors.subscriptionDecode {
            throw StoreKitManager.Errors.noNewSubscriptionInSuccessfullResponse

        } catch let error {
            completion(.erroredWithUnspecifiedError(error))
        }
    }
}
