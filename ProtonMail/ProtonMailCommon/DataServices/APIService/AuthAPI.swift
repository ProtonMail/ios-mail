//
//  AuthAPI.swift
//  ProtonMail - Created on 6/17/15.
//
//
//  The MIT License
//
//  Copyright (c) 2018 Proton Technologies AG
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.


import Foundation

//TODO:: need refacotr the api request structures
struct AuthKey {
    static let clientID = "ClientID"
    static let clientSecret = "ClientSecret"
    static let responseType = "ResponseType"
    static let userName = "Username"
    static let password = "Password"
    static let hashedPassword = "HashedPassword"
    static let grantType = "GrantType"
    static let redirectUrl = "RedirectURI"
    static let state = "State"
    static let scope = "Scope"
    
    static let ephemeral = "ClientEphemeral"
    static let proof = "ClientProof"
    static let session = "SRPSession"
    static let twoFactor = "TwoFactorCode"
}


/// Description
final class AuthInfoRequest : ApiRequest<AuthInfoResponse> {
    
    var username : String!
    
    /// inital
    ///
    /// - Parameters:
    ///   - username: user name
    ///   - authCredential: auto credential
    init(username : String, authCredential: AuthCredential?) {
        super.init()
        self.username = username;
        self.authCredential = authCredential
    }
    
    override func toDictionary() -> [String : Any]? {
        let out : [String : Any] = [
            AuthKey.clientID : Constants.App.clientID,
            AuthKey.userName : username
        ]
        return out
    }
    
    override func method() -> APIService.HTTPMethod {
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
    override func method() -> APIService.HTTPMethod {
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
    
    var username : String!
    var clientEphemeral : String! //base64
    var clientProof : String!  //base64
    var srpSession : String!  //hex
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
            AuthKey.clientID : Constants.App.clientID,
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
    
    override func method() -> APIService.HTTPMethod {
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


// MARK : refresh token
final class AuthRefreshRequest<T : ApiResponse> : ApiRequest<T> {
    
    var resfreshToken : String!
    var Uid : String!
    
    init(resfresh : String, uid: String) {
        self.resfreshToken = resfresh;
        self.Uid = uid
    }
    
    override func toDictionary() -> [String : Any]? {
        let out : [String : Any] = [
            "ClientID": Constants.App.clientID,
            "ResponseType": "token",
            "RefreshToken": resfreshToken,
            "GrantType": "refresh_token",
            "RedirectURI" : "http://www.protonmail.ch",
            AuthKey.state : "\(UUID().uuidString)",
            "Uid" : self.Uid
        ]
        return out
    }
    
    override func method() -> APIService.HTTPMethod {
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
    
    override func method() -> APIService.HTTPMethod {
        return .delete
    }
    
    override func path() -> String {
        return AuthAPI.path + Constants.App.DEBUG_OPTION
    }
    
    override func getIsAuthFunction() -> Bool {
        return true
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
    var userID : String?
    var eventID : String?
    
    var scope : String?
    var serverProof : String?
    var resetToken : String?
    var tokenType : String?
    var privateKey : String?
    var passwordMode : Int = 0
    var keySalt : String?
    
    var userStatus : Int = 0
    
    override func ParseResponse(_ response: [String : Any]!) -> Bool {
        self.userID = response["UID"] as? String
        self.accessToken = response["AccessToken"] as? String
        self.expiresIn = response["ExpiresIn"] as? TimeInterval
        self.scope = response["Scope"] as? String
        self.eventID = response["EventID"] as? String
        
        self.serverProof = response["ServerProof"] as? String
        self.resetToken = response["ResetToken"] as? String
        self.tokenType = response["TokenType"] as? String
        self.privateKey = response["PrivateKey"] as? String
        self.passwordMode = response["PasswordMode"] as? Int ?? 0
        self.userStatus = response["UserStatus"] as? Int ?? 0
        
        self.keySalt = response["KeySalt"] as? String
        self.refreshToken = response["RefreshToken"] as? String
        return true
    }
}

final class AuthInfoResponse : ApiResponse {
    
    var Modulus : String?
    var ServerEphemeral : String?
    var Version : Int = 0
    var Salt : String?
    var SRPSession : String?
    var TwoFactor : Int = 0   //0 is off
    
    override func ParseResponse(_ response: [String : Any]!) -> Bool {
        
        self.Modulus         = response["Modulus"] as? String
        self.ServerEphemeral = response["ServerEphemeral"] as? String
        self.Version         = response["Version"] as? Int ?? 0
        self.Salt            = response["Salt"] as? String
        self.SRPSession      = response["SRPSession"] as? String
        self.TwoFactor       = response["TwoFactor"] as? Int ?? 0
        
        return true
    }
}

