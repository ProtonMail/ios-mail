//
//  PaymentStatusRequest.swift
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
import ProtonCoreLog
import ProtonCoreNetworking
import ProtonCoreServices

typealias PaymentStatusRequest = BaseApiRequest<PaymentStatusResponse>

/// Payment Status request for API v4
final class V4PaymentStatusRequest: PaymentStatusRequest {

    override init(api: APIService) {
        super.init(api: api)
    }

    override var path: String { super.path + "/v4/status/apple" }

    override var isAuth: Bool { false }
}

/// Payment Status request for API v5
final class V5PaymentStatusRequest: PaymentStatusRequest {

    override init(api: APIService) {
        super.init(api: api)
    }

    override var path: String { super.path + "/v5/status/apple" }

    override var isAuth: Bool { false }
}

/// Common Payment Status response
final class PaymentStatusResponse: Response {
    var isAvailable: Bool?

    override func ParseResponse(_ response: [String: Any]) -> Bool {
        PMLog.debug(response.json(prettyPrinted: true))
        let states = response["VendorStates"] as? [String: Any] ?? response
        self.isAvailable = states["InApp"].map { $0 as? Int == 1 }
        return true
    }
}
