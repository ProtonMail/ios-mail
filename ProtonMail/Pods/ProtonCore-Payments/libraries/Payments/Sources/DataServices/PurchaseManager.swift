//
//  PurchaseManager.swift
//  ProtonCorePaymentsUI - Created on 01/06/2021.
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

import Foundation
import ProtonCoreFeatureFlags
import ProtonCoreServices
import ProtonCoreObservability
import ProtonCoreUtilities

public enum PurchaseResult {
    case purchasedPlan(accountPlan: InAppPurchasePlan)
    case toppedUpCredits
    case planPurchaseProcessingInProgress(processingPlan: InAppPurchasePlan)
    case purchaseError(error: Error, processingPlan: InAppPurchasePlan? = nil)
    case apiMightBeBlocked(message: String, originalError: Error, processingPlan: InAppPurchasePlan? = nil)
    case purchaseCancelled
}

public protocol PurchaseManagerProtocol {
    /// Plan corresponding to the first successful transaction pending to process, if any
    var unfinishedPurchasePlan: InAppPurchasePlan? { get }

    func buyPlan(plan: InAppPurchasePlan,
                 addCredits: Bool,
                 callFinishCallbackOn queueToCallFinishCallbackOn: DispatchQueue,
                 finishCallback: @escaping (PurchaseResult) -> Void)
}

public extension PurchaseManagerProtocol {

    /// If no queue to callFinishCallbackOn is provided, the finish callback **will be called on the main queue**
    func buyPlan(plan: InAppPurchasePlan, addCredits: Bool = false, finishCallback: @escaping (PurchaseResult) -> Void) {
        buyPlan(plan: plan, addCredits: addCredits, callFinishCallbackOn: DispatchQueue.main, finishCallback: finishCallback)
    }
}

final class PurchaseManager: PurchaseManagerProtocol {

    private let planService: Either<ServicePlanDataServiceProtocol, PlansDataSourceProtocol>
    private let storeKitManager: StoreKitManagerProtocol
    private var paymentsApi: PaymentsApiProtocol
    private let apiService: APIService
    private let featureFlagsRepository: FeatureFlagsRepositoryProtocol

    private let queue = DispatchQueue(label: "PurchaseManager dispatch queue", qos: .userInitiated)

    var unfinishedPurchasePlan: InAppPurchasePlan? {
        guard storeKitManager.hasUnfinishedPurchase(), let transaction = storeKitManager.currentTransaction() else { return nil }
        return InAppPurchasePlan(storeKitProductId: transaction.payment.productIdentifier)
    }

    init(planService: Either<ServicePlanDataServiceProtocol, PlansDataSourceProtocol>,
         storeKitManager: StoreKitManagerProtocol,
         paymentsApi: PaymentsApiProtocol,
         apiService: APIService,
         featureFlagsRepository: FeatureFlagsRepositoryProtocol = FeatureFlagsRepository.shared) {
        self.planService = planService
        self.storeKitManager = storeKitManager
        self.paymentsApi = paymentsApi
        self.apiService = apiService
        self.featureFlagsRepository = featureFlagsRepository
    }

