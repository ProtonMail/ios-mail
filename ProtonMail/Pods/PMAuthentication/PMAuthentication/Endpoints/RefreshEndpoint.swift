//
//  RefreshEndpoint.swift
//  PMAuthentication - Created on 21/02/2020.
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
    
    struct RefreshResponse: Codable, CredentialConvertible {
        var code: Int
        var accessToken: String
        var expiresIn: TimeInterval
        var tokenType: String
        var scope: AuthRouteResponse.Scope
        var refreshToken: String
    }
    
    struct RefreshEndpoint: Request {
        var path: String {
            return "/auth/refresh"
        }
        
        var method: HTTPMethod {
            return .post
        }
        
        var parameters: [String: Any]? {
            let body = [
                "ResponseType": "token",
                "GrantType": "refresh_token",
                "RefreshToken": refreshToken,
                "RedirectURI": "http://protonmail.ch"
            ]
            return body
        }
        
        var isAuth: Bool {
            return true
        }
        var authCredential: AuthCredential? {
            return credential
        }

        var credential: AuthCredential?
        let refreshToken: String
        init(authCredential: AuthCredential) {
            self.credential = authCredential
            self.refreshToken = authCredential.refreshToken
        }
    }
}
