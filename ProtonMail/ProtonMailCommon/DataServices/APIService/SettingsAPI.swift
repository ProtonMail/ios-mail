//
//  SettingAPI.swift
//  ProtonMail - Created on 7/13/15.
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
import PMCommon


/**
 [Settings API Part 1]:
 https://github.com/ProtonMail/Slim-API/blob/develop/api-spec/pm_api_mail_settings.md
 [Settings API Part 2]:
 https://github.com/ProtonMail/Slim-API/blob/develop/api-spec/pm_api_settings.md
 
 Settings API
 - Doc: [Settings API Part 1], [Settings API Part 2]
 */
struct SettingsAPI {
    /// base settings api path
    static let path :String = "/\(Constants.App.API_PREFIXED)/settings"
    
    static let settingsPath: String = "/settings"
    
    /// Get general settings [GET]
    static let v_get_general_settings : Int = 3
    
    /// Turn on/off email notifications [PUT]
    static let v_update_notify : Int = 3
    
    /// Update email [PUT]
    static let v_update_email : Int = 3
    
    /// Update swipe left flag [PUT]
    static let v_update_swipe_left_right : Int = -1
    
    /// Update swipe right flag [PUT]
    static let v_update_swipe_right_left : Int = -1
    
    /// Update newsletter subscription [PUT]
    static let v_update_sub_news : Int = -1
    
    /// Update display name [PUT]
    static let v_update_display_name : Int = -1
    
    /// Update images bits [PUT]
    static let v_update_shwo_images : Int = -1
    
    /// Update login password [PUT]
    static let v_update_login_password : Int = 3
    
    /// Update login password [PUT]
    static let v_update_link_confirmation : Int = -1
    
    /// Update email signature [PUT]
    static let v_update_email_signature: Int = -1
}


//"News" : 255 // 0 - 255 bitmask., . 16, 32, 64, and 128 are currently unused.
struct News : OptionSet {
    let rawValue: Int
    //255 means throw out client cache and reload everything from server, 1 is mail, 2 is contacts
    static let announcements = News(rawValue: 1 << 0) //1 is announcements
    static let features      = News(rawValue: 1 << 1) //2 is features
    static let newsletter    = News(rawValue: 1 << 2) //4 is newsletter
    static let all           = News(rawValue: 0xFF)
}

// Mark : get settings -- SettingsResponse
final class GetUserSettings : Request {
    var path: String {
        return SettingsAPI.settingsPath
    }
    
    //custom auth credentical
    var auth: AuthCredential?
    var authCredential : AuthCredential? {
        get {
            return self.auth
        }
    }
}

final class SettingsResponse : Response {
    var userSettings: [String : Any]?
    override func ParseResponse(_ response: [String : Any]!) -> Bool {
        if let settings = response["UserSettings"] as? [String : Any] {
            self.userSettings = settings
        }
        return true
    }
}

// Mark : get mail settings -- MailSettingsResponse
final class GetMailSettings : Request {
    var path: String {
        return SettingsAPI.path
    }
    
    //custom auth credentical
    var auth: AuthCredential?
    var authCredential : AuthCredential? {
        get {
            return self.auth
        }
    }
}

final class MailSettingsResponse : Response {
    var mailSettings: [String : Any]?
    override func ParseResponse(_ response: [String : Any]!) -> Bool {
        if let settings = response["MailSettings"] as? [String : Any] {
            self.mailSettings = settings
        }
        return true
    }
}


// MARK : update email notifiy - Response
final class UpdateNotify : Request {
    let notify : Int
    init(notify : Int, authCredential: AuthCredential?) {
        self.notify = notify
        self.auth = authCredential
    }
    
    //custom auth credentical
    let auth: AuthCredential?
    var authCredential : AuthCredential? {
        get {
            return self.auth
        }
    }
    var parameters: [String : Any]? {
        let out : [String : Any] = ["Notify" : self.notify]
        return out
    }
    
    var method: HTTPMethod {
        return .put
    }
    
