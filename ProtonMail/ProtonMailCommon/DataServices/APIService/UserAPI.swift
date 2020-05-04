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

typealias CheckUserNameBlock = (Result<CheckUserExistResponse.AvailabilityStatus>) -> Void
typealias CreateUserBlock = (Bool, Bool, String, Error?) -> Void
typealias GenerateKey = (Bool, String?, NSError?) -> Void
typealias SendVerificationCodeBlock = (Bool, NSError?) -> Void

// MARK : update right swipe action
class CreateNewUser : ApiRequest<ApiResponse> {
    
    let userName : String
    let recaptchaToken : String
    let email : String
    let tokenType : String
    
    let modulusID : String //encrypted_id
    let salt : String //base64_encoded_salt
    let verifer : String //base64_encoded_verifier
    
    let deviceToken : String
    
    init(token : String,
         type : String,
         username :String,
         email:String,
         
         modulusID : String,
         salt : String,
         verifer : String, deviceToken: String) {
        self.recaptchaToken = token
        self.tokenType = type
        self.userName = username
        self.email = email
        
        self.modulusID = modulusID
        self.salt = salt
        self.verifer = verifer
        self.deviceToken = deviceToken
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
            "Token" : self.recaptchaToken,
            "Auth" : auth,
            "Type" : 1,   //hard code to 1 for mail
            "Payload": ["mail-ios-payload" :  deviceToken ]
        ]
        return out
    }
    
    override func getIsAuthFunction() -> Bool {
        return false
    }
    
    override func method() -> HTTPMethod {
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

    override func method() -> HTTPMethod {
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
    
    override func method() -> HTTPMethod {
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
    
    override func method() -> HTTPMethod {
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
    
    let userName : String
    
    init(userName : String) {
        self.userName = userName;
    }
    
    override func toDictionary() -> [String : Any]? {
        return nil
    }
    
    override func getIsAuthFunction() -> Bool {
        return false
    }
    
    override func method() -> HTTPMethod {
        return .get
    }
    
    override func path() -> String {
        return UsersAPI.path + "/available?Name=" + (userName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")
    }
    
    override func apiVersion() -> Int {
        return UsersAPI.v_check_is_user_exist
    }
}

class CheckUserExistResponse : ApiResponse {
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
    
    override func ParseHttpError(_ error: NSError, response: [String : Any]?) {
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


class DirectRequest : ApiRequest<DirectResponse> {
    
    override func toDictionary() -> [String : Any]? {
        return nil
    }
    
    override func getIsAuthFunction() -> Bool {
        return false
    }
    
    override func method() -> HTTPMethod {
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
    
    override func method() -> HTTPMethod {
        return .post
    }
    
    override func path() -> String {
        return UsersAPI.path + "/code"
    }
    
    override func apiVersion() -> Int {
        return UsersAPI.v_send_verification_code
    }
}
