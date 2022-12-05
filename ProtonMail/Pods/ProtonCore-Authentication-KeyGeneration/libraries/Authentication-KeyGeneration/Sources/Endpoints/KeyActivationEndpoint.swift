//
//  KeyActivateEndpoint.swift
//  ProtonCore-Authentication-KeyGeneration - Created on 05/23/2020
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
import ProtonCore_Authentication
import ProtonCore_Networking

extension AuthService {
    
    // active a key when Activation is not null --- Response
    struct KeyActivationEndpoint: Request {
        let addressID: String
        let privateKey: String
        let signedKeyList: [String: Any]
        let token: String
        let tokenSignature: String
        let primary: Int

        init(addrID: String, privKey: String, signedKL: [String: Any], token: String, signature: String, primary: Int) {
            self.addressID = addrID
            self.privateKey = privKey
            self.signedKeyList = signedKL
            self.token = token
            self.tokenSignature = signature
            self.primary = primary
        }

        var parameters: [String: Any]? {
            let out: [String: Any] = [
                "PrivateKey": self.privateKey,
                "SignedKeyList": self.signedKeyList,
                "Token": token,     // +  new on phase 2
                "Signature": tokenSignature, // +  new on phase 2
                "Primary": primary
            ]
            
            return out
        }

        var method: HTTPMethod {
            .put
        }

        var path: String {
            "keys/" + addressID + "/activate"
        }

        // custom auth credentical
        var auth: AuthCredential?
        var authCredential: AuthCredential? {
            self.auth
        }
    }
}
