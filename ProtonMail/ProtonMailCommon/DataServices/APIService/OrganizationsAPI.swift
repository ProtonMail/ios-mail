//
//  OrganizationsAPI.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 11/15/16.
//  Copyright © 2016 ProtonMail. All rights reserved.
//

import Foundation

//MARK : get keys salt
final class GetOrgKeys : ApiRequest<OrgKeyResponse> {
    
    override func method() -> APIService.HTTPMethod {
        return .get
    }
    
    override func path() -> String {
        return OrganizationsAPI.Path + "/keys" + AppConstants.DEBUG_OPTION
    }
    
    override func apiVersion() -> Int {
        return OrganizationsAPI.v_get_org_keys
    }
}

final class OrgKeyResponse : ApiResponse {
    var privKey : String?
    
    override func ParseResponse(_ response: [String : Any]!) -> Bool {
        self.privKey = response["PrivateKey"] as? String
        return true
    }
}