    var path: String {
        return SettingsAPI.settingsPath + "/email/notify"
    }
}

// MARK: update email signature - Response
final class UpdateSignature: Request {
    let signature: String
    init(signature: String, authCredential: AuthCredential?) {
        self.signature = signature
        self.auth = authCredential
    }
    
    //custom auth credentical
    let auth: AuthCredential?
    var authCredential : AuthCredential? {
        get {
            return self.auth
        }
    }
    
    var parameters: [String : Any]? {
        let out : [String : Any] = ["Signature" : self.signature]
        return out
    }
    
    var method: HTTPMethod {
        return .put
    }
    
    var path: String {
        return SettingsAPI.path + "/signature"
    }
}

// MARK : update notification email -- Response
final class UpdateNotificationEmail : Request {
    
    let email : String
    
    let clientEphemeral : String //base64 encoded
    let clientProof : String //base64 encoded
    let SRPSession : String //hex encoded session id
    let tfaCode : String? // optional
    
    
    init(clientEphemeral : String!, clientProof : String, sRPSession: String, notificationEmail : String,
         tfaCode : String?, authCredential: AuthCredential?) {
        self.clientEphemeral = clientEphemeral
        self.clientProof = clientProof
        self.SRPSession = sRPSession
        self.email = notificationEmail
        self.tfaCode = tfaCode
        
        self.auth = authCredential
    }
    
    //custom auth credentical
    let auth: AuthCredential?
    var authCredential : AuthCredential? {
        get {
            return self.auth
        }
    }
    
    var parameters: [String : Any]? {
        
        var out : [String : Any] = [
            "ClientEphemeral" : self.clientEphemeral,
            "ClientProof" : self.clientProof,
            "SRPSession": self.SRPSession,
            "Email" : email
        ]
        
        if let code = tfaCode {
            out["TwoFactorCode"] = code
        }
        return out
    }
    
    var method: HTTPMethod {
        return .put
    }
    
    var path: String {
        return SettingsAPI.settingsPath + "/email"
    }
}

// MARK : update notification email -- Response
final class UpdateNewsRequest : Request {
    let news : Bool
    init(news : Bool, auth: AuthCredential? = nil) {
        self.news = news
        self.auth = auth
    }
    var parameters: [String : Any]? {
        let receiveNews = self.news == true ? 255 : 0
        let out : [String : Any] = ["News" : receiveNews]
        return out
    }
    var method: HTTPMethod {
        return .put
    }
    
    var path: String {
        return SettingsAPI.path + "/news"
    }
    
    //custom auth credentical
    let auth: AuthCredential?
    var authCredential : AuthCredential? {
        get {
            return self.auth
        }
    }
}

//MARK : update display name, seems deprecated - Response
final class UpdateDisplayNameRequest : Request {
    let displayName : String
    
    init(displayName: String, authCredential: AuthCredential?) {
        self.displayName = displayName
        self.auth = authCredential
    }
    
    //custom auth credentical
    let auth: AuthCredential?
    var authCredential : AuthCredential? {
        get {
            return self.auth
        }
    }
    
    var parameters: [String : Any]? {
        let out : [String : Any] = ["DisplayName" : displayName]
        return out
    }
    var method: HTTPMethod  {
        return .put
    }
    var path: String {
        return SettingsAPI.path + "/display"
    }
}

//MARK : update display name -- Response

final class UpdateShowImages : Request {
    let status : Int
    
    /// Initial
    ///
    /// - Parameter status: //0 for none, 1 for remote, 2 for embedded, 3 for remote and embedded
    init(status: Int, authCredential: AuthCredential?) {
        self.status = status
        self.auth = authCredential
    }
    
    //custom auth credentical
    let auth: AuthCredential?
    var authCredential : AuthCredential? {
        get {
            return self.auth
        }
    }
    
    var parameters: [String : Any]? {
        let out : [String : Any] = ["ShowImages" : status]
        return out
    }
    var method: HTTPMethod {
        return .put
    }
    var path: String {
        return SettingsAPI.path + "/images"
    }
}


