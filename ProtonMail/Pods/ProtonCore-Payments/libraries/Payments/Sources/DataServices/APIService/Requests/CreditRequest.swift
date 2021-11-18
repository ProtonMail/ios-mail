//
//  CreditRequest.swift
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
import ProtonCore_Log
import ProtonCore_Networking
import ProtonCore_Services

enum PaymentAction {
    @available(*, deprecated) case apple(reciept: String)
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
        case .apple(reciept: let reciept): return reciept
        case .token(token: let token): return token
        }
    }
}

class CreditRequest<T: Response>: BaseApiRequest<T> {
    private let paymentAction: PaymentAction
    private let amount: Int

    init(api: APIService, amount: Int, paymentAction: PaymentAction) {
        self.paymentAction = paymentAction
        self.amount = amount
        super.init(api: api)
    }

    override var method: HTTPMethod { .post }

    override var path: String { super.path + "/v4/credit" }

    override var parameters: [String: Any]? {
        [
            "Amount": amount,
            "Currency": "USD",
            "Payment": ["Type": paymentAction.getType,
                        "Details": [paymentAction.getKey: paymentAction.getValue]
            ]
        ]
    }
}

final class CreditResponse: Response {
    var newSubscription: Subscription?

    override func ParseResponse(_ response: [String: Any]!) -> Bool {
        PMLog.debug(response.json(prettyPrinted: true))
        guard let code = response["Code"] as? Int, code == 1000 else {
            error = RequestErrors.creditDecode.toResponseError(updating: error)
            return false
        }
        
        return true
    }
}
