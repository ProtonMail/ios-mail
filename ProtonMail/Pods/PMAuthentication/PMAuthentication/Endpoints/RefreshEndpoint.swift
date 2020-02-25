//
//  RefreshEndpoint.swift
//  PMAuthentication
//
//  Created by Anatoly Rosencrantz on 21/02/2020.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

import Foundation

extension AuthService {
    struct RefreshEndpoint: Endpoint {
        struct Response: Codable, CredentialConvertible {
            var code: Int
            var accessToken: String
            var expiresIn: TimeInterval
            var tokenType: String
            var scope: AuthEndpoint.Response.Scope
            var refreshToken: String
        }
        
        var request: URLRequest
        
        init(refreshToken: String,
             UID: String)
        {
            // url
            let authInfoUrl = AuthService.url(of: "/auth/refresh")
            
            // request
            var request = URLRequest(url: authInfoUrl)
            request.httpMethod = "POST"
            
            // headers
            var headers = AuthService.baseHeaders
            headers["x-pm-uid"] = UID
            headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }
            
            // body
            let body = [
            "ResponseType": "token",
            "GrantType": "refresh_token",
            "RefreshToken": refreshToken,
            "RedirectURI": AuthService.redirectUri
            ]
            request.httpBody = try? JSONEncoder().encode(body)
            
            self.request = request
        }
    }
}
