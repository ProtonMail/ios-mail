//
//  TokenRequest.swift
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

final class TokenRequest: BaseApiRequest<TokenResponse> {
    private let amount: Int
    private let receipt: String

    init (api: API, amount: Int, receipt: String) {
        self.amount = amount
        self.receipt = receipt
        super.init(api: api)
    }

    override func method() -> HTTPMethod {
        return .post
    }

    override func getIsAuthFunction() -> Bool {
        return false
    }

    override func path() -> String {
        return super.path() + "/tokens"
    }

    override func toDictionary() -> [String: Any]? {
        return [
            "Amount": amount,
            "Currency": "USD",
            "Payment": [
                "Type": "apple",
                "Details": [
                    "Receipt": receipt
                ]
            ]
        ]
    }
}

final class TokenResponse: ApiResponse {
    var paymentToken: PaymentToken?

    override func ParseResponse(_ response: [String: Any]!) -> Bool {
        PMLog.debug(response.json(prettyPrinted: true))

        guard let code = response["Code"] as? Int, code == 1000 else { return false }
        do {
            let data = try JSONSerialization.data(withJSONObject: response as Any, options: [])
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .custom(decapitalizeFirstLetter)
            paymentToken = try decoder.decode(PaymentToken.self, from: data)
            return true
        } catch let error {
            super.error = RequestErrors.tokenDecode as NSError
            PMLog.debug("Failed to parse payment token: \(error.localizedDescription)")
            return false
        }
    }
}
