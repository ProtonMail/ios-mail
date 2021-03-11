//
//  ModulusEndpoint.swift
//  PMAuthentication
//
//  Created by Igor Kulman on 14.12.2020.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

import Foundation
import PMCommon

extension AuthService {
    public struct ModulusEndpointResponse: Codable {
        let modulus: String
        let modulusID: String
        let code: Int
    }

    struct ModulusEndpoint: Request {
        var path: String {
            return "/auth/modulus"
        }
        var method: HTTPMethod {
            return .get
        }

        var isAuth: Bool {
            return false
        }
    }
}
