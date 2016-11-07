//
//  AuthAPI.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 6/17/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

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

struct Constants {
    // FIXME: These values would be obtainable by inspecting the binary code, but to make thins a little more difficult, we probably don't want to these values visible when the source code is distributed.  We will probably want to come up with a way to pass in these values as pre-compiler macros.  Swift doesn't support pre-compiler macros, but we have Objective-C and can still use them.  The values would be passed in by the build scripts at build time.  Or, these values could be cleared before publishing the code.
    static let clientID = "iOS"
    static let clientSecret = "db85d1c1a3021b8371ebdedd6f2fe354"
    static let rediectURL = "https://protonmail.ch"
}



// MARK : Get messages part
public class AuthInfoRequest<T : ApiResponse> : ApiRequest<T> {
    
    var username : String!
    
    init(username : String) {
        self.username = username;
    }
    
    override func toDictionary() -> Dictionary<String, AnyObject>? {
        let out : [String : AnyObject] = [
            AuthKey.clientID : Constants.clientID,
            AuthKey.clientSecret : Constants.clientSecret,
            AuthKey.userName : username
        ]
        PMLog.D(self.JSONStringify(out, prettyPrinted: true))
        return out
    }
    
    override func getAPIMethod() -> APIService.HTTPMethod {
        return .POST
    }
    
    override public func getRequestPath() -> String {
        return AuthAPI.Path + "/info" + AppConstants.getDebugOption
    }
    
    override public func getIsAuthFunction() -> Bool {
        return false
    }
}


// MARK : Get messages part
public class AuthRequest<T : ApiResponse> : ApiRequest<T> {
    
    var username : String!
    var clientEphemeral : String! //base64
    var clientProof : String!  //base64
    var srpSession : String!  //hex
    var twoFactorCode : String?
    
    //local verify only
    var serverProof : NSData!
    
    init(username : String, ephemeral:NSData, proof:NSData, session:String!, serverProof : NSData!, code:String?) {
        self.username = username
        self.clientEphemeral = ephemeral.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0))
        self.clientProof = proof.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0))
        self.srpSession = session
        self.twoFactorCode = code
        self.serverProof = serverProof
    }
    
    override func toDictionary() -> Dictionary<String, AnyObject>? {
        
        var out : [String : AnyObject] = [
            AuthKey.clientID : Constants.clientID,
            AuthKey.clientSecret : Constants.clientSecret,
            AuthKey.userName : username,
            
            AuthKey.ephemeral : clientEphemeral,
            AuthKey.proof : clientProof,
            AuthKey.session : srpSession,
        ]
        
        if let code = self.twoFactorCode {
            out[AuthKey.twoFactor] = code
        }
        
        PMLog.D(self.JSONStringify(out, prettyPrinted: true))
        
        return out
    }
    
    override func getAPIMethod() -> APIService.HTTPMethod {
        return .POST
    }
    
    override public func getRequestPath() -> String {
        return AuthAPI.Path + AppConstants.getDebugOption
    }
    
    override public func getIsAuthFunction() -> Bool {
        return false
    }
}


// MARK : Get messages part
public class AuthRefreshRequest<T : ApiResponse> : ApiRequest<T> {
    
    var resfreshToken : String!
    // var password : String!
    
    init(resfresh : String) {
        self.resfreshToken = resfresh;
    }
    
    override func toDictionary() -> Dictionary<String, AnyObject>? {
        
        let out = [
            "ClientID": Constants.clientID,
            "ResponseType": "token",
            "RefreshToken": resfreshToken,
            "GrantType": "refresh_token",
            "RedirectURI" : "http://www.protonmail.ch",
            AuthKey.state : "\(NSUUID().UUIDString)"]
        
        PMLog.D(self.JSONStringify(out, prettyPrinted: true))
        return out
    }
    
    override func getAPIMethod() -> APIService.HTTPMethod {
        return .POST
    }
    
    override public func getRequestPath() -> String {
        return AuthAPI.Path + "/refresh" + AppConstants.getDebugOption
    }
    
    override public func getIsAuthFunction() -> Bool {
        return false
    }
}



// MARK : Get messages part
public class AuthDeleteRequest<T : ApiResponse> : ApiRequest<T> {
    
    override init() {
    }
    
    override func getAPIMethod() -> APIService.HTTPMethod {
        return .DELETE
    }
    
    override public func getRequestPath() -> String {
        return AuthAPI.Path + AppConstants.getDebugOption
    }
    
    override public func getIsAuthFunction() -> Bool {
        return false
    }
}


// MARK : Response part
public class AuthResponse : ApiResponse {
    
    var encPrivateKey : String?
    var accessToken : String?
    var expiresIn : NSTimeInterval?
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
    
    override func ParseResponse(response: Dictionary<String, AnyObject>!) -> Bool {
        
        PMLog.D(response.JSONStringify(true))
        self.encPrivateKey = response["EncPrivateKey"] as? String
        self.userID = response["Uid"] as? String
        self.accessToken = response["AccessToken"] as? String
        self.expiresIn = response["ExpiresIn"] as? NSTimeInterval
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



public class AuthInfoResponse : ApiResponse {
    
    var Modulus : String?
    var ServerEphemeral : String?
    var Version : Int = 0
    var Salt : String?
    var SRPSession : String?
    var TwoFactor : Int = 0   //0 is off
    
    override func ParseResponse(response: Dictionary<String, AnyObject>!) -> Bool {
        
        PMLog.D(response.JSONStringify(true))
        
        self.Modulus = response["Modulus"] as? String
        self.ServerEphemeral = response["ServerEphemeral"] as? String
        self.Version = response["Version"] as? Int ?? 0
        self.Salt = response["Salt"] as? String
        self.SRPSession = response["SRPSession"] as? String
        self.TwoFactor = response["TwoFactor"] as? Int ?? 0
        
        return true
    }
}