///Response
final class UpdateLinkConfirmation : Request {
    private let status: LinkOpeningMode
    
    init(status: LinkOpeningMode, authCredential: AuthCredential?) {
        self.status = status
        self.auth = authCredential
    }
    
    //custom auth credentical
    let auth: AuthCredential?
    var authCredential : AuthCredential? {
        get {
            return self.auth
        }
    }
    
    var parameters: [String : Any]? {
        return ["ConfirmLink" : NSNumber(value: self.status == .confirmationAlert).intValue]
    }
    var method: HTTPMethod {
        return .put
    }
    var path: String {
        return SettingsAPI.path + "/confirmlink"
    }
}

// MARK : update left swipe action -- Response
final class UpdateSwiftLeftAction : Request {
    let newAction : MessageSwipeAction
    
    init(action : MessageSwipeAction, authCredential: AuthCredential?) {
        self.newAction = action;
        self.auth = authCredential
    }
    
    //custom auth credentical
    let auth: AuthCredential?
    var authCredential : AuthCredential? {
        get {
            return self.auth
        }
    }
    
    var parameters: [String : Any]? {
        let out : [String : Any] = ["SwipeLeft" : self.newAction.rawValue]
        return out
    }
    var method: HTTPMethod {
        return .put
    }
    var path: String {
        return SettingsAPI.path + "/swipeleft"
    }
}

// MARK : update right swipe action -- Response
final class UpdateSwiftRightAction : Request {
    let newAction : MessageSwipeAction
    
    init(action : MessageSwipeAction, authCredential: AuthCredential?) {
        self.newAction = action
        self.auth = authCredential
    }
    
    //custom auth credentical
    let auth: AuthCredential?
    var authCredential : AuthCredential? {
        get {
            return self.auth
        }
    }
    
    var parameters: [String : Any]? {
        let out : [String : Any] = ["SwipeRight" : self.newAction.rawValue]
        return out
    }
    
    var method: HTTPMethod {
        return .put
    }
    
    var path: String {
        return SettingsAPI.path + "/swiperight"
    }
}

// update login password this is only in two password mode - Response
final class UpdateLoginPassword : Request {
    let clientEphemeral : String //base64_encoded_ephemeral
    let clientProof : String //base64_encoded_proof
    let SRPSession : String //hex_encoded_session_id
    let tfaCode : String?
    
    let modulusID : String //encrypted_id
    let salt : String //base64_encoded_salt
    let verifer : String //base64_encoded_verifier
    
    init(clientEphemeral : String,
         clientProof : String,
         SRPSession : String,
         modulusID : String,
         salt : String,
         verifer : String,
         tfaCode : String?,
         authCredential: AuthCredential?) {
        
        self.clientEphemeral = clientEphemeral
        self.clientProof = clientProof
        self.SRPSession = SRPSession
        self.tfaCode = tfaCode
        self.modulusID = modulusID
        self.salt = salt
        self.verifer = verifer
        
        self.auth = authCredential
    }
    
    //custom auth credentical
    let auth: AuthCredential?
    var authCredential : AuthCredential? {
        get {
            return self.auth
        }
    }
    
    var parameters: [String : Any]? {
        
        let auth : [String : Any] = [
            "Version" : 4,
            "ModulusID" : self.modulusID,
            "Salt" : self.salt,
            "Verifier" : self.verifer
        ]
        
        var out : [String : Any] = [
            "ClientEphemeral": self.clientEphemeral,
            "ClientProof": self.clientProof,
            "SRPSession": self.SRPSession,
            "Auth": auth
        ]
        
        if let code = tfaCode {
            out["TwoFactorCode"] = code
        }
        //PMLog.D(JSONStringify(out))
        return out
    }
    var method: HTTPMethod {
        return .put
    }
    
    var path: String {
        return SettingsAPI.settingsPath + "/password"
    }
}
