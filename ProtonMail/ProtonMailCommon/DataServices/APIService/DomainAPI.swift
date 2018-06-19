//
//  DomainAPI.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 2/2/16.
//  Copyright (c) 2016 ArcTouch. All rights reserved.
//

import Foundation


// MARK : update right swipe action
final class GetAvailableDomainsRequest : ApiRequest<AvailableDomainsResponse> {

    override func getIsAuthFunction() -> Bool {
        return false
    }
    
    override open func path() -> String {
        return DomainsAPI.path + "/available"
    }
    
    override func apiVersion() -> Int {
        return DomainsAPI.v_available_domains
    }
}

//Responses
final class AvailableDomainsResponse : ApiResponse {
    var domains : [String]?
    override func ParseResponse(_ response: [String : Any]!) -> Bool {
        self.domains = response?["Domains"] as? [String]
        return true
    }
}
