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
    let password: String!
    let email : String!
    let news : Bool!
    let publicKey : String!
    let privateKey : String!
    let domain: String!
    let tokenType : String!
    
    init(token : String!, type : String!, username :String!, password: String!, email:String!, domain:String!, news:Bool!, publicKey:String!, privateKey:String!) {
        self.recaptchaToken = token
        self.tokenType = type
        self.userName = username
        self.password = password
        self.email = email
        self.news = news
        self.publicKey = publicKey
        self.privateKey = privateKey
        self.domain = domain
    }
    
    override func toDictionary() -> Dictionary<String, AnyObject>? {
        var out : [String : AnyObject] = ["TokenType" : self.tokenType,
            "Username" : self.userName,
            "Password" : self.password,
            "Domain" : self.domain,
            "Email" : self.email,
            "News" : self.news == true ? 1 : 0,
            "PublicKey" : self.publicKey,
            "PrivateKey" : self.privateKey,
            "Token" : self.recaptchaToken
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
        self.userInfo = UserInfo(
            response: response["User"] as! Dictionary<String, AnyObject>,
            displayNameResponseKey: "DisplayName",
            maxSpaceResponseKey: "MaxSpace",
            notificationEmailResponseKey: "NotificationEmail",
            privateKeyResponseKey: "EncPrivateKey",
            publicKeyResponseKey: "PublicKey",
            signatureResponseKey: "Signature",
            usedSpaceResponseKey: "UsedSpace",
            userStatusResponseKey: "UserStatus",
            userAddressResponseKey: "Addresses",
            
            autoSaveContactResponseKey : "AutoSaveContacts",
            languageResponseKey : "Language",
            maxUploadResponseKey: "MaxUpload",
            notifyResponseKey: "Notify",
            showImagesResponseKey : "ShowImages",
            swipeLeftResponseKey : "SwipeLeft",
            swipeRightResponseKey : "SwipeRight",
            roleResponseKey : "Role",
            delinquentResponseKey : "Delinquent"
        )
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
        PMLog.D(response.JSONStringify(prettyPrinted: true))
        isAvailable =  response["Available"] as? Bool
        return true
    }
}


public enum VerifyCodeType : Int {
    case email = 0
    case recaptcha = 1
    var toString : String {
        get {
            switch(self) {
            case email:
                return "email"
            case recaptcha:
                return "recaptcha"
            }
        }
    }
}

public class VerificationCodeRequest<T : ApiResponse> : ApiRequest<T> {
    
    let userName : String!
    let emailAddress : String!
    let type : VerifyCodeType!
    let platform : String = "ios"
    
    init(userName : String!, emailAddress : String!, type : VerifyCodeType!) {
        self.userName = userName
        self.emailAddress = emailAddress
        self.type = type
    }
    
    override func toDictionary() -> Dictionary<String, AnyObject>? {
        
        var out : [String : AnyObject] = [
            "Username" : userName,
            "Type" : type.toString,
            "Platform" : platform,
            "Destination" : ["Address" : emailAddress]
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

