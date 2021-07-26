//
//  SubscriptionRequest.swift
//  ProtonCore-Payments - Created on 2/12/2020.
//
//  Copyright (c) 2019 Proton Technologies AG
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

import Foundation
import ProtonCore_APIClient
import ProtonCore_Log
import ProtonCore_Networking
import ProtonCore_Services

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
        params?["PlanIDs"] = [planId: 1]
        params?["Cycle"] = 12
        return params
    }
}

final class SubscriptionResponse: ApiResponse {
    var newSubscription: ServicePlanSubscription?

    override func ParseResponse(_ response: [String: Any]!) -> Bool {
        PMLog.debug(response.json(prettyPrinted: true))

        guard let code = response["Code"] as? Int, code == 1000 else {
            error = RequestErrors.subscriptionDecode.toResponseError(updating: error)
            return false
        }

        let subscriptionParser = GetSubscriptionResponse()
        guard subscriptionParser.ParseResponse(response) else {
            error = RequestErrors.subscriptionDecode.toResponseError(updating: error)
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
