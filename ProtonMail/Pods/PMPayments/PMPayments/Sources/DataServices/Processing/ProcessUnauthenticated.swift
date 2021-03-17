//
//  ProcessUnauthenticated.swift
//  PMPayments - Created on 25/12/2020.
//
//
//  Copyright (c) 2020 Proton Technologies AG
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

import StoreKit
import AwaitKit
import PMLog

class ProcessUnauthenticated: ProcessUnathenticatedProtocol {

    weak var delegate: ProcessDelegateProtocol?
    let queue = DispatchQueue(label: "ProcessUnauthenticated async queue")

    func process(transaction: SKPaymentTransaction, plan: AccountPlan, completion: @escaping CompletionCallback) throws {
        guard let delegate = delegate,
              let storeKitDelegate = delegate.storeKitDelegate, let apiService = storeKitDelegate.apiService else {
            throw StoreKitManager.Errors.transactionFailedByUnknownReason }
        guard let receipt = try? delegate.getReceipt() else {
            PMLog.debug("StoreKit: Proton token not found! Apple receipt not found!")
            return
        }
        do {
            let tokenApi = delegate.paymentsApiProtocol.tokenRequest(api: apiService, amount: plan.yearlyCost, receipt: receipt)
            let tokenRes = try await(tokenApi.run())
            guard let token = tokenRes.paymentToken else { return }
            PMLog.debug("StoreKit: payment token created for signup")
            delegate.tokenStorage?.add(token)
            try self.processUnauthenticated(withToken: token, transaction: transaction, plan: plan, completion: completion)
        } catch let error {
            PMLog.debug("StoreKit: Create token failed: \(error.localizedDescription)")
            delegate.tokenStorage?.clear()
            delegate.transactionsBeforeSignup.append(transaction)
            delegate.successCallback?(nil)
            completion()
        }
    }

    func processAuthenticatedBeforeSignup(transaction: SKPaymentTransaction, plan: AccountPlan, completion: @escaping CompletionCallback) throws {

        guard let delegate = delegate, let storeKitDelegate = delegate.storeKitDelegate, let apiService = storeKitDelegate.apiService else { throw StoreKitManager.Errors.transactionFailedByUnknownReason }

        // Ask user if he wants to retry or fill a bug report
        let retryOnError = { [weak self] in
            try? self?.retryAlertView(transaction: transaction, plan: plan, completion: completion)
        }

        // Create token
        guard let token = delegate.tokenStorage?.get() else {
            guard let receipt = try? delegate.getReceipt() else {
                PMLog.debug("StoreKit: Proton token not found! Apple receipt not found!")
                return
            }
            PMLog.debug("StoreKit: No proton token found")
            do {
                let tokenApi = delegate.paymentsApiProtocol.tokenRequest(api: apiService, amount: plan.yearlyCost, receipt: receipt)
                let tokenRes = try await(tokenApi.run())
                guard let token = tokenRes.paymentToken else { return }
                delegate.tokenStorage?.add(token)
                try self.processAuthenticatedBeforeSignup(transaction: transaction, plan: plan, completion: completion)
            } catch _ {
                PMLog.debug("StoreKit: payment token was not (re)created")
                retryOnError()
            }
            return
        }

        do {
            try getTokenStatus(transaction: transaction, plan: plan, token: token, retryOnError: retryOnError, completion: completion)
        } catch let error {
            PMLog.debug("StoreKit: Get token info failed: \(error.localizedDescription)")
            if error.isNetworkIssueError {
                retryOnError()
                return
            }
            PMLog.debug("StoreKit: will cleanup old token and restart procedure in \(delegate.errorRetry) seconds")
            delegate.tokenStorage?.clear()
            queue.asyncAfter(deadline: .now() + delegate.errorRetry) {
                try? self.processAuthenticatedBeforeSignup(transaction: transaction, plan: plan, completion: completion)
            }
        }
    }

    private func getTokenStatus(transaction: SKPaymentTransaction, plan: AccountPlan, token: PaymentToken, retryOnError: @escaping () -> Void?, completion: @escaping CompletionCallback) throws {
        guard let delegate = delegate, let storeKitDelegate = delegate.storeKitDelegate, let apiService = storeKitDelegate.apiService else { throw StoreKitManager.Errors.transactionFailedByUnknownReason }

        let tokenStatusApi = delegate.paymentsApiProtocol.tokenStatusRequest(api: apiService, token: token)
        let tokenStatusRes = try await(tokenStatusApi.run())
        let status = tokenStatusRes.paymentTokenStatus?.status ?? .failed
        switch status {
        case .pending:
            // Waiting for the token to get ready to be charged (should not happen with IAP)
            PMLog.debug("StoreKit: token not ready yet. Scheduling retry in \(delegate.pendingRetry) seconds")
            queue.asyncAfter(deadline: .now() + delegate.pendingRetry) {
                try? self.getTokenStatus(transaction: transaction, plan: plan, token: token, retryOnError: retryOnError, completion: completion)
            }
            return
        case .chargeable:
            // Gr8 success
            do {
                // buy plan
                try buySubscription(transaction: transaction, plan: plan, token: token, retryOnError: retryOnError, completion: completion)
            }
        case .failed:
            // throw away token and retry with the new one
            PMLog.debug("StoreKit: token failed")
            delegate.tokenStorage?.clear()
            try self.processAuthenticatedBeforeSignup(transaction: transaction, plan: plan, completion: completion)
        case .consumed:
            // throw away token and receipt
            PMLog.debug("StoreKit: token already consumed")
            self.finish(transaction: transaction, completion: completion)
            delegate.tokenStorage?.clear()
        case .notSupported:
            // throw away token and retry
            delegate.tokenStorage?.clear()
            retryOnError()
        }
    }

