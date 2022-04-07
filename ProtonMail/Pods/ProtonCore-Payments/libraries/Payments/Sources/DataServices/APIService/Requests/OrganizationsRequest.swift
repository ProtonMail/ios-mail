//
//  OrganizationsRequest.swift
//  ProtonCore-Payments - Created on 10/08/2021.
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

final class OrganizationsRequest: BaseApiRequest<OrganizationsResponse> {

    override var path: String { "/core/v4/organizations" }
}

final class OrganizationsResponse: Response {

    private(set) var organization: Organization?

    override func ParseResponse(_ response: [String: Any]!) -> Bool {
        PMLog.debug(response.json(prettyPrinted: true))
        guard let organizationResponse = response["Organization"] else { return false }
        let (result, details) = decodeResponse(organizationResponse, to: Organization.self, errorToReturn: .organizationDecode)
        organization = details
        return result
    }
}
