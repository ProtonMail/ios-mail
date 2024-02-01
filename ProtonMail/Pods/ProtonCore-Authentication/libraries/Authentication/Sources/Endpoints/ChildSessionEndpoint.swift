//
//  ForkSessionEndpoint.swift
//  ProtonCore-Authentication - Created on 21.11.2023.
//
//  Copyright (c) 2023 Proton Technologies AG
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

extension AuthService {

    public struct ChildSessionResponse: APIDecodableResponse, Encodable, Equatable {
        public let UID: String
        public let refreshToken: String
        public let accessToken: String
        public let userID: String
        public let scopes: [String]
    }

    struct ChildSessionRequest: Request {

        private let selector: String

        init(selector: String) {
            self.selector = selector
        }

        var path: String {
            return "/auth/v4/sessions/forks/\(selector)"
        }

        var method: HTTPMethod {
            return .get
        }

        var isAuth: Bool {
            return true
        }

        var auth: AuthCredential?
        var authCredential: AuthCredential? {
            return self.auth
        }
    }
}
