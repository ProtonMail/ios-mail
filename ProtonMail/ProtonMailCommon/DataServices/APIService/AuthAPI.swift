//
//  AuthAPI.swift
//  ProtonMail - Created on 6/17/15.
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
import ProtonCore_Networking
import ProtonCore_Services

//Auth API
//Doc:https://github.com/ProtonMail/Slim-API/blob/develop/api-spec/pm_api_auth.md
struct AuthAPI {
    /// base message api path
    static let path :String = "/auth"
    
    /// user auth post
    static let v_auth : Int = 3
    
    /// refresh token post
    static let v_auth_refresh : Int = 3
    
    /// setup auth info post
    static let v_auth_info : Int = 3
    
    /// get random srp modulus
    static let v_get_auth_modulus : Int = 3
    
    /// delete auth
    static let v_delete_auth : Int = 3
    
    /// revoke other tokens
    static let v_revoke_others : Int = 3
    
    /// submit 2fa code
    static let v_auth_2fa : Int = 3
}

//TODO:: need refacotr the api request structures
struct AuthKey {
    static let clientSecret = "ClientSecret"
    static let responseType = "ResponseType"
    static let userName = "Username"
    static let password = "Password"
    static let hashedPassword = "HashedPassword"
    static let grantType = "GrantType"
    static let redirectUrl = "RedirectURI"
    static let scope = "Scope"
    
    static let ephemeral = "ClientEphemeral"
    static let proof = "ClientProof"
    static let session = "SRPSession"
    static let twoFactor = "TwoFactorCode"
}


/// Description -- AuthInfoResponse
final class AuthInfoRequest : Request {
    
    var username : String
    
    /// inital
    ///
    /// - Parameters:
    ///   - username: user name
    ///   - authCredential: auto credential
    init(username : String, authCredential: AuthCredential?) {
        self.username = username
        self.auth = authCredential
    }
    
    //custom auth credentical
    let auth: AuthCredential?
    var authCredential : AuthCredential? {
        get {
            return self.auth
        }
    }
    
    var parameters: [String : Any]? {
        let out : [String : Any] = [
            AuthKey.userName : username
        ]
        return out
    }
    
    var method: HTTPMethod {
        return .post
    }
    
    var path: String {
        return AuthAPI.path + "/info"
    }
    
    var isAuth: Bool {
        return false
    }
}

// AuthModulusResponse
final class AuthModulusRequest : Request {
    init(authCredential: AuthCredential?) {
        self.auth = authCredential
    }
    
    //custom auth credentical
    let auth: AuthCredential?
    var authCredential : AuthCredential? {
        get {
            return self.auth
        }
    }
    
    var path: String {
        return AuthAPI.path + "/modulus"
    }
    
    var isAuth: Bool {
        return false
    }
}

final class AuthModulusResponse : Response {
    
    var Modulus : String?
    var ModulusID : String?
    
    override func ParseResponse(_ response: [String : Any]!) -> Bool {
        self.Modulus = response["Modulus"] as? String
        self.ModulusID = response["ModulusID"] as? String
        return true
    }
}

// MARK :delete auth token - Response
final class AuthDeleteRequest : Request {
    
    var method: HTTPMethod {
        return .delete
    }
    
    var path: String {
        return AuthAPI.path
    }
    
    var isAuth: Bool {
        return true
    }
    
    var autoRetry: Bool {
        return false
    }
}

final class AuthInfoResponse : Response {
    
    var Modulus : String?
    var ServerEphemeral : String?
    var Version : Int = 0
    var Salt : String?
    var SRPSession : String?
    
    override func ParseResponse(_ response: [String : Any]!) -> Bool {
        
        self.Modulus         = response["Modulus"] as? String
        self.ServerEphemeral = response["ServerEphemeral"] as? String
        self.Version         = response["Version"] as? Int ?? 0
        self.Salt            = response["Salt"] as? String
        self.SRPSession      = response["SRPSession"] as? String
        
        return true
    }
}

