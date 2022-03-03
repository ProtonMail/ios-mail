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

// swiftlint:disable empty_string

import Foundation
import ProtonCore_Networking
import ProtonCore_Services

// Test API

public class TestApiClient: Client {
    public var apiService: APIService
    public init(api: APIService) {
        self.apiService = api
    }
    static let route: String = "/internal/tests"
    public enum Router: Request {
        case humanverify(destination: String? = nil, type: VerifyMethod? = nil, token: String? = nil, isAuth: Bool)
        public var path: String {
            switch self {
            case .humanverify:
                return route + "/humanverification"
            }
        }
        public var isAuth: Bool {
            switch self {
            case .humanverify(_, _, _, let auth):
                return auth
            }
        }
        public var header: [String: Any] {
            switch self {
            case .humanverify(let destination, let type, let token, _):
                if let typ = type, let str = token {
                    let dest = destination ?? ""
                    let dict = ["x-pm-human-verification-token-type": typ.method,
                                "x-pm-human-verification-token": dest == "" ? str : "\(dest):\(str)"]
                    return dict
                }
            }
            return [:]
        }
        public var method: HTTPMethod {
            switch self {
            case .humanverify:
                return .post
            }
        }
        public var parameters: [String: Any]? {
            switch self {
            case .humanverify(_, _, _, let isAuth):
                // Possible values:
                // - "verify" - already authenticated
                // - "signup" - unauthenticated
                // Due to a bug on the BE side, currently only "signup" works well
                return ["Purpose": isAuth == true ? "signup" : "signup"]
            }
        }
    }
}

extension TestApiClient {
    // 3 ways.
    //  1. primise kit
    //  2. delaget
    //  3. combin
    public func triggerHumanVerify(isAuth: Bool = true, complete: @escaping  (_ task: URLSessionDataTask?, _ response: HumanVerificationResponse) -> Void) {
        let route = createHumanVerifyRoute(isAuth: isAuth)
        self.apiService.exec(route: route, responseObject: HumanVerificationResponse(), complete: complete)
    }

    public func createHumanVerifyRoute(destination: String? = nil, type: VerifyMethod? = nil, token: String? = nil, isAuth: Bool = true) -> Router {
        return Router.humanverify(destination: destination, type: type, token: token, isAuth: isAuth)
    }
}

class TestApi: Request {
    var path: String = "/tests/humanverification"
    var header: [String: Any] = [:]
    var method: HTTPMethod = .get
    var parameters: [String: Any]?
}
