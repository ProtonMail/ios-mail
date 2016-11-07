//
//  SettingAPI.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 7/13/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation



// MARK : update domain order
public class UpdateDomainOrder<T : ApiResponse> : ApiRequest<T> {
    let newOrder : Array<Int>!
    
    init(adds:Array<Int>!) {
        self.newOrder = adds
    }
    
    override func toDictionary() -> Dictionary<String, AnyObject>? {
        let out : [String : AnyObject] = ["Order" : self.newOrder]
    
        //self.domains.();
        PMLog.D(self.JSONStringify(out, prettyPrinted: true))
        return out
    }
    
    override func getAPIMethod() -> APIService.HTTPMethod {
        return .PUT
    }
    
    override public func getRequestPath() -> String {
        return SettingsAPI.Path + "/addressorder" + AppConstants.getDebugOption
    }
    
    override public func getVersion() -> Int {
        return SettingsAPI.V_SettingsUpdateDomainRequest
    }
}


// MARK : update email notifiy
public class UpdateNotify<T : ApiResponse> : ApiRequest<T> {
    let notify : Int
    
    init(notify : Int) {
        self.notify = notify
    }
    
    override func toDictionary() -> Dictionary<String, AnyObject>? {
        let out : [String : AnyObject] = ["Notify" : self.notify]

        return out
    }
    
    override func getAPIMethod() -> APIService.HTTPMethod {
        return .PUT
    }
    
    override public func getRequestPath() -> String {
        return SettingsAPI.Path + "/notify" + AppConstants.getDebugOption
    }
    
    override public func getVersion() -> Int {
        return SettingsAPI.V_SettingsUpdateNotifyRequest
    }
}


// MARK : update notification email
public class UpdateNotificationEmail<T : ApiResponse> : ApiRequest<T> {
    let pwd : String!
    let email : String!
    let tfaCode : String?
    
    init(password : String, notificationEmail : String, tfaCode : String?) {
        self.pwd = password
        self.email = notificationEmail
        self.tfaCode = tfaCode
    }
    
    override func toDictionary() -> Dictionary<String, AnyObject>? {
        var out : [String : AnyObject] = ["Password" : self.pwd, "NotificationEmail" : self.email]
        if let code = tfaCode {
            out["TwoFactorCode"] = code
        }
        return out
    }
    
    override func getAPIMethod() -> APIService.HTTPMethod {
        return .PUT
    }
    
    override public func getRequestPath() -> String {
        return SettingsAPI.Path + "/noticeemail" + AppConstants.getDebugOption
    }
    
    override public func getVersion() -> Int {
        return SettingsAPI.V_SettingsUpdateNotifyRequest
    }
}

// MARK : update notification email
public class UpdateNewsRequest<T : ApiResponse> : ApiRequest<T> {
    let news : Bool!
    
    init(news : Bool) {
        self.news = news
    }
    
    override func toDictionary() -> Dictionary<String, AnyObject>? {
        let receiveNews = self.news == true ? 1 : 0
        let out : [String : AnyObject] = ["News" : receiveNews]
        return out
    }
    
    override func getAPIMethod() -> APIService.HTTPMethod {
        return .PUT
    }
    
    override public func getRequestPath() -> String {
        return SettingsAPI.Path + "/news" + AppConstants.getDebugOption
    }
    
    override public func getVersion() -> Int {
        return SettingsAPI.V_SettingsUpdateNewsRequest
    }
}

//MARK : update display name 
public class UpdateDisplayNameRequest<T : ApiResponse> : ApiRequest<T> {
    let displayName : String!
    
    init(displayName: String) {
        self.displayName = displayName
    }
    
    override func toDictionary() -> Dictionary<String, AnyObject>? {
        let out : [String : AnyObject] = ["DisplayName" : displayName]
        return out
    }
    
    override func getAPIMethod() -> APIService.HTTPMethod {
        return .PUT
    }
    
    override public func getRequestPath() -> String {
        return SettingsAPI.Path + "/display" + AppConstants.getDebugOption
    }
    
    override public func getVersion() -> Int {
        return SettingsAPI.V_SettingsUpdateDisplayNameRequest
    }
}

//MARK : update display name
public class UpdateShowImagesRequest<T : ApiResponse> : ApiRequest<T> {
    let status : Int!
    
    init(status: Int) {
        self.status = status
    }
    
    override func toDictionary() -> Dictionary<String, AnyObject>? {
        let out : [String : AnyObject] = ["ShowImages" : status]
        return out
    }
    
    override func getAPIMethod() -> APIService.HTTPMethod {
        return .PUT
    }
    
    override public func getRequestPath() -> String {
        return SettingsAPI.Path + "/showimages" + AppConstants.getDebugOption
    }
    
    override public func getVersion() -> Int {
        return SettingsAPI.V_SettingsUpdateShowImagesRequest
    }
}

// MARK : update left swipe action
public class UpdateSwiftLeftAction<T : ApiResponse> : ApiRequest<T> {
    let newAction : MessageSwipeAction!
    
    init(action : MessageSwipeAction!) {
        self.newAction = action;
    }
    
    override func toDictionary() -> Dictionary<String, AnyObject>? {
        let out : [String : AnyObject] = ["SwipeLeft" : self.newAction.rawValue]
        return out
    }
    
    override func getAPIMethod() -> APIService.HTTPMethod {
        return .PUT
    }
    
    override public func getRequestPath() -> String {
        return SettingsAPI.Path + "/swipeleft" + AppConstants.getDebugOption
    }
    
    override public func getVersion() -> Int {
        return SettingsAPI.V_SettingsUpdateSwipeLeftRequest
    }
}

// MARK : update right swipe action
public class UpdateSwiftRightAction<T : ApiResponse> : ApiRequest<T> {
    let newAction : MessageSwipeAction!
    
    init(action : MessageSwipeAction!) {
        self.newAction = action;
    }
    
    override func toDictionary() -> Dictionary<String, AnyObject>? {
        let out : [String : AnyObject] = ["SwipeRight" : self.newAction.rawValue]
        return out
    }
    
    override func getAPIMethod() -> APIService.HTTPMethod {
        return .PUT
    }
    
    override public func getRequestPath() -> String {
        return SettingsAPI.Path + "/swiperight" + AppConstants.getDebugOption
    }
    
    override public func getVersion() -> Int {
        return SettingsAPI.V_SettingsUpdateSwipeRightRequest
    }
}
