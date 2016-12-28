//
//  UserAPI.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 11/3/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation


typealias CheckUserNameBlock = (Bool, NSError?) -> Void
typealias CreateUserBlock = (Bool, Bool, String, NSError?) -> Void
typealias GenerateKey = (Bool, String?, NSError?) -> Void
typealias SendVerificationCodeBlock = (Bool, NSError?) -> Void

// MARK : update right swipe action
public class CreateNewUserRequest<T : ApiResponse> : ApiRequest<T> {
    
    let userName : String!
    let recaptchaToken : String!
    let email : String!
    let news : Bool!
    let tokenType : String!
    
    let modulusID : String! //encrypted_id
    let salt : String! //base64_encoded_salt
    let verifer : String! //base64_encoded_verifier
    
    init(token : String!,
         type : String!,
         username :String!,
         email:String!,
         news:Bool!,
         
         modulusID : String!,
         salt : String!,
         verifer : String!) {
        self.recaptchaToken = token
        self.tokenType = type
        self.userName = username
        self.email = email
        self.news = news
        
        self.modulusID = modulusID
        self.salt = salt
        self.verifer = verifer
    }
    
    override func toDictionary() -> Dictionary<String, AnyObject>? {
        
        let auth : [String : AnyObject] = [
            "Version" : 4,
            "ModulusID" : self.modulusID,
            "Salt" : self.salt,
            "Verifier" : self.verifer
        ]
        
        let out : [String : AnyObject] = ["TokenType" : self.tokenType,
            "Username" : self.userName,
            "Email" : self.email,
            "News" : self.news == true ? 1 : 0,
            "Token" : self.recaptchaToken,
            "Auth" : auth
        ]
        return out
    }
    
    override public func getIsAuthFunction() -> Bool {
        return false
    }
    
    override func getAPIMethod() -> APIService.HTTPMethod {
        return .POST
    }
    
    override public func getRequestPath() -> String {
        return UsersAPI.Path
    }
    
    override public func getVersion() -> Int {
        return UsersAPI.V_CreateUsersRequest
    }
}


public class GetUserInfoRequest<T : ApiResponse> : ApiRequest<T> {
    
    override init() {
    }
    
    override func toDictionary() -> Dictionary<String, AnyObject>? {
        return nil
    }
    
    override func getAPIMethod() -> APIService.HTTPMethod {
        return .GET
    }
    
    override public func getRequestPath() -> String {
        return UsersAPI.Path
    }
    
    override public func getVersion() -> Int {
        return UsersAPI.V_GetUserInfoRequest
    }
}

public class GetUserInfoResponse : ApiResponse {
    var userInfo : UserInfo?
    
    override func ParseResponse(response: Dictionary<String, AnyObject>!) -> Bool {
        guard let res = response["User"] as? Dictionary<String, AnyObject> else {
            let err = NSError.badUserInfoResponse("\(response)")
            err.uploadFabricAnswer(FetchUserInfoErrorTitle)
            return false
        }
        self.userInfo = UserInfo(response: res)
        return true
    }
}


public class CheckUserExistRequest<T : ApiResponse> : ApiRequest<T> {
    
    let userName : String!
    
    init(userName : String) {
        self.userName = userName;
    }
    
    override func toDictionary() -> Dictionary<String, AnyObject>? {
        return nil
    }
    
    override public func getIsAuthFunction() -> Bool {
        return false
    }
    
    override func getAPIMethod() -> APIService.HTTPMethod {
        return .GET
    }
    
    override public func getRequestPath() -> String {
        return UsersAPI.Path + "/available/" + userName
    }
    
    override public func getVersion() -> Int {
        return UsersAPI.V_CheckUserExistRequest
    }
}

public class CheckUserExistResponse : ApiResponse {
    var isAvailable : Bool?
    
    override func ParseResponse(response: Dictionary<String, AnyObject>!) -> Bool {
        PMLog.D(response.JSONStringify(true))
        isAvailable =  response["Available"] as? Bool
        return true
    }
}


public class DirectRequest<T : ApiResponse> : ApiRequest<T> {

    override func toDictionary() -> Dictionary<String, AnyObject>? {
        return nil
    }
    
    override public func getIsAuthFunction() -> Bool {
        return false
    }
    
    override func getAPIMethod() -> APIService.HTTPMethod {
        return .GET
    }
    
    override public func getRequestPath() -> String {
        return UsersAPI.Path + "/direct"
    }
    
    override public func getVersion() -> Int {
        return UsersAPI.V_DirectRequest
    }
}

public class DirectResponse : ApiResponse {
    var isSignUpAvailable : Int = 1
    var signupFunctions : [String]?
    override func ParseResponse(response: Dictionary<String, AnyObject>!) -> Bool {
        PMLog.D(response.JSONStringify(true))
        isSignUpAvailable =  response["Direct"] as? Int ?? 1
        
        if let functions = response["VerifyMethods"] as? [String] {
            signupFunctions = functions
        }
        return true
    }
}

public enum VerifyCodeType : Int {
    case email = 0
    case recaptcha = 1
    case sms = 2
    var toString : String {
        get {
            switch(self) {
            case email:
                return "email"
            case recaptcha:
                return "captcha"
            case sms:
                return "sms"
            }
        }
    }
}

public class VerificationCodeRequest<T : ApiResponse> : ApiRequest<T> {
    
    let userName : String!
    let destination : String!
    let type : VerifyCodeType!
    let platform : String = "ios"
    
    init(userName : String!, destination : String!, type : VerifyCodeType!) {
        self.userName = userName
        self.destination = destination
        self.type = type
    }
    
    override func toDictionary() -> Dictionary<String, AnyObject>? {
        let dest = type == .email ? ["Address" : destination] : ["Phone" : destination]
        let out : [String : AnyObject] = [            
            "Username" : userName,
            "Type" : type.toString,
            "Platform" : platform,
            "Destination" : dest
        ]
        return out
    }
    
    override public func getIsAuthFunction() -> Bool {
        return false
    }
    
    override func getAPIMethod() -> APIService.HTTPMethod {
        return .POST
    }
    
    override public func getRequestPath() -> String {
        return UsersAPI.Path + "/code"
    }
    
    override public func getVersion() -> Int {
        return UsersAPI.V_SendVerificationCodeRequest
    }
}


extension NSError {
    class func badUserInfoResponse(error : String) -> NSError {
        return apiServiceError(
            code: APIErrorCode.SendErrorCode.draftBad,
            localizedDescription: NSLocalizedString(error),
            localizedFailureReason: NSLocalizedString("The user info fetch is wrong"))
    }
}
