//
//  AuthInfoResponse.swift
//  PMAuthentication
//
//  Created by Anatoly Rosencrantz on 20/02/2020.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

import Foundation

extension AuthService {
    struct InfoEndpoint: Endpoint {
        struct Response: Codable {
            var code: Int
            var modulus: String
            var serverEphemeral: String
            var version: Int
            var salt: String
            var SRPSession: String
        }
        
        var request: URLRequest
        
        init(username: String) {
            // url
            let authInfoUrl = AuthService.url(of: "/auth/info")
            
            // request
            var request = URLRequest(url: authInfoUrl)
            request.httpMethod = "POST"
            
            // headers
            let headers = AuthService.baseHeaders
            headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }
            
            // body
            let body = [
            "Username": username
            ]
            request.httpBody = try? JSONEncoder().encode(body)
            
            self.request = request
        }
    }
}
