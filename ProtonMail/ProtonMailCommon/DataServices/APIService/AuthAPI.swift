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


/// Description
final class AuthInfoRequest : ApiRequest<AuthInfoResponse> {
    
    var username : String
    
    /// inital
    ///
    /// - Parameters:
    ///   - username: user name
    ///   - authCredential: auto credential
    init(username : String, authCredential: AuthCredential?) {
        self.username = username
        
        super.init()
        
        self.authCredential = authCredential
    }
    
    override func toDictionary() -> [String : Any]? {
        let out : [String : Any] = [
            AuthKey.userName : username
        ]
        return out
    }
    
    override func method() -> HTTPMethod {
        return .post
    }
    
    override func path() -> String {
        return AuthAPI.path + "/info" + Constants.App.DEBUG_OPTION
    }
    
    override func getIsAuthFunction() -> Bool {
        return false
    }
    
    override func apiVersion() -> Int {
        return AuthAPI.v_auth_info
    }
}


final class AuthModulusRequest : ApiRequest<AuthModulusResponse> {
    init(authCredential: AuthCredential?) {
        super.init()
        self.authCredential = authCredential
    }
    override func method() -> HTTPMethod {
        return .get
    }
    
    override func path() -> String {
        return AuthAPI.path + "/modulus" + Constants.App.DEBUG_OPTION
    }
    
    override func getIsAuthFunction() -> Bool {
        return false
    }
    
    override func apiVersion() -> Int {
        return AuthAPI.v_get_auth_modulus
    }
}

final class AuthModulusResponse : ApiResponse {
    
    var Modulus : String?
    var ModulusID : String?
    
    override func ParseResponse(_ response: [String : Any]!) -> Bool {
        self.Modulus = response["Modulus"] as? String
        self.ModulusID = response["ModulusID"] as? String
        return true
    }
}


// MARK : Get messages part
final class AuthRequest : ApiRequest<AuthResponse> {
    
    var username : String
    var clientEphemeral : String //base64
    var clientProof : String  //base64
    var srpSession : String  //hex
    var twoFactorCode : String?
    
    //local verify only
    var serverProof : Data!
    
    init(username : String, ephemeral:Data, proof:Data, session:String!, serverProof : Data!, code:String?) {
        self.username = username
        self.clientEphemeral = ephemeral.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
        self.clientProof = proof.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
        self.srpSession = session
        self.twoFactorCode = code
        self.serverProof = serverProof
    }
    
    override func toDictionary() -> [String : Any]? {
        var out : [String : Any] = [
            AuthKey.userName : username,
            
            AuthKey.ephemeral : clientEphemeral,
            AuthKey.proof : clientProof,
            AuthKey.session : srpSession,
        ]
        
        if let code = self.twoFactorCode {
            out[AuthKey.twoFactor] = code
        }
        //PMLog.D(self.JSONStringify(out, prettyPrinted: true))
        return out
    }
    
    override func method() -> HTTPMethod {
        return .post
    }
    
    override func path() -> String {
        return AuthAPI.path + Constants.App.DEBUG_OPTION
    }
    
    override func getIsAuthFunction() -> Bool {
        return false
    }
    
    override func apiVersion() -> Int {
        return AuthAPI.v_auth
    }
}


final class TwoFARequest : ApiRequestNew<ApiResponse> {
    
    var tfacode : String
    init(api: API, code : String) {
        self.tfacode = code
        super.init(api: api)
    }
    
    override func toDictionary() -> [String : Any]? {
        let out : [String : Any] = [
            "TwoFactorCode": tfacode
        ]
        return out
    }
    
    override func method() -> HTTPMethod {
        return .post
    }
    
    override func authRetry() -> Bool {
        return false
    }
    
    override func path() -> String {
        return AuthAPI.path + "/2fa" + Constants.App.DEBUG_OPTION
    }
    
    override func apiVersion() -> Int {
        return AuthAPI.v_auth_2fa
    }
}


// MARK : refresh token
final class AuthRefreshRequest : ApiRequest<AuthResponse> {
    
    var resfreshToken : String
    var Uid : String
    
    init(resfresh : String, uid: String) {
        self.resfreshToken = resfresh
        self.Uid = uid
    }
    
    override func getHeaders() -> [String : Any] {
        return ["x-pm-uid" :  self.Uid] //TODO:: fixme this shouldn't be here
    }
    
    override func toDictionary() -> [String : Any]? {
        let out : [String : Any] = [
            "ResponseType": "token",
            "RefreshToken": resfreshToken,
            "GrantType": "refresh_token",
            "RedirectURI" : "http://www.protonmail.ch",
        ]
        return out
    }
    
    override func method() -> HTTPMethod {
        return .post
    }
    
    override func path() -> String {
        return AuthAPI.path + "/refresh" + Constants.App.DEBUG_OPTION
    }
    
    override func getIsAuthFunction() -> Bool {
        return false
    }
    
    override func apiVersion() -> Int {
        return AuthAPI.v_auth_refresh
    }
}



// MARK :delete auth token
final class AuthDeleteRequest : ApiRequest<ApiResponse> {
    
    override func method() -> HTTPMethod {
        return .delete
    }
    
    override func path() -> String {
        return AuthAPI.path + Constants.App.DEBUG_OPTION
    }
    
    override func getIsAuthFunction() -> Bool {
        return true
    }
    
    override func authRetry() -> Bool {
        return false
    }
    
    override func apiVersion() -> Int {
        return AuthAPI.v_delete_auth
    }
}


// MARK : Response part
final class AuthResponse : ApiResponse {
    
    var accessToken : String?
    var expiresIn : TimeInterval?
    var refreshToken : String?
    var sessionID : String?
    var eventID : String?
    
    var scope : String?
    var serverProof : String?
    var resetToken : String?
    var tokenType : String?
    var passwordMode : Int = 0
    
    var userStatus : Int = 0
    
    /// The private key and salt will remove from auth response. need two sperate call to get them
    var privateKey : String?
    var keySalt : String?
    
    var twoFactor : Int = 0
    
    var isEncryptedToken : Bool {
        return accessToken?.armored ?? false
    }
    
    override func ParseResponse(_ response: [String : Any]!) -> Bool {
        self.sessionID = response["UID"] as? String //session id
        self.accessToken = response["AccessToken"] as? String
        self.expiresIn = response["ExpiresIn"] as? TimeInterval
        self.scope = response["Scope"] as? String
        self.eventID = response["EventID"] as? String
        
        self.serverProof = response["ServerProof"] as? String
        self.resetToken = response["ResetToken"] as? String
        self.tokenType = response["TokenType"] as? String
        self.passwordMode = response["PasswordMode"] as? Int ?? 0
        self.userStatus = response["UserStatus"] as? Int ?? 0
        
        self.privateKey = response["PrivateKey"] as? String
        self.keySalt = response["KeySalt"] as? String
        self.refreshToken = response["RefreshToken"] as? String
        
        if let twoFA = response["2FA"]  as? [String : Any] {
            self.twoFactor = twoFA["Enabled"] as? Int ?? 0
        }
        
        return true
    }
}

final class AuthInfoResponse : ApiResponse {
    
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

