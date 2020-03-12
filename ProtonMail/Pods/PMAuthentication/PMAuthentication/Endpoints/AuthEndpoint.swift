//
//  AuthResponse.swift
//  PMAuthentication
//
//  Created by Anatoly Rosencrantz on 20/02/2020.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

import Foundation

extension AuthService {
    struct AuthEndpoint: Endpoint {
        struct Response: Codable, CredentialConvertible {
            struct TwoFA: Codable {
                var enabled: State
                
                enum State: Int, Codable {
                    case off, on, u2f, otp
                }
            }
            
            var code: Int
            var accessToken: String
            var expiresIn: TimeInterval
            var tokenType: String
            var refreshToken: String
            var scope: Scope
            var UID: String
            var userID: String
            var eventID: String
            var serverProof: String
            var passwordMode: PasswordMode
            
            var _2FA: TwoFA
        }
        
        var request: URLRequest
        
        init(username: String,
             ephemeral: Data,
             proof: Data,
             session: String,
             serverProof: Data)
        {
            // url
            let authUrl = AuthService.url(of: "/auth")
            
            // request
            var request = URLRequest(url: authUrl)
            request.httpMethod = "POST"
            
            // headers
            let headers = AuthService.baseHeaders
            headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }
            
            // body
            let body = [
                "Username": username,
                "ClientEphemeral": ephemeral.base64EncodedString(),
                "ClientProof": proof.base64EncodedString(),
                "SRPSession": session
            ]
            request.httpBody = try? JSONEncoder().encode(body)
            
            self.request = request
        }
    }
}
