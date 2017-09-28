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
    
    override func getAPIMethod() -> APIService.HTTPMethod {
        return .get
    }
    
    override open func getRequestPath() -> String {
        return OrganizationsAPI.Path + "/keys" + AppConstants.DEBUG_OPTION
    }
    
    override open func getVersion() -> Int {
        return OrganizationsAPI.V_GetOrgKeysRequest
    }
}

final class OrgKeyResponse : ApiResponse {
    var pubKey : String?
    var privKey : String?
    
    override func ParseResponse(_ response: Dictionary<String, Any>!) -> Bool {
        self.pubKey = response["PublicKey"] as? String
        self.privKey = response["PrivateKey"] as? String
        return true
    }
}
