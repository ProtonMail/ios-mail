//
//  MessageDataService+Builder.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 4/12/18.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation
import PromiseKit
import AwaitKit



//////////
final class PreContact {
    let email : String
    let pubKey : String
    let sign : Bool
    let encrypt : Bool
    
    init(email: String, pubKey: String, sign : Bool, encrypt: Bool) {
        self.email = email
        self.pubKey = pubKey
        self.sign = sign
        self.encrypt = encrypt
    }
}

extension Array where Element == PreContact {
    
    func find(email: String) -> PreContact? {
        for c in self {
            if c.email == email {
                return c
            }
        }
        return nil
    }
}

final class PreAddress {
    let email : String!
    let recipintType : Int!
    let eo : Bool
    let pubKey : String?
    init(email : String, pubKey : String?, recipintType : Int, eo : Bool ) {
        self.email = email
        self.recipintType = recipintType
        self.eo = eo
        self.pubKey = pubKey
    }
}

final class PreAttachment {
    /// attachment id
    let ID : String!
    /// clear session key
    let Key : Data
    
    /// initial
    ///
    /// - Parameters:
    ///   - id: att id
    ///   - key: clear encrypted attachment session key
    public init(id: String, key: Data) {
        self.ID = id
        self.Key = key
    }
}




/// A sending message request builder
///
/// You can create new builder like:
/// ````
///     let builder = SendBuilder()
/// ````
class SendBuilder {
    var bodyDataPacket : Data!
    var bodySession : Data!
    var preAddresses : [PreAddress] = [PreAddress]()
    var preAttachments : [PreAttachment] = [PreAttachment]()
    var password: String!
    var hit : String?
    
    init() { }
    
    func update(bodyData data : Data, bodySession : Data) {
        self.bodyDataPacket = data
        self.bodySession = bodySession
    }
    
    func set(pwd password: String, hit: String?) {
        self.password = password
        self.hit = hit
    }
    
    func add(addr address : PreAddress) {
        preAddresses.append(address)
    }
    
    func add(att attachment : PreAttachment) {
        self.preAttachments.append(attachment)
    }
    
    var clearBody : ClearBodyPackage? {
        get {
            if self.contains(type: .cinln) ||  self.contains(type: .cmime) {
                return ClearBodyPackage(key: self.encodedSession)
            }
            return nil
        }
    }
    
    var clearAtts :  [ClearAttachmentPackage]? {
        get {
            if self.contains(type: .cinln) ||  self.contains(type: .cmime) {
                var atts = [ClearAttachmentPackage]()
                for it in self.preAttachments {
                    atts.append(ClearAttachmentPackage(attID: it.ID,
                                                       key: it.Key.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))))
                }
                return atts.count > 0 ? atts : nil
            }
            return nil
        }
    }
    
    
    private func build(type rt : Int, eo : Bool) -> SendType {
        switch (rt, eo) {
        case (1, _):
            return SendType.intl
        case (2, true):
            return SendType.eo
        case (2, false):
            return SendType.cinln
        case (_, _):
            //should not be here
            break
        }
        return SendType.intl
    }
    
    
    var builders : [PackageBuilder] {
        get {
            var out : [PackageBuilder] = [PackageBuilder]()
            for pre in preAddresses {
                switch self.build(type: pre.recipintType, eo: pre.eo) {
                case .intl:
                    out.append(AddressBuilder(type: .intl, addr: pre, session: self.bodySession, atts: self.preAttachments))
                case .eo:
                    out.append(EOAddressBuilder(type: .eo, addr: pre, session: self.bodySession, password: self.password, atts: self.preAttachments, hit: self.hit))
                case .cinln:
                    out.append(ClearAddressBuilder(type: .cinln, addr: pre))
                default:
                    break
                }
            }
            return out
        }
    }
    
    func contains(type : SendType) -> Bool {
        for pre in preAddresses {
            let buildType = self.build(type: pre.recipintType, eo: pre.eo)
            if buildType.contains(type) {
                return true
            }
        }
        return false
    }
    
    var promises : [Promise<AddressPackageBase>] {
        get {
            var out : [Promise<AddressPackageBase>] = [Promise<AddressPackageBase>]()
            for it in builders {
                out.append(it.build())
            }
            return out
        }
    }
    
    var encodedBody : String {
        get {
            return self.bodyDataPacket.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
        }
    }
    
    var encodedSession : String {
        get {
            return self.bodySession.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
        }
    }
    
    var outSideUser : Bool {
        get {
            for pre in preAddresses {
                if pre.recipintType == 2 {
                    return true
                }
            }
            return false
        }
    }
}




protocol IPackageBuilder {
    func build() -> Promise<AddressPackageBase>
}

