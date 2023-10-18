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
import ProtonCoreFeatureSwitch
import ProtonCoreNetworking
import ProtonCoreServices

extension AuthService {
    struct InfoEndpoint: Request {
        struct Key {
            static let userName = "Username"
            static let intent = "Intent"
        }
        
        let username: String
        private let intent: Intent?
        
        init(username: String, intent: Intent? = nil) {
            self.username = username
            self.intent = intent
        }
        
        var path: String {
            return "/auth/info"
        }
        
        var method: HTTPMethod {
            return .post
        }
        
        var parameters: [String: Any]? {
            var parameters = [Key.userName: username]
            if let intent {
                parameters[Key.intent] = intent.rawValue
            }
            
            return parameters
        }
        
        var isAuth: Bool {
            return false
        }

        var header: [String: Any] {
            return ["X-Accept-ExtAcc": true]
        }
    }
}
