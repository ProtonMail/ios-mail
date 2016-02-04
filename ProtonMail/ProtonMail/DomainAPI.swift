//
//  DomainAPI.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 2/2/16.
//  Copyright (c) 2016 ArcTouch. All rights reserved.
//

import Foundation


// MARK : update right swipe action
public class CetAvailableDomainsRequest<T : ApiResponse> : ApiRequest<T> {
    
    override init() {
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
        return DomainsAPI.Path
    }
    
    override public func getVersion() -> Int {
        return DomainsAPI.V_AvailableDomainsRequest
    }
}


//public class GetUserInfoRequest<T : ApiResponse> : ApiRequest<T> {
//    
//    override init() {
//    }
//    
//    override func toDictionary() -> Dictionary<String, AnyObject>? {
//        return nil
//    }
//    
//    override func getAPIMethod() -> APIService.HTTPMethod {
//        return .GET
//    }
//    
//    override public func getRequestPath() -> String {
//        return UsersAPI.Path
//    }
//    
//    override public func getVersion() -> Int {
//        return UsersAPI.V_GetUserInfoRequest
//    }
//}
