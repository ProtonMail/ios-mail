//
//  KeySaltsEndpoint.swift
//  PMAuthentication - Created on 17/03/2020.
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
    public struct KeySaltsResponse: Codable {
        let code: Int
        let keySalts: [AddressKeySalt]
    }

    /// This is a LOCKED endpoint, appropriate scope is set for the following call when you either login or call `/users/lock`, otherwise this call will fail with 403 Forbidden
    struct KeySaltsEndpoint: Request {
        
        var path: String {
            return "/keys/salts"
        }
        var method: HTTPMethod {
            return .get
        }
        
        var parameters: [String: Any]?
        
        var isAuth: Bool {
            return true
        }
        var auth: AuthCredential?
        var authCredential: AuthCredential? {
            return self.auth
        }
    }
}
