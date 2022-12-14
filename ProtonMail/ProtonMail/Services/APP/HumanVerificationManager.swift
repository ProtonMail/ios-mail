//
//  HumanVerificationManager.swift
//  Proton Mail
//
//
//  Copyright (c) 2019 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import Foundation
import LifetimeTracker
import ProtonCore_HumanVerification
import ProtonCore_Services
#if DEBUG
import OHHTTPStubs
#endif

class HumanVerificationManager: LifetimeTrackable {
    static var lifetimeConfiguration: LifetimeConfiguration {
        .init(maxCount: 1)
    }
    static let shared = HumanVerificationManager()

    var humanVerifyDelegates: [String: HumanVerifyDelegate] = [:]

    private init() {
        trackLifetime()
    }

    func humanCheckHelper(apiService: PMAPIService) -> HumanVerifyDelegate {

        // find HumanVerifyDelegate by sessionUID
        if let humanVerifyDelegate = humanVerifyDelegates[apiService.sessionUID] {
            return humanVerifyDelegate
        }

        // create new HumanVerifyDelegate
        guard let url = URL(string: "https://proton.me/support/knowledge-base/human-verification/") else {
            fatalError("Shouldn't fail")
        }
        let humanDelegate = HumanCheckHelper(
            apiService: apiService,
            supportURL: url,
            viewController: nil,
            clientApp: .mail,
            versionToBeUsed: .v3,
            responseDelegate: nil,
            paymentDelegate: nil
        )

        // add humanVerifyDelegate to humanVerifyDelegates
        humanVerifyDelegates[apiService.sessionUID] = humanDelegate
        return humanDelegate
    }
}

#if DEBUG
extension HumanVerificationManager {

    func setupUITestsMocks() {
        HTTPStubs.setEnabled(true)
        stub(condition: isHost("api.protonmail.ch") && isPath("/payments/status") && isMethodGET()) { _ in
            let body = Data(self.responseString9001.utf8)
            let headers = ["Content-Type": "application/json;charset=utf-8"]
            return HTTPStubsResponse(data: body, statusCode: 200, headers: headers)
        }
    }

    var responseString9001: String {
        """
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
