//
//  UserAPI.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 11/3/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation



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
