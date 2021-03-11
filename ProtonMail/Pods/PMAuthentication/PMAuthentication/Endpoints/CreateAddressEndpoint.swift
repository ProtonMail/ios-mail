//
//  CreateAddressEndpoint.swift
//  PMAuthentication
//
//  Created by Igor Kulman on 09.12.2020.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

import Foundation
import PMCommon

extension AuthService {
    struct CreateAddressEndpointResponse: Codable {
        let code: Int
        let address: Address
    }

    struct CreateAddressEndpoint: Request {
        let domain: String
        let displayName: String?
        let signature: String?

        var path: String {
            return "/addresses/setup"
        }
        var method: HTTPMethod {
            return .post
        }

        var isAuth: Bool {
            return true
        }

        var parameters: [String: Any]? {
            let body = [
                "Domain": domain,
                "DisplayName": displayName,
                "Signature": signature
            ]
            return body
        }

        var auth: AuthCredential?
        var authCredential: AuthCredential? {
            return self.auth
        }
    }
}
