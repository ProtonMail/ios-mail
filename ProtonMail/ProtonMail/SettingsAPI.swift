//
//  SettingAPI.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 7/13/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation

// MARK : update email notifiy
final class UpdateNotify<T : ApiResponse> : ApiRequest<T> {
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
    
    override open func path() -> String {
        return SettingsAPI.Path + "/notify" + AppConstants.DEBUG_OPTION
    }
    
    override func apiVersion() -> Int {
        return SettingsAPI.V_SettingsUpdateNotifyRequest
    }
}

// MARK : update notification email
final class UpdateNotificationEmail<T : ApiResponse> : ApiRequest<T> {

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
    
    override open func path() -> String {
        return SettingsAPI.Path + "/noticeemail" + AppConstants.DEBUG_OPTION
    }
    
    override func apiVersion() -> Int {
        return SettingsAPI.V_SettingsUpdateNotifyRequest
    }
}

// MARK : update notification email
final class UpdateNewsRequest<T : ApiResponse> : ApiRequest<T> {
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
    
    override open func path() -> String {
        return SettingsAPI.Path + "/news" + AppConstants.DEBUG_OPTION
    }
    
    override func apiVersion() -> Int {
        return SettingsAPI.V_SettingsUpdateNewsRequest
    }
}

//MARK : update display name 
final class UpdateDisplayNameRequest<T : ApiResponse> : ApiRequest<T> {
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
    
    override open func path() -> String {
        return SettingsAPI.Path + "/display" + AppConstants.DEBUG_OPTION
    }
    
    override func apiVersion() -> Int {
        return SettingsAPI.V_SettingsUpdateDisplayNameRequest
    }
}

//MARK : update display name
final class UpdateShowImagesRequest<T : ApiResponse> : ApiRequest<T> {
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
    
    override open func path() -> String {
        return SettingsAPI.Path + "/showimages" + AppConstants.DEBUG_OPTION
    }
    
    override func apiVersion() -> Int {
        return SettingsAPI.V_SettingsUpdateShowImagesRequest
    }
}

// MARK : update left swipe action
final class UpdateSwiftLeftAction<T : ApiResponse> : ApiRequest<T> {
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
    
    override open func path() -> String {
        return SettingsAPI.Path + "/swipeleft" + AppConstants.DEBUG_OPTION
    }
    
    override func apiVersion() -> Int {
        return SettingsAPI.V_SettingsUpdateSwipeLeftRequest
    }
}

// MARK : update right swipe action
final class UpdateSwiftRightAction<T : ApiResponse> : ApiRequest<T> {
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
    
    override open func path() -> String {
        return SettingsAPI.Path + "/swiperight" + AppConstants.DEBUG_OPTION
    }
    
    override func apiVersion() -> Int {
        return SettingsAPI.V_SettingsUpdateSwipeRightRequest
    }
}

// update login password this is only in two password mode
final class UpdateLoginPassword<T : ApiResponse> : ApiRequest<T> {
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
    
    override open func path() -> String {
        return SettingsAPI.Path + "/password" + AppConstants.DEBUG_OPTION
    }
    
    override func apiVersion() -> Int {
        return SettingsAPI.V_SettingsUpdateLoginPasswordRequest
    }
}
