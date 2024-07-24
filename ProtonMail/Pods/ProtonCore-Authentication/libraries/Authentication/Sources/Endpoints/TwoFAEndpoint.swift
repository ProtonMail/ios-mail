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
import ProtonCoreNetworking
import ProtonCoreServices
import ProtonCoreObservability

extension AuthService {

    struct TwoFAResponse: APIDecodableResponse, Encodable {
        var scopes: CredentialConvertible.Scopes
    }

    struct TwoFAEndpoint: Request {
        let twoFAParams: TwoFAParams

        init(code: String) {
            self.twoFAParams = .totp(code)
        }

        init(signature: Fido2Signature) {
            self.twoFAParams = .fido2(signature)
        }

        var path: String {
            "/auth/v4/2fa"
        }

        var method: HTTPMethod {
            .post
        }

        var parameters: [String: Any]? {
            twoFAParams.asParameterDictionary
        }

        var isAuth: Bool {
            true
        }

        var auth: AuthCredential?

        var authCredential: AuthCredential? {
            auth
        }

        var authRetry: Bool {
            false
        }
    }
}

public enum TwoFAParams {
    case totp(String)
    case fido2(Fido2Signature)

    public var asParameterDictionary: [String: Any]? {
        switch self {
        case let .totp(code):
            return ["TwoFactorCode": code]
        case let .fido2(signature):
            let encoder = JSONEncoder()
            encoder.dataEncodingStrategy = .deferredToData
            guard let authenticationOptionsDictionary = try? JSONSerialization.jsonObject(with: try encoder.encode(signature.authenticationOptions)) else {
                return nil
            }
            return ["FIDO2": [
                "AuthenticationOptions": authenticationOptionsDictionary,
                "ClientData": signature.clientData.base64EncodedString(),
                "AuthenticatorData": signature.authenticatorData.base64EncodedString(),
                "Signature": signature.signature.base64EncodedString(),
                "CredentialID": [UInt8](signature.credentialID)
            ]
            ]
        }
    }

    public var observabilityMode: TwoFactorMode {
        return switch self {
        case .totp: .totp
        case .fido2: .webauthn
        }
    }
}
