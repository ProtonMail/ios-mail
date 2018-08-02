//
//  SettingAPI.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 7/13/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation

//"News" : 255 // 0 - 255 bitmask., . 16, 32, 64, and 128 are currently unused.
struct News : OptionSet {
    let rawValue: Int
    //255 means throw out client cache and reload everything from server, 1 is mail, 2 is contacts
    static let announcements = RefreshStatus(rawValue: 1 << 0) //1 is announcements
    static let features      = RefreshStatus(rawValue: 1 << 1) //2 is features
    static let newsletter    = RefreshStatus(rawValue: 1 << 2) //4 is newsletter
    static let all           = RefreshStatus(rawValue: 0xFF)
}

// Mark : get settings
final class GetUserSettings : ApiRequestNew<SettingsResponse> {
    override func path() -> String {
        return SettingsAPI.path + AppConstants.DEBUG_OPTION
    }
    
    override func apiVersion() -> Int {
        return SettingsAPI.v_get_general_settings
    }
}

final class SettingsResponse : ApiResponse {
    var userSettings: [String : Any]?
    override func ParseResponse(_ response: [String : Any]!) -> Bool {
        if let settings = response["UserSettings"] as? [String : Any] {
            self.userSettings = settings
        }
        //        {
        //            "Code": 1000,
        //            "UserSettings": {
        //                "PasswordMode": 1,
        //                "Email": {
        //                    "Value": "abc@gmail.com",
        //                    "Status": 0,
        //                    "Notify": 1,
        //                    "Reset": 0
        //                },
        //                "News": 244,
        //                "Locale": "en_US",
        //                "LogAuth": 2,
        //                "InvoiceText": "रिवार में हुआ। ज檷\r\nCartoon Law Services\r\n1 DisneyWorld Lane\r\nOrlando, FL, 12345\r\nVAT blahblahlblahblah",
        //                "TwoFactor": 0
        //            }
        //        }
        return true
    }
}


// Mark : get mail settings
final class GetMailSettings : ApiRequestNew<MailSettingsResponse> {
    override func path() -> String {
        return SettingsAPI.path + "/mail" + AppConstants.DEBUG_OPTION
    }
    
    override func apiVersion() -> Int {
        return SettingsAPI.v_get_general_settings
    }
}

final class MailSettingsResponse : ApiResponse {
    var mailSettings: [String : Any]?
    override func ParseResponse(_ response: [String : Any]!) -> Bool {
        if let settings = response["MailSettings"] as? [String : Any] {
            self.mailSettings = settings
        }
        
//        "MailSettings": {
//            "DisplayName": "Put Chinese Here",
//            "Signature": "Your signature here",
//            "Theme": "<CSS>",
//            "AutoResponder": {
//                "StartTime": 0, // seconds relative to the start of the period (unix timestamp for fixed interval)
//                "Endtime" :  0, // seconds relative to the end of the period (unix timestamp for fixed interval)
//                "Repeat": 0, // Mode: 0 => fixed interval, 1 => daily, 2 => weekly, 3 => monthly, 4 => permanent
//                "DaysSelected": [], // For daily mode: the day of the week expressed as an integer between 0 and 6. 0 is Sunday, 1 is Monday, etc.
//                "Subject": "Auto", // The subject prefix: e.g. "Re" for "Re: <original subject>"
//                "Message": "",
//                "IsEnabled: false,
//                "Zone": "Europe/Zurich"
//            },
//            "AutoSaveContacts": 1,
//            "AutoWildcardSearch": 1,
//            "ComposerMode": 1,
//            "MessageButtons": 0,
//            "ShowImages": 1,
//            "ShowMoved": 3,
//            "ViewMode": 0,
//            "ViewLayout": 0,
//            "SwipeLeft": 0,
//            "SwipeRight": 3,
//            "AlsoArchive": 0,
//            "Hotkeys": 1,
//            "PMSignature": 1,
//            "ImageProxy": 0,
//            "TLS": 0,
//            "RightToLeft": 0,
//            "AttachPublicKey": 0,
//            "Sign": 0,
//            "PGPScheme": 16,
//            "PromptPin": 1,
//            "Autocrypt": 1,
//            "NumMessagePerPage": 50,
//            "DraftMIMEType": "text/html",
//            "ReceiveMIMEType": "text/html",
//            "ShowMIMEType": "text/html"
//        }
        return true
    }
}


// MARK : update email notifiy
final class UpdateNotify : ApiRequest<ApiResponse> {
    let notify : Int
    
    init(notify : Int) {
        self.notify = notify
    }
    
    override func toDictionary() -> [String : Any]? {
        let out : [String : Any] = ["Notify" : self.notify]
        return out
    }
    
    override func method() -> APIService.HTTPMethod {
        return .put
    }
    
    override func path() -> String {
        return SettingsAPI.path + "/email/notify" + AppConstants.DEBUG_OPTION
    }
    
    override func apiVersion() -> Int {
        return SettingsAPI.v_update_notify
    }
}

// MARK : update notification email
final class UpdateNotificationEmail : ApiRequest<ApiResponse> {

    let email : String!
    
    let clientEphemeral : String! //base64 encoded
    let clientProof : String! //base64 encoded
    let SRPSession : String! //hex encoded session id
    let tfaCode : String? // optional

    
    init(clientEphemeral : String!, clientProof : String!, sRPSession: String!, notificationEmail : String!, tfaCode : String?) {
        self.clientEphemeral = clientEphemeral
        self.clientProof = clientProof
        self.SRPSession = sRPSession
        self.email = notificationEmail
        self.tfaCode = tfaCode
    }
    
