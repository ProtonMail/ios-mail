//
//  PaymentsUIViewModel.swift
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

#if os(iOS)

import UIKit
import enum ProtonCoreDataModel.ClientApp
import ProtonCoreUIFoundations
import ProtonCorePayments
import ProtonCoreUtilities
import ProtonCoreFeatureFlags

enum FooterType: Equatable {
    static func == (lhs: FooterType, rhs: FooterType) -> Bool {
        switch (lhs, rhs) {
        case (.withPlansToBuy, .withPlansToBuy): return true
        case (.withoutPlansToBuy, .withoutPlansToBuy): return true
        case (.withExtendSubscriptionButton, .withExtendSubscriptionButton): return true
        case (.disabled, .disabled): return true
        default: return false
        }
    }

    case withPlansToBuy // only used pre-Dynamic Plans
    case withoutPlansToBuy
    case withExtendSubscriptionButton(PlanPresentation) // only used pre-Dynamic Plans
    case disabled
}

enum PaymentCellType {
    case alert(AlertBoxViewModel)
    case currentPlan(CurrentPlanPresentation)
    case availablePlan(AvailablePlansPresentation)
}

class PaymentsUIViewModel {
    private var isDynamicPlansEnabled: Bool {
        featureFlagsRepository.isEnabled(CoreFeatureFlagType.dynamicPlan)
    }
    private var isSplitStorageEnabled: Bool {
        featureFlagsRepository.isEnabled(CoreFeatureFlagType.splitStorage)
    }
    private var planService: Either<ServicePlanDataServiceProtocol, PlansDataSourceProtocol>

    private var servicePlan: ServicePlanDataServiceProtocol? {
        guard !isDynamicPlansEnabled, case .left(let servicePlan) = planService else {
            assertionFailure("Dynamic plans can't use the ServicePlanDataServiceProtocol object")
            return nil
        }
        return servicePlan
    }

    private var plansDataSource: PlansDataSourceProtocol? {
        guard isDynamicPlansEnabled, case .right(let plansDataSource) = planService else {
            assertionFailure("Dynamic plans must use the PlansDataSourceProtocol object")
            return nil
        }
        return plansDataSource
    }

    private let mode: PaymentsUIMode
    private var accountPlans: [InAppPurchasePlan] = []
    private let planRefreshHandler: (CurrentPlanDetails?) -> Void
    private let extendSubscriptionHandler: () -> Void

    private let storeKitManager: StoreKitManagerProtocol
    private let clientApp: ClientApp
    private let shownPlanNames: ListOfShownPlanNames
    private let customPlansDescription: CustomPlansDescription
    private let featureFlagsRepository: FeatureFlagsRepositoryProtocol

    // MARK: Public properties

    private (set) var plans: [[PlanPresentation]] = []
    private (set) var footerType: FooterType = .withoutPlansToBuy

    var dynamicPlans: [[PaymentCellType]] {
         [
            {
                guard isSplitStorageEnabled,
                      clientApp == .mail || clientApp == .drive,
                      currentPlan?.details.shouldDisplayStorageFullAlert ?? false,
                      currentPlan != nil else { return [] }
                return  [.alert(AlertBoxViewModel())]
            }(),
            {
                guard let currentPlan else { return [] }
                return [.currentPlan(currentPlan)]
            }(),
            {
                guard let availablePlans else { return [] }
                return availablePlans.map { .availablePlan($0) }
            }()
         ].filter { !$0.isEmpty }
    }
    private (set) var availablePlans: [AvailablePlansPresentation]?
    var currentPlan: CurrentPlanPresentation?

