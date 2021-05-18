//
//  ProcessAuthenticated.swift
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

class ProcessAuthenticated: ProcessProtocol {

    weak var delegate: ProcessDelegateProtocol?
    let queue = DispatchQueue(label: "ProcessAuthenticated async queue")

    func process(transaction: SKPaymentTransaction, plan: AccountPlan, completion: @escaping CompletionCallback) throws {
        guard let delegate = delegate, let storeKitDelegate = delegate.storeKitDelegate else {
            throw StoreKitManager.Errors.transactionFailedByUnknownReason
        }
        guard let details = storeKitDelegate.servicePlanDataService?.detailsOfServicePlan(named: plan.rawValue),
            let planId = details.iD else {
            delegate.errorCallback(StoreKitManager.Errors.alreadyPurchasedPlanDoesNotMatchBackend)
            completion()
            return
        }

        // Create token
        guard let token = delegate.tokenStorage?.get() else {
            return try getToken(transaction: transaction, plan: plan, planId: planId, completion: completion)
        }

        do {
            guard let apiService = storeKitDelegate.apiService else {
                throw StoreKitManager.Errors.transactionFailedByUnknownReason
            }
            let tokenStatusApi = delegate.paymentsApiProtocol.tokenStatusRequest(api: apiService, token: token)
            let tokenStatusRes = try await(tokenStatusApi.run())
            let status = tokenStatusRes.paymentTokenStatus?.status ?? .failed
            switch status {
            case .pending:
                // Waiting for the token to get ready to be charged (should not happen with IAP)
                PMLog.debug("StoreKit: token not ready yet. Scheduling retry in \(delegate.pendingRetry) seconds")
                queue.asyncAfter(deadline: .now() + delegate.pendingRetry) {
                    try? self.process(transaction: transaction, plan: plan, completion: completion)
                }
                return
            case .chargeable:
                // Gr8 success
                try buySubscription(transaction: transaction, plan: plan, token: token, completion: completion)
            case .failed, .notSupported:
                // throw away token and retry with the new one
                PMLog.debug("StoreKit: token \(status == .failed ? "failed" : "not supported")")
                delegate.tokenStorage?.clear()
                delegate.errorCallback(StoreKitManager.Errors.wrongTokenStatus(status))
                completion()
            case .consumed:
                // throw away token and receipt
                PMLog.debug("StoreKit: token already consumed")
                delegate.paymentQueueProtocol.finishTransaction(transaction)
                delegate.tokenStorage?.clear()
                delegate.successCallback?(nil)
                completion()
            }
        } catch let error {
            PMLog.debug("StoreKit: Get token info failed: \(error.localizedDescription)")
            delegate.errorCallback(error)
            completion()
        }
    }

    private func getToken(transaction: SKPaymentTransaction, plan: AccountPlan, planId: String, completion: @escaping CompletionCallback) throws {
        guard let delegate = delegate, let storeKitDelegate = delegate.storeKitDelegate, let apiService = storeKitDelegate.apiService else { throw StoreKitManager.Errors.transactionFailedByUnknownReason }
        let receipt = try delegate.getReceipt()

        PMLog.debug("StoreKit: No proton token found")
        do {
            let tokenApi = delegate.paymentsApiProtocol.tokenRequest(api: apiService, amount: plan.yearlyCost, receipt: receipt)
            let tokenRes = try await(tokenApi.run())
            guard let token = tokenRes.paymentToken else { return }
            delegate.tokenStorage?.add(token)
            try? self.process(transaction: transaction, plan: plan, completion: completion) // Exception would've been thrown on the first call
        } catch let error where error.isSandboxReceiptError {
            // sandbox receipt sent to BE
            PMLog.debug("StoreKit: sandbox receipt sent to BE")
            delegate.paymentQueueProtocol.finishTransaction(transaction)
            delegate.tokenStorage?.clear()
            delegate.errorCallback(error)
            completion()
        } catch let error where error.isApplePaymentAlreadyRegisteredError {
            // Apple payment already registered
            PMLog.debug("StoreKit: apple payment already registered (2)")
            delegate.paymentQueueProtocol.finishTransaction(transaction)
            delegate.tokenStorage?.clear()
            delegate.successCallback?(nil)
            completion()
        }
        return
    }

    private func buySubscription(transaction: SKPaymentTransaction, plan: AccountPlan, token: PaymentToken, completion: @escaping CompletionCallback) throws {
        guard let delegate = delegate, let storeKitDelegate = delegate.storeKitDelegate, let apiService = storeKitDelegate.apiService else { throw StoreKitManager.Errors.transactionFailedByUnknownReason }

        let planId = try servicePlan(for: transaction.payment.productIdentifier)
        do {
            // buy plan
            var request: SubscriptionRequest
            if let recieptApi = try delegate.paymentsApiProtocol.buySubscriptionRequest(api: apiService, planId: planId, amount: plan.yearlyCost, paymentAction: .token(token: token.token)) {
                request = recieptApi
            } else {
                // error from validate subscription
                request = SubscriptionRequest(api: apiService, planId: planId, amount: plan.yearlyCost, paymentAction: .token(token: token.token))
            }
            let recieptRes = try await(request.run())
            PMLog.debug("StoreKit: success (1)")
            if let newSubscription = recieptRes.newSubscription {
                storeKitDelegate.servicePlanDataService?.currentSubscription = newSubscription
                delegate.paymentQueueProtocol.finishTransaction(transaction)
                delegate.tokenStorage?.clear()
                delegate.successCallback?(nil)
                completion()
            } else {
                throw StoreKitManager.Errors.noNewSubscriptionInSuccessfullResponse
            }
        } catch let error where error.isPaymentAmmountMismatchError {
            PMLog.debug("StoreKit: amount mismatch")
            // ammount mismatch
            do {
                let serverUpdateApi = delegate.paymentsApiProtocol.creditRequest(api: apiService, amount: plan.yearlyCost, paymentAction: .token(token: token.token))
                _ = try await(serverUpdateApi.run())
                delegate.paymentQueueProtocol.finishTransaction(transaction)
                delegate.tokenStorage?.clear()
                delegate.errorCallback(StoreKitManager.Errors.creditsApplied)
                completion()
            } catch let error where error.isApplePaymentAlreadyRegisteredError {
                PMLog.debug("StoreKit: apple payment already registered")
                delegate.paymentQueueProtocol.finishTransaction(transaction)
                delegate.tokenStorage?.clear()
                delegate.successCallback?(nil)
                completion()
            }
        } catch let error as RequestErrors where error == RequestErrors.subscriptionDecode {
            throw StoreKitManager.Errors.noNewSubscriptionInSuccessfullResponse
        } catch let error {
            delegate.errorCallback(error)
            completion()
        }
    }

    private func servicePlan(for productId: String) throws -> String {
        guard let plan = AccountPlan(storeKitProductId: productId),
              let details = delegate?.storeKitDelegate?.servicePlanDataService?.detailsOfServicePlan(named: plan.rawValue),
            let planId = details.iD else {
            throw StoreKitManager.Errors.alreadyPurchasedPlanDoesNotMatchBackend
        }
        return planId
    }
}
