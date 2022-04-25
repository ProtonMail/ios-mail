//
//  HumanVerificationManager.swift
//  ProtonMail
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
import ProtonCore_Services
import ProtonCore_HumanVerification
#if DEBUG
import OHHTTPStubs
#endif

class HumanVerificationManager {

    static let shared = HumanVerificationManager()

    var humanVerifyDelegates: [String: HumanVerifyDelegate] = [:]

    private init() { }

    func humanCheckHelper(apiService: PMAPIService) -> HumanVerifyDelegate {

        // find HumanVerifyDelegate by sessionUID
        if let humanVerifyDelegate = humanVerifyDelegates[apiService.sessionUID] {
            return humanVerifyDelegate
        }

        // create new HumanVerifyDelegate
        let url = URL(string: "https://protonmail.com/support/knowledge-base/human-verification/")!
        let humanDelegate = HumanCheckHelper(apiService: apiService, supportURL: url, viewController: nil, clientApp: .mail, versionToBeUsed: .v2, responseDelegate: nil, paymentDelegate: nil)

        // add humanVerifyDelegate to humanVerifyDelegates
        humanVerifyDelegates[apiService.sessionUID] = humanDelegate
        return humanDelegate
    }
}

#if DEBUG
extension HumanVerificationManager {

    func setupUITestsMocks() {
        HTTPStubs.setEnabled(true)
        stub(condition: isHost("api.protonmail.ch") && isPath("/payments/status") && isMethodGET()) { request in
            let body = self.responseString9001.data(using: String.Encoding.utf8)!
            let headers = ["Content-Type": "application/json;charset=utf-8"]
            return HTTPStubsResponse(data: body, statusCode: 200, headers: headers)
        }
    }

    var responseString9001: String { """
        {
            "Code": 9001,
            "Error": "Human verification required",
            "Details": {
                "HumanVerificationMethods": ["captcha", "sms", "email", "payment", "invite", "coupon"],
                "HumanVerificationToken": "signup"
            },
            "ErrorDescription": "signup"
        }
        """
    }
}
#endif
