//
//  SetupKeysEndpoint.swift
//  PMAuthentication
//
//  Created by Igor Kulman on 21.12.2020.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

import Foundation
import PMCommon

extension AuthService {
    struct CreateAddressKeysEndpointResponse: Codable {
        let code: Int
        let key: AddressKey
    }

    struct CreateAddressKeyEndpoint: Request {
        let addressID: String
        let privateKey: String
        let signedKeyList: [String: Any]
        let primary: Bool

        var path: String {
            return "/keys"
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
            let address: [String: Any] = [
                "AddressID": addressID,
                "PrivateKey": privateKey,
                "Primary": primary ? 1 : 0,
                "SignedKeyList": signedKeyList
            ]

            return address
        }
    }
}
