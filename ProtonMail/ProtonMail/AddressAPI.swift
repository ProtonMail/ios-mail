//
//  AddressAPI.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 6/7/16.
//  Copyright © 2016 ProtonMail. All rights reserved.
//

import Foundation


//MARK : update display name
final class UpdateAddressRequest<T : ApiResponse> : ApiRequest<T> {
    let addressid : String!
    let displayName : String!
    let signature : String!
    init(id : String, displayName: String, signature: String) {
        self.addressid = id
        self.displayName = displayName
        self.signature = signature;
    }
    
    override func toDictionary() -> Dictionary<String, Any>? {
        let out : [String : Any] = ["DisplayName" : displayName, "Signature":signature]
        return out
    }
    
    override func getAPIMethod() -> APIService.HTTPMethod {
        return .put
    }
    
    override func getRequestPath() -> String {
        return AddressesAPI.Path + "/" + addressid + AppConstants.getDebugOption
    }
    
    override func getVersion() -> Int {
        return AddressesAPI.V_AddressesUpdateRequest
    }
}

final class SetupAddressRequest<T : ApiResponse> : ApiRequest<T> {
    let domain: String!
    init(domain_name: String) {
        self.domain = domain_name
    }
    
    override func toDictionary() -> Dictionary<String, Any>? {
        let out : [String : Any] = ["Domain": self.domain]
        return out
    }
    
    override func getAPIMethod() -> APIService.HTTPMethod {
        return .post
    }
    
    override func getRequestPath() -> String {
        return AddressesAPI.Path + "/setup"
    }
    
    override func getVersion() -> Int {
        return AddressesAPI.V_AddressesSetupRequest
    }
}

final class SetupAddressResponse : ApiResponse {
    var addresses: [Address] = Array<Address>()
    override func ParseResponse(_ response: Dictionary<String, Any>!) -> Bool {
        
        if let res = response["Address"] as? Dictionary<String, Any> {
            
            var keys: [Key] = Array<Key>()
            if let address_keys = res["Keys"] as? Array<Dictionary<String, Any>> {
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

