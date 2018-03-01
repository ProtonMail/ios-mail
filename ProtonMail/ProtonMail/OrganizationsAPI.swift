//
//  OrganizationsAPI.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 11/15/16.
//  Copyright © 2016 ProtonMail. All rights reserved.
//

import Foundation



//MARK : get keys salt  #not in used
final class GetOrgKeys<T : ApiResponse> : ApiRequest<T> {
    
    override func method() -> APIService.HTTPMethod {
        return .get
    }
    
    override open func path() -> String {
        return OrganizationsAPI.Path + "/keys" + AppConstants.DEBUG_OPTION
    }
    
    override func apiVersion() -> Int {
        return OrganizationsAPI.V_GetOrgKeysRequest
    }
}

final class OrgKeyResponse : ApiResponse {
    var pubKey : String?
    var privKey : String?
    
    override func ParseResponse(_ response: [String : Any]!) -> Bool {
        self.pubKey = response["PublicKey"] as? String
        self.privKey = response["PrivateKey"] as? String
        return true
    }
}
