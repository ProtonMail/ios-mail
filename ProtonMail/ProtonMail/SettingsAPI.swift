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
        var out : [String : AnyObject] = ["Order" : self.newOrder]
    
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
        var out : [String : AnyObject] = ["Notify" : self.notify]

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
    
    init(password : String, notificationEmail : String) {
        self.pwd = password;
        self.email = notificationEmail;
    }
    
    override func toDictionary() -> Dictionary<String, AnyObject>? {
        var out : [String : AnyObject] = ["Password" : self.pwd, "NotificationEmail" : self.email]
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



