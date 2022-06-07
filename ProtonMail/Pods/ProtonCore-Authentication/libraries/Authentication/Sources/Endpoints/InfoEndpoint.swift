//
//  InfoEndpoint.swift
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
import ProtonCore_Networking

extension AuthService {
    
    public final class AuthInfoResponse: Response, Codable {
        public var modulus: String?
        public var serverEphemeral: String?
        public var version: Int = 0
        public var salt: String?
        public var srpSession: String?
        
        override public func ParseResponse(_ response: [String: Any]!) -> Bool {
            self.modulus = response["Modulus"] as? String
            self.serverEphemeral = response["ServerEphemeral"] as? String
            self.version = response["Version"] as? Int ?? 0
            self.salt = response["Salt"] as? String
            self.srpSession = response["SRPSession"] as? String
            return true
        }
    }
    
    struct InfoEndpoint: Request {
        struct Key {
            static let userName = "Username"
        }
        
        let username: String
        init(username: String) {
            self.username = username
        }
        
        var path: String {
            return "/auth/info"
        }
        
        var method: HTTPMethod {
            return .post
        }
        
        var parameters: [String: Any]? {
            return [Key.userName: username]
        }
        
        var isAuth: Bool {
            return false
        }
    }
}
