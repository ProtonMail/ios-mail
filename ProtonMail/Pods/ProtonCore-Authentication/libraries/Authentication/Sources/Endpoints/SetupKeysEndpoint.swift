//
//  SetupKeysEndpoint.swift
//  PMAuthentication - Created on 21.12.2020.
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
import ProtonCore_Networking

extension AuthService {
    struct SetupKeysEndpointResponse: Codable {
        let code: Int
    }

    struct SetupKeysEndpoint: Request {
        let addresses: [[String: Any]]
        let privateKey: String
        
        /// base64 encoded need random value
        let keySalt: String
        let passwordAuth: PasswordAuth

        var path: String {
            return "/keys/setup"
        }
        var method: HTTPMethod {
            return .post            
        }

        var isAuth: Bool {
            return true
        }

        var auth: AuthCredential?
        var authCredential: AuthCredential? {
            return self.auth
        }

        var parameters: [String: Any]? {
            let out: [String: Any] = [
                "KeySalt": keySalt,
                "PrimaryKey": privateKey,
                "AddressKeys": addresses,
                "Auth": passwordAuth.toDictionary()!
            ]

            return out
        }
    }
}
