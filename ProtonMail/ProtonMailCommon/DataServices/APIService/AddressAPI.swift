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
import PMCommon



//Addresses API
//Doc: https://github.com/ProtonMail/Slim-API/blob/develop/api-spec/pm_api_addresses.md
struct AddressesAPI {
    /// base message api path
    static let path :String = "/addresses"
    
    //Create new address [POST /addresses] locked
    
    //Update address [PUT]
    //static let v_update_address : Int = 3
    
}

//Responses
final class AddressesResponse : Response {
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

// Mark : get addresses
//Get Addresses [GET /addresses]
//Get Address [GET /addresses/{address_id}]
//response : AddressesResponse
final class GetAddressesRequest : Request {
    var path: String {
        return AddressesAPI.path
    }
    
    //custom auth credentical
    var auth: AuthCredential?
    var authCredential : AuthCredential? {
        get {
            return self.auth
        }
    }
}

// MARK : update addresses order
// Order Addresses [/addresses/order]
final class UpdateAddressOrder : Request {  //Response
    
    let newOrder : [String]
    init(adds : [String], authCredential: AuthCredential?) {
        self.newOrder = adds
        self.auth = authCredential
    }
    
    //custom auth credentical
    let auth: AuthCredential?
    var authCredential : AuthCredential? {
        get {
            return self.auth
        }
    }
    
    var path: String {
        return AddressesAPI.path + "/order"
    }
    
    var parameters: [String : Any]? {
        let out : [String : Any] = ["AddressIDs" : self.newOrder]
        return out
    }
    
    var method: HTTPMethod {
        return .put
    }
}


//MARK : update display name

final class UpdateAddressRequest : Request { //Response
    let addressid : String
    let displayName : String
    let signature : String
    init(id : String, displayName: String, signature: String, authCredential: AuthCredential?) {
        self.addressid = id
        self.displayName = displayName
        self.signature = signature;
        self.auth = authCredential
    }
    
    //custom auth credentical
    let auth: AuthCredential?
    var authCredential : AuthCredential? {
        get {
            return self.auth
        }
    }
    
    var path: String {
        return AddressesAPI.path + "/" + addressid
    }
    
    var parameters: [String : Any]? {
        let out : [String : Any] = ["DisplayName" : displayName,
                                    "Signature":signature]
        return out
    }
    
    var method: HTTPMethod {
        return .put
    }
}


//Mark setup address when signup after create the user
//Setup new non-subuser address [POST /addresses/setup]

final class SetupAddressRequest : Request { //AddressesResponse
    let domain: String
    init(domain_name: String, auth: AuthCredential?) {
        self.domain = domain_name
        self.auth = auth
    }
    
    var parameters: [String : Any]? {
        let out : [String : Any] = ["Domain": self.domain]
        return out
    }
    var method: HTTPMethod {
        return .post
    }
    var path: String {
        return AddressesAPI.path + "/setup"
    }
    
    //custom auth credentical
    let auth: AuthCredential?
    var authCredential : AuthCredential? {
        get {
            return self.auth
        }
    }
}


