//
//  ForceUpgradeManager.swift
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
import ProtonCore_ForceUpgrade
import ProtonCore_Networking
#if DEBUG
import OHHTTPStubs
#endif

class ForceUpgradeManager {
    static let shared = ForceUpgradeManager()

    private init() { }

    var forceUpgradeHelper: ForceUpgradeDelegate = {
        return ForceUpgradeHelper(config: .mobile(URL.appleStore))
    }()
}

#if DEBUG
extension ForceUpgradeManager {

    func setupUITestsMocks() {
        HTTPStubs.setEnabled(true)
        stub(condition: isHost("api.protonmail.ch") && isPath("/payments/status") && isMethodGET()) { request in
            let body = self.responseString5003.data(using: String.Encoding.utf8)!
            let headers = ["Content-Type": "application/json;charset=utf-8"]
            return HTTPStubsResponse(data: body, statusCode: 200, headers: headers)
        }
    }

    var responseString5003: String { """
        {
            "Code": 5003,
            "Error": "Test error description",
            "ErrorDescription": ""
        }
        """
    }
}
#endif
