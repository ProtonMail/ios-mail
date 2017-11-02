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
class CreateNewUserRequest<T : ApiResponse> : ApiRequest<T> {
    
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

class GetUserInfoResponse : ApiResponse {
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


class GetUserInfoRequest<T : ApiResponse> : ApiRequest<T> {
    
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


class GetHumanCheckRequest<T : ApiResponse> : ApiRequest<T> {
    
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

class GetHumanCheckResponse : ApiResponse {
    var token : String?
    var type : [String]?
    override func ParseResponse(_ response: Dictionary<String, Any>!) -> Bool {
        self.type = response["VerifyMethods"] as? [String]
        self.token = response["Token"] as? String
        return true
    }
}

class HumanCheckRequest<T : ApiResponse> : ApiRequest<T> {
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

class CheckUserExistRequest<T : ApiResponse> : ApiRequest<T> {
    
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

class CheckUserExistResponse : ApiResponse {
    var isAvailable : Bool?
    
    override func ParseResponse(_ response: Dictionary<String, Any>!) -> Bool {
        PMLog.D(response.JSONStringify(true))
        isAvailable =  response["Available"] as? Bool
        return true
    }
}


class DirectRequest<T : ApiResponse> : ApiRequest<T> {
    
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

class DirectResponse : ApiResponse {
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

class VerificationCodeRequest<T : ApiResponse> : ApiRequest<T> {
    
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


class GetUserPublicKeysRequest<T : ApiResponse> : ApiRequest<T> {
    var emails : String
    var requestPath : String =  UsersAPI.Path + "/pubkeys"
    
    init(emails : String) {
        self.emails = emails
        if let base64Emails = emails.base64Encoded() {
            let escapedValue : String? = base64Emails.addingPercentEncoding(withAllowedCharacters: CharacterSet(charactersIn: "/+=\n").inverted)
            self.requestPath = UsersAPI.Path.stringByAppendingPathComponent("pubkeys").stringByAppendingPathComponent(escapedValue ?? base64Emails)
            PMLog.D(self.requestPath)
        }
    }
    
    override func getAPIMethod() -> APIService.HTTPMethod {
        return .get
    }
    
    override func getRequestPath() -> String {
        return requestPath
    }
    
    override func getVersion() -> Int {
        return UsersAPI.V_GetUserPublicKeysRequest
    }
}

class PublicKeysResponse : ApiResponse {

    var publicKeys : [String : String] = [String : String]()
    override func ParseResponse(_ response: Dictionary<String, Any>!) -> Bool {
        for (k,v) in response {
            if k != "Code" {
                publicKeys[k] = (v as? String) ?? ""
            }
        }
        return true
    }
}

class EmailsCheckResponse : PublicKeysResponse {
    var hasOutsideEmails : Bool = false
    
    override func ParseResponse(_ response: Dictionary<String, Any>!) -> Bool {
        if super.ParseResponse(response) {
            for (_, v) in publicKeys {
                if v.isEmpty {
                    hasOutsideEmails = true
                }
            }
            return true
        }
        return false
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
