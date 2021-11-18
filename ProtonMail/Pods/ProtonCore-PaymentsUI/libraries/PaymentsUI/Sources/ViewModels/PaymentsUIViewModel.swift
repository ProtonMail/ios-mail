//
//  PaymentsUIViewModelViewModel.swift
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

import UIKit
import ProtonCore_UIFoundations
import ProtonCore_Payments

final class PaymentsUIViewModelViewModel: CurrentSubscriptionChangeDelegate {
    
    private var servicePlan: ServicePlanDataServiceProtocol
    private let mode: PaymentsUIMode
    private var accountPlans: [InAppPurchasePlan] = []
    private var planRefreshHandler: (() -> Void)?

    private let storeKitManager: StoreKitManagerProtocol
    private let updateCredits: Bool

    // MARK: Public properties
    
    private (set) var plans: [PlanPresentation] = []
    private (set) var isAnyPlanToPurchase = false
    
    var processingAccountPlan: InAppPurchasePlan? {
        didSet {
            processDisablePlans()
        }
    }
    
    // MARK: Public interface
    
    init(mode: PaymentsUIMode,
         storeKitManager: StoreKitManagerProtocol,
         servicePlan: ServicePlanDataServiceProtocol,
         updateCredits: Bool,
         planRefreshHandler: (() -> Void)? = nil) {
        self.mode = mode
        self.servicePlan = servicePlan
        self.storeKitManager = storeKitManager
        self.updateCredits = updateCredits
        self.planRefreshHandler = planRefreshHandler
        
        if self.mode != .signup {
            self.servicePlan.currentSubscriptionChangeDelegate = self
        }
    }

    func onCurrentSubscriptionChange(old _: Subscription?, new: Subscription?) {
        let oldPlansCount = self.plans.count
        self.createPlanPresentations(withCurrentPlan: self.mode == .current )
        if self.plans.count < oldPlansCount {
            if updateCredits {
                servicePlan.updateCredits {
                    self.planRefreshHandler?()
                } failure: { _ in
                    self.planRefreshHandler?()
                }
            } else {
                self.planRefreshHandler?()
            }
        }
    }
    
    func fetchPlans(backendFetch: Bool, completionHandler: ((Result<([PlanPresentation], Bool), Error>) -> Void)? = nil) {
        isAnyPlanToPurchase = false
        switch mode {
        case .signup:
            fetchAllPlans(backendFetch: backendFetch, completionHandler: completionHandler)
        case .current:
            fetchPlansToPresent(withCurrentPlan: true, backendFetch: backendFetch, completionHandler: completionHandler)
        case .update:
            fetchPlansToPresent(withCurrentPlan: false, backendFetch: backendFetch, completionHandler: completionHandler)
        }

    }
    
    // MARK: Private methods - All plans (signup mode)

    private func fetchAllPlans(backendFetch: Bool, completionHandler: ((Result<([PlanPresentation], Bool), Error>) -> Void)? = nil) {
        self.plans = []
        if backendFetch {
            servicePlan.updateServicePlans {
                self.processAllPlans(completionHandler: completionHandler)
            } failure: { error in
                completionHandler?(.failure(error))
            }
        } else {
            processAllPlans { result in
                // if there are no planes stored, fetch from backend
                if self.plans.count == 0 {
                    self.fetchAllPlans(backendFetch: true, completionHandler: completionHandler)
                } else {
                    completionHandler?(result)
                }
            }
        }
    }
    
    private func processAllPlans(completionHandler: ((Result<([PlanPresentation], Bool), Error>) -> Void)? = nil) {
        self.plans = servicePlan.plans
            .compactMap {
                return createPlan(details: $0, isSelectable: true, isCurrent: false, isMultiUser: false)
            }
        self.isAnyPlanToPurchase = true
        completionHandler?(.success((self.plans, true)))
    }

    // MARK: Private methods - Update plans (current, update mode)
    
    private func fetchPlansToPresent(withCurrentPlan: Bool, backendFetch: Bool, completionHandler: ((Result<([PlanPresentation], Bool), Error>) -> Void)? = nil) {
        if backendFetch {
            updateServicePlanDataService { result in
                switch result {
                case .success:
                    self.createPlanPresentations(withCurrentPlan: withCurrentPlan, completionHandler: completionHandler)
                case .failure(let error):
                    completionHandler?(.failure(error))
                }
            }
        } else {
            self.createPlanPresentations(withCurrentPlan: withCurrentPlan, completionHandler: completionHandler)
        }
    }
    
