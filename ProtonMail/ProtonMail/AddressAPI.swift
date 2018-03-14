//
//  AddressAPI.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 6/7/16.
//  Copyright © 2016 ProtonMail. All rights reserved.
//

import Foundation


// MARK : update addresses order
final class UpdateAddressOrder<T : ApiResponse> : ApiRequest<T> {
    let newOrder : [String]!
    
    init(adds : [String]!) {
        self.newOrder = adds
    }
    
    override func toDictionary() -> [String : Any]? {
        let out : [String : Any] = ["AddressIDs" : self.newOrder]
        return out
    }
    
    override func method() -> APIService.HTTPMethod {
        return .post
    }
    
    override open func path() -> String {
        return AddressesAPI.Path + "/order" + AppConstants.DEBUG_OPTION
    }
    
    override func apiVersion() -> Int {
        return AddressesAPI.V_AddressesOrderUpdate
    }
}


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
    
    override func toDictionary() -> [String : Any]? {
        let out : [String : Any] = ["DisplayName" : displayName, "Signature":signature]
        return out
    }
    
    override func method() -> APIService.HTTPMethod {
        return .put
    }
    
    override func path() -> String {
        return AddressesAPI.Path + "/" + addressid + AppConstants.DEBUG_OPTION
    }
    
    override func apiVersion() -> Int {
        return AddressesAPI.V_AddressesUpdateRequest
    }
}



final class SetupAddressRequest<T : ApiResponse> : ApiRequest<T> {
    let domain: String!
    init(domain_name: String) {
        self.domain = domain_name
    }
    
    override func toDictionary() -> [String : Any]? {
        let out : [String : Any] = ["Domain": self.domain]
        return out
    }
    
    override func method() -> APIService.HTTPMethod {
        return .post
    }
    
    override func path() -> String {
        return AddressesAPI.Path + "/setup"
    }
    
    override func apiVersion() -> Int {
        return AddressesAPI.V_AddressesSetupRequest
    }
}

final class SetupAddressResponse : ApiResponse {
    var addresses: [Address] = [Address]()
    override func ParseResponse(_ response: [String : Any]!) -> Bool {
        
        if let res = response["Address"] as? [String : Any] {
            
            var keys: [Key] = [Key]()
            if let address_keys = res["Keys"] as? [[String : Any]] {
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
                order: res["Order"] as? Int,
                receive: res["Receive"] as? Int,
                mailbox: res["Mailbox"] as? Int,
                display_name: res["DisplayName"] as? String,
                signature: res["Signature"] as? String,
                keys : keys,
                status: res["Status"] as? Int,
                type: res["Type"] as? Int,
                send: res["Send"] as? Int
                ))
            
        }
        return true
    }
}

