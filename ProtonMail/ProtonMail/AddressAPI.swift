//
//  AddressAPI.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 6/7/16.
//  Copyright © 2016 ProtonMail. All rights reserved.
//

import Foundation


// Mark : get addresses
final class GetAddressesRequest : ApiRequest<AddressesResponse> {
    
    override func method() -> APIService.HTTPMethod {
        return .get
    }
    
    override func path() -> String {
        return AddressesAPI.path
    }
    
    override func toDictionary() -> [String : Any]? {
        return nil
    }
    
    override func apiVersion() -> Int {
        return AddressesAPI.v_get_addresses
    }
}

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
        return .put
    }
    
    override open func path() -> String {
        return AddressesAPI.path + "/order" + AppConstants.DEBUG_OPTION
    }
    
    override func apiVersion() -> Int {
        return AddressesAPI.v_update_order
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
        return AddressesAPI.path + "/" + addressid + AppConstants.DEBUG_OPTION
    }
    
    override func apiVersion() -> Int {
        return AddressesAPI.v_update_address
    }
}

final class SetupAddressRequest : ApiRequest<AddressesResponse> {
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
        return AddressesAPI.path + "/setup"
    }
    
    override func apiVersion() -> Int {
        return AddressesAPI.v_setup
    }
}

final class AddressesResponse : ApiResponse {
    var addresses: [Address] = [Address]()
    override func ParseResponse(_ response: [String : Any]!) -> Bool {
        if let addresses = response["Addresses"] as? [[String : Any]] {
            for address in addresses {
                self.parseAddr(res: address)
            }
        } else if let address = response["Address"] as? [String : Any] {
            self.parseAddr(res: address)
        }
        return true
    }
    
    private func parseAddr(res: [String : Any]!) {
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
}

