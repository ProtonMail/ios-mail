//
//  UserAvailableEndpoint.swift
//  ProtonCore-Authentication - Created on 01.12.2020.
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

extension AuthService {
    
    // This is temp. it belongs to core common
    static let urlQueryValueAllowed: CharacterSet = {
        let generalDelimitersToEncode = ":#[]@"
        let subDelimitersToEncode = "!$&'()*+,;="
        
        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: generalDelimitersToEncode + subDelimitersToEncode)
        
        return allowed
    }()
    
    public struct UserAvailableResponse: Codable {
        var code: Int
    }
    
    struct UserAvailableWithoutSpecifyingDomainEndpoint: Request {
        
        let username: String
        
        init(username: String)  {
            self.username = username
        }
        
        var path: String {
            return "/users" + "/available?Name=" + (self.username.addingPercentEncoding(withAllowedCharacters: urlQueryValueAllowed) ?? "")
        }
        
        var method: HTTPMethod {
            return .get
        }
        
        var isAuth: Bool {
            return false
        }
    }
    
    struct UserAvailableWithinDomainEndpoint: Request {
        
        let username: String
        let domain: String
        
        init(username: String, domain: String)  {
            self.username = username
            self.domain = domain
        }
        
        var path: String {
            let usernameWithDomain = "\(username)@\(domain)"
            let encodedParameter = usernameWithDomain.addingPercentEncoding(withAllowedCharacters: urlQueryValueAllowed)
            return "/users/available?ParseDomain=1&Name=\(encodedParameter ?? "")"
        }
        
        var method: HTTPMethod { .get }
        
        var isAuth: Bool { false }
    }
}
