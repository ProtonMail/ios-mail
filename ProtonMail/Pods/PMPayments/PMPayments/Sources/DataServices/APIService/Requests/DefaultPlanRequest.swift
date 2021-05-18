//
//  DefaultPlanRequest.swift
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

final class DefaultPlanRequest: BaseApiRequest<DefaultPlanResponse> {

    override func path() -> String {
        return super.path() + "/plans/default"
    }
}

final class DefaultPlanResponse: ApiResponse {
    internal var servicePlans: [ServicePlanDetails]?

    var defaultMailPlan: ServicePlanDetails? {
        return self.servicePlans?.filter({ (details) -> Bool in
            return details.title.containsIgnoringCase(check: "ProtonMail Free")
        }).first
    }

    override func ParseResponse(_ response: [String: Any]!) -> Bool {
        PMLog.debug(response.json(prettyPrinted: true))
        do {
            let data = try JSONSerialization.data(withJSONObject: response["Plans"] as Any, options: [])
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .custom(decapitalizeFirstLetter)
            self.servicePlans = try decoder.decode(Array<ServicePlanDetails>.self, from: data)
            return true
        } catch let error {
            super.error = RequestErrors.defaultPlanDecode as NSError
            PMLog.debug("Failed to parse ServicePlans: \(error.localizedDescription)")
            return false
        }
    }
}