    private func createPlanPresentations(withCurrentPlan: Bool, completionHandler: ((Result<([PlanPresentation], Bool), Error>) -> Void)? = nil) {
        self.plans = []
        let userHasNoAccessToThePlan = self.servicePlan.currentSubscription?.isEmptyBecauseOfUnsufficientScopeToFetchTheDetails == true
        let userHasNoPlan = !userHasNoAccessToThePlan && (self.servicePlan.currentSubscription?.planDetails.map { $0.isEmpty } ?? true)
        let freePlan = servicePlan.detailsOfServicePlan(named: InAppPurchasePlan.freePlanName).flatMap {
            self.createPlan(details: $0, isSelectable: false, isCurrent: true, isMultiUser: false)
        }

        if userHasNoPlan {

            if withCurrentPlan, let freePlan = freePlan {
                self.plans = [freePlan]
            }
            let plansToShow = self.servicePlan.availablePlansDetails
                .compactMap { createPlan(details: $0, isSelectable: true, isCurrent: false, isMultiUser: false) }
            self.plans += plansToShow
            self.isAnyPlanToPurchase = !plansToShow.isEmpty
            completionHandler?(.success((self.plans, self.isAnyPlanToPurchase)))

        } else if userHasNoAccessToThePlan {
            self.plans = [PlanPresentation.unavailableBecauseUserHasNoAccessToPlanDetails]
            completionHandler?(.success((self.plans, false)))

        } else {

            if let subscription = self.servicePlan.currentSubscription,
               let accountPlan = InAppPurchasePlan(protonName: subscription.computedPresentationDetails.name,
                                                   listOfIAPIdentifiers: storeKitManager.inAppPurchaseIdentifiers),
               let plan = self.createPlan(details: subscription.computedPresentationDetails,
                                          isSelectable: false,
                                          isCurrent: true,
                                          isMultiUser: subscription.organization?.isMultiUser ?? false,
                                          endDate: servicePlan.endDateString(plan: accountPlan)) {
                self.plans += [plan]
                completionHandler?(.success((self.plans, self.isAnyPlanToPurchase)))
            } else {
                // there is an other subscription type
                if let freePlan = freePlan {
                    self.plans += [freePlan]
                    completionHandler?(.success((self.plans, self.isAnyPlanToPurchase)))
                }
            }
        }
    }
    
    // MARK: Private methods - support methods
    
    private func updateServicePlanDataService(completion: @escaping (Result<(), Error>) -> Void) {
        servicePlan.updateServicePlans {
            if self.servicePlan.isIAPAvailable {
                self.servicePlan.updateCurrentSubscription(updateCredits: self.updateCredits) {
                    completion(.success(()))
                } failure: { error in
                    completion(.failure(error))
                }
            } else {
                completion(.failure(StoreKitManagerErrors.transactionFailedByUnknownReason))
            }
        } failure: { error in
            completion(.failure(error))
        }
    }

    private func createPlan(details baseDetails: Plan, isSelectable: Bool, isCurrent: Bool, isMultiUser: Bool, endDate: NSAttributedString? = nil) -> PlanPresentation? {

        // we only show plans that are either current or available for purchase
        guard isCurrent || baseDetails.isPurchasable else { return nil }

        let details = servicePlan.defaultPlanDetails.map { Plan.combineDetailsDroppingPricing(baseDetails, $0) } ?? baseDetails

        return PlanPresentation.createPlan(from: details,
                                           storeKitManager: storeKitManager,
                                           isCurrent: isCurrent,
                                           isSelectable: isSelectable,
                                           isMultiUser: isMultiUser,
                                           endDate: endDate)
    }
    
    private func processDisablePlans() {
        guard let currentlyProcessingPlan = self.processingAccountPlan else { return }
        self.plans = self.plans.map {
            var plan = $0
            plan.isSelectable = false
            if let planId = plan.storeKitProductId,
               let processingPlanId = currentlyProcessingPlan.storeKitProductId,
               planId == processingPlanId {
                plan.isCurrentlyProcessed = true
            }
            return plan
        }
        isAnyPlanToPurchase = false
    }
}
