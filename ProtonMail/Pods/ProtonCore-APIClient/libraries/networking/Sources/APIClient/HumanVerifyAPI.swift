//
//  UserAPI.swift
//  ProtonCore-APIClient - Created on 5/25/20.
//
//  Copyright (c) 2019 Proton Technologies AG
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

// Users API
public class HumanVerifyAPI: APIClient {

    static let route: String = "/users"

    public enum Router: Request {
        case code(type: HumanVerificationToken.TokenType, receiver: String)
        case check(token: HumanVerificationToken)
        case checkUsername(String)
        case userInfo

        public var path: String {
            switch self {
            case .code:
                return route + "/code"
            case .check:
                return route + "/check"
            case .checkUsername(let username):
                return route + "/available?Name=" + username.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
            case .userInfo:
                return route
            }
        }

        public var isAuth: Bool {
            switch self {
            case .code, .check, .userInfo:
                return true
            default:
                return false
            }
        }

        public var header: [String: Any] {
            return [:]
        }

        public var apiVersion: Int {
            switch self {
            case .code, .check, .checkUsername, .userInfo:
                return 3
            }
        }

        public var method: HTTPMethod {
            switch self {
            case .checkUsername, .userInfo:
                return .get
            case  .code:
                return .post
            case .check:
                return .put
            }
        }

        public var parameters: [String: Any]? {
            switch self {
            case .code(let type, let receiver):
                let destinationType: String
                switch type {
                case .email:
                    destinationType = "Address"
                case .sms:
                    destinationType = "Phone"
                case .payment, .invite, .captcha:
                    fatalError("Wrong parameter used. Payment is not supported by code endpoint.")
                }
                return [
                    "Type": type.rawValue,
                    "Destination": [
                        destinationType: receiver
                    ]
                ]
            case .check(let token):
                return [
                    "Token": "\(token.fullValue)",
                    "TokenType": token.type.rawValue,
                    "Type": "1"
                ]
            default:
                return [:]
            }
        }
    }
}
