//
//  AuthInfoResponse.swift
//  PMAuthentication
//
//  Created by Anatoly Rosencrantz on 20/02/2020.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

import Foundation

extension AuthService {
    struct TwoFAEndpoint: Endpoint {
        struct Response: Codable {
            var code: Int
            var scope: CredentialConvertible.Scope
        }
        
        var request: URLRequest
        
        init(code: Int,
             token: String,
             UID: String)
        {
            // url
            let authInfoUrl = AuthService.url(of: "/auth/2fa")
            
            // request
            var request = URLRequest(url: authInfoUrl)
            request.httpMethod = "POST"
            
            // headers
            var headers = AuthService.baseHeaders
            headers["Authorization"] = "Bearer " + token
            headers["x-pm-uid"] = UID
            headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }
            
            // body
            let body = [
            "TwoFactorCode": code
            ]
            request.httpBody = try? JSONEncoder().encode(body)
            
            self.request = request
        }
    }
}
