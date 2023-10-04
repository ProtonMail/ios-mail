//
//  CreditRequest.swift
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

public enum PaymentAction {
    @available(*, deprecated) case apple(receipt: String)
    case token(token: String)

    var getType: String {
        switch self {
        case .apple: return "apple"
        case .token: return "token"
        }
    }

    var getKey: String {
        switch self {
        case .apple: return "Receipt"
        case .token: return "Token"
        }
    }

    var getValue: String {
        switch self {
        case .apple(receipt: let receipt): return receipt
        case .token(token: let token): return token
        }
    }
}

public class CreditRequest: BaseApiRequest<CreditResponse> {
    private let paymentAction: PaymentAction
    private let amount: Int

    public init(api: APIService, amount: Int, paymentAction: PaymentAction) {
        self.paymentAction = paymentAction
        self.amount = amount
        super.init(api: api)
    }

    override public var method: HTTPMethod { .post }

    override public var path: String { super.path + "/v4/credit" }

    override public var parameters: [String: Any]? {
        switch paymentAction {
        case .token(let token):
            return [
                "Amount": amount,
                "Currency": "USD",
                "PaymentToken": token
            ]
        case .apple:
            let paymentData: [String: Any] = ["Type": paymentAction.getType, "Details": [paymentAction.getKey: paymentAction.getValue]]
            return [
                "Amount": amount,
                "Currency": "USD",
                "Payment": paymentData
            ]
        }
    }
}

public final class CreditResponse: Response {
    override public func ParseResponse(_ response: [String: Any]!) -> Bool {
        PMLog.debug(response.json(prettyPrinted: true))
        guard let code = response["Code"] as? Int, code == 1000 else {
            error = RequestErrors.creditDecode.toResponseError(updating: error)
            return false
        }
        return true
    }
}
