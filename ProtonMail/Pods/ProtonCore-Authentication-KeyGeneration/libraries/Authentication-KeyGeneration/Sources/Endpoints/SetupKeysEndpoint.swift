//
//  SetupKeysEndpoint.swift
//  ProtonCore-Authentication-KeyGeneration - Created on 21.12.2020.
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
#if canImport(ProtonCore_Crypto_VPN)
import ProtonCore_Crypto_VPN
#elseif canImport(ProtonCore_Crypto)
import ProtonCore_Crypto
#endif
import ProtonCore_Authentication
import ProtonCore_Networking

extension AuthService {
    struct SetupKeysEndpointResponse: APIDecodableResponse {
        var code: Int?
        
        var error: String?
        
        var details: HumanVerificationDetails?
    }

    struct SetupKeysEndpoint: Request {
        let addresses: [[String: Any]]
        let privateKey: ArmoredKey
        
        /// base64 encoded need random value
        let keySalt: String
        let passwordAuth: PasswordAuth

        var path: String {
            "/keys/setup"
        }
        var method: HTTPMethod {
            .post
        }

        var isAuth: Bool {
            true
        }

        var auth: AuthCredential?
        var authCredential: AuthCredential? {
            self.auth
        }

        var parameters: [String: Any]? {
            let out: [String: Any] = [
                "KeySalt": keySalt,
                "PrimaryKey": privateKey.value,
                "AddressKeys": addresses,
                "Auth": passwordAuth.toDictionary()!
            ]

            return out
        }
    }
}
