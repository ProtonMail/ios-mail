//
//  UnlockPasswordEndpoint.swift
//  ProtonCore-PasswordRequest - Created on 17/05/2024
//
//  Copyright (c) 2024 Proton AG
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
//  along with ProtonVPN.  If not, see <https://www.gnu.org/licenses/>.

import Foundation
import ProtonCoreAuthentication
import ProtonCoreNetworking
import ProtonCoreServices

public struct UnlockPasswordEndpoint: Request {

    let twoFAParams: TwoFAParams
    let authData: AuthEndpointData

    init(authData: AuthEndpointData, code: String) {
        self.authData = authData
        self.twoFAParams = .totp(code)
    }

    public init(authData: AuthEndpointData, signature: Fido2Signature) {
        self.authData = authData
        self.twoFAParams = .fido2(signature)
    }

    public var parameters: [String: Any]? {
        guard let twoFAParamsDictionary = twoFAParams.asParameterDictionary else {
            return nil
        }

        var authParams: [String: Any] = [
            "Username": authData.username,
            "ClientEphemeral": authData.ephemeral.base64EncodedString(),
            "ClientProof": authData.proof.base64EncodedString(),
            "SRPSession": authData.srpSession
        ]
            authParams.merge(twoFAParamsDictionary, uniquingKeysWith: { a, _ in a })

        return authParams
    }

    public var path: String { "/users/password" }
    public var method: HTTPMethod { .put }

}
