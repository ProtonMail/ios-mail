//
//  ValidateSubscriptionRequest.swift
//  ProtonCore-Payments - Created on 2/12/2020.
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

import Foundation
import ProtonCore_Log
import ProtonCore_Networking
import ProtonCore_Services

final class ValidateSubscriptionRequest: BaseApiRequest<ValidateSubscriptionResponse> {
    private let protonPlanName: String
    private let isAuthenticated: Bool

    init(api: APIService, protonPlanName: String, isAuthenticated: Bool) {
        self.protonPlanName = protonPlanName
        self.isAuthenticated = isAuthenticated
        super.init(api: api)
    }

    override var isAuth: Bool { isAuthenticated }

    override var method: HTTPMethod { .put }

    override var path: String { super.path + "/v4/subscription/check" }

    override var parameters: [String: Any]? {
        [
            "Currency": "USD",
            "Plans": [protonPlanName: 1],
            "Cycle": 12
        ]
    }
}

final class ValidateSubscriptionResponse: Response {
    var validateSubscription: ValidateSubscription?

    override func ParseResponse(_ response: [String: Any]!) -> Bool {
        PMLog.debug(response.json(prettyPrinted: true))
        let (result, validation) = decodeResponse(response as Any, to: ValidateSubscription.self, errorToReturn: .validateSubscriptionDecode)
        self.validateSubscription = validation
        return result
    }
}
