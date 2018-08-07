//
//  MessageAPI+Packages.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 4/12/18.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation


// message attachment key package
final class AttachmentPackage {
    let ID : String!
    let encodedKeyPacket : String!
    init(attID:String!, attKey:String!) {
        self.ID = attID
        self.encodedKeyPacket = attKey
    }
}

// message attachment key package for clear text
final class ClearAttachmentPackage {
    /// attachment id
    let ID : String
    /// based64 encoded session key
    let encodedSession : String
    let algo : String //default is "aes256"
    init(attID: String, encodedSession: String, algo: String) {
        self.ID = attID
        self.encodedSession = encodedSession
        self.algo = algo
    }
}

// message attachment key package for clear text
final class ClearBodyPackage {
    /// based64 encoded session key
    let key : String
    let algo : String // default is "aes256"
    init(key : String, algo: String) {
        self.key = key
        self.algo = algo
    }
}

/// message packages
final class EOAddressPackage : AddressPackage {
    
    let token : String!  //<random_token>
    let encToken : String! //<encrypted_random_token>
    let auth : PasswordAuth! //
    let pwdHit : String?  //"PasswordHint" : "Example hint", // optional
    
    init(token: String, encToken : String,
         auth : PasswordAuth, pwdHit : String?,
         email:String,
         bodyKeyPacket : String,
         plainText : Bool,
         attPackets:[AttachmentPackage]=[AttachmentPackage](),
         type: SendType = SendType.intl, //for base
        sign : Int = 0) {
        
        self.token = token
        self.encToken = encToken
        self.auth = auth
        self.pwdHit = pwdHit
        
        super.init(email: email, bodyKeyPacket: bodyKeyPacket, type: type, plainText: plainText, attPackets: attPackets, sign: sign)
    }
    
    override func toDictionary() -> [String : Any]? {
        var out = super.toDictionary() ?? [String : Any]()
        out["Token"] = self.token
        out["EncToken"] = self.encToken
        out["Auth"] = self.auth.toDictionary()
        if let hit = self.pwdHit {
            out["PasswordHint"] = hit
        }
        return out
    }
}

class AddressPackage : AddressPackageBase {
    let bodyKeyPacket : String
    let attPackets : [AttachmentPackage]
    
    init(email:String,
         bodyKeyPacket : String,
         type: SendType,
         plainText : Bool,
         attPackets:[AttachmentPackage]=[AttachmentPackage](),
        sign : Int = 0) {
        self.bodyKeyPacket = bodyKeyPacket
        self.attPackets = attPackets
        super.init(email: email, type: type, sign: sign, plainText: plainText)
    }
    
    override func toDictionary() -> [String : Any]? {
        var out = super.toDictionary() ?? [String : Any]()
        out["BodyKeyPacket"] = self.bodyKeyPacket
        //change to == id : packet
        if attPackets.count > 0 {
            var atts : [String:Any] = [String:Any]()
            for attPacket in attPackets {
                atts[attPacket.ID] = attPacket.encodedKeyPacket
            }
            out["AttachmentKeyPackets"] = atts
        }
        
        return out
    }
}

class MimeAddressPackage : AddressPackageBase {
    let bodyKeyPacket : String
    init(email:String,
         bodyKeyPacket : String,
         type: SendType,
         plainText : Bool) {
        self.bodyKeyPacket = bodyKeyPacket
        super.init(email: email, type: type, sign: -1, plainText: plainText)
    }
    
    override func toDictionary() -> [String : Any]? {
        var out = super.toDictionary() ?? [String : Any]()
        out["BodyKeyPacket"] = self.bodyKeyPacket        
        return out
    }
}


class AddressPackageBase : Package {
    
    let type : SendType!
    let sign : Int! //0 or 1
    let email : String
    let plainText : Bool
    
    init(email: String, type: SendType, sign : Int, plainText : Bool) {
        self.type = type
        self.sign = sign
        self.email = email
        self.plainText = plainText
    }
    
    func toDictionary() -> [String : Any]? {
        var out : [String: Any] = [
            "Type" : type.rawValue
        ]
        if sign > -1 {
            out["Signature"] = sign
        }
        return out
    }
}
