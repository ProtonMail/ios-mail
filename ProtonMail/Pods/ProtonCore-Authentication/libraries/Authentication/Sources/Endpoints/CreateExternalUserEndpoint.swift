//
//  CreateExternalUserEndpoint.swift
//  ProtonCore-Authentication - Created on 04/03/2021.
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
import ProtonCore_Networking

public struct ExternalUserParameters {
    public let email: String
    public let modulusID: String
    public let salt: String
    public let verifer: String
    public let challenge: [[String: Any]]
    public let verifyToken: String
    public let tokenType: String
    public let productPrefix: String
    
    public init(email: String, modulusID: String, salt: String, verifer: String, challenge: [[String: Any]] = [], verifyToken: String, tokenType: String, productPrefix: String) {
        self.email = email
        self.modulusID = modulusID
        self.salt = salt
        self.verifer = verifer
        self.challenge = challenge
        self.verifyToken = verifyToken
        self.tokenType = tokenType
        self.productPrefix = productPrefix
    }
}

extension AuthService {
    struct CreateExternalUserEndpoint: Request {
        let externalUserParameters: ExternalUserParameters

        var parameters: [String: Any]? {
            let auth: [String: Any] = [
                "Version": 4,
                "ModulusID": externalUserParameters.modulusID,
                "Salt": externalUserParameters.salt,
                "Verifier": externalUserParameters.verifer
            ]
            var payload: [String: Any] = [:]
            for (index, data) in externalUserParameters.challenge.enumerated() {
                payload["\(externalUserParameters.productPrefix)-ios-v4-challenge-\(index)"] = data
            }
            let out: [String: Any] = [
                "Email": externalUserParameters.email,
                "Auth": auth,
                "Payload": payload
            ]
            return out
        }
        
        var header: [String: Any] {
            let token: String
            if externalUserParameters.tokenType == VerifyMethod.PredefinedMethod.email.rawValue {
                token = "\(externalUserParameters.email):\(externalUserParameters.verifyToken)"
            } else {
                token = "\(externalUserParameters.verifyToken)"
            }
            
            return ["x-pm-human-verification-token-type": externalUserParameters.tokenType,
                    "x-pm-human-verification-token": token]
        }

        var path: String {
            return "/users/external"
        }

        var method: HTTPMethod {
            return .post
        }

        var isAuth: Bool {
            return false
        }
    }
}
