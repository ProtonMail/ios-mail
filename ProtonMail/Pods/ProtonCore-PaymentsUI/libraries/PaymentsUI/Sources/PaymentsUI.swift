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
import enum ProtonCore_DataModel.ClientApp
import ProtonCore_Payments

public enum PaymentsUIPresentationType {
    case modal          // modal presentation
    case none           // no presentation by PaymentsUI
}

public enum PaymentsUIResultReason {
    case open(vc: PaymentsUIViewController, opened: Bool)
    case close
    case purchasedPlan(accountPlan: InAppPurchasePlan)
    case planPurchaseProcessingInProgress(accountPlan: InAppPurchasePlan)
    case purchaseError(error: Error)
}

enum PaymentsUIMode {
    case signup         // presents all plans
    case current        // presents current plan + plans to upgrade
    case update         // presents plans to upgrade
}

public final class PaymentsUI {

    private let coordinator: PaymentsUICoordinator
    private let paymentsUIAlertManager: PaymentsUIAlertManager
    
    public init(payments: Payments, clientApp: ClientApp, shownPlanNames: ListOfShownPlanNames, alertManager: AlertManagerProtocol? = nil) {
        if let alertManager = alertManager {
            self.paymentsUIAlertManager = AlwaysDelegatingPaymentsUIAlertManager(delegatedAlertManager: alertManager)
        } else {
            let paymentsUIAlertManager = LocallyPresentingPaymentsUIAlertManager(delegatedAlertManager: payments.alertManager)
            payments.alertManager = paymentsUIAlertManager
            self.paymentsUIAlertManager = paymentsUIAlertManager
        }
        self.coordinator = PaymentsUICoordinator(planService: payments.planService,
                                                 storeKitManager: payments.storeKitManager,
                                                 purchaseManager: payments.purchaseManager,
                                                 clientApp: clientApp, shownPlanNames: shownPlanNames,
                                                 alertManager: paymentsUIAlertManager)
    }
    
    // MARK: Public interface
    
    public func showSignupPlans(viewController: UIViewController, completionHandler: @escaping ((PaymentsUIResultReason) -> Void)) {
        coordinator.start(viewController: viewController, completionHandler: completionHandler)
    }
    
    public func showCurrentPlan(presentationType: PaymentsUIPresentationType,
                                backendFetch: Bool,
                                updateCredits: Bool,
                                completionHandler: @escaping ((PaymentsUIResultReason) -> Void)) {
        coordinator.start(presentationType: presentationType, mode: .current, backendFetch: backendFetch, updateCredits: updateCredits, completionHandler: completionHandler)
    }
    
    public func showUpgradePlan(presentationType: PaymentsUIPresentationType,
                                backendFetch: Bool,
                                updateCredits: Bool,
                                completionHandler: @escaping ((PaymentsUIResultReason) -> Void)) {
        coordinator.start(presentationType: presentationType, mode: .update, backendFetch: backendFetch, updateCredits: updateCredits, completionHandler: completionHandler)
    }

}
