//
//  PaymentsUIViewModelViewModel.swift
//  ProtonCore_PaymentsUI - Created on 01/06/2021.
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

import UIKit
import enum ProtonCore_DataModel.ClientApp
import ProtonCore_UIFoundations
import ProtonCore_Payments

enum FooterType {
    case withPlans
    case withoutPlans
    case disabled
}

final class PaymentsUIViewModelViewModel: CurrentSubscriptionChangeDelegate {
    
    private var servicePlan: ServicePlanDataServiceProtocol
    private let mode: PaymentsUIMode
    private var accountPlans: [InAppPurchasePlan] = []
    private let planRefreshHandler: (CurrentPlanDetails?) -> Void
    private let onError: (Error) -> Void

    private let storeKitManager: StoreKitManagerProtocol
    private let clientApp: ClientApp
    private let shownPlanNames: ListOfShownPlanNames

    // MARK: Public properties

    private (set) var plans: [[PlanPresentation]] = []
    private (set) var footerType: FooterType = .withoutPlans
    
    var isExpandButtonHidden: Bool {
        if UIDevice.current.isIpad, UIDevice.current.orientation.isPortrait {
            return true
        } else {
            return isExpandButtonHiddenByNumberOfPlans
        }
    }
    
    var shouldShowExpandButton: Bool {
        return UIDevice.current.isIpad && UIDevice.current.orientation.isLandscape && !isExpandButtonHiddenByNumberOfPlans
    }
    
    private var isExpandButtonHiddenByNumberOfPlans: Bool {
        plans
            .flatMap { $0 }
            .filter { !$0.accountPlan.isFreePlan }
            .count < 2
    }
    
    var iapInProgress: Bool { storeKitManager.hasIAPInProgress() }
    
    var processingAccountPlan: InAppPurchasePlan? {
        didSet {
            processDisablePlans()
        }
    }
    
    // MARK: Public interface
    
    init(mode: PaymentsUIMode,
         storeKitManager: StoreKitManagerProtocol,
         servicePlan: ServicePlanDataServiceProtocol,
         shownPlanNames: ListOfShownPlanNames,
         clientApp: ClientApp,
         planRefreshHandler: @escaping (CurrentPlanDetails?) -> Void,
         onError: @escaping (Error) -> Void) {
        self.mode = mode
        self.servicePlan = servicePlan
        self.storeKitManager = storeKitManager
        self.shownPlanNames = shownPlanNames
        self.clientApp = clientApp
        self.planRefreshHandler = planRefreshHandler
        self.onError = onError
        
        if self.mode != .signup {
            self.servicePlan.currentSubscriptionChangeDelegate = self
        }
        
        registerRefreshHandler()
    }
    
    func registerRefreshHandler() {
        storeKitManager.refreshHandler = { [weak self] in
            self?.fetchPlans(backendFetch: false) { [weak self] result in
                switch result {
                case .success:
                    self?.servicePlan.updateCredits { [weak self] in
                        self?.planRefreshHandler(nil)
                    } failure: { [weak self] _ in
                        self?.planRefreshHandler(nil)
                    }
                case .failure(let error):
                    self?.planRefreshHandler(nil)
                    self?.onError(error)
                }
            }
        }
    }

    func onCurrentSubscriptionChange(old: Subscription?, new: Subscription?) {
        let oldPlansCount = plansTotalCount
        self.createPlanPresentations(withCurrentPlan: self.mode == .current )
        if plansTotalCount < oldPlansCount, plansSectionCount == 1, case .current(let currentPlanPresentationType) = plans.first?.first?.planPresentationType {
            var currentPlan: CurrentPlanDetails?
            if let old = old, let new = new, !old.hasExistingProtonSubscription, new.hasExistingProtonSubscription {
                if case .details(let planDetails) = currentPlanPresentationType {
                    currentPlan = planDetails
                }
            }
            servicePlan.updateCredits { [weak self] in
                self?.planRefreshHandler(currentPlan)
            } failure: { [weak self] _ in
                self?.planRefreshHandler(currentPlan)
            }
        }
    }
    
