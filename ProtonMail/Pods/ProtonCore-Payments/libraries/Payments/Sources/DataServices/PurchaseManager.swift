//
//  PaymentsManager.swift
//  ProtonCore_PaymentsUI - Created on 01/06/2021.
//
//  Copyright (c) 2021 Proton Technologies AG
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

import AwaitKit
import ProtonCore_Services

public enum PurchaseResult {
    case purchasedPlan(accountPlan: InAppPurchasePlan)
    case planPurchaseProcessingInProgress(processingPlan: InAppPurchasePlan)
    case purchaseError(error: Error, processingPlan: InAppPurchasePlan? = nil)
    case purchaseCancelled
}

public protocol PurchaseManagerProtocol {
    var unfinishedPurchasePlan: InAppPurchasePlan? { get }

    func buyPlan(plan: InAppPurchasePlan,
                 callFinishCallbackOn queueToCallFinishCallbackOn: DispatchQueue,
                 finishCallback: @escaping (PurchaseResult) -> Void)
}

public extension PurchaseManagerProtocol {

    /// If no queue to callFinishCallbackOn is provided, the finish callback **will be called on the main queue**
    func buyPlan(plan: InAppPurchasePlan, finishCallback: @escaping (PurchaseResult) -> Void) {
        buyPlan(plan: plan, callFinishCallbackOn: DispatchQueue.main, finishCallback: finishCallback)
    }
}

final class PurchaseManager: PurchaseManagerProtocol {

    private let planService: ServicePlanDataServiceProtocol
    private let storeKitManager: StoreKitManagerProtocol
    private var paymentsApi: PaymentsApiProtocol
    private let apiService: APIService

    private let queue = DispatchQueue(label: "PurchaseManager dispatch queue", qos: .userInitiated)

    var unfinishedPurchasePlan: InAppPurchasePlan? {
        guard storeKitManager.hasUnfinishedPurchase(), let transaction = storeKitManager.currentTransaction() else { return nil }
        return InAppPurchasePlan(storeKitProductId: transaction.payment.productIdentifier)
    }

    init(planService: ServicePlanDataServiceProtocol,
         storeKitManager: StoreKitManagerProtocol,
         paymentsApi: PaymentsApiProtocol,
         apiService: APIService) {
        self.planService = planService
        self.storeKitManager = storeKitManager
        self.paymentsApi = paymentsApi
        self.apiService = apiService
    }

    func buyPlan(plan: InAppPurchasePlan,
                 callFinishCallbackOn queueToCallFinishCallbackOn: DispatchQueue,
                 finishCallback finishCallbackToBeCalledOnProvidedQueue: @escaping (PurchaseResult) -> Void) {

        var callbackExecuted = false
        let finishCallback: (PurchaseResult) -> Void = { result in
            queueToCallFinishCallbackOn.async {
                guard callbackExecuted == false else {
                    assertionFailure("Purchase product completion block should be called only once")
                    return
                }
                callbackExecuted = true
                finishCallbackToBeCalledOnProvidedQueue(result)
            }
        }

        queue.async { [weak self] in
            do {
                try self?.buyPlanUsingProperFlow(plan: plan, finishCallback: finishCallback)
            } catch {
                finishCallback(.purchaseError(error: error, processingPlan: self?.unfinishedPurchasePlan))
            }
        }
    }

    private func buyPlanUsingProperFlow(plan: InAppPurchasePlan, finishCallback: @escaping (PurchaseResult) -> Void) throws {

        guard InAppPurchasePlan.isThisAFreePlan(protonName: plan.protonName) == false else {
            // "free plan" is really the lack of any plan — so no purchase is required if user selects free
            finishCallback(.purchasedPlan(accountPlan: plan))
            return
        }

        guard unfinishedPurchasePlan == nil else {
            // purchase already started, don't start it again, report back that we're in progress
            finishCallback(.planPurchaseProcessingInProgress(processingPlan: unfinishedPurchasePlan!))
            return
        }

        guard let details = planService.detailsOfServicePlan(named: plan.protonName),
              let planId = planService.detailsOfServicePlan(named: plan.protonName)?.iD else {
            // the plan details, including its id, are unknown, preventing us from doing any further operation
            assertionFailure("Programmer's error: buy plan method must be called when the plan details are available")
            throw StoreKitManagerErrors.transactionFailedByUnknownReason
        }

        let amountDue = try fetchAmountDue(protonPlanName: details.name)
        guard amountDue != .zero else {
            // backend indicated that plan can be bought for free — no need to initiate the IAP flow
            try buyPlanWhenAmountDueIsZero(plan: plan, planId: planId, finishCallback: finishCallback)
            return
        }

        // initiate the IAP flow
        buyPlanWhenIAPIsNecessaryToProvideMoney(plan: plan, amountDue: amountDue, finishCallback: finishCallback)
    }

    private func fetchAmountDue(protonPlanName: String) throws -> Int {

        let isAuthenticated = storeKitManager.delegate?.userId?.isEmpty == false
        let validateSubscriptionRequest = paymentsApi.validateSubscriptionRequest(
            api: apiService, protonPlanName: protonPlanName, isAuthenticated: isAuthenticated
        )

        let validationResponse = try AwaitKit.await(validateSubscriptionRequest.run())
        guard let amountDue = validationResponse.validateSubscription?.amountDue
        else { throw StoreKitManagerErrors.transactionFailedByUnknownReason }

        return amountDue
    }

    private func buyPlanWhenAmountDueIsZero(
        plan: InAppPurchasePlan, planId: String, finishCallback: @escaping (PurchaseResult) -> Void
    ) throws {
        let subscriptionRequest = paymentsApi.buySubscriptionForZeroRequest(api: apiService, planId: planId)
        let subscriptionResponse = try AwaitKit.await(subscriptionRequest.run())
        if let newSubscription = subscriptionResponse.newSubscription {
            planService.currentSubscription = newSubscription
            finishCallback(.purchasedPlan(accountPlan: plan))
        } else {
            throw StoreKitManager.Errors.noNewSubscriptionInSuccessfullResponse
        }
        return
    }

    private func buyPlanWhenIAPIsNecessaryToProvideMoney(
        plan: InAppPurchasePlan, amountDue: Int, finishCallback: @escaping (PurchaseResult) -> Void
    ) {
        self.storeKitManager.purchaseProduct(plan: plan, amountDue: amountDue) { _ in
            finishCallback(.purchasedPlan(accountPlan: plan))
        } errorCompletion: { [weak self] error in
            if let error = error as? StoreKitManagerErrors, error == .cancelled || error == .unknown {
                finishCallback(.purchaseCancelled)
            } else {
                finishCallback(.purchaseError(error: error, processingPlan: self?.unfinishedPurchasePlan))
            }
        }
    }
}
