//
//  PlanPresentation.swift
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

import ProtonCorePayments
import typealias ProtonCoreDataModel.ClientApp
import ProtonCoreUIFoundations
import UIKit

enum DetailType {
    case checkmark, storage, envelope, globe, tag, calendarCheckmark, shield
    case powerOff, rocket, servers, play, locks, brandTor, arrowsSwitch, eyeSlash
    case user
    case infinity, lock, vault, alias, at, forward, eye, penSquare
    case custom(UIImage)

    var icon: UIImage {
        switch self {
        case .checkmark: return IconProvider.checkmark
        case .storage: return IconProvider.storage
        case .envelope: return IconProvider.envelope
        case .globe: return IconProvider.globe
        case .tag: return IconProvider.tag
        case .calendarCheckmark: return IconProvider.calendarCheckmark
        case .shield: return IconProvider.shield
        case .powerOff: return IconProvider.powerOff
        case .rocket: return IconProvider.rocket
        case .servers: return IconProvider.servers
        case .play: return IconProvider.play
        case .locks: return IconProvider.locks
        case .brandTor: return IconProvider.brandTor
        case .arrowsSwitch: return IconProvider.arrowsSwitch
        case .eyeSlash: return IconProvider.eyeSlash
        case .user: return IconProvider.user
        case .infinity: return UIImage(systemName: "infinity")!
        case .lock: return IconProvider.lock
        case .vault: return IconProvider.vault
        case .alias: return IconProvider.alias
        case .at: return IconProvider.at
        case .forward: return IconProvider.forward
        case .eye: return IconProvider.eye
        case .penSquare: return IconProvider.penSquare
        case .custom(let image): return image
        }
    }
}

enum CurrentPlanPresentationType {
    case details(CurrentPlanDetails)
    case unavailable
}

enum PlanPresentationType {
    case plan(PlanDetails)
    case current(CurrentPlanPresentationType)
}

class PlanPresentation {
    let accountPlan: InAppPurchasePlan
    var planPresentationType: PlanPresentationType
    var storeKitProductId: String? { accountPlan.storeKitProductId }
    var isCurrentlyProcessed: Bool = false
    var isExpanded: Bool = false

    init(accountPlan: InAppPurchasePlan, planPresentationType: PlanPresentationType, isCurrentlyProcessed: Bool = false, isExpanded: Bool = false) {
        self.accountPlan = accountPlan
        self.planPresentationType = planPresentationType
        self.isCurrentlyProcessed = isCurrentlyProcessed
        self.isExpanded = isExpanded
    }
}

extension PlanPresentation {
    static func createPlan(from details: Plan,
                           servicePlan: ServicePlanDataServiceProtocol,
                           clientApp: ClientApp,
                           storeKitManager: StoreKitManagerProtocol,
                           customPlansDescription: CustomPlansDescription,
                           isCurrent: Bool,
                           isSelectable: Bool,
                           isMultiUser: Bool,
                           hasPaymentMethods: Bool,
                           endDate: NSAttributedString?,
                           price protonPrice: String?) -> PlanPresentation? {
        guard let plan = InAppPurchasePlan(protonPlan: details, listOfIAPIdentifiers: storeKitManager.inAppPurchaseIdentifiers) else { return nil }
        var planPresentationType: PlanPresentationType
        let countriesCount = servicePlan.countriesCount?.first { $0.maxTier == details.maxTier ?? 0 }?.count
        if isCurrent {
            let currentPlanDetails = CurrentPlanDetails.createPlan(from: details, plan: plan, servicePlan: servicePlan, countriesCount: countriesCount, clientApp: clientApp, storeKitManager: storeKitManager, customPlansDescription: customPlansDescription, isMultiUser: isMultiUser, protonPrice: protonPrice, hasPaymentMethods: hasPaymentMethods, endDate: endDate)
            planPresentationType = .current(.details(currentPlanDetails))
        } else {
            let planDetails = PlanDetails.createPlan(from: details, plan: plan, countriesCount: countriesCount, clientApp: clientApp, storeKitManager: storeKitManager, customPlansDescription: customPlansDescription, protonPrice: protonPrice, isSelectable: isSelectable)
            planPresentationType = .plan(planDetails)
        }
        return PlanPresentation(accountPlan: plan, planPresentationType: planPresentationType)
    }

    static var unavailableBecauseUserHasNoAccessToPlanDetails: PlanPresentation {
        PlanPresentation(accountPlan: InAppPurchasePlan.freePlan, planPresentationType: .current(.unavailable))
    }

    static func getLocale(from plan: InAppPurchasePlan, storeKitManager: StoreKitManagerProtocol) -> Locale? {
        return plan.planLocale(from: storeKitManager)
    }
}

#endif
