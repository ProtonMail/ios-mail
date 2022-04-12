//
//  ProcessUnauthenticated.swift
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
import AwaitKit
import ProtonCore_Log

final class ProcessUnauthenticated: ProcessUnathenticatedProtocol {

    unowned let dependencies: ProcessDependencies

    init(dependencies: ProcessDependencies) {
        self.dependencies = dependencies
    }

    let queue = DispatchQueue(label: "ProcessUnauthenticated async queue", qos: .userInitiated)

    func process(
        transaction: SKPaymentTransaction, plan: PlanToBeProcessed, completion: @escaping ProcessCompletionCallback
    ) throws {
        let receipt = try dependencies.getReceipt()
        do {
            PMLog.debug("Making TokenRequest")
            let tokenApi = dependencies.paymentsApiProtocol.tokenRequest(
                api: dependencies.apiService, amount: plan.amount, receipt: receipt
            )
            let tokenRes = try AwaitKit.await(tokenApi.run())
            guard let token = tokenRes.paymentToken else { return }
            PMLog.debug("StoreKit: payment token created for signup")
            dependencies.tokenStorage.add(token)
            self.processUnauthenticated(withToken: token, transaction: transaction, plan: plan, completion: completion)
        } catch let error {
            PMLog.debug("StoreKit: Create token failed: \(error.messageForTheUser)")
            dependencies.tokenStorage.clear()
            dependencies.addTransactionsBeforeSignup(transaction: transaction)
            completion(.finished)
        }
    }

    private func processUnauthenticated(withToken token: PaymentToken,
                                        transaction: SKPaymentTransaction,
                                        plan: PlanToBeProcessed,
                                        completion: @escaping ProcessCompletionCallback) {
        // In App Payment already succeeded at this point
        do {
            PMLog.debug("Making TokenRequestStatus")
            let tokenStatusApi = dependencies.paymentsApiProtocol.tokenStatusRequest(api: dependencies.apiService, token: token)
            let tokenStatusRes = try AwaitKit.await(tokenStatusApi.run())
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
                // Gr8 success
                dependencies.addTransactionsBeforeSignup(transaction: transaction)
                completion(.paymentToken(token))
                // Transaction will be finished after login
            default:
                PMLog.debug("StoreKit: token status: \(status)")
                dependencies.tokenStorage.clear()
                dependencies.addTransactionsBeforeSignup(transaction: transaction)
                completion(.finished)
                // Transaction will be finished after login
            }
        } catch let error {
            PMLog.debug("StoreKit: Get token info failed: \(error.messageForTheUser)")
            dependencies.tokenStorage.clear()
            dependencies.addTransactionsBeforeSignup(transaction: transaction)
            completion(.finished)
            // Transaction will be finished after login
        }
    }

    func processAuthenticatedBeforeSignup(
        transaction: SKPaymentTransaction, plan: PlanToBeProcessed, completion: @escaping ProcessCompletionCallback
    ) throws {

        // Ask user if he wants to retry or fill a bug report
        let retryOnError = { [weak self] in
            guard let self = self else { return }
            try self.retryAlertView(transaction: transaction, plan: plan, completion: completion)
        }

        // Create token
        guard let token = dependencies.tokenStorage.get() else {
            PMLog.debug("StoreKit: No proton token found")
            let receipt = try dependencies.getReceipt()
            do {
                let tokenApi = dependencies.paymentsApiProtocol.tokenRequest(
                    api: dependencies.apiService, amount: plan.amount, receipt: receipt
                )
                let tokenRes = try AwaitKit.await(tokenApi.run())
                guard let token = tokenRes.paymentToken else {
                    throw StoreKitManager.Errors.transactionFailedByUnknownReason
                }
                dependencies.tokenStorage.add(token)
                try self.processAuthenticatedBeforeSignup(transaction: transaction, plan: plan, completion: completion)

            } catch let error {
                PMLog.debug("StoreKit: payment token was not (re)created: \(error.messageForTheUser)")
                try retryOnError()
            }

            return
        }

        do {
            try getTokenStatusAuthenticatedBeforeSignup(transaction: transaction,
                               plan: plan,
                               token: token,
                               retryOnError: retryOnError,
                               completion: completion)

        } catch let error {
            PMLog.debug("StoreKit: Get token info failed: \(error.messageForTheUser)")
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

        let tokenStatusApi = dependencies.paymentsApiProtocol.tokenStatusRequest(api: dependencies.apiService, token: token)
        let tokenStatusRes = try AwaitKit.await(tokenStatusApi.run())
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
            // Gr8 success
            // buy plan
            try buySubscription(transaction: transaction, plan: plan, token: token, retryOnError: retryOnError, completion: completion)
        case .failed:
            // throw away token and retry with the new one
            PMLog.debug("StoreKit: token failed")
            dependencies.tokenStorage.clear()
            try self.processAuthenticatedBeforeSignup(transaction: transaction, plan: plan, completion: completion)
        case .consumed:
            // throw away token and receipt
            PMLog.debug("StoreKit: token already consumed")
            self.finish(transaction: transaction, completion: completion)
            dependencies.tokenStorage.clear()
        case .notSupported:
            // throw away token and retry
            dependencies.tokenStorage.clear()
            try retryOnError()
        }
    }

    private func buySubscription(transaction: SKPaymentTransaction,
                                 plan: PlanToBeProcessed,
                                 token: PaymentToken,
                                 retryOnError: () throws -> Void?,
                                 completion: @escaping ProcessCompletionCallback) throws {
        do {
            let request = try dependencies.paymentsApiProtocol.buySubscriptionRequest(
                api: dependencies.apiService,
                planId: plan.protonIdentifier,
                amount: plan.amount,
                amountDue: plan.amountDue,
                paymentAction: .token(token: token.token)
            )
            let recieptRes = try AwaitKit.await(request.run())
            PMLog.debug("StoreKit: success (2)")
            if let newSubscription = recieptRes.newSubscription {
                dependencies.updateSubscription(newSubscription)
                self.finish(transaction: transaction, completion: completion)
                dependencies.tokenStorage.clear()
            } else {
                throw StoreKitManager.Errors.noNewSubscriptionInSuccessfullResponse
            }
        } catch let error {
            PMLog.debug("StoreKit: Buy plan failed: \(error.messageForTheUser)")
            try retryOnError()
        }
    }

    private func finish(transaction: SKPaymentTransaction, completion: @escaping ProcessCompletionCallback) {
        dependencies.finishTransaction(transaction)
        dependencies.removeTransactionsBeforeSignup(transaction: transaction)
        NotificationCenter.default.post(name: Payments.transactionFinishedNotification, object: nil)
        completion(.finished)
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
            self.finish(transaction: transaction, completion: completion)
            self.dependencies.bugAlertHandler?(receipt)
        }
    }
}
