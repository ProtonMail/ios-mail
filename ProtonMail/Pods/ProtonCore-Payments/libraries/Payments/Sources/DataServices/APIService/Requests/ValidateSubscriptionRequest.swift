//
//  ValidateSubscriptionRequest.swift
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

final class ValidateSubscriptionRequest: BaseApiRequest<ValidateSubscriptionResponse> {
    private let planId: String

    init(api: API, planId: String) {
        self.planId = planId
        super.init(api: api)
    }

    override func method() -> HTTPMethod {
        return .put
    }

    override func path() -> String {
        return super.path() + "/subscription/check"
    }

    override func toDictionary() -> [String: Any]? {
        return [
            "Currency": "USD",
            "PlanIDs": [planId: 1],
            "Cycle": 12
        ]
    }
}

final class ValidateSubscriptionResponse: ApiResponse {
    var validateSubscription: ValidateSubscription?

    override func ParseResponse(_ response: [String: Any]!) -> Bool {
        PMLog.debug(response.json(prettyPrinted: true))
        do {
            let data = try JSONSerialization.data(withJSONObject: response as Any, options: [])
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .custom(decapitalizeFirstLetter)
            validateSubscription = try decoder.decode(ValidateSubscription.self, from: data)
            return true
        } catch let decodingError {
            error = RequestErrors.validateSubscriptionDecode.toResponseError(updating: error)
            PMLog.debug("Failed to parse ServicePlans: \(decodingError.localizedDescription)")
            return false
        }
    }
}
