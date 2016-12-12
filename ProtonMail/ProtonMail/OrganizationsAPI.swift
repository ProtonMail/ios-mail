//
//  OrganizationsAPI.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 11/15/16.
//  Copyright © 2016 ProtonMail. All rights reserved.
//

import Foundation



//MARK : get keys salt  #not in used
public class GetOrgKeys<T : ApiResponse> : ApiRequest<T> {
    
    override func getAPIMethod() -> APIService.HTTPMethod {
        return .GET
    }
    
    override public func getRequestPath() -> String {
        return OrganizationsAPI.Path + "/keys" + AppConstants.getDebugOption
    }
    
    override public func getVersion() -> Int {
        return OrganizationsAPI.V_GetOrgKeysRequest
    }
}

public class OrgKeyResponse : ApiResponse {
    var pubKey : String?
    var privKey : String?
    
    override func ParseResponse(response: Dictionary<String, AnyObject>!) -> Bool {
        self.pubKey = response["PublicKey"] as? String
        self.privKey = response["PrivateKey"] as? String
        return true
    }
}
