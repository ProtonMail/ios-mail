//
//  RefreshEndpoint.swift
//  ProtonCore-Service - Created on 21/02/2020.
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
import ProtonCoreNetworking

public typealias Scopes = [String]
public class RefreshResponse: APIDecodableResponse, CredentialConvertible, Encodable {
    public init(accessToken: String, tokenType: String, scopes: Scopes, refreshToken: String) {
        self.accessToken = accessToken
        self.tokenType = tokenType
        self.scopes = scopes
        self.refreshToken = refreshToken
    }
    public var accessToken: String
    public var tokenType: String
    public var scopes: Scopes
    public var refreshToken: String
}

public final class RefreshEndpoint: Request {
    let refreshToken: String
    var credential: AuthCredential?

    public init(authCredential: AuthCredential) {
        self.credential = authCredential
        self.refreshToken = authCredential.refreshToken
    }

    public var path: String {
        "/auth/v4/refresh"
    }

    public var method: HTTPMethod {
        .post
    }

    public var parameters: [String: Any]? {
        let body = [
            "ResponseType": "token",
            "GrantType": "refresh_token",
            "RefreshToken": refreshToken,
            "RedirectURI": "http://protonmail.ch"
        ]
        return body
    }

    public var isAuth: Bool {
        true
    }
    public var authCredential: AuthCredential? {
        credential
    }
}
