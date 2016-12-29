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

public class SetupAddressRequest<T : ApiResponse> : ApiRequest<T> {
    let domain: String!
    init(domain_name: String) {
        self.domain = domain_name
    }
    
    override func toDictionary() -> Dictionary<String, AnyObject>? {
        let out : [String : AnyObject] = ["Domain": self.domain ]
        return out
    }
    
    override func getAPIMethod() -> APIService.HTTPMethod {
        return .POST
    }
    
    override public func getRequestPath() -> String {
        return AddressesAPI.Path + "/setup"
    }
    
    override public func getVersion() -> Int {
        return AddressesAPI.V_AddressesSetupRequest
    }
}

public class SetupAddressResponse : ApiResponse {
    var addresses: [Address] = Array<Address>()
    override func ParseResponse(response: Dictionary<String, AnyObject>!) -> Bool {
        
        if let res = response["Address"] as? Dictionary<String, AnyObject> {
            
            var keys: [Key] = Array<Key>()
            if let address_keys = res["Keys"] as? Array<Dictionary<String, AnyObject>> {
                for key_res in address_keys {
                    keys.append(Key(
                        key_id: key_res["ID"] as? String,
                        public_key: key_res["PublicKey"] as? String,
                        private_key: key_res["PrivateKey"] as? String,
                        fingerprint: key_res["Fingerprint"] as? String,
                        isupdated: false))
                }
            }
            
            addresses.append(Address(
                addressid: res["ID"] as? String,
                email:res["Email"] as? String,
                send: res["Send"] as? Int,
                receive: res["Receive"] as? Int,
                mailbox: res["Mailbox"] as? Int,
                display_name: res["DisplayName"] as? String,
                signature: res["Signature"] as? String,
                keys : keys,
                status: res["Status"] as? Int,
                type: res["Type"] as? Int
                ))
            
        }
        return true
    }
}

