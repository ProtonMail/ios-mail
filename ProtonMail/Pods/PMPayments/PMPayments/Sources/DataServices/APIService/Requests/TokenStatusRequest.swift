//
//  TokenStatusRequest.swift
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

final class TokenStatusRequest: BaseApiRequest<TokenStatusResponse> {
    private let token: PaymentToken

    init (api: API, token: PaymentToken) {
        self.token = token
        super.init(api: api)
    }

    override func getIsAuthFunction() -> Bool {
        return false
    }

    override func path() -> String {
        return super.path() + "/tokens/" + token.token
    }
}

final class TokenStatusResponse: ApiResponse {
    var paymentTokenStatus: PaymentTokenStatus?

    override func ParseResponse(_ response: [String: Any]!) -> Bool {
        PMLog.debug(response.json(prettyPrinted: true))
        do {
            let data = try JSONSerialization.data(withJSONObject: response as Any, options: [])
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .custom(decapitalizeFirstLetter)
            paymentTokenStatus = try decoder.decode(PaymentTokenStatus.self, from: data)
            return true
        } catch let error {
            super.error = RequestErrors.tokenStatusDecode as NSError
            PMLog.debug("Failed to parse payment token status: \(error.localizedDescription)")
            return false
        }
    }
}
