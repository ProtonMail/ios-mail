//
//  UserAPI.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 11/3/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation

typealias CheckUserNameBlock = (Bool, NSError?) -> Void
typealias CreateUserBlock = (Bool, Bool, String, Error?) -> Void
typealias GenerateKey = (Bool, String?, NSError?) -> Void
typealias SendVerificationCodeBlock = (Bool, NSError?) -> Void

// MARK : update right swipe action
final class CreateNewUserRequest<T : ApiResponse> : ApiRequest<T> {
    
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
    
    override func toDictionary() -> Dictionary<String, Any>? {
        
        let auth : [String : Any] = [
            "Version" : 4,
            "ModulusID" : self.modulusID,
            "Salt" : self.salt,
            "Verifier" : self.verifer
        ]
        
        let out : [String : Any] = [
            "TokenType" : self.tokenType,
            "Username" : self.userName,
            "Email" : self.email,
            "News" : self.news == true ? 1 : 0,
            "Token" : self.recaptchaToken,
            "Auth" : auth
        ]
        return out
    }
    
    override func getIsAuthFunction() -> Bool {
        return false
    }
    
    override func getAPIMethod() -> APIService.HTTPMethod {
        return .post
    }
    
    override func getRequestPath() -> String {
        return UsersAPI.Path
    }
    
    override func getVersion() -> Int {
        return UsersAPI.V_CreateUsersRequest
    }
}

final class GetUserInfoResponse : ApiResponse {
    var userInfo : UserInfo?
    
    override func ParseResponse(_ response: Dictionary<String, Any>!) -> Bool {
        guard let res = response["User"] as? Dictionary<String, Any> else {
            let err = NSError.badUserInfoResponse("\(response)")
            err.uploadFabricAnswer(FetchUserInfoErrorTitle)
            return false
        }
        self.userInfo = UserInfo(response: res)
        return true
    }
}


final class GetUserInfoRequest<T : ApiResponse> : ApiRequest<T> {
    
    override init() {
    }
    
    override func toDictionary() -> Dictionary<String, Any>? {
        return nil
    }
    
    override func getAPIMethod() -> APIService.HTTPMethod {
        return .get
    }
    
    override func getRequestPath() -> String {
        return UsersAPI.Path
    }
    
    override func getVersion() -> Int {
        return UsersAPI.V_GetUserInfoRequest
    }
}


final class GetHumanCheckRequest<T : ApiResponse> : ApiRequest<T> {
    
    override init() {
    }
    
    override func toDictionary() -> Dictionary<String, Any>? {
        return nil
    }
    
    override func getAPIMethod() -> APIService.HTTPMethod {
        return .get
    }
    
    override open func getRequestPath() -> String {
        return UsersAPI.Path + "/human"
    }
    
    override open func getVersion() -> Int {
        return UsersAPI.V_GetHumanRequest
    }
}

final class GetHumanCheckResponse : ApiResponse {
    var token : String?
    var type : [String]?
    override func ParseResponse(_ response: Dictionary<String, Any>!) -> Bool {
        self.type = response["VerifyMethods"] as? [String]
        self.token = response["Token"] as? String
        return true
    }
}

final class HumanCheckRequest<T : ApiResponse> : ApiRequest<T> {
    var token : String
    var type : String
    
    init(type: String, token: String) {
        self.token = token
        self.type = type
    }
    
    override func toDictionary() -> Dictionary<String, Any>? {
        let out : [String : Any] =  ["Token":self.token, "TokenType":self.type ]
        return out
    }
    
    override func getAPIMethod() -> APIService.HTTPMethod {
        return .post
    }
    
    override func getRequestPath() -> String {
        return UsersAPI.Path + "/human"
    }
    
    override func getVersion() -> Int {
        return UsersAPI.V_HumanCheckRequest
    }
}

final class CheckUserExistRequest<T : ApiResponse> : ApiRequest<T> {
    
    let userName : String!
    
    init(userName : String) {
        self.userName = userName;
    }
    
    override func toDictionary() -> Dictionary<String, Any>? {
        return nil
    }
    
    override open func getIsAuthFunction() -> Bool {
        return false
    }
    
    override func getAPIMethod() -> APIService.HTTPMethod {
        return .get
    }
    
    override func getRequestPath() -> String {
        return UsersAPI.Path + "/available/" + userName
    }
    
    override func getVersion() -> Int {
        return UsersAPI.V_CheckUserExistRequest
    }
}

final class CheckUserExistResponse : ApiResponse {
    var isAvailable : Bool?
    
    override func ParseResponse(_ response: Dictionary<String, Any>!) -> Bool {
        PMLog.D(response.JSONStringify(true))
        isAvailable =  response["Available"] as? Bool
        return true
    }
}


final class DirectRequest<T : ApiResponse> : ApiRequest<T> {

    override func toDictionary() -> Dictionary<String, Any>? {
        return nil
    }
    
    override open func getIsAuthFunction() -> Bool {
        return false
    }
    
    override func getAPIMethod() -> APIService.HTTPMethod {
        return .get
    }
    
    override func getRequestPath() -> String {
        return UsersAPI.Path + "/direct"
    }
    
    override func getVersion() -> Int {
        return UsersAPI.V_DirectRequest
    }
}

final class DirectResponse : ApiResponse {
    var isSignUpAvailable : Int = 1
    var signupFunctions : [String]?
    override func ParseResponse(_ response: Dictionary<String, Any>!) -> Bool {
        PMLog.D(response.JSONStringify(true))
        isSignUpAvailable =  response["Direct"] as? Int ?? 1
        
        if let functions = response["VerifyMethods"] as? [String] {
            signupFunctions = functions
        }
        return true
    }
}

enum VerifyCodeType : Int {
    case email = 0
    case recaptcha = 1
    case sms = 2
    var toString : String {
        get {
            switch(self) {
            case .email:
                return "email"
            case .recaptcha:
                return "captcha"
            case .sms:
                return "sms"
            }
        }
    }
}

final class VerificationCodeRequest<T : ApiResponse> : ApiRequest<T> {
    
    let userName : String!
    let destination : String!
    let type : VerifyCodeType!
    let platform : String = "ios"
    
    init(userName : String!, destination : String!, type : VerifyCodeType!) {
        self.userName = userName
        self.destination = destination
        self.type = type
    }
    
    override func toDictionary() -> Dictionary<String, Any>? {
        let dest = type == .email ? ["Address" : destination] : ["Phone" : destination]
        let out : [String : Any] = [
            "Username" : userName,
            "Type" : type.toString,
            "Platform" : platform,
            "Destination" : dest
        ]
        return out
    }
    
    override open func getIsAuthFunction() -> Bool {
        return false
    }
    
    override func getAPIMethod() -> APIService.HTTPMethod {
        return .post
    }
    
    override open func getRequestPath() -> String {
        return UsersAPI.Path + "/code"
    }
    
    override open func getVersion() -> Int {
        return UsersAPI.V_SendVerificationCodeRequest
    }
}


extension NSError {
    class func badUserInfoResponse(_ error : String) -> NSError {
        return apiServiceError(
            code: APIErrorCode.SendErrorCode.draftBad,
            localizedDescription: error,
            localizedFailureReason: NSLocalizedString("The user info fetch is wrong", comment: "Description"))
    }
}