    var defaultCycle: Int? {
        switch planService {
        case .left:
            return nil
        case .right(let dataSource):
            return dataSource.availablePlans?.defaultCycle
        }
    }

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
        if isDynamicPlansEnabled {
            return isExpandButtonHiddenByNumberOfDynamicPlans
        } else {
            return isExpandButtonHiddenByNumberOfStaticPlans
        }
    }

    private var isExpandButtonHiddenByNumberOfDynamicPlans: Bool {
        dynamicPlans
            .flatMap { $0 }
            .filter {
                switch $0 {
                case .availablePlan(let availablePlan):
                    return !(availablePlan.availablePlan?.isFreePlan ?? true)
                case .alert, .currentPlan:
                    return false
                }
            }
            .count < 2
    }

    private var isExpandButtonHiddenByNumberOfStaticPlans: Bool {
        return plans
            .flatMap { $0 }
            .filter { !$0.accountPlan.isFreePlan }
            .count < 2
    }

    var iapInProgress: Bool { storeKitManager.hasIAPInProgress() }

    var unfinishedPurchasePlan: InAppPurchasePlan? {
        didSet {
            guard let unfinishedPurchasePlan = unfinishedPurchasePlan else { return }
            processUnfinishedPurchasePlan(unfinishedPurchasePlan: unfinishedPurchasePlan)
        }
    }

    var shouldDisablePurchaseButtons: Bool {
        guard case .right(let planDataSource) = planService else { return false }
        return !planDataSource.isIAPAvailable
    }

    // MARK: Public interface

    init(mode: PaymentsUIMode,
         storeKitManager: StoreKitManagerProtocol,
         planService: Either<ServicePlanDataServiceProtocol, PlansDataSourceProtocol>,
         shownPlanNames: ListOfShownPlanNames = [],
         clientApp: ClientApp,
         customPlansDescription: CustomPlansDescription,
         featureFlagsRepository: FeatureFlagsRepositoryProtocol = FeatureFlagsRepository.shared,
         planRefreshHandler: @escaping (CurrentPlanDetails?) -> Void,
         extendSubscriptionHandler: @escaping () -> Void) {
        self.mode = mode
        self.planService = planService
        self.storeKitManager = storeKitManager
        self.shownPlanNames = shownPlanNames
        self.clientApp = clientApp
        self.customPlansDescription = customPlansDescription
        self.featureFlagsRepository = featureFlagsRepository
        self.planRefreshHandler = planRefreshHandler
        self.extendSubscriptionHandler = extendSubscriptionHandler
        registerRefreshHandler()
    }

    private var getCurrentPlan: CurrentPlanDetails? {
        if case .current(let currentPlanPresentationType) = plans.first?.first?.planPresentationType, case .details(let planDetails) = currentPlanPresentationType {
            return planDetails
        }
        return nil
    }

    func fetchPlans() async throws {
        try await fetchIAPAvailability()
        switch mode {
        case .signup:
            try await fetchAvailablePlans()
            footerType = .disabled
        case .current:
            try await fetchCurrentPlan()
            try await fetchAvailablePlans()
            try await fetchPaymentMethods()
            footerType = availablePlans?.count ?? 0 > 0 ? .disabled : .withoutPlansToBuy
        case .update:
            try await fetchAvailablePlans()
            try await fetchPaymentMethods()
            footerType = .disabled
        }
    }

    func fetchPlans(backendFetch: Bool, completionHandler: ((Result<([[PlanPresentation]], FooterType), Error>) -> Void)? = nil) {
        footerType = .withoutPlansToBuy
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
        guard let servicePlan else {
            completionHandler?(.failure(StoreKitManagerErrors.transactionFailedByUnknownReason))
            return
        }
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
        footerType = isDynamicPlansEnabled ? .disabled : .withPlansToBuy
        completionHandler?(.success((self.plans, footerType)))
    }

    private func getLocaleFromIAP(plansPresentation: [PlanPresentation]) -> Locale {
        for plan in plansPresentation {
            if let locale = PlanPresentation.getLocale(from: plan.accountPlan, storeKitManager: storeKitManager) {
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
                        currentPlanDetails.price = PriceFormatter.formatPlanPrice(price: 0, locale: locale, maximumFractionDigits: 0)
                        updatedFreePlan?.planPresentationType = .current(.details( currentPlanDetails))
                    default: break
                    }
                case .plan(var plan):
                    plan.price = PriceFormatter.formatPlanPrice(price: 0, locale: locale, maximumFractionDigits: 0)
                    updatedFreePlan?.planPresentationType = .plan(plan)
                case .none:
                    break
                }
            }
        }
        return updatedFreePlan
    }

    // MARK: Private methods - Update plans (current, update mode)

    // static plans only
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

    // static
    private func createPlanPresentations(withCurrentPlan: Bool, completionHandler: ((Result<([[PlanPresentation]], FooterType), Error>) -> Void)? = nil) {
        guard let servicePlan else {
            completionHandler?(.failure(StoreKitManagerErrors.transactionFailedByUnknownReason))
            return
        }
        var plans: [[PlanPresentation]] = []
        let userHasNoAccessToThePlan = servicePlan.currentSubscription?.isEmptyBecauseOfUnsufficientScopeToFetchTheDetails == true
        let userHasNoPlan = !userHasNoAccessToThePlan && (servicePlan.currentSubscription?.planDetails.map { $0.isEmpty } ?? true)
        let freePlan = servicePlan.detailsOfPlanCorrespondingToIAP(InAppPurchasePlan.freePlan).flatMap {
            self.createPlan(details: $0,
                            isSelectable: false,
                            isCurrent: true,
                            isMultiUser: false,
                            hasPaymentMethods: servicePlan.hasPaymentMethods,
                            endDate: nil,
                            price: nil,
                            cycle: nil)
        }

        if userHasNoPlan && servicePlan.isIAPAvailable {
            let plansToShow = servicePlan.availablePlansDetails
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
            footerType = plansToShow.isEmpty ? .withoutPlansToBuy : .withPlansToBuy
            self.plans = plans
            completionHandler?(.success((self.plans, footerType)))

        } else if userHasNoAccessToThePlan {
            plans.append([PlanPresentation.unavailableBecauseUserHasNoAccessToPlanDetails])
            footerType = .disabled
            self.plans = plans
            completionHandler?(.success((self.plans, footerType)))

        } else {
            if let subscription = servicePlan.currentSubscription,
               let accountPlan = InAppPurchasePlan(protonPlan: subscription.computedPresentationDetails(shownPlanNames: shownPlanNames),
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

                // check if current plan is still available
                let isExtensionPlanAvailable = servicePlan.availablePlansDetails.first { $0.name == accountPlan.protonName } != nil

                self.plans = plans
                // `storeKitManager.canExtendSubscription` is never true with DynamicPlans enabled
                if storeKitManager.canExtendSubscription, !servicePlan.hasPaymentMethods, isExtensionPlanAvailable, !servicePlan.willRenewAutomatically(plan: accountPlan) {
                    footerType = .withExtendSubscriptionButton(plan)
                } else {
                    footerType = .withoutPlansToBuy
                }
                completionHandler?(.success((self.plans, footerType)))
            } else {
                // there is an other subscription type
                if let freePlan = freePlan, servicePlan.isIAPAvailable {
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
            guard let servicePlan = self.servicePlan else {
                completion(.failure(StoreKitManagerErrors.transactionFailedByUnknownReason))
                return
            }
            if servicePlan.isIAPAvailable {
                servicePlan.updateCurrentSubscription {
                    completion(.success(()))
                } failure: { error in
                    completion(.failure(error))
                }
            } else {
                completion(.success)         
            }
        } failure: { error in
            completion(.failure(error))
        }
    }

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

        guard let servicePlan else { return nil }

        var details = servicePlan.defaultPlanDetails.map { Plan.combineDetailsKeepingPricing(baseDetails, $0) } ?? baseDetails
        if let cycle = cycle {
            details = details.updating(cycle: cycle)
        }
        return PlanPresentation.createPlan(from: details,
                                           servicePlan: servicePlan,
                                           clientApp: clientApp,
                                           storeKitManager: storeKitManager,
                                           customPlansDescription: customPlansDescription,
                                           isCurrent: isCurrent,
                                           isSelectable: isSelectable,
                                           isMultiUser: isMultiUser,
                                           hasPaymentMethods: hasPaymentMethods,
                                           endDate: endDate,
                                           price: price)
    }

    // static
    private func updateServicePlans(success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        guard let servicePlan else {
            failure(StoreKitManagerErrors.transactionFailedByUnknownReason)
            return
        }

        if clientApp == .vpn {
            servicePlan.updateCountriesCount {
                servicePlan.updateServicePlans(success: success, failure: failure)
            } failure: { error in
                servicePlan.updateServicePlans(success: success, failure: failure)
            }
        } else {
            servicePlan.updateServicePlans(success: success, failure: failure)
        }
    }

    // MARK: Private methods - Refresh data

    private func processUnfinishedPurchasePlan(unfinishedPurchasePlan: InAppPurchasePlan) {
        if isDynamicPlansEnabled {
             processUnfinishedPurchaseDynamicPlan(unfinishedPurchasePlan: unfinishedPurchasePlan)
         } else {
             processUnfinishedPurchaseStaticPlan(unfinishedPurchasePlan: unfinishedPurchasePlan)
         }
     }

     private func processUnfinishedPurchaseDynamicPlan(unfinishedPurchasePlan: InAppPurchasePlan) {
         self.dynamicPlans.forEach {
             $0.forEach {
                 if case .availablePlan(let availablePlan) = $0 {
                     if let planId = availablePlan.storeKitProductId, let processingPlanId = unfinishedPurchasePlan.storeKitProductId, planId == processingPlanId {
                         // select currently processed buy plan button
                         availablePlan.isCurrentlyProcessed = true
                         availablePlan.canBePurchasedNow = true
                     } else {
                         // disable buy plan buttons for other plans
                         availablePlan.canBePurchasedNow = false
                     }
                 }
             }
         }
         planRefreshHandler(nil)
     }

     private func processUnfinishedPurchaseStaticPlan(unfinishedPurchasePlan: InAppPurchasePlan) {
        self.plans.forEach {
            $0.forEach {
                if case .plan(var planDetails) = $0.planPresentationType {
                    if let planId = $0.storeKitProductId, let processingPlanId = unfinishedPurchasePlan.storeKitProductId, planId == processingPlanId {
                        // select currently prcessed buy plan button
                        $0.isCurrentlyProcessed = true
                        planDetails.isSelectable = true
                    } else {
                        // disable buy plan buttons for other plans
                        planDetails.isSelectable = false
                    }
                    $0.planPresentationType = .plan(planDetails)
                } else if case .current(let currentPlanPresentationType) = $0.planPresentationType, case .details = currentPlanPresentationType {
                    if let planId = $0.storeKitProductId, let processingPlanId = unfinishedPurchasePlan.storeKitProductId, planId == processingPlanId {
                        // select extend subscription button
                        extendSubscriptionHandler()
                    }
                }
            }
        }
        planRefreshHandler(nil)
    }

    private func registerRefreshHandler() {
        storeKitManager.refreshHandler = { [weak self] result in
            guard let self else { return }
            switch result {
            case .finished(let paymentSucceeded):
                guard paymentSucceeded == .resolvingIAPToCredits ||
                        paymentSucceeded == .resolvingIAPToSubscription else { return }
                // refresh plans
                if self.isDynamicPlansEnabled {
                    Task { [weak self] in
                        do {
                            try await self?.fetchPlans()
                            self?.planRefreshHandler(self?.getCurrentPlan)
                        } catch {
                            self?.planRefreshHandler(nil)
                        }
                    }
                } else {
                    self.createPlanPresentations(withCurrentPlan: self.mode == .current)
                    self.planRefreshHandler(self.getCurrentPlan)
                }
            case .errored, .erroredWithUnspecifiedError:
                if self.isDynamicPlansEnabled {
                    self.planRefreshHandler(nil)
                } else {
                    // update credits
                    self.updateCredits { [weak self] in self?.planRefreshHandler(nil) }
                }
            }
        }
    }

    private func updateCredits(completionHandler: (() -> Void)?) {
        guard let servicePlan else {
            completionHandler?()
            return
        }

        servicePlan.updateCredits {
            completionHandler?()
        } failure: { _ in
            completionHandler?()
        }
    }
}

