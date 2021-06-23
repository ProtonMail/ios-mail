//
//  ServicePlanDataService+Extensions.swift
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

import ProtonCore_Payments
import ProtonCore_CoreTranslation

extension ServicePlanDataService {
    
    // MARK: Public interface
    
    func endDateString(plan: AccountPlan) -> NSAttributedString? {
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
        return getAttributedBoldString(string: string, boldString: endDateString)
    }

    // MARK: Private interface
    
    private func getAttributedBoldString(string: String, boldString: String) -> NSMutableAttributedString {
        let attrStr = NSMutableAttributedString(string: string)
        if let range = string.range(of: boldString) {
            let boldedRange = NSRange(range, in: string)
            attrStr.addAttributes([NSAttributedString.Key.font: UIFont.systemFont(ofSize: 13, weight: .bold)], range: boldedRange)
        }
        return attrStr
    }

    private func willRenewAutomcatically(plan: AccountPlan) -> Bool {
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

    private func hasEnoughCreditToExtendSubscription(plan: AccountPlan) -> Bool {
        let credit = credits?.credit ?? 0
        let yearlyCost = Double(plan.yearlyCost) / 100
        return credit >= yearlyCost
    }
}
