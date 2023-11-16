//
//  PlanIconsRequest.swift
//  ProtonCorePayments - Created on 28.08.23.
//
//  Copyright (c) 2023 Proton Technologies AG
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
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore. If not, see https://www.gnu.org/licenses/.
//

import Foundation
import ProtonCoreLog
import ProtonCoreNetworking
import ProtonCoreServices

public final class PlanIconsRequest: BaseApiRequest<PlanIconsResponse> {
    let iconName: String

    public init(api: APIService, iconName: String) {
        self.iconName = iconName
        super.init(api: api)
    }

    override public var path: String { super.path + "/v5/resources/icons/\(iconName)" }

    override public var isAuth: Bool { false }
}

public final class PlanIconsResponse: Response {
    internal var iconData: Data?

    override public func ParseResponse(_ response: [String: Any]!) -> Bool {
        PMLog.debug(response.json(prettyPrinted: true))
        let (result, iconData) = decodeResponse(response as Any, to: Data.self, errorToReturn: .plansDecode)
        self.iconData = iconData
        return result
    }
}
