//
//  KeysAPI.swift
//  ProtonMail - Created on 11/11/16.
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
import PromiseKit
import Crypto
import PMCommon


//Keys API
//Doc: https://github.com/ProtonMail/Slim-API/blob/develop/api-spec/pm_api_keys.md
struct KeysAPI {
    static let path : String = "/keys"
    
    /// Update private keys only, use for mailbox password/single password updates PUT
    static let v_update_private_key : Int = 3
    
    /// Setup keys for new account, private user [POST]
    static let v_setup_key : Int = 3
    
    /// Get key salts, locked route [GET]
    static let v_get_key_salts : Int = 3
    
    /// Get public keys [GET]
    static let v_get_emails_pub_key : Int = 3
    
    /// Activate newly-provisioned member key [PUT]
    static let v_activate_key : Int = 3
}


///KeysResponse
final class UserEmailPubKeys : Request {
    let email : String
    init(email: String, authCredential: AuthCredential? = nil) {
        self.email = email
        self.auth = authCredential
    }
    var parameters: [String : Any]? {
        let out : [String : Any] = ["Email" : self.email]
        return out
    }
    var path: String {
        return KeysAPI.path
    }
    
    //custom auth credentical
    let auth: AuthCredential?
    var authCredential : AuthCredential? {
        get {
            return self.auth
        }
    }
}

extension Array where Element : UserEmailPubKeys {
    func getPromises(api: APIService) -> [Promise<KeysResponse>] {
        var out : [Promise<KeysResponse>] = [Promise<KeysResponse>]()
        for it in self {
            out.append(api.run(route: it))
        }
        return out
    }
}


final class KeyResponse {
    //TODO:: change to bitmap later
    var flags : Int = 0 // bitmap: 1 = can be used to verify, 2 = can be used to encrypt
    var publicKey : String?
   
    init(flags : Int, pubkey: String?) {
        self.flags = flags
        self.publicKey = pubkey
    }
}

final class KeysResponse : Response {
    var recipientType : Int = 1 // 1 internal 2 external
    var mimeType : String?
    var keys : [KeyResponse] = [KeyResponse]()
    override func ParseResponse(_ response: [String : Any]!) -> Bool {
        self.recipientType = response["RecipientType"] as? Int ?? 1
        self.mimeType = response["MIMEType"] as? String
        
        if let keyRes = response["Keys"] as? [[String : Any]] {
            for keyDict in keyRes {
                let flags =  keyDict["Flags"] as? Int ?? 0
                let pubKey = keyDict["PublicKey"] as? String
                self.keys.append(KeyResponse(flags: flags, pubkey: pubKey))
            }
        }
        return true
    }
    
    func firstKey () -> String? {
        for k in keys {
            if k.flags == 2 ||  k.flags == 3 {
                return k.publicKey
            }
        }
        return nil
    }
    
    //TODO:: change to filter later.
    func getCompromisedKeys() -> Data?  {
        var pubKeys : Data? = nil
        for k in keys {
            if k.flags == 0 {
                if pubKeys == nil {
                    pubKeys = Data()
                }
                if let p = k.publicKey {
                    var error : NSError?
                    if let data = ArmorUnarmor(p, &error) {
                        if error == nil && data.count > 0 {
                            pubKeys?.append(data)
                        }
                    }
                }
            }
        }
        return pubKeys
    }
    
    func getVerifyKeys() -> Data? {
        var pubKeys : Data? = nil
        for k in keys {
            if k.flags == 1 || k.flags == 3 {
                if pubKeys == nil {
                    pubKeys = Data()
                }
                if let p = k.publicKey {
                    var error : NSError?
                    if let data = ArmorUnarmor(p, &error) {
                        if error == nil && data.count > 0 {
                            pubKeys?.append(data)
                        }
                    }
                }
            }
        }
        return pubKeys
    }
}

///KeySaltResponse
final class GetKeysSalts : Request {
    init(authCredential: AuthCredential? = nil) {
        self.auth = authCredential
    }
    var path: String {
        return KeysAPI.path + "/salts"
    }
    
    //custom auth credentical
    var auth: AuthCredential?
    var authCredential : AuthCredential? {
        get {
            return self.auth
        }
    }
}

final class KeySaltResponse : Response {
    var keySalt : String?
    var keyID : String?
    override func ParseResponse(_ response: [String : Any]!) -> Bool {
        if let keySalts = response["KeySalts"] as? [[String : Any]], let firstKeySalt = keySalts.first {
            self.keySalt = firstKeySalt["KeySalt"] as? String
            self.keyID = firstKeySalt["ID"] as? String
        }
        return true
    }
}

/// message packages
final class PasswordAuth : Package {

    let AuthVersion : Int = 4
    let ModulusID : String //encrypted id
    let salt : String //base64 encoded
    let verifer : String //base64 encoded
    
    init(modulus_id : String, salt :String, verifer : String) {
        self.ModulusID = modulus_id
        self.salt = salt
        self.verifer = verifer
    }
    
