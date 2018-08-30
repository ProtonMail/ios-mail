//
//  UserAPI.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 11/3/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation
import Crashlytics

typealias CheckUserNameBlock = (Bool, NSError?) -> Void
typealias CreateUserBlock = (Bool, Bool, String, Error?) -> Void
typealias GenerateKey = (Bool, String?, NSError?) -> Void
typealias SendVerificationCodeBlock = (Bool, NSError?) -> Void

// MARK : update right swipe action
class CreateNewUser : ApiRequest<ApiResponse> {
    
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
    
    override func toDictionary() -> [String : Any]? {
        
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
    
    override func method() -> APIService.HTTPMethod {
        return .post
    }
    
    override func path() -> String {
        return UsersAPI.path
    }
    
    override func apiVersion() -> Int {
        return UsersAPI.v_create_user
    }
}

final class GetUserInfoRequest : ApiRequestNew<GetUserInfoResponse> {
    
    override func method() -> APIService.HTTPMethod {
        return .get
    }
    
    override func path() -> String {
        return UsersAPI.path
    }
    
    override func apiVersion() -> Int {
        return UsersAPI.v_get_userinfo
    }
}


final class GetUserInfoResponse : ApiResponse {
    var userInfo : UserInfo?
    
    override func ParseResponse(_ response: [String : Any]!) -> Bool {
        guard let res = response["User"] as? [String : Any] else {
            return false
        }
        self.userInfo = UserInfo(response: res)
        return true
    }
}


class GetHumanCheckToken : ApiRequest<GetHumanCheckResponse> {
    
    override init() {
    }
    
    override func toDictionary() -> [String : Any]? {
        return nil
    }
    
    override func method() -> APIService.HTTPMethod {
        return .get
    }
    
    override func path() -> String {
        return UsersAPI.path + "/human"
    }
    
    override func apiVersion() -> Int {
        return UsersAPI.v_get_human_verify_options
    }
}

class GetHumanCheckResponse : ApiResponse {
    var token : String?
    var type : [String]?
    override func ParseResponse(_ response: [String : Any]!) -> Bool {
        self.type = response["VerifyMethods"] as? [String]
        self.token = response["Token"] as? String
        return true
    }
}

class HumanCheckRequest : ApiRequest<ApiResponse> {
    var token : String
    var type : String
    
    init(type: String, token: String) {
        self.token = token
        self.type = type
    }
    
    override func toDictionary() -> [String : Any]? {
        let out : [String : Any] =  ["Token":self.token, "TokenType":self.type ]
        return out
    }
    
    override func method() -> APIService.HTTPMethod {
        return .post
    }
    
    override func path() -> String {
        return UsersAPI.path + "/human"
    }
    
    override func apiVersion() -> Int {
        return UsersAPI.v_verify_human
    }
}

class CheckUserExist : ApiRequest<CheckUserExistResponse> {
    
    let userName : String!
    
    init(userName : String) {
        self.userName = userName;
    }
    
    override func toDictionary() -> [String : Any]? {
        return nil
    }
    
    override func getIsAuthFunction() -> Bool {
        return false
    }
    
    override func method() -> APIService.HTTPMethod {
        return .get
    }
    
    override func path() -> String {
        return UsersAPI.path + "/available/" + userName
    }
    
    override func apiVersion() -> Int {
        return UsersAPI.v_check_is_user_exist
    }
}

class CheckUserExistResponse : ApiResponse {
    var isAvailable : Bool?
    
    override func ParseResponse(_ response: [String : Any]!) -> Bool {
        PMLog.D(response.json(prettyPrinted: true))
        isAvailable =  response["Available"] as? Bool
        return true
    }
}


class DirectRequest : ApiRequest<DirectResponse> {
    
    override func toDictionary() -> [String : Any]? {
        return nil
    }
    
    override func getIsAuthFunction() -> Bool {
        return false
    }
    
    override func method() -> APIService.HTTPMethod {
        return .get
    }
    
    override func path() -> String {
        return UsersAPI.path + "/direct"  //type (optional, integer, 1) ... 1 => mail, 2 => VPN
    }
    
    override func apiVersion() -> Int {
        return UsersAPI.v_get_user_direct
    }
}

class DirectResponse : ApiResponse {
    var isSignUpAvailable : Int = 1
    var signupFunctions : [String]?
    override func ParseResponse(_ response: [String : Any]!) -> Bool {
        PMLog.D(response.json(prettyPrinted: true))
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

class VerificationCodeRequest : ApiRequest<ApiResponse> {
    
    let userName : String!
    let destination : String!
    let type : VerifyCodeType!
    let platform : String = "ios"
    
    init(userName : String!, destination : String!, type : VerifyCodeType!) {
        self.userName = userName
        self.destination = destination
        self.type = type
    }
    
    override func toDictionary() -> [String : Any]? {
        let dest = type == .email ? ["Address" : destination] : ["Phone" : destination]
        let out : [String : Any] = [
            "Username" : userName,
            "Type" : type.toString,
            "Platform" : platform,
            "Destination" : dest
        ]
        return out
    }
    
    override func getIsAuthFunction() -> Bool {
        return false
    }
    
    override func method() -> APIService.HTTPMethod {
        return .post
    }
    
    override func path() -> String {
        return UsersAPI.path + "/code"
    }
    
    override func apiVersion() -> Int {
        return UsersAPI.v_send_verification_code
    }
}