class PackageBuilder : IPackageBuilder {
    let preAddress : PreAddress
    func build() -> Promise<AddressPackageBase> {
        fatalError("This method must be overridden")
    }
    
    let sendType : SendType!
    
    init(type : SendType, addr : PreAddress) {
        self.sendType = type
        self.preAddress = addr
    }
    
}

/// Encrypt outside address builder
class EOAddressBuilder : PackageBuilder {
    let password : String
    let hit : String?
    let session : Data
    
    /// prepared attachment list
    let preAttachments : [PreAttachment]
    
    init(type: SendType, addr: PreAddress, session: Data, password: String, atts : [PreAttachment], hit: String?) {
        self.session = session
        self.password = password
        self.preAttachments = atts
        self.hit = hit
        super.init(type: type, addr: addr)
    }
    
    override func build() -> Promise<AddressPackageBase> {
        return async {
            let encodedKeyPackage = try self.session.getSymmetricSessionKeyPackage(self.password)?.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0)) ?? ""
            //create outside encrypt packet
            let token = String.randomString(32) as String
            let based64Token = token.encodeBase64() as String
            let encryptedToken = try based64Token.encryptWithPassphrase(self.password)!
            
            
            //start build auth package
            let authModuls = try AuthModulusRequest().syncCall()
            guard let moduls_id = authModuls?.ModulusID else {
                throw UpdatePasswordError.invalidModulusID.error
            }
            guard let new_moduls = authModuls?.Modulus, let new_encodedModulus = try new_moduls.getSignature() else {
                throw UpdatePasswordError.invalidModulus.error
            }
            //generat new verifier
            let new_decodedModulus : Data = new_encodedModulus.decodeBase64()
            let new_lpwd_salt : Data = PMNOpenPgp.randomBits(80) //for the login password needs to set 80 bits
            guard let new_hashed_password = PasswordUtils.hashPasswordVersion4(self.password, salt: new_lpwd_salt, modulus: new_decodedModulus) else {
                throw UpdatePasswordError.cantHashPassword.error
            }
            guard let verifier = try generateVerifier(2048, modulus: new_decodedModulus, hashedPassword: new_hashed_password) else {
                throw UpdatePasswordError.cantGenerateVerifier.error
            }
            let authPacket = PasswordAuth(modulus_id: moduls_id,
                                          salt: new_lpwd_salt.encodeBase64(),
                                          verifer: verifier.encodeBase64())
            
            
            
            // encrypt keys use key
            var attPack : [AttachmentPackage] = []
            for att in self.preAttachments {
                //TODO::here need handle error
                let newKeyPack = try att.Key.getSymmetricSessionKeyPackage(self.password)?.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0)) ?? ""
                let attPacket = AttachmentPackage(attID: att.ID, attKey: newKeyPack)
                attPack.append(attPacket)
            }
            
            let eo = EOAddressPackage(token: based64Token,
                                      encToken: encryptedToken,
                                      auth: authPacket,
                                      pwdHit: self.hit,
                                      email: self.preAddress.email,
                                      bodyKeyPacket: encodedKeyPackage,
                                      attPackets: attPack,
                                      type : self.sendType)
            return eo
        }
    }
}

/// Address Builder for building the packages
class AddressBuilder : PackageBuilder {
    /// message body session key
    let session : Data
    
    /// prepared attachment list
    let preAttachments : [PreAttachment]
    
    /// Initial
    ///
    /// - Parameters:
    ///   - type: SendType sending message type for address
    ///   - addr: message send to
    ///   - session: message encrypted body session key
    ///   - atts: prepared attachments
    init(type: SendType, addr: PreAddress, session: Data, atts : [PreAttachment]) {
        self.session = session
        self.preAttachments = atts
        super.init(type: type, addr: addr)
    }
    
    override func build() -> Promise<AddressPackageBase> {
        return async {
            var attPackages = [AttachmentPackage]()
            for att in self.preAttachments {
                //TODO::here need hanlde the error
                let newKeyPack = try att.Key.getPublicSessionKeyPackage(self.preAddress.pubKey!)?.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0)) ?? ""
                let attPacket = AttachmentPackage(attID: att.ID, attKey: newKeyPack)
                attPackages.append(attPacket)
            }
            
            let newKeypacket = try self.session.getPublicSessionKeyPackage(self.preAddress.pubKey!)
            let newEncodedKey = newKeypacket?.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0)) ?? ""
            let addr = AddressPackage(email: self.preAddress.email, bodyKeyPacket: newEncodedKey, attPackets: attPackages)
            return addr
        }
    }
}

class ClearAddressBuilder : PackageBuilder {
    override func build() -> Promise<AddressPackageBase> {
        return async {
            let eo = AddressPackageBase(email: self.preAddress.email, type: self.sendType, sign: 0)
            return eo
        }
    }
}
