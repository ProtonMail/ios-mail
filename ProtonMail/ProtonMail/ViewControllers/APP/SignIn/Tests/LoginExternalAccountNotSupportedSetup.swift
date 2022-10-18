//
//  LoginExternalAccountNotSupportedSetup.swift
//  Proton Mail - Created on 06/10/2022
//
//  Copyright (c) 2021 Proton AG
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

#if DEBUG
import OHHTTPStubs

final class LoginExternalAccountNotSupportedSetup {
    static func stop() {
        HTTPStubs.removeAllStubs()
    }

    static func start() {
        HTTPStubs.setEnabled(true)

        // get code stub
        weak var usersStub = stub(condition: pathEndsWith("auth") && isMethodPOST()) { _ in
            let body = loginResponse.data(using: String.Encoding.utf8) ?? Data()
            let headers = ["Content-Type": "application/json;charset=utf-8"]
            return HTTPStubsResponse(data: body, statusCode: 200, headers: headers)
        }
        usersStub?.name = "External accounts not supported stub"
    }

    static var loginResponse: String {
    """
        {
          "Error" : "This app does not support external accounts",
          "Code" : 5099,
          "ErrorDescription" : "",
          "Details" : {

          }
        }
    """
    }
}
#endif