    override func toDictionary() -> [String : Any]? {
        
        var out : [String : Any] = [
            "ClientEphemeral" : self.clientEphemeral,
            "ClientProof" : self.clientProof,
            "SRPSession": self.SRPSession,
            "NotificationEmail" : email
        ]
        
        if let code = tfaCode {
            out["TwoFactorCode"] = code
        }
        return out
    }
    
    override func method() -> APIService.HTTPMethod {
        return .put
    }
    
    override func path() -> String {
        return SettingsAPI.path + "/email" + AppConstants.DEBUG_OPTION
    }
    
    override func apiVersion() -> Int {
        return SettingsAPI.v_update_email
    }
}

// MARK : update notification email
final class UpdateNewsRequest : ApiRequest<ApiResponse> {
    let news : Bool!
    
    init(news : Bool) {
        self.news = news
    }
    
    override func toDictionary() -> [String : Any]? {
        let receiveNews = self.news == true ? 1 : 0
        let out : [String : Any] = ["News" : receiveNews]
        return out
    }
    
    override func method() -> APIService.HTTPMethod {
        return .put
    }
    
    override func path() -> String {
        return SettingsAPI.path + "/news" + AppConstants.DEBUG_OPTION
    }
    
    override func apiVersion() -> Int {
        return SettingsAPI.v_update_sub_news
    }
}

//MARK : update display name 
final class UpdateDisplayNameRequest : ApiRequest<ApiResponse> {
    let displayName : String!
    
    init(displayName: String) {
        self.displayName = displayName
    }
    
    override func toDictionary() -> [String : Any]? {
        let out : [String : Any] = ["DisplayName" : displayName]
        return out
    }
    
    override func method() -> APIService.HTTPMethod {
        return .put
    }
    
    override func path() -> String {
        return SettingsAPI.path + "/mail/display" + AppConstants.DEBUG_OPTION
    }
    
    override func apiVersion() -> Int {
        return SettingsAPI.v_update_display_name
    }
}

//MARK : update display name

//Here need to change to 0 for none, 1 for remote, 2 for embedded, 3 for remote and embedded
final class UpdateShowImagesRequest : ApiRequest<ApiResponse> {
    let status : Int!
    
    init(status: Int) {
        self.status = status
    }
    
    override func toDictionary() -> [String : Any]? {
        let out : [String : Any] = ["ShowImages" : status]
        return out
    }
    
    override func method() -> APIService.HTTPMethod {
        return .put
    }
    
    override func path() -> String {
        return SettingsAPI.path + "/mail/images" + AppConstants.DEBUG_OPTION
    }
    
    override func apiVersion() -> Int {
        return SettingsAPI.v_update_shwo_images
    }
}

// MARK : update left swipe action
final class UpdateSwiftLeftAction : ApiRequest<ApiResponse> {
    let newAction : MessageSwipeAction!
    
    init(action : MessageSwipeAction!) {
        self.newAction = action;
    }
    
    override func toDictionary() -> [String : Any]? {
        let out : [String : Any] = ["SwipeLeft" : self.newAction.rawValue]
        return out
    }
    
    override func method() -> APIService.HTTPMethod {
        return .put
    }
    
    override func path() -> String {
        return SettingsAPI.path + "/mail/swipeleft" + AppConstants.DEBUG_OPTION
    }
    
    override func apiVersion() -> Int {
        return SettingsAPI.v_update_swipe_left_right
    }
}

// MARK : update right swipe action
final class UpdateSwiftRightAction : ApiRequest<ApiResponse> {
    let newAction : MessageSwipeAction!
    
    init(action : MessageSwipeAction!) {
        self.newAction = action;
    }
    
    override func toDictionary() -> [String : Any]? {
        let out : [String : Any] = ["SwipeRight" : self.newAction.rawValue]
        return out
    }
    
    override func method() -> APIService.HTTPMethod {
        return .put
    }
    
    override func path() -> String {
        return SettingsAPI.path + "/mail/swiperight" + AppConstants.DEBUG_OPTION
    }
    
    override func apiVersion() -> Int {
        return SettingsAPI.v_update_swipe_right_left
    }
}

// update login password this is only in two password mode
final class UpdateLoginPassword : ApiRequest<ApiResponse> {
    let clientEphemeral : String! //base64_encoded_ephemeral
    let clientProof : String! //base64_encoded_proof
    let SRPSession : String! //hex_encoded_session_id
    let tfaCode : String?
    
    let modulusID : String! //encrypted_id
    let salt : String! //base64_encoded_salt
    let verifer : String! //base64_encoded_verifier

    
    init(clientEphemeral : String!,
         clientProof : String!,
         SRPSession : String!,
         modulusID : String!,
         salt : String!,
         verifer : String!,
         tfaCode : String?) {
        
        self.clientEphemeral = clientEphemeral
        self.clientProof = clientProof
        self.SRPSession = SRPSession
        self.tfaCode = tfaCode
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
    
    override func method() -> APIService.HTTPMethod {
        return .put
    }
    
    override func path() -> String {
        return SettingsAPI.path + "/password" + AppConstants.DEBUG_OPTION
    }
    
    override func apiVersion() -> Int {
        return SettingsAPI.v_update_login_password
    }
}
