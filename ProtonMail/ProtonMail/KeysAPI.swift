//
//  KeysAPI.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 11/11/16.
//  Copyright © 2016 ProtonMail. All rights reserved.
//

import Foundation


//MARK : update display name
public class UpdatePrivateKeyRequest<T : ApiResponse> : ApiRequest<T> {
    
    let clientEphemeral : String! //base64 encoded
    let clientProof : String! //base64 encoded
    let SRPSession : String! //hex encoded session id
    let tfaCode : String? // optional
    let keySalt : String! //base64 encoded need random value
    var userKeys: Array<Key>!
    
    let orgKey : Key?
    
    let isSinglePasswordMode : Bool
    let AuthVersion : Int = 4
    let ModulusID : String? //encrypted id
    let salt : String? //base64 encoded
    let verifer : String? //base64 encoded
    
    init(clientEphemeral: String!,
         clientProof: String!,
         SRPSession: String!,
         keySalt: String!,
         userKeys: Array<Key>!,
         singlePwdMode : Bool,
         
         orgKey: Key?,
         tfaCode: String?,
         ModulusID : String?,
         salt : String?,
         verifer : String?
         ) {
        self.clientEphemeral = clientEphemeral
        self.clientProof = clientProof
        self.SRPSession = SRPSession
        self.keySalt = keySalt
        self.userKeys = userKeys
        self.isSinglePasswordMode = singlePwdMode
        
        //optional values
        self.orgKey = orgKey
        self.tfaCode = tfaCode
        self.ModulusID = ModulusID
        self.salt = salt
        self.verifer = verifer
    }
    
    override func toDictionary() -> Dictionary<String, AnyObject>? {
        
        var keysDict : [AnyObject] = [AnyObject]()
        for _key in userKeys {
            keysDict.append( ["ID": _key.key_id, "PrivateKey" : _key.private_key] )
        }
        
        var out : [String : AnyObject] = [
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
        
        if isSinglePasswordMode {
            if let modulus_id = self.ModulusID, let salt_check = self.salt, let verifer_check = self.verifer {
                out["Auth"] = [
                    "Version" : 4,
                    "ModulusID" : modulus_id,
                    "Salt" : salt_check,
                    "Verifer" : verifer_check
                ]
            }
        }
        
        return out
    }
    
    override func getAPIMethod() -> APIService.HTTPMethod {
        return .PUT
    }
    
    override public func getRequestPath() -> String {
        return KeysAPI.Path + "/private" + AppConstants.getDebugOption
    }
    
    override public func getVersion() -> Int {
        return KeysAPI.V_UpdatePrivateKeyRequest
    }
}
