//
//  SubscriptionRequest.swift
//  PMPayments - Created on 2/12/2020.
//
//
//  Copyright (c) 2019 Proton Technologies AG
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

import Foundation
import PMCommon
import PMLog

final class SubscriptionRequest: CreditRequest<SubscriptionResponse> {
    private let planId: String
    private let amount: Int

    init(api: API, planId: String, amount: Int, paymentAction: PaymentAction) {
        self.planId = planId
        self.amount = amount
        super.init(api: api, amount: amount, paymentAction: paymentAction)
    }

    override func method() -> HTTPMethod {
        return .post
    }

    override func path() -> String {
        return super.basePath() + "/subscription"
    }

    override func toDictionary() -> [String: Any]? {
        var params = super.toDictionary()
        params?["PlanIDs"] = [planId]
        params?["Cycle"] = 12
        return params
    }
}

final class SubscriptionResponse: ApiResponse {
    var newSubscription: ServicePlanSubscription?

    override func ParseResponse(_ response: [String: Any]!) -> Bool {
        PMLog.debug(response.json(prettyPrinted: true))

        guard let code = response["Code"] as? Int, code == 1000 else {
            super.error = RequestErrors.subscriptionDecode as NSError
            return false
        }

        let subscriptionParser = GetSubscriptionResponse()
        guard subscriptionParser.ParseResponse(response) else {
            super.error = RequestErrors.subscriptionDecode as NSError
            return false
        }
        self.newSubscription = subscriptionParser.subscription
        return true
    }
}

final class GetSubscriptionRequest: BaseApiRequest<GetSubscriptionResponse> {

    override func path() -> String {
        return super.path() + "/subscription"
    }
}

final class GetSubscriptionResponse: ApiResponse {
    var subscription: ServicePlanSubscription?

    override func ParseResponse(_ response: [String: Any]!) -> Bool {
        PMLog.debug(response.json(prettyPrinted: true))
        guard let response = response["Subscription"] as? [String: Any],
            let startRaw = response["PeriodStart"] as? Int,
            let endRaw = response["PeriodEnd"] as? Int else { return false }

        let couponCode = response["PeriodEnd"] as? String
        let cycle = response["Cycle"] as? Int

        let plansParser = PlansResponse()
        guard plansParser.ParseResponse(response) else { return false }

        let plans = plansParser.availableServicePlans
        let start = Date(timeIntervalSince1970: Double(startRaw))
        let end = Date(timeIntervalSince1970: Double(endRaw))
        self.subscription = ServicePlanSubscription(start: start, end: end, planDetails: plans, defaultPlanDetails: nil, paymentMethods: nil, couponCode: couponCode, cycle: cycle)
        return true
    }
}