// MARK: - dynamic plan

extension PaymentsUIViewModel {
    func fetchCurrentPlan() async throws {
        guard let plansDataSource else {
            throw StoreKitManagerErrors.transactionFailedByUnknownReason
        }

        try await plansDataSource.fetchCurrentPlan()
        guard let currentPlanSubscription = plansDataSource.currentPlan?.subscriptions.first else {
            return
        }

        currentPlan = try await CurrentPlanPresentation.createCurrentPlan(from: currentPlanSubscription, plansDataSource: plansDataSource)
    }

    func fetchAvailablePlans() async throws {
        guard let plansDataSource else {
            throw StoreKitManagerErrors.transactionFailedByUnknownReason
        }

        try await plansDataSource.fetchAvailablePlans()

        guard let availablePlansDataSource = plansDataSource.availablePlans?.plans else {
            return
        }

        self.availablePlans = []
        for plan in availablePlansDataSource {
            if plan.instances.isEmpty {
                if let plan = try await AvailablePlansPresentation.createAvailablePlans(
                    from: plan,
                    defaultCycle: plansDataSource.availablePlans?.defaultCycle,
                    plansDataSource: plansDataSource) {
                        self.availablePlans?.append(plan)
                }
            } else {
                for instance in plan.instances {
                    if let plan = try await AvailablePlansPresentation.createAvailablePlans(
                        from: plan,
                        for: instance,
                        defaultCycle: plansDataSource.availablePlans?.defaultCycle,
                        plansDataSource: plansDataSource,
                        storeKitManager: storeKitManager
                    ) {
                        self.availablePlans?.append(plan)
                    }
                }
            }
        }
        if availablePlans?.isEmpty == true, mode == .update {
            try await fetchCurrentPlan()
        }
    }

    func fetchPaymentMethods() async throws {
        guard let plansDataSource else {
            throw StoreKitManagerErrors.transactionFailedByUnknownReason
        }

        try await plansDataSource.fetchPaymentMethods()
    }

    func fetchIAPAvailability() async throws {
        guard let plansDataSource else {
            throw StoreKitManagerErrors.transactionFailedByUnknownReason
        }

        try await plansDataSource.fetchIAPAvailability()
    }
}

#endif