    func buyPlan(plan: InAppPurchasePlan,
                 addCredits: Bool,
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
                try self?.buyPlanUsingProperFlow(plan: plan, addCredits: addCredits, finishCallback: finishCallback)
            } catch {
                finishCallback(.purchaseError(error: error, processingPlan: self?.unfinishedPurchasePlan))
            }
        }
    }

    private func buyPlanUsingProperFlow(plan: InAppPurchasePlan, addCredits: Bool, finishCallback: @escaping (PurchaseResult) -> Void) throws {

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

        let planName: String
        let planId: String
        let cycle: Int
        switch planService {
        case .left(let planService):
            guard let details = planService.detailsOfPlanCorrespondingToIAP(plan),
                  let id = planService.detailsOfPlanCorrespondingToIAP(plan)?.ID else {
                // the plan details, including its id, are unknown, preventing us from doing any further operation
                assertionFailure("Programmer's error: buy plan method must be called when the plan details are available")
                throw StoreKitManagerErrors.transactionFailedByUnknownReason
            }
            planName = details.name
            planId = id
            cycle = 12

        case .right(let planDataSource):
            guard let availablePlan = planDataSource.detailsOfAvailablePlanCorrespondingToIAP(plan),
                  let instance = planDataSource.detailsOfAvailablePlanInstanceCorrespondingToIAP(plan),
                  let name = availablePlan.name,
                  let id = availablePlan.ID else {
                // the plan details, including its id, are unknown, preventing us from doing any further operation
                assertionFailure("Programmer's error: buy plan method must be called when the plan details are available")
                throw StoreKitManagerErrors.transactionFailedByUnknownReason
            }
            planName = name
            planId = id
            cycle = instance.cycle
        }

        var amountDue = 0
        if !addCredits {
            amountDue = try fetchAmountDue(protonPlanName: planName, cycle: cycle)
            guard amountDue != .zero else {
                // backend indicated that plan can be bought for free — no need to initiate the IAP flow
                try buyPlanWhenAmountDueIsZero(plan: plan, finishCallback: finishCallback)
                return
            }
        }

        // initiate the IAP flow
        buyPlanWhenIAPIsNecessaryToProvideMoney(plan: plan, amountDue: amountDue, finishCallback: finishCallback)
    }

    private func fetchAmountDue(protonPlanName: String, cycle: Int) throws -> Int {

        let isDynamic = featureFlagsRepository.isEnabled(CoreFeatureFlagType.dynamicPlan)
        let isAuthenticated = storeKitManager.delegate?.userId?.isEmpty == false
        let validateSubscriptionRequest = paymentsApi.validateSubscriptionRequest(
            api: apiService,
            protonPlanName: protonPlanName,
            isAuthenticated: isAuthenticated,
            cycle: cycle
        )

        let validationResponse = try validateSubscriptionRequest.awaitResponse(responseObject: ValidateSubscriptionResponse())
        if let validationError = validationResponse.error {
            ObservabilityEnv.report(.paymentValidatePlanTotal(error: validationError, isDynamic: featureFlagsRepository.isEnabled(CoreFeatureFlagType.dynamicPlan)))
        } else {
            ObservabilityEnv.report(.paymentValidatePlanTotal(status: .http2xx, isDynamic: featureFlagsRepository.isEnabled(CoreFeatureFlagType.dynamicPlan)))
        }

        guard let amountDue = isDynamic ? validationResponse.validateSubscription?.amount : validationResponse.validateSubscription?.amountDue
        else { throw StoreKitManagerErrors.transactionFailedByUnknownReason }

        return amountDue
    }

    private func buyPlanWhenAmountDueIsZero(
        plan: InAppPurchasePlan, finishCallback: @escaping (PurchaseResult) -> Void
    ) throws {
        let processablePlan = try plan.processablePlan()
        let subscriptionRequest = paymentsApi.buySubscriptionForZeroRequest(api: apiService, plan: processablePlan)
        let subscriptionResponse = try subscriptionRequest.awaitResponse(responseObject: SubscriptionResponse())
        if let newSubscription = subscriptionResponse.newSubscription {
            switch planService {
            case .left(let planService):
                planService.updateCurrentSubscription { [weak self] in
                    finishCallback(.purchasedPlan(accountPlan: plan))
                    self?.storeKitManager.refreshHandler(.finished(.resolvingIAPToSubscription))
                } failure: { [weak self] _ in
                    // if updateCurrentSubscription is failed for some reason, update subscription with newSubscription data
                    planService.currentSubscription = newSubscription
                    finishCallback(.purchasedPlan(accountPlan: plan))
                    self?.storeKitManager.refreshHandler(.finished(.resolvingIAPToSubscription))
                }

            case .right(let planDataSource):
                Task { [weak self] in
                    do {
                        try await planDataSource.fetchCurrentPlan()
                        finishCallback(.purchasedPlan(accountPlan: plan))
                        self?.storeKitManager.refreshHandler(.finished(.resolvingIAPToSubscription))
                    } catch {
                        finishCallback(.purchasedPlan(accountPlan: plan))
                        self?.storeKitManager.refreshHandler(.errored(StoreKitManagerErrors.noNewSubscriptionInSuccessfulResponse))
                    }
                }
            }
        } else {
            throw StoreKitManager.Errors.noNewSubscriptionInSuccessfulResponse
        }
        return
    }

    private func buyPlanWhenIAPIsNecessaryToProvideMoney(
        plan: InAppPurchasePlan, amountDue: Int, finishCallback: @escaping (PurchaseResult) -> Void
    ) {
        ObservabilityEnv.report(.paymentScreenView(screenID: .aiapBilling))
        self.storeKitManager.purchaseProduct(plan: plan, amountDue: amountDue) { [weak self] result in
            guard let self else {
                finishCallback(.purchaseCancelled)
                return
            }
            if case .cancelled = result {
                finishCallback(.purchaseCancelled)
            } else if case .resolvingIAPToCredits = result,
                      !self.featureFlagsRepository.isEnabled(CoreFeatureFlagType.dynamicPlan) {
                finishCallback(.toppedUpCredits)
            } else if case .resolvingIAPToCreditsCausedByError = result,
                      !self.featureFlagsRepository.isEnabled(CoreFeatureFlagType.dynamicPlan) {
                finishCallback(.toppedUpCredits)
            } else {
                finishCallback(.purchasedPlan(accountPlan: plan))
            }
        } errorCompletion: { [weak self] error in
            // ignored payment errors
            if let error = error as? StoreKitManagerErrors, error == .notAllowed || error.isUnknown || error == .alreadyPurchasedPlanDoesNotMatchBackend {
                finishCallback(.purchaseCancelled)
            } else if let error = error as? StoreKitManagerErrors, case .apiMightBeBlocked(let message, let originalError) = error {
                finishCallback(.apiMightBeBlocked(message: message, originalError: originalError, processingPlan: self?.unfinishedPurchasePlan))
            } else {
                finishCallback(.purchaseError(error: error, processingPlan: self?.unfinishedPurchasePlan))
            }
        }
    }
}
