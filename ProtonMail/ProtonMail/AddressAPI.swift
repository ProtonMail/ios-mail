//
//  AddressAPI.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 6/7/16.
//  Copyright © 2016 ProtonMail. All rights reserved.
//

import Foundation


//MARK : update display name
public class UpdateAddressRequest<T : ApiResponse> : ApiRequest<T> {
    let addressid : String!
    let displayName : String!
    let signature : String!
    init(id : String, displayName: String, signature: String) {
        self.addressid = id
        self.displayName = displayName
        self.signature = signature;
    }
    
    override func toDictionary() -> Dictionary<String, AnyObject>? {
        let out : [String : AnyObject] = ["DisplayName" : displayName, "Signature":signature ]
        return out
    }
    
    override func getAPIMethod() -> APIService.HTTPMethod {
        return .PUT
    }
    
    override public func getRequestPath() -> String {
        return AddressesAPI.Path + "/" + addressid + AppConstants.getDebugOption
    }
    
    override public func getVersion() -> Int {
        return AddressesAPI.V_AddressesUpdateRequest
    }
}