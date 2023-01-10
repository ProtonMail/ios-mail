//
//  TwoFAEndpoint.swift
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
import ProtonCore_Networking

extension AuthService {
    
    struct TwoFAResponse: APIDecodableResponse, Encodable {
        var scopes: CredentialConvertible.Scopes
    }
    
    struct TwoFAEndpoint: Request {
        let code: String
        
        init(code: String)  {
            self.code = code
        }
        
        var path: String {
            "/auth/v4/2fa"
        }
        
        var method: HTTPMethod {
            .post
        }
        
        var parameters: [String: Any]? {
            ["TwoFactorCode": code]
        }
        
        var isAuth: Bool {
            true
        }
        
        var auth: AuthCredential?
        
        var authCredential: AuthCredential? {
            auth
        }
        
        var autoRetry: Bool {
            false
        }
    }
}