    private func buySubscription(transaction: SKPaymentTransaction, plan: AccountPlan, token: PaymentToken, retryOnError: () -> Void?, completion: @escaping CompletionCallback) throws {

        guard let delegate = delegate, let storeKitDelegate = delegate.storeKitDelegate, let apiService = storeKitDelegate.apiService else { throw StoreKitManager.Errors.transactionFailedByUnknownReason }

        guard let plan = AccountPlan(storeKitProductId: transaction.payment.productIdentifier),
              let details = storeKitDelegate.servicePlanDataService?.detailsOfServicePlan(named: plan.rawValue),
            let planId = details.iD else {
            PMLog.debug("StoreKit: Can't fetch plan details")
            return
        }

        do {
            // buy plan
            if let request = try delegate.paymentsApiProtocol.buySubscriptionRequest(api: apiService, planId: planId, amount: plan.yearlyCost, paymentAction: .token(token: token.token)) {
                let recieptRes = try await(request.run())
                PMLog.debug("StoreKit: success (2)")
                if let newSubscription = recieptRes.newSubscription {
                    storeKitDelegate.servicePlanDataService?.currentSubscription = newSubscription
                    delegate.paymentQueueProtocol.finishTransaction(transaction)
                    self.finish(transaction: transaction, completion: completion)
                    delegate.tokenStorage?.clear()
                } else {
                    throw StoreKitManager.Errors.noNewSubscriptionInSuccessfullResponse
                }
            } else {
                // error from validate subscription
                retryOnError()
            }
        } catch let error {
            PMLog.debug("StoreKit: Buy plan failed: \(error.localizedDescription)")
            retryOnError()
        }
    }

    private func processUnauthenticated(withToken token: PaymentToken, transaction: SKPaymentTransaction, plan: AccountPlan, completion: @escaping CompletionCallback) throws {
        // In App Payment already succeeded at this point

        guard let delegate = delegate, let storeKitDelegate = delegate.storeKitDelegate, let apiService = storeKitDelegate.apiService else { throw StoreKitManager.Errors.transactionFailedByUnknownReason }

        do {
            let tokenStatusApi = delegate.paymentsApiProtocol.tokenStatusRequest(api: apiService, token: token)
            let tokenStatusRes = try await(tokenStatusApi.run())
            let status = tokenStatusRes.paymentTokenStatus?.status ?? .failed
            switch status {
            case .pending:
                // Waiting for the token to get ready to be charged (should not happen with IAP)
                PMLog.debug("StoreKit: token not ready yet. Scheduling retry in \(delegate.pendingRetry) seconds")
                queue.asyncAfter(deadline: .now() + delegate.pendingRetry) {
                    try? self.processUnauthenticated(withToken: token, transaction: transaction, plan: plan, completion: completion)
                }
                return
            case .chargeable:
                // Gr8 success
                delegate.transactionsBeforeSignup.append(transaction)
                delegate.successCallback?(token)
                completion()
                // Transaction will be finished after login
            default:
                PMLog.debug("StoreKit: token status: \(status)")
                delegate.tokenStorage?.clear()
                delegate.successCallback?(nil)
                completion()
                // Transaction will be finished after login
            }
        } catch let error {
            PMLog.debug("StoreKit: Get token info failed: \(error.localizedDescription)")
            delegate.tokenStorage?.clear()
            delegate.successCallback?(nil)
            completion()
            // Transaction will be finished after login
        }
    }

    private func finish(transaction: SKPaymentTransaction, completion: @escaping CompletionCallback) {
        guard let delegate = delegate else { return }
        delegate.paymentQueueProtocol.finishTransaction(transaction)
        delegate.transactionsBeforeSignup.removeAll(where: { $0 == transaction })
        NotificationCenter.default.post(name: StoreKitManager.transactionFinishedNotification, object: nil)
        completion()
    }

    // Alerts

    func retryAlertView(transaction: SKPaymentTransaction, plan: AccountPlan, completion: @escaping CompletionCallback) throws {
        guard let delegate = delegate else { throw StoreKitManager.Errors.transactionFailedByUnknownReason }
        delegate.alertManager.retryAlert { _ in
            try? self.processAuthenticatedBeforeSignup(transaction: transaction, plan: plan, completion: completion)
        } cancelAction: { _ in
            self.finish(transaction: transaction, completion: completion)
            delegate.alertManager.retryCancelAlert()
        }
    }
}