    func fetchPlans(backendFetch: Bool, completionHandler: ((Result<([[PlanPresentation]], FooterType), Error>) -> Void)? = nil) {
        footerType = .withoutPlans
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

    private func fetchAllPlans(backendFetch: Bool, completionHandler: ((Result<([[PlanPresentation]], FooterType), Error>) -> Void)? = nil) {
        self.plans = []
        if backendFetch {
            updateServicePlans {
                self.processAllPlans(completionHandler: completionHandler)
            } failure: { error in
                completionHandler?(.failure(error))
            }
        } else {
            processAllPlans { result in
                // if there are no planes stored, fetch from backend
                if self.plansTotalCount == 0 {
                    self.fetchAllPlans(backendFetch: true, completionHandler: completionHandler)
                } else {
                    completionHandler?(result)
                }
            }
        }
    }
    
    private func processAllPlans(completionHandler: ((Result<([[PlanPresentation]], FooterType), Error>) -> Void)? = nil) {
        var localPlans = servicePlan.plans
            .compactMap {
                return createPlan(details: $0,
                                  isSelectable: true,
                                  isCurrent: false,
                                  isMultiUser: false,
                                  hasPaymentMethods: servicePlan.hasPaymentMethods,
                                  endDate: nil,
                                  price: nil,
                                  cycle: $0.cycle)
            }
        let updatedFreePlan = updatedFreePlanPrice(plansPresentation: localPlans)
        localPlans = localPlans.map { $0.accountPlan.isFreePlan ? updatedFreePlan ?? $0 : $0 }
        if localPlans.count > 0 {
            self.plans.append(localPlans)
        }
        footerType = .withPlans
        completionHandler?(.success((self.plans, footerType)))
    }
    
    private func getLocaleFromIAP(plansPresentation: [PlanPresentation]) -> Locale {
        for plan in plansPresentation {
            if let locale = PlanPresentation.getLocale(from: plan.accountPlan.protonName, storeKitManager: storeKitManager) {
                return locale
            }
        }
        return Locale.autoupdatingCurrent
    }
    
    private func updatedFreePlanPrice(plansPresentation: [PlanPresentation]) -> PlanPresentation? {
        var updatedFreePlan: PlanPresentation?
        plansPresentation.forEach {
            if $0.accountPlan.isFreePlan {
                let locale = getLocaleFromIAP(plansPresentation: plansPresentation)
                updatedFreePlan = $0
                switch updatedFreePlan?.planPresentationType {
                case .current(let current):
                    switch current {
                    case .details(var currentPlanDetails):
                        currentPlanDetails.price = InAppPurchasePlan.formatPlanPrice(price: NSDecimalNumber(value: 0.0), locale: locale, maximumFractionDigits: 0)
                        updatedFreePlan?.planPresentationType = .current(.details( currentPlanDetails))
                    default: break
                    }
                case .plan(var plan):
                    plan.price = InAppPurchasePlan.formatPlanPrice(price: NSDecimalNumber(value: 0.0), locale: locale, maximumFractionDigits: 0)
                    updatedFreePlan?.planPresentationType = .plan(plan)
                case .none:
                    break
                }
            }
        }
        return updatedFreePlan
    }

    // MARK: Private methods - Update plans (current, update mode)
    
    private func fetchPlansToPresent(withCurrentPlan: Bool, backendFetch: Bool, completionHandler: ((Result<([[PlanPresentation]], FooterType), Error>) -> Void)? = nil) {
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
    
    private func createPlanPresentations(withCurrentPlan: Bool, completionHandler: ((Result<([[PlanPresentation]], FooterType), Error>) -> Void)? = nil) {
        var plans: [[PlanPresentation]] = []
        let userHasNoAccessToThePlan = self.servicePlan.currentSubscription?.isEmptyBecauseOfUnsufficientScopeToFetchTheDetails == true
        let userHasNoPlan = !userHasNoAccessToThePlan && (self.servicePlan.currentSubscription?.planDetails.map { $0.isEmpty } ?? true)
        let freePlan = servicePlan.detailsOfServicePlan(named: InAppPurchasePlan.freePlanName).flatMap {
            self.createPlan(details: $0,
                            isSelectable: false,
                            isCurrent: true,
                            isMultiUser: false,
                            hasPaymentMethods: servicePlan.hasPaymentMethods,
                            endDate: nil,
                            price: nil,
                            cycle: nil)
        }

        if userHasNoPlan {

            let plansToShow = self.servicePlan.availablePlansDetails
                .compactMap {
                    createPlan(details: $0,
                               isSelectable: true,
                               isCurrent: false,
                               isMultiUser: false,
                               hasPaymentMethods: servicePlan.hasPaymentMethods,
                               endDate: nil,
                               price: nil,
                               cycle: $0.cycle)
                }
            
            if let freePlan = freePlan {
                if withCurrentPlan {
                    plans.append([updatedFreePlanPrice(plansPresentation: plansToShow + [freePlan]) ?? freePlan])
                } else if plansToShow.isEmpty {
                    // if mode is update and there are no any plans to update then show free plan as a current plan.
                    plans.append([freePlan])
                }
            }
            if !plansToShow.isEmpty {
                plans.append(plansToShow)
            }
            footerType = plansToShow.isEmpty ? .withoutPlans : .withPlans
            self.plans = plans
            completionHandler?(.success((self.plans, footerType)))

        } else if userHasNoAccessToThePlan {
            plans.append([PlanPresentation.unavailableBecauseUserHasNoAccessToPlanDetails])
            footerType = .disabled
            self.plans = plans
            completionHandler?(.success((self.plans, footerType)))

        } else {
            if let subscription = self.servicePlan.currentSubscription,
               let accountPlan = InAppPurchasePlan(protonName: subscription.computedPresentationDetails(shownPlanNames: shownPlanNames).name,
                                                   listOfIAPIdentifiers: storeKitManager.inAppPurchaseIdentifiers),
               let plan = self.createPlan(details: subscription.computedPresentationDetails(shownPlanNames: shownPlanNames),
                                          isSelectable: false,
                                          isCurrent: true,
                                          isMultiUser: subscription.organization?.isMultiUser ?? false,
                                          hasPaymentMethods: servicePlan.hasPaymentMethods,
                                          endDate: servicePlan.endDateString(plan: accountPlan),
                                          price: subscription.price,
                                          cycle: subscription.cycle) {
                plans.append([plan])
                self.plans = plans
                completionHandler?(.success((self.plans, footerType)))
            } else {
                // there is an other subscription type
                if let freePlan = freePlan {
                    plans.append([freePlan])
                }
                self.plans = plans
                completionHandler?(.success((self.plans, footerType)))
            }
        }
    }
    
    // MARK: Private methods - support methods
    
    private var plansTotalCount: Int {
        return plans.flatMap { $0 }.count
    }
    
    private var plansSectionCount: Int {
        return plans.count
    }
    
    private func updateServicePlanDataService(completion: @escaping (Result<(), Error>) -> Void) {
        updateServicePlans {
            if self.servicePlan.isIAPAvailable {
                self.servicePlan.updateCurrentSubscription {
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

    // swiftlint:disable function_parameter_count
    private func createPlan(details baseDetails: Plan,
                            isSelectable: Bool,
                            isCurrent: Bool,
                            isMultiUser: Bool,
                            hasPaymentMethods: Bool,
                            endDate: NSAttributedString?,
                            price: String?,
                            cycle: Int?) -> PlanPresentation? {
        
        // we need to remove all other plans not defined in the shownPlanNames
        guard shownPlanNames.contains(where: { baseDetails.name == $0 }) || InAppPurchasePlan.isThisAFreePlan(protonName: baseDetails.name) else {
            return nil
        }

        // we only show plans that are either current or available for purchase
        guard isCurrent || baseDetails.isPurchasable else { return nil }

        var details = servicePlan.defaultPlanDetails.map { Plan.combineDetailsDroppingPricing(baseDetails, $0) } ?? baseDetails
        if let cycle = cycle {
            details = details.updating(cycle: cycle)
        }
        return PlanPresentation.createPlan(from: details,
                                           servicePlan: servicePlan,
                                           clientApp: clientApp,
                                           storeKitManager: storeKitManager,
                                           isCurrent: isCurrent,
                                           isSelectable: isSelectable,
                                           isMultiUser: isMultiUser,
                                           hasPaymentMethods: hasPaymentMethods,
                                           endDate: endDate,
                                           price: price)
    }
    
    private func processDisablePlans() {
        guard let currentlyProcessingPlan = self.processingAccountPlan else { return }
        self.plans.forEach {
            $0.forEach {
                if case .plan(var planDetails) = $0.planPresentationType {
                    if let planId = $0.storeKitProductId,
                       let processingPlanId = currentlyProcessingPlan.storeKitProductId,
                       planId == processingPlanId {
                        $0.isCurrentlyProcessed = true
                        planDetails.isSelectable = true
                    } else {
                        planDetails.isSelectable = false
                    }
                    $0.planPresentationType = .plan(planDetails)
                }
            }
        }
        footerType = .withoutPlans
        planRefreshHandler(nil)
    }
    
    private func updateServicePlans(success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        if clientApp == .vpn {
            servicePlan.updateCountriesCount { [weak self] in
                self?.servicePlan.updateServicePlans(success: success, failure: failure)
            } failure: { [weak self] error in
                self?.servicePlan.updateServicePlans(success: success, failure: failure)
            }
        } else {
            servicePlan.updateServicePlans(success: success, failure: failure)
        }
    }
}
