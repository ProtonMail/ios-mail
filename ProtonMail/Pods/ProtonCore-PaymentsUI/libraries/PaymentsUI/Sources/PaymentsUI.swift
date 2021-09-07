//
//  PaymentsUIMode.swift
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
import ProtonCore_Payments

public enum PaymentsUIPresentationType {
    case modal          // modal presentation
    case none           // no presentation by PaymentsUI
}

public enum PaymentsUIResultReason {
    case open(vc: PaymentsUIViewController, opened: Bool)
    case close
    case purchasedPlan(accountPlan: AccountPlan)
    case purchaseError(error: Error)
}

// Can be extended with other platform plans
public enum PlanTypes {
    case mail           // mail plans
    case vpn            // vpn plans
    case mailWithoutUpgrades // mail plans but with no ability to upgrade
    case vpnWithoutUpgrades  // vpn plans but with no ability to upgrade
}

enum PaymentsUIMode {
    case signup         // presents all plans
    case current        // presents current plan + plans to upgrade
    case update         // presents plans to upgrade
}

public class PaymentsUI {
    
    private let servicePlan: ServicePlanDataService
    private let coordinator: PaymentsUICoordinator
    
    public init(servicePlanDataService: ServicePlanDataService, planTypes: PlanTypes) {
        self.servicePlan = servicePlanDataService
        self.coordinator = PaymentsUICoordinator(planTypes: planTypes)
    }
    
    // MARK: Public interface
    
    public func showSignupPlans(viewController: UIViewController, completionHandler: @escaping ((PaymentsUIResultReason) -> Void)) {
        coordinator.start(viewController: viewController, servicePlan: servicePlan, completionHandler: completionHandler)
    }
    
    public func showCurrentPlan(presentationType: PaymentsUIPresentationType, backendFetch: Bool, completionHandler: @escaping ((PaymentsUIResultReason) -> Void)) {
        coordinator.start(presentationType: presentationType, servicePlan: servicePlan, mode: .current, backendFetch: backendFetch, completionHandler: completionHandler)
    }
    
    public func showUpgradePlan(presentationType: PaymentsUIPresentationType, backendFetch: Bool, completionHandler: @escaping ((PaymentsUIResultReason) -> Void)) {
        coordinator.start(presentationType: presentationType, servicePlan: servicePlan, mode: .update, backendFetch: backendFetch, completionHandler: completionHandler)
    }

}
