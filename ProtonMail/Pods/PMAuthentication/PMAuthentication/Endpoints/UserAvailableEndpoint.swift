//
//  UserAvailableEndpoint.swift
//  PMAuthentication
//
//  Created on 01.12.2020.
//  Copyright © 2020 ProtonMail. All rights reserved.
//
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.

import Foundation
import PMCommon

extension AuthService {
    
    //this is temp. it belongs to core common
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
    
    struct UserAvailableEndpoint: Request {
        
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

//        init(username: String) {
//            // url
//            let authInfoUrl = AuthService.url(of: "/users/available")
//
//            var urlComponents = URLComponents(url: authInfoUrl, resolvingAgainstBaseURL: false)
//            urlComponents?.queryItems = [URLQueryItem(name: "Name", value: username)]
//
//            // request
//            var request = URLRequest(url: (urlComponents?.url)!)
//            request.httpMethod = "GET"
//
//            // headers
//            let headers = AuthService.baseHeaders
//            headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }
//
//            self.request = request
//        }
    }
}
