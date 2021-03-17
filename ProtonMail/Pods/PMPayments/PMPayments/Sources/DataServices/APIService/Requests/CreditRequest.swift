//
//  CreditRequest.swift
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

class CreditRequest<T: ApiResponse>: BaseApiRequest<T> {
    private let paymentAction: PaymentAction
    private let amount: Int

    init(api: API, amount: Int, paymentAction: PaymentAction) {
        self.paymentAction = paymentAction
        self.amount = amount
        super.init(api: api)
    }

    override func method() -> HTTPMethod {
        return .post
    }

    override func path() -> String {
        return basePath() + "/credit"
    }

    func basePath() -> String {
        return super.path()
    }

    override func toDictionary() -> [String: Any]? {
        return [
            "Amount": amount,
            "Currency": "USD",
            "Payment": ["Type": paymentAction.getType,
                        "Details": [paymentAction.getKey: paymentAction.getValue]
            ]
        ]
    }
}

final class CreditResponse: ApiResponse {
    var newSubscription: ServicePlanSubscription?

    override func ParseResponse(_ response: [String: Any]!) -> Bool {
        PMLog.debug(response.json(prettyPrinted: true))
        guard let code = response["Code"] as? Int, code == 1000 else {
            super.error = RequestErrors.creditDecode as NSError
            return false
        }
        return true
    }
}
