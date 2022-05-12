//
//  AuthEndpoint.swift
//  ProtonCore-Authentication - Created on 20/02/2020.
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
import ProtonCore_APIClient
import ProtonCore_Networking

extension AuthService {
    
    struct AuthRouteResponse: Codable, CredentialConvertible {
        struct TwoFA: Codable {
            var enabled: State
            struct State: OptionSet, Codable {
                let rawValue: Int

                static let off: State = []
                static let totp = State(rawValue: 1 << 0)
                static let webAuthn = State(rawValue: 1 << 2)
            }
        }
        
        var code: Int
        var accessToken: String
        var expiresIn: TimeInterval
        var tokenType: String
        var refreshToken: String
        var scope: Scope
        var UID: String
        var userID: String
        var eventID: String
        var serverProof: String
        var passwordMode: PasswordMode
        
        var _2FA: TwoFA
    }
    
    struct AuthEndpoint: Request {
        let username: String
        let ephemeral: Data
        let proof: Data
        let session: String
        init(username: String,
             ephemeral: Data,
             proof: Data,
             session: String) {
            self.username = username
            self.ephemeral = ephemeral
            self.proof = proof
            self.session = session
        }
        
        var path: String {
            return "/auth"
        }
        
        var method: HTTPMethod {
            return .post
        }
        
        var parameters: [String: Any]? {
            return [
                "Username": username,
                "ClientEphemeral": ephemeral.base64EncodedString(),
                "ClientProof": proof.base64EncodedString(),
                "SRPSession": session
            ]
        }
        var isAuth: Bool {
            return false
        }
        
    }
}
