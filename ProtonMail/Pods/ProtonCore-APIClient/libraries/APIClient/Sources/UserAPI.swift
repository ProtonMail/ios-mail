//
//  UserAPI.swift
//  ProtonCore-APIClient - Created on 5/25/20.
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

// swiftlint:disable identifier_name todo

import Foundation
import ProtonCore_DataModel
import ProtonCore_Networking

public struct HumanVerificationToken {
    let type: TokenType
    let token: String
    let input: String? // Email, phone number or catcha token

    public init(type: TokenType, token: String, input: String? = nil) {
        self.type = type
        self.token = token
        self.input = input
    }

    var fullValue: String {
        switch type {
        case .email, .sms:
            return "\(input ?? ""):\(token)"
        case .payment, .captcha:
            return token
        case .invite:
            return ""
        }
    }

    public enum TokenType: String, CaseIterable {
        case email
        case sms
        case invite
        case payment
        case captcha
        //    case coupon // Since this isn't compatible with IAP, this option can be safely ignored

        static func type(fromString: String) -> TokenType? {
            for value in TokenType.allCases where value.rawValue == fromString {
                return value
            }
            return nil
        }
    }
}

// Users API
// Doc: https://github.com/ProtonMail/Slim-API/blob/develop/api-spec/pm_api_users.md

public class UserAPI: APIClient {

    static let route: String = "/users"

    ///
    static let vpnType = 2

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
            case .userInfo:
                return true
            case .code, .check:
                return false
            default:
                return false
            }
        }

        public var header: [String: Any] {
            return [:]
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
                let out: [String: Any] = [
                    "Type": type.rawValue,
                    "Destination": [
                        destinationType: receiver
                    ]
                ]
                return out
            case .check(let token):
                return [
                    "Token": "\(token.fullValue)",
                    "TokenType": token.type.rawValue,
                    "Type": vpnType
                ]
            default:
                return [:]
            }
        }
    }
}

public final class GetUserInfoResponse: Response {
    public var userInfo: UserInfo?

    override public func ParseResponse(_ response: [String: Any]!) -> Bool {
        guard let res = response["User"] as? [String: Any] else {
            return false
        }
        self.userInfo = UserInfo(response: res)
        return true
    }
}
