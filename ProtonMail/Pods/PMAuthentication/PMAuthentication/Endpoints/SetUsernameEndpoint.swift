//
//  SetUsernameEndpoint.swift
//  PMAuthentication
//
//  Created by Igor Kulman on 08.12.2020.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

import Foundation
import PMCommon

extension AuthService {
    struct SetUsernameResponse: Codable {
        let code: Int
    }

    struct SetUsernameEndpoint: Request {
        var path: String {
            return "/settings/username"
        }

        var method: HTTPMethod {
            return .put
        }

        var isAuth: Bool {
            return true
        }

        var auth: AuthCredential?
        var authCredential: AuthCredential? {
            return self.auth
        }

        var parameters: [String: Any]? {
            let body = [
                "Username": username
            ]
            return body
        }

        let username: String

        init(username: String)  {
            self.username = username
        }
    }
}
