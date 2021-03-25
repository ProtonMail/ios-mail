//
//  AuthEndpoint.swift
//  PMAuthentication - Created on 20/02/2020.
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

extension AuthService {
    
    struct AuthRouteResponse: Codable, CredentialConvertible {
        struct TwoFA: Codable {
            var enabled: State
            enum State: Int, Codable {
                case off, on, u2f, otp
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