    var parameters: [String : Any]? {
        let out : [String : Any] = [
            "Version" : self.AuthVersion,
            "ModulusID" : self.ModulusID,
            "Salt" : self.salt,
            "Verifier" : self.verifer
        ]
        return out
    }
}


//MARK : update user's private keys -- Response
final class UpdatePrivateKeyRequest : Request {
    
    let clientEphemeral : String //base64 encoded
    let clientProof : String //base64 encoded
    let SRPSession : String //hex encoded session id
    let tfaCode : String? // optional
    let keySalt : String //base64 encoded need random value
    
    var userLevelKeys: [Key]
    var userAddressKeys: [Key]
    let orgKey : String?
    
    let auth : PasswordAuth?

    
    init(clientEphemeral: String,
         clientProof: String,
         SRPSession: String,
         keySalt: String,
         userlevelKeys: [Key],
         addressKeys: [Key],
         tfaCode : String?,
         orgKey: String?,
         
         auth: PasswordAuth?,
         authCredential: AuthCredential?
         ) {
        self.clientEphemeral = clientEphemeral
        self.clientProof = clientProof
        self.SRPSession = SRPSession
        self.keySalt = keySalt
        self.userLevelKeys = userlevelKeys
        self.userAddressKeys = addressKeys
        
        //optional values
        self.orgKey = orgKey
        self.tfaCode = tfaCode
        self.auth = auth
        
        self.credential = authCredential
    }
    
    //custom auth credentical
    let credential: AuthCredential?
    var authCredential : AuthCredential? {
        get {
            return self.credential
        }
    }
    
    var parameters: [String : Any]? {
        var keysDict : [Any] = [Any]()
        for _key in userLevelKeys {
            if _key.is_updated {
                keysDict.append( ["ID": _key.key_id, "PrivateKey" : _key.private_key] )
            }
        }
        for _key in userAddressKeys {
            if _key.is_updated {
                keysDict.append( ["ID": _key.key_id, "PrivateKey" : _key.private_key] )
            }
        }
        
        var out : [String : Any] = [
            "ClientEphemeral" : self.clientEphemeral,
            "ClientProof" : self.clientProof,
            "SRPSession": self.SRPSession,
            "KeySalt" : self.keySalt,
            "Keys" : keysDict
            ]
        
        if let code = tfaCode {
            out["TwoFactorCode"] = code
        }
        if let org_key = orgKey {
             out["OrganizationKey"] = org_key
        }
        if let auth_obj = self.auth {
            out["Auth"] = auth_obj.parameters
        }
        return out
    }
    
    var method: HTTPMethod {
        return .put
    }
    
    var path: String {
        return KeysAPI.path + "/private"
    }
}


//MARK : update user's private keys -- Response
final class SetupKeyRequest : Request {

    let addressID : String
    let privateKey : String
    let signedKeyList: [String: Any]
    let keySalt : String //base64 encoded need random value
    let auth : PasswordAuth
    
    init(address_id: String,
         private_key : String,
         keysalt : String,
         signedKL : [String: Any],
         auth : PasswordAuth,
         authCredential: AuthCredential?) {
        self.keySalt = keysalt
        self.addressID = address_id
        self.privateKey = private_key
        self.signedKeyList = signedKL
        self.auth = auth
        self.credential = authCredential
    }
    
    //custom auth credentical
    let credential: AuthCredential?
    var authCredential : AuthCredential? {
        get {
            return self.credential
        }
    }
    
    var parameters: [String : Any]? {
        let address : [String: Any] = [
            "AddressID" : self.addressID,
            "PrivateKey" : self.privateKey,
            "SignedKeyList" : self.signedKeyList
        ]
        
        let out : [String : Any] = [
            "KeySalt" : self.keySalt,
            "PrimaryKey": self.privateKey,
            "AddressKeys" : [address] ,
            "Auth" : self.auth.parameters!
        ]

        PMLog.D(out.json(prettyPrinted: true))
        
        return out
    }
    
    var method: HTTPMethod {
        return .post
    }
    
    var path: String {
        return KeysAPI.path + "/setup"
    }
}




//MARK : active a key when Activation is not null --- Response
final class ActivateKey : Request {
    let addressID : String
    let privateKey : String
    let signedKeyList: [String: Any]
    
    init(addrID: String, privKey : String, signedKL : [String: Any]) {
        self.addressID = addrID
        self.privateKey = privKey
        self.signedKeyList = signedKL
    }
    
    var parameters: [String : Any]? {
        let out : [String: Any] = [
            "PrivateKey" : self.privateKey,
            "SignedKeyList" : self.signedKeyList
        ]
        PMLog.D(out.json(prettyPrinted: true))
        return out
    }
    
    var method: HTTPMethod {
        return .put
    }
    
    var path: String {
        return KeysAPI.path + "/" + addressID + "/activate"
    }
    
    //custom auth credentical
    var auth: AuthCredential?
    var authCredential : AuthCredential? {
        get {
            return self.auth
        }
    }
}



