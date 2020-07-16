//
//  AddressAPI.swift
//  ProtonMail - Created on 6/7/16.
//
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.


import Foundation


// Mark : get addresses
final class GetAddressesRequest : ApiRequestNew<AddressesResponse> {
    override func path() -> String {
        return AddressesAPI.path + Constants.App.DEBUG_OPTION
    }
    
    override func apiVersion() -> Int {
        return AddressesAPI.v_get_addresses
    }
}

// MARK : update addresses order
final class UpdateAddressOrder : ApiRequest<ApiResponse> {
    let newOrder : [String]
    
    init(adds : [String], authCredential: AuthCredential?) {
        self.newOrder = adds
        super.init()
        self.authCredential = authCredential
    }
    
    override func toDictionary() -> [String : Any]? {
        let out : [String : Any] = ["AddressIDs" : self.newOrder]
        return out
    }
    
    override func method() -> HTTPMethod {
        return .put
    }
    
    override func path() -> String {
        return AddressesAPI.path + "/order" + Constants.App.DEBUG_OPTION
    }
    
    override func apiVersion() -> Int {
        return AddressesAPI.v_update_order
    }
}

//MARK : update display name
final class UpdateAddressRequest : ApiRequest<ApiResponse> {
    let addressid : String
    let displayName : String
    let signature : String
    init(id : String, displayName: String, signature: String, authCredential: AuthCredential?) {
        self.addressid = id
        self.displayName = displayName
        self.signature = signature;
        super.init()
        self.authCredential = authCredential
    }
    
    override func toDictionary() -> [String : Any]? {
        let out : [String : Any] = ["DisplayName" : displayName,
                                    "Signature":signature]
        return out
    }
    
    override func method() -> HTTPMethod {
        return .put
    }
    
    override func path() -> String {
        return AddressesAPI.path + "/" + addressid + Constants.App.DEBUG_OPTION
    }
    
    override func apiVersion() -> Int {
        return AddressesAPI.v_update_address
    }
}


//Mark setup address when signup after create the user
final class SetupAddressRequest : ApiRequest<AddressesResponse> {
    let domain: String
    init(domain_name: String, auth: AuthCredential?) {
        self.domain = domain_name
        super.init()
        self.authCredential = auth
    }
    
    override func toDictionary() -> [String : Any]? {
        let out : [String : Any] = ["Domain": self.domain]
        return out
    }
    
    override func method() -> HTTPMethod {
        return .post
    }
    
    override func path() -> String {
        return AddressesAPI.path + "/setup" + Constants.App.DEBUG_OPTION
    }
    
    override func apiVersion() -> Int {
        return AddressesAPI.v_setup
    }
}


//Responses
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
    
    func parseAddr(res: [String : Any]!) {
        var keys: [Key] = [Key]()
        if let address_keys = res["Keys"] as? [[String : Any]] {
            for key_res in address_keys {
                keys.append(Key(
                    key_id: key_res["ID"] as? String,
                    private_key: key_res["PrivateKey"] as? String,
                    token: key_res["Token"] as? String,
                    signature: key_res["Signature"] as? String,
                    activation: key_res["Activation"] as? String,
                    isupdated: false))
            }
        }
        
        addresses.append(Address(
            addressid: res["ID"] as? String,
            email:res["Email"] as? String,
            order: res["Order"] as? Int,
            receive: res["Receive"] as? Int,
            display_name: res["DisplayName"] as? String,
            signature: res["Signature"] as? String,
            keys : keys,
            status: res["Status"] as? Int,
            type: res["Type"] as? Int,
            send: res["Send"] as? Int
        ))
    }
}

