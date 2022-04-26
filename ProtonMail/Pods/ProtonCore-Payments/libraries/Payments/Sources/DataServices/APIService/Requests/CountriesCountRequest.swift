//
//  CountriesCountRequest.swift
//  ProtonCore-Payments - Created on 5/03/2022.
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
import ProtonCore_Log
import ProtonCore_Networking
import ProtonCore_Services

final class CountriesCountRequest: BaseApiRequest<CountriesCountResponse> {

    override var path: String { "/vpn/countries/count" }

    override var isAuth: Bool { false }
}

final class  CountriesCountResponse: Response {
    var countriesCount: [Countries]?

    override func ParseResponse(_ response: [String: Any]!) -> Bool {
        PMLog.debug(response.json(prettyPrinted: true))
        guard let paymentMethods = response["Counts"] as? [[String: Any]] else { return false }
        let (result, countriesCount) = decodeResponse(paymentMethods, to: [Countries].self, errorToReturn: .methodsDecode)
        self.countriesCount = countriesCount
        return result
    }
}
