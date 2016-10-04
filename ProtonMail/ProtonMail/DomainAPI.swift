//
//  DomainAPI.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 2/2/16.
//  Copyright (c) 2016 ArcTouch. All rights reserved.
//

import Foundation


// MARK : update right swipe action
public class GetAvailableDomainsRequest<T : ApiResponse> : ApiRequest<T> {
    
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



