//
//  AppleRequest.swift
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

final class AppleRequest: BaseApiRequest<AppleResponse> {
    var currency: String
    var country: String

    init(api: API, currency: String, country: String) {
        self.currency = currency
        self.country = country
        super.init(api: api)
    }

    override func path() -> String {
        return super.path() + "/apple"
    }

    override func toDictionary() -> [String: Any]? {
        return [
            "Country": self.country,
            "Currency": self.currency,
            "Tier": 54
        ]
    }
}

final class AppleResponse: ApiResponse {
    var proceed = Decimal(0)

    override func ParseResponse(_ response: [String: Any]!) -> Bool {
        PMLog.debug(response.json(prettyPrinted: true))
        if let proceedPrice = response["Proceeds"] as? String {
            self.proceed = Decimal(string: proceedPrice) ?? Decimal(0)
        } else if let proceeds = response["Proceeds"] as? [String: Any],
            // the resposne when not pass the tier
            let proceedPrice = proceeds["Tier 54"] as? String {
            self.proceed = Decimal(string: proceedPrice) ?? Decimal(0)
        }
        return true
    }
}
