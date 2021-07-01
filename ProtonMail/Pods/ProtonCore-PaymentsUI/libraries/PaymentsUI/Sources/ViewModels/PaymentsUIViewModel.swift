//
//  PaymentsUIViewModelViewModel.swift
//  ProtonCore_PaymentsUI - Created on 01/06/2021.
//
//  Copyright (c) 2021 Proton Technologies AG
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

import UIKit
import ProtonCore_UIFoundations
import ProtonCore_Payments

final class PaymentsUIViewModelViewModel: NSObject {
    
    @objc private dynamic var servicePlan: ServicePlanDataService
    private let planType: PaymentsUIViewModelProtocol
    private var accountPlans: [AccountPlan] = []
    private var observation: NSKeyValueObservation?
    private var mode: PaymentsUIMode = .signup
    private var planRefreshHandler: (() -> Void)?
    
    // MARK: Public properties
    
    private (set) var plans: [Plan] = []
    private (set) var isAnyPlanToPurchase = false
    
    var processingAccountPlan: AccountPlan? {
        didSet {
            processDisablePlans()
        }
    }
    
    // MARK: Public interface
    
    init(servicePlan: ServicePlanDataService, planTypes: PlanTypes, planRefreshHandler: (() -> Void)? = nil) {
        self.servicePlan = servicePlan
        switch planTypes {
        case .mail:
            planType = MailPlansViewModel()
        }
        self.planRefreshHandler = planRefreshHandler
        super.init()
        
        observation = observe(\.servicePlan.currentSubscription, options: [.new] ) { _, _ in
            if self.mode != .signup {
                let oldPlansCount = self.plans.count
                self.processPlansToUpdate(withCurrentPlan: self.mode == .current )
                if self.plans.count < oldPlansCount {
                    self.planRefreshHandler?()
                }
            }
        }
    }
    
    func fatchPlans(mode: PaymentsUIMode, backendFetch: Bool, completionHandler: ((Result<([Plan], Bool), Error>) -> Void)? = nil) {
        isAnyPlanToPurchase = false
        self.mode = mode

        switch mode {
        case .signup:
            fetchAllPlans(plans: planType.plansToShow, backendFetch: backendFetch, completionHandler: completionHandler)
        case .current:
            fetchPlansToUpdate(withCurrentPlan: true, backendFetch: backendFetch, completionHandler: completionHandler)
        case .update:
            fetchPlansToUpdate(withCurrentPlan: false, backendFetch: backendFetch, completionHandler: completionHandler)
        }

    }
    
    // MARK: Private methods - All plans (signup mode)

    private func fetchAllPlans(plans: [AccountPlan], backendFetch: Bool, completionHandler: ((Result<([Plan], Bool), Error>) -> Void)? = nil) {
        self.plans = []
        if backendFetch {
            servicePlan.updateServicePlans {
                self.processAllPlans(plans: plans, completionHandler: completionHandler)
            } failure: { error in
                completionHandler?(.failure(error))
            }
        } else {
            processAllPlans(plans: plans) { result in
                // if there are no planes stored, fetch from backend
                if self.plans.count == 0 {
                    self.fetchAllPlans(plans: plans, backendFetch: true, completionHandler: completionHandler)
                } else {
                    completionHandler?(result)
                }
            }
        }
    }
    
    private func processAllPlans(plans: [AccountPlan], completionHandler: ((Result<([Plan], Bool), Error>) -> Void)? = nil) {
        self.plans = self.getPlans(plans: planType.plansToShow)
        self.isAnyPlanToPurchase = true
        completionHandler?(.success((self.plans, true)))
    }

    // MARK: Private methods - Update plans (current, update mode)
    
    private func fetchPlansToUpdate(withCurrentPlan: Bool, backendFetch: Bool, completionHandler: ((Result<([Plan], Bool), Error>) -> Void)? = nil) {
        if backendFetch {
            updateServicePlanDataService { result in
                switch result {
                case .success:
                    self.processPlansToUpdate(withCurrentPlan: withCurrentPlan, completionHandler: completionHandler)
                case .failure(let error):
                    completionHandler?(.failure(error))
                }
            }
        } else {
            self.processPlansToUpdate(withCurrentPlan: withCurrentPlan, completionHandler: completionHandler)
        }
    }
    
    private func processPlansToUpdate(withCurrentPlan: Bool, completionHandler: ((Result<([Plan], Bool), Error>) -> Void)? = nil) {
        self.plans = []
        let currentPlans = self.servicePlan.currentSubscription?.plans.filter { $0 != .free } ?? []
        if currentPlans.count == 0 {
            // current plan is free - show other plans to update
            if withCurrentPlan, let freePlan = self.fetchPlan(plan: .free, isSelectable: false) {
                self.plans += [freePlan]
            }
            let plansToShow = planType.plansToShow.filter { $0 != .free }
            self.plans += self.getPlans(plans: plansToShow)
            self.isAnyPlanToPurchase = self.plans.count > 0
            completionHandler?(.success((self.plans, self.isAnyPlanToPurchase)))
        } else {
            // filter other subscriptions
            let allPlans = currentPlans.filter { planType.allPaidPlans.contains($0) }
            
            if let foundPlan = allPlans.first, let plan = self.fetchPlan(plan: foundPlan, isSelectable: false, endDate: servicePlan.endDateString(plan: foundPlan)) {
                self.plans += [plan]
                completionHandler?(.success((self.plans, self.isAnyPlanToPurchase)))
            } else {
                // there is an other subscription type
                if let freePlan = self.fetchPlan(plan: .free, isSelectable: false) {
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
                self.servicePlan.updateCurrentSubscription {
                    completion(.success(()))
                } failure: { error in
                    completion(.failure(error))
                }
            } else {
                completion(.failure(StoreKitManager.Errors.transactionFailedByUnknownReason))
            }
        } failure: { error in
            completion(.failure(error))
        }
    }
    
    private func getPlans(plans: [AccountPlan]) -> [Plan] {
        return plans.compactMap {
            return fetchPlan(plan: $0, isSelectable: true)
        }
    }
    
    private func fetchPlan(plan: AccountPlan, isSelectable: Bool, endDate: NSAttributedString? = nil) -> Plan? {
        guard let details = fetchDetails(accountPlan: plan) else { return nil }
        var strDetails = [details.usersDescription, details.storageDescription, details.addressesDescription]
        strDetails += details.additionalDescription
        return Plan(name: details.nameDescription, details: strDetails, price: plan.planPrice, isSelectable: isSelectable, endDate: endDate, accountPlan: plan)
    }

    private func fetchDetails(accountPlan: AccountPlan) -> ServicePlanDetails? {
        return servicePlan.detailsOfServicePlan(named: accountPlan.rawValue)
    }
    
    private func processDisablePlans() {
        if self.processingAccountPlan != nil {
            self.plans = self.plans.map {
                var plan = $0
                if (mode == .signup && plan.accountPlan != self.processingAccountPlan) ||
                    (mode != .signup && plan.accountPlan == self.processingAccountPlan) {
                    plan.isSelectable = false
                    return plan
                } else {
                    return $0
                }
            }
            isAnyPlanToPurchase = false
            self.plans.forEach {
                if $0.isSelectable == true {
                    isAnyPlanToPurchase = true
                }
            }
        }
    }
}
