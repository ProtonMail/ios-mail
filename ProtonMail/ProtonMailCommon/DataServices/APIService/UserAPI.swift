//
//  UserAPI.swift
//  ProtonMail - Created on 11/3/15.
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
import PromiseKit
import PMCommon

typealias CheckUserNameBlock = (Result<CheckUserExistResponse.AvailabilityStatus>) -> Void
typealias CreateUserBlock = (Bool, Bool, String, Error?) -> Void
typealias GenerateKey = (Bool, String?, NSError?) -> Void
typealias SendVerificationCodeBlock = (NSError?) -> Void


//Users API
//Doc: https://github.com/ProtonMail/Slim-API/blob/develop/api-spec/pm_api_users.md
struct UsersAPI {
    //
    static let path : String = "/users"
    
    /// Check if username already taken [GET]
    static let v_check_is_user_exist : Int = 3
    
    /// Check if direct user signups are enabled [GET]
    static let v_get_user_direct : Int = 3
    
    /// Get user's info [GET]
    static let v_get_userinfo : Int = 3
    
    /// Get options for human verification [GET]
    static let v_get_human_verify_options : Int = 3
    
    /// Verify user is human [POST]
    static let v_verify_human : Int = 3
    
    /// Create user [POST]
    static let v_create_user : Int = 3
    
    /// Send a verification code [POST]
    static let v_send_verification_code : Int = 3
}

// MARK : update right swipe action -- Response
class CreateNewUser : Request {
    
    let userName : String
    let recaptchaToken : String
    let email : String
    let tokenType : String
    
    let passwordAuth: PasswordAuth
    
    let deviceToken : String
    let challenge: [String: Any]
    
    init(token : String,
         type : String,
         username :String,
         email:String,
         passwordAuth: PasswordAuth,
         deviceToken: String,
         challenge: [String: Any]) {
        self.recaptchaToken = token
        self.tokenType = type
        self.userName = username
        self.email = email

        self.passwordAuth = passwordAuth
        
        self.deviceToken = deviceToken
        self.challenge = challenge
    }
    var parameters: [String : Any]? {
        
        let payload: [String: Any] = [
            "mail-ios-payload": deviceToken,
            "mail-ios-challenge": self.challenge
        ]
        
        let out : [String : Any] = [
            "TokenType" : self.tokenType,
            "Username" : self.userName,
            "Email" : self.email,
            "Token" : self.recaptchaToken,
            "Auth" : self.passwordAuth.parameters,
            "Type" : 1,   //hard code to 1 for mail
            "Payload": payload
        ]
        return out
    }
    
    var isAuth: Bool {
        return false
    }
    
    var method: HTTPMethod {
        return .post
    }
    
    var path: String {
        return UsersAPI.path
    }
}

///Get user info  --- GetUserInfoResponse
final class GetUserInfoRequest : Request {
    
    init(authCredential: AuthCredential? = nil) {
        self.auth = authCredential
    }
    
    var method: HTTPMethod {
        return .get
    }
    
    var path: String {
        return UsersAPI.path
    }
    
    //custom auth credentical
    var auth: AuthCredential?
    var authCredential : AuthCredential? {
        get {
            return self.auth
        }
    }    
}


final class GetUserInfoResponse : Response {
    var userInfo : UserInfo?
    
    override func ParseResponse(_ response: [String : Any]!) -> Bool {
        guard let res = response["User"] as? [String : Any] else {
            return false
        }
        self.userInfo = UserInfo(response: res)
        return true
    }
}

/// GetHumanCheckResponse
class GetHumanCheckToken : Request {
    var path: String {
        return UsersAPI.path + "/human"
    }
}

class GetHumanCheckResponse : Response {
    var token : String?
    var type : [String]?
    override func ParseResponse(_ response: [String : Any]!) -> Bool {
        self.type = response["VerifyMethods"] as? [String]
        self.token = response["Token"] as? String
        return true
    }
}

/// -- Response
class HumanCheckRequest : Request {
    var token : String
    var type : String
    
    init(type: String, token: String) {
        self.token = token
        self.type = type
    }
    
    var parameters: [String : Any]? {
        let out : [String : Any] =  ["Token":self.token, "TokenType":self.type ]
        return out
    }
    
    var method: HTTPMethod {
        return .post
    }
    
    var path: String {
        return UsersAPI.path + "/human"
    }
}

///CheckUserExistResponse
class CheckUserExist : Request {
    
    let userName : String
    init(userName : String) {
        self.userName = userName;
    }
    var isAuth: Bool {
        return false
    }
    var path: String {
        return UsersAPI.path + "/available?Name=" + (userName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")
    }
}

//TODO:: fix me before duouble check 
class CheckUserExistResponse : Response {
    enum AvailabilityStatus {
        case available
        case invalidCharacters(reason: String)
        case startWithSpecialCharacterForbidden(reason: String)
        case endWithSpecialCharacterForbidden(reason: String)
        case tooLong(reason: String)
        case unavailable(reason: String, suggestions: [String])
        case other(reason: String)
        
        init?(code: Int, reason: String, suggestions: [String]?) {
            switch code {
            case 12102: self = .invalidCharacters(reason: reason)
            case 12103: self = .startWithSpecialCharacterForbidden(reason: reason)
            case 12104: self = .endWithSpecialCharacterForbidden(reason: reason)
            case 12105: self = .tooLong(reason: reason)
            case 12106 where suggestions != nil: self = .unavailable(reason: reason, suggestions: suggestions!)
            default: self = .other(reason: reason)
            }
        }
    }
    
    internal var availabilityStatus : AvailabilityStatus?
    
    func ParseHttpError(_ error: NSError, response: [String : Any]?) {
        guard let response = response else { return }
        
        PMLog.D(response.json(prettyPrinted: true))
        guard let statusRaw = response["Code"] as? Int else {
            return
        }
        let errorMessage = response["Error"] as? String
        let details = response["Details"] as? [String: Any]
        let suggestions = details?["Suggestions"] as? [String]
        
        self.availabilityStatus = AvailabilityStatus(code: statusRaw,
                                                     reason: errorMessage ?? LocalString._error_invalid_username,
                                                     suggestions: suggestions)
    }
    
    override func ParseResponse(_ response: [String : Any]!) -> Bool {
        PMLog.D(response.json(prettyPrinted: true))
        self.availabilityStatus = AvailabilityStatus.available
        return true
    }
}

///DirectResponse
class DirectRequest : Request {
    
    var isAuth: Bool {
        return false
    }
    var path: String {
        return UsersAPI.path + "/direct"  //type (optional, integer, 1) ... 1 => mail, 2 => VPN
    }
}

class DirectResponse : Response {
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

///Response
class VerificationCodeRequest : Request {
    
    let userName : String
    let destination : String
    let type : VerifyCodeType
    let platform : String = "ios"
    
    init(userName : String, destination : String, type : VerifyCodeType) {
        self.userName = userName
        self.destination = destination
        self.type = type
    }
    
    var parameters: [String : Any]? {
        let dest = type == .email ? ["Address" : destination] : ["Phone" : destination]
        let out : [String : Any] = [
            "Username" : userName,
            "Type" : type.toString,
            "Platform" : platform,
            "Destination" : dest
        ]
        return out
    }
    
    var isAuth: Bool {
        return false
    }
    
    var method: HTTPMethod {
        return .post
    }
    
    var path: String {
        return UsersAPI.path + "/code"
    }
}
