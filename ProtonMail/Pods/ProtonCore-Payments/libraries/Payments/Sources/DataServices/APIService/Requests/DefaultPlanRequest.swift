//
//  DefaultPlanRequest.swift
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

final class DefaultPlanRequest: BaseApiRequest<DefaultPlanResponse> {

    override func path() -> String {
        return super.path() + "/plans/default"
    }
    
    override func getIsAuthFunction() -> Bool {
        return false
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
        } catch let decodingError {
            error = RequestErrors.defaultPlanDecode.toResponseError(updating: error)
            PMLog.debug("Failed to parse ServicePlans: \(decodingError.localizedDescription)")
            return false
        }
    }
}
