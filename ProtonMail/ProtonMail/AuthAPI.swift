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
}

struct Constants {
    // FIXME: These values would be obtainable by inspecting the binary code, but to make thins a little more difficult, we probably don't want to these values visible when the source code is distributed.  We will probably want to come up with a way to pass in these values as pre-compiler macros.  Swift doesn't support pre-compiler macros, but we have Objective-C and can still use them.  The values would be passed in by the build scripts at build time.  Or, these values could be cleared before publishing the code.
    static let clientID = "iOSBeta"
    static let clientSecret = "f53b44a68f9d8bc5d68de62e5e042eec"
    static let rediectURL = "https://protonmail.ch"
}

// MARK : Get messages part
public class AuthRequest<T : ApiResponse> : ApiRequest<T> {
    
    var username : String!
    var password : String!
    
    init(username : String, password:String) {
        self.username = username;
        self.password = password;
    }
    
    override func toDictionary() -> Dictionary<String, AnyObject>? {
        
        let out : [String : AnyObject] = [
            AuthKey.clientID : Constants.clientID,
            AuthKey.clientSecret : Constants.clientSecret,
            AuthKey.responseType : "token",
            AuthKey.userName : username,
            AuthKey.password : password,
            AuthKey.hashedPassword : "",
            AuthKey.grantType : "password",
            AuthKey.redirectUrl : Constants.rediectURL,
            AuthKey.state : "\(NSUUID().UUIDString)",
            AuthKey.scope : "full"
        ]
    
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
        
//            {
//                "ResponseType": "token",
//                "ClientID": "demoapp",
//                "GrantType": "refresh_token",
//                "RefreshToken":"8de763c8e14a3c793e7a3b916b53c3492d100285",
//                "RedirectURI": "http://www.protonmail.ch",
//                "State": "random_string"
        //}
        
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




// MARK : Response part


public class AuthResponse : ApiResponse {
    
    var encPrivateKey : String?
    var accessToken : String?
    var expiresIn : NSTimeInterval?
    var refreshToken : String?
    var userID : String?
    var eventID : String?
    
    override func ParseResponse(response: Dictionary<String, AnyObject>!) -> Bool {
        
        PMLog.D(response.JSONStringify(prettyPrinted: true))
        
        self.userID = response["Uid"] as? String
        self.encPrivateKey = response["EncPrivateKey"] as? String
        self.accessToken = response["AccessToken"] as? String
        self.expiresIn = response["ExpiresIn"] as? NSTimeInterval
        self.refreshToken = response["RefreshToken"] as? String
        self.eventID = response["EventID"] as? String
        
        return true
    }
}





