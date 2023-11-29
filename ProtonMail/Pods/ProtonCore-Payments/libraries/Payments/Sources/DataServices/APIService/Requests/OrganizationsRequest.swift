//
//  OrganizationsRequest.swift
//  ProtonCore-Payments - Created on 10/08/2021.
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

public final class OrganizationsRequest: BaseApiRequest<OrganizationsResponse> {
    
    override public init(api: APIService) {
        super.init(api: api)
    }
    
    override public var path: String { "/core/v4/organizations" }
}

public final class OrganizationsResponse: Response {

    private(set) var organization: Organization?

    override public func ParseResponse(_ response: [String: Any]!) -> Bool {
        guard let organizationResponse = response["Organization"] else { return false }
        let (result, details) = decodeResponse(organizationResponse, to: Organization.self, errorToReturn: .organizationDecode)
        organization = details
        PMLog.debug(organization?.debugDescription ?? RequestErrors.methodsDecode.localizedDescription)
        return result
    }
}
