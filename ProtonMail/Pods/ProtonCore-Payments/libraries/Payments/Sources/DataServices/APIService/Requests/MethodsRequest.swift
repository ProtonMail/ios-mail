//
//  MethodRequest.swift
//  ProtonCore-Payments - Created on 17/02/2022.
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

public class MethodRequest: BaseApiRequest<MethodResponse> {

    override public init(api: APIService) {
        super.init(api: api)
    }
    
    override public var method: HTTPMethod { .get }

    override public var path: String { super.path + "/v4/methods" }
    
    override public var parameters: [String: Any]? { nil }
    
    override public var isAuth: Bool { true }
}

public final class MethodResponse: Response {
    var methods: [PaymentMethod]?

    override public func ParseResponse(_ response: [String: Any]!) -> Bool {
        guard let paymentMethods = response["PaymentMethods"] as? [[String: Any]] else { return false }
        let (result, methods) = decodeResponse(paymentMethods, to: [PaymentMethod].self, errorToReturn: .methodsDecode)
        self.methods = methods
        PMLog.debug(methods?.debugDescription ?? RequestErrors.methodsDecode.localizedDescription)
        return result
    }
}
