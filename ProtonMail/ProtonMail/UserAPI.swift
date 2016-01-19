//
//  UserAPI.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 11/3/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation


typealias CheckUserNameBlock = (Bool, NSError?) -> Void

// MARK : update right swipe action
public class CreateNewUserRequest<T : ApiResponse> : ApiRequest<T> {
    
    let token : String!
    
    init(token : String) {
        self.token = token;
    }
    
    override func toDictionary() -> Dictionary<String, AnyObject>? {
        var out : [String : AnyObject] = ["g-recaptcha-response" : token]
        return out
    }
    
    override public func getIsAuthFunction() -> Bool {
        return false
    }
    
    override func getAPIMethod() -> APIService.HTTPMethod {
        return .POST
    }
    
    override public func getRequestPath() -> String {
        return "http://protonmail.xyz/check.php"
    }
    
    override public func getVersion() -> Int {
        return SettingsAPI.V_SettingsUpdateSwipeRightRequest
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
            swipeRightResponseKey : "SwipeRight"
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




