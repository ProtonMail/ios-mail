//
//  ServicePlanDataService+Extensions.swift
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

import ProtonCore_UIFoundations
import ProtonCore_Payments
import ProtonCore_CoreTranslation

extension ServicePlanDataServiceProtocol {
    
    // MARK: Public interface
    
    func endDateString(plan: InAppPurchasePlan) -> NSAttributedString? {
        guard let endDate = currentSubscription?.endDate, endDate.isFuture else { return nil }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yy"
        let endDateString = dateFormatter.string(from: endDate)
        var string: String
        if willRenewAutomcatically(plan: plan) {
            string = String(format: CoreString._pu_plan_details_renew_auto_expired, endDateString)
        } else {
            string = String(format: CoreString._pu_plan_details_renew_expired, endDateString)
        }
        return string.getAttributedString(replacement: endDateString, attrFont: .systemFont(ofSize: 13, weight: .bold))
    }

    // MARK: Private interface

    private func willRenewAutomcatically(plan: InAppPurchasePlan) -> Bool {
        guard let subscription = currentSubscription else {
            return false
        }
        // Special coupon that will extend subscription
        if subscription.hasSpecialCoupon {
            return true
        }
        // Has credit that will be used for renewal
        if hasEnoughCreditToExtendSubscription(plan: plan) {
            return true
        }
        return false
    }

    private func hasEnoughCreditToExtendSubscription(plan: InAppPurchasePlan) -> Bool {
        let credit = credits?.credit ?? 0
        guard let details = detailsOfServicePlan(named: plan.protonName), let amount = details.pricing(for: plan.period)
        else { return false }
        let cost = Double(amount) / 100
        return credit >= cost
    }
}
