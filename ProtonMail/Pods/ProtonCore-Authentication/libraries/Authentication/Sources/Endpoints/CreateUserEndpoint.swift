//
//  CreateUserEndpoint.swift
//  ProtonCore-Authentication - Created on 04/03/2021.
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
import ProtonCore_Networking

public struct UserParameters {
    public let userName: String
    public let email: String?
    public let phone: String?
    public let modulusID: String
    public let salt: String
    public let verifer: String
    public let deviceToken: String
    public let challenge: [[String: Any]]
    
    public init(userName: String, email: String?, phone: String?, modulusID: String, salt: String, verifer: String, deviceToken: String, challenge: [[String: Any]] = []) {
        self.userName = userName
        self.email = email
        self.phone = phone
        self.modulusID = modulusID
        self.salt = salt
        self.verifer = verifer
        self.deviceToken = deviceToken
        self.challenge = challenge
    }
}

extension AuthService {
    struct CreateUserEndpoint: Request {
        let userParameters: UserParameters

        var parameters: [String: Any]? {
            let auth: [String: Any] = [
                "Version": 4,
                "ModulusID": userParameters.modulusID,
                "Salt": userParameters.salt,
                "Verifier": userParameters.verifer
            ]
            let payload: [String: Any] = [
                "mail-ios-payload": userParameters.deviceToken,
                "mail-ios-challenge": userParameters.challenge
            ]
            var out: [String: Any] = [
                "Username": userParameters.userName,
                "Auth": auth,
                "Payload": payload
            ]
            if let email = userParameters.email {
                out["Email"] = email
            }
            if let phone = userParameters.phone {
                out["Phone"] = phone
            }
            return out
        }

        var path: String {
            return "/v4/users"
        }

        var method: HTTPMethod {
            return .post
        }

        var isAuth: Bool {
            return false
        }
    }
}
