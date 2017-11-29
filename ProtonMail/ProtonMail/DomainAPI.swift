//
//  DomainAPI.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 2/2/16.
//  Copyright (c) 2016 ArcTouch. All rights reserved.
//

import Foundation


// MARK : update right swipe action
final class GetAvailableDomainsRequest<T : ApiResponse> : ApiRequest<T> {
    
    override init() {
    }
    
    override func toDictionary() -> Dictionary<String, Any>? {
        return nil
    }
    
    override func getIsAuthFunction() -> Bool {
        return false
    }
    
    override func method() -> APIService.HTTPMethod {
        return .get
    }
    
    override open func path() -> String {
        return DomainsAPI.Path + "/available"
    }
    
    override func apiVersion() -> Int {
        return DomainsAPI.V_AvailableDomainsRequest
    }
}

final class AvailableDomainsResponse : ApiResponse {
    var domains : [String]?
    override func ParseResponse(_ response: Dictionary<String, Any>!) -> Bool {
        self.domains = response?["Domains"] as? [String]
        return true
    }
}
