//
//  MessageDataService+Builder.swift
//  ProtonMail - Created on 4/12/18.
//
//
//  The MIT License
//
//  Copyright (c) 2018 Proton Technologies AG
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.


import Foundation
import PromiseKit
import AwaitKit
import Crypto

extension Data {
    var html2AttributedString: NSAttributedString? {
        do {
            return try NSAttributedString(data: self, options: [.documentType: NSAttributedString.DocumentType.html, .characterEncoding: String.Encoding.utf8.rawValue], documentAttributes: nil)
        } catch {
            PMLog.D("error:\(error)" )
            return  nil
        }
    }
    var html2String: String {
        return html2AttributedString?.string ?? ""
    }
}

extension String {
    var html2AttributedString: NSAttributedString? {
        return Data(utf8).html2AttributedString
    }
    var html2String: String {
        return html2AttributedString?.string ?? ""
    }
}

//////////
final class PreContact {
    let email : String
    let firstPgpKey : Data?
    let pgpKeys : Data?
    let sign : Bool
    let encrypt : Bool
    let mime : Bool
    let plainText : Bool
    
    init(email: String, pubKey: Data?, pubKeys: Data?, sign : Bool, encrypt: Bool, mime : Bool, plainText : Bool) {
        self.email = email
        self.firstPgpKey = pubKey
        self.pgpKeys = pubKeys
        self.sign = sign
        self.encrypt = encrypt
        self.mime = mime
        self.plainText = plainText
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
    let pgpKey : Data?
    let mime : Bool
    let sign : Bool
    let pgpencrypt : Bool
    let plainText : Bool
    init(email : String, pubKey : String?, pgpKey : Data?, recipintType : Int, eo : Bool, mime : Bool, sign : Bool, pgpencrypt : Bool, plainText : Bool) {
        self.email = email
        self.recipintType = recipintType
        self.eo = eo
        self.pubKey = pubKey
        self.pgpKey = pgpKey
        self.mime = mime
        self.sign = sign
        self.pgpencrypt = pgpencrypt
        self.plainText = plainText
    }
}

final class PreAttachment {
    /// attachment id
    let ID : String
    /// clear session key
    let Session : Data
    let Algo : String
    
    
    let att : Attachment
    
    /// initial
    ///
    /// - Parameters:
    ///   - id: att id
    ///   - key: clear encrypted attachment session key
    public init(id: String, session: Data, algo: String, att: Attachment) {
        self.ID = id
        self.Session = session
        self.Algo = algo
        self.att = att
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
    var bodySessionAlgo : String!
    
    var preAddresses : [PreAddress] = [PreAddress]()
    var preAttachments : [PreAttachment] = [PreAttachment]()
    var password: String!
    var hit : String?
    
    var mimeSession : Data!
    var mimeSessionAlgo : String!
    var mimeDataPackage : String!
    
    var clearBody : String!
    
    var plainTextSession : Data!
    var plainTextSessionAlgo : String!
    var plainTextDataPackage : String!
    
    var clearPlainTextBody : String!
    
    init() { }
    
    func update(bodyData data : Data, bodySession : Data, algo : String) {
        self.bodyDataPacket = data
        self.bodySession = bodySession
        self.bodySessionAlgo = algo
    }
    
    func set(pwd password: String, hit: String?) {
        self.password = password
        self.hit = hit
    }
    
    func set(clear clearBody : String) {
        self.clearBody = clearBody
    }
    
    func add(addr address : PreAddress) {
        preAddresses.append(address)
    }
    
    func add(att attachment : PreAttachment) {
        self.preAttachments.append(attachment)
    }
    
    var clearBodyPackage : ClearBodyPackage? {
        get {
            if self.contains(type: .cinln) ||  self.contains(type: .cmime) {
                return ClearBodyPackage(key: self.encodedSession, algo: self.bodySessionAlgo)
            }
            return nil
        }
    }
    
    var clearMimeBodyPackage : ClearBodyPackage? {
        get {
            if self.contains(type: .cmime) {
                return ClearBodyPackage(key: self.mimeSession.encodeBase64(), algo: self.mimeSessionAlgo)
            }
            return nil
        }
    }
    
    var clearPlainBodyPackage : ClearBodyPackage? {
        get {
            if hasPlainText && ( self.contains(type: .cinln) ||  self.contains(type: .cmime) ) {
                return ClearBodyPackage(key: self.plainTextSession.encodeBase64(), algo: self.plainTextSessionAlgo)
            }
            return nil
        }
    }
    
    var mimeBody : String {
        get {
            if self.hasMime {
               return mimeDataPackage
            }
            return ""
        }
    }
    
    var plainBody : String {
        get {
            if self.hasPlainText {
                return plainTextDataPackage
            }
            return ""
        }
    }
    
    var clearAtts :  [ClearAttachmentPackage]? {
        get {
            if self.contains(type: .cinln) ||  self.contains(type: .cmime) {
                var atts = [ClearAttachmentPackage]()
                for it in self.preAttachments {
                    atts.append(ClearAttachmentPackage(attID: it.ID,
                                                       encodedSession: it.Session.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0)),
                                                       algo: it.Algo))
                }
                return atts.count > 0 ? atts : nil
            }
            return nil
        }
    }
    
    
    private func build(type rt : Int, eo : Bool, pgpkey: Bool, pgpencrypt : Bool, mime: Bool, sign: Bool) -> SendType {
        if rt == 1 {
            return .intl
        }

        //pgp mime
        if rt == 2 && mime && pgpkey && pgpencrypt {
            return .pgpmime
        }

        
        // sign only and set eo pwd
        if rt == 2 && !pgpencrypt && eo {
            return .eo
        }
        
        //pgp mime clear
        if rt == 2 && mime {
            return .cmime
        }

        if rt == 2 && pgpkey && pgpencrypt {
            return .inlnpgp
        }
        
        // seems this check is useless 
        if rt == 2 && eo {
            return .eo
        }
        
        return .cinln
    }
    
    func buildMime(pubKey: String, privKey : String, passphrase: String, privKeys: Data) -> Promise<SendBuilder> {
        return Promise { seal in
            async {
                /// decrypt attachments
                var messageBody = self.clearBody ?? ""
                messageBody = QuotedPrintable.encode(string: messageBody)
                var signbody = ""
                let boundaryMsg : String = "uF5XZWCLa1E8CXCUr2Kg8CSEyuEhhw9WU222" //TODO::this need to change
                let typeMessage = "Content-Type: multipart/mixed; boundary=\"\(boundaryMsg)\""
                signbody.append(contentsOf: typeMessage + "\r\n")
                signbody.append(contentsOf: "\r\n")
                signbody.append(contentsOf: "--\(boundaryMsg)" + "\r\n")
                signbody.append(contentsOf: "Content-Type: text/html; charset=utf-8" + "\r\n")
                signbody.append(contentsOf: "Content-Transfer-Encoding: quoted-printable" + "\r\n")
                signbody.append(contentsOf: "Content-Language: en-US" + "\r\n")
                signbody.append(contentsOf: "\r\n")
                signbody.append(contentsOf: messageBody +  "\r\n")
                signbody.append(contentsOf: "\r\n")
                signbody.append(contentsOf: "\r\n")
                signbody.append(contentsOf: "\r\n")
                
                var fetchs : [Promise<String>] = [Promise<String>]()
                for att in self.preAttachments {
                    fetchs.append(att.att.fetchAttachmentBody())
                }
                //1. fetch attachment first
                firstly {
                    when(resolved: fetchs)
                }.done { (bodys)  in
                    for (index, body) in bodys.enumerated() {
                        switch body {
                        case .fulfilled(let value):
                            let att = self.preAttachments[index].att
                            signbody.append(contentsOf: "--\(boundaryMsg)" + "\r\n")
                            signbody.append(contentsOf: "Content-Type: \(att.mimeType); name=\"\(att.fileName)\"" + "\r\n")
                            signbody.append(contentsOf: "Content-Transfer-Encoding: base64" + "\r\n")
                            signbody.append(contentsOf: "Content-Disposition: attachment; filename=\"\(att.fileName)\"" + "\r\n")
                            signbody.append(contentsOf: "\r\n")
                            signbody.append(contentsOf: value + "\r\n")
                        case .rejected(let error):
                            PMLog.D(error.localizedDescription)
                            break
                        }
                        
                    }
                        
                    signbody.append(contentsOf: "--\(boundaryMsg)--")
                    
                    //PMLog.D(signbody)

                    let encrypted = try signbody.encrypt(withPubKey: pubKey,
                                                         privateKey: privKey,
                                                         mailbox_pwd: passphrase)
                    let spilted = try encrypted?.split()
                    let session = try spilted?.keyPacket().getSessionFromPubKeyPackage(passphrase, privKeys: privKeys)!
                    
                    self.mimeSession = session?.session()
                    self.mimeSessionAlgo = session?.algo()
                    self.mimeDataPackage = spilted?.dataPacket().base64EncodedString()
                    
                    seal.fulfill(self)
                }.catch({ error in
                    seal.reject(error)
                })
            }
        }
    }
    
    
    func buildPlainText(pubKey: String, privKey : String, passphrase: String, privKeys: Data) -> Promise<SendBuilder> {
        return Promise { seal in
            async {
                let messageBody = self.clearBody ?? ""
                //TODO:: need improve replace part
                let plainText = messageBody.html2String.preg_replace("\n", replaceto: "\r\n")
                
                PMLog.D(plainText)
                
                let encrypted = try plainText.encrypt(withPubKey: pubKey,
                                                       privateKey: privKey,
                                                       mailbox_pwd: passphrase)
                let spilted = try encrypted?.split()
                let session = try spilted?.keyPacket().getSessionFromPubKeyPackage(passphrase, privKeys: privKeys)!
                
                self.plainTextSession = session?.session()
                self.plainTextSessionAlgo = session?.algo()
                self.plainTextDataPackage = spilted?.dataPacket().base64EncodedString()
                
                self.clearPlainTextBody = plainText
                
                seal.fulfill(self)
            }
        }
    }
    
    var builders : [PackageBuilder] {
        get {
            var out : [PackageBuilder] = [PackageBuilder]()
            for pre in preAddresses {
                
                var session = self.bodySession == nil ? Data() : self.bodySession!
                var algo = self.bodySessionAlgo == nil ? "aes256" : self.bodySessionAlgo!
                if pre.plainText {
                    session = self.plainTextSession
                    algo = self.plainTextSessionAlgo
                }
                switch self.build(type: pre.recipintType, eo: pre.eo, pgpkey: pre.pgpKey != nil, pgpencrypt: pre.pgpencrypt, mime: pre.mime, sign: pre.sign) {
                case .intl:
                    out.append(AddressBuilder(type: .intl, addr: pre, session: session, algo: algo, atts: self.preAttachments))
                case .eo:
                    out.append(EOAddressBuilder(type: .eo, addr: pre,
                                                session: session,
                                                algo: algo,
                                                password: self.password,
                                                atts: self.preAttachments, hit: self.hit))
                case .cinln:
                    out.append(ClearAddressBuilder(type: .cinln, addr: pre))
                case .inlnpgp:
                    out.append(PGPAddressBuilder(type: .inlnpgp, addr: pre,
                                                 session: session,
                                                 algo: algo,
                                                 atts: self.preAttachments))
                case .pgpmime: //pgp mime
                    out.append(MimeAddressBuilder(type: .pgpmime, addr: pre,
                                                  session: self.mimeSession,
                                                  algo: self.mimeSessionAlgo))
                case .cmime: //clear text mime
                    out.append(ClearMimeAddressBuilder(type: .cmime, addr: pre))
                default:
                    break
                }
            }
            return out
        }
    }
    
    var hasMime : Bool {
        get {
            return self.contains(type: .pgpmime) ||  self.contains(type: .cmime)
        }
    }
    
    var hasPlainText : Bool {
        get {
            for pre in preAddresses {
                if pre.plainText {
                    return true
                }
            }
            return false
        }
    }
    
    func contains(type : SendType) -> Bool {
        for pre in preAddresses {
            let buildType = self.build(type: pre.recipintType, eo: pre.eo,
                                       pgpkey: pre.pgpKey != nil, pgpencrypt: pre.pgpencrypt, mime: pre.mime, sign: pre.sign)
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
    let algo : String
    
    /// prepared attachment list
    let preAttachments : [PreAttachment]
    
    init(type: SendType, addr: PreAddress, session: Data, algo: String, password: String, atts : [PreAttachment], hit: String?) {
        self.session = session
        self.algo = algo
        self.password = password
        self.preAttachments = atts
        self.hit = hit
        super.init(type: type, addr: addr)
    }
    
    override func build() -> Promise<AddressPackageBase> {
        return async {
            let encodedKeyPackage = try self.session.getSymmetricPacket(withPwd: self.password, algo: self.algo)?.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0)) ?? ""
            //create outside encrypt packet
            let token = String.randomString(32) as String
            let based64Token = token.encodeBase64() as String
            let encryptedToken = try based64Token.encrypt(withPwd: self.password) ?? ""
            
            
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
                let newKeyPack = try att.Session.getSymmetricPacket(withPwd: self.password, algo: att.Algo)?.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0)) ?? ""
                let attPacket = AttachmentPackage(attID: att.ID, attKey: newKeyPack)
                attPack.append(attPacket)
            }
            
            let eo = EOAddressPackage(token: based64Token,
                                      encToken: encryptedToken,
                                      auth: authPacket,
                                      pwdHit: self.hit,
                                      email: self.preAddress.email,
                                      bodyKeyPacket: encodedKeyPackage,
                                      plainText : self.preAddress.plainText,
                                      attPackets: attPack,
                                      type : self.sendType)
            return eo
        }
    }
}


/// Address Builder for building the packages
class PGPAddressBuilder : PackageBuilder {
    /// message body session key
    let session : Data
    let algo : String
    
    /// prepared attachment list
    let preAttachments : [PreAttachment]
    
    /// Initial
    ///
    /// - Parameters:
    ///   - type: SendType sending message type for address
    ///   - addr: message send to
    ///   - session: message encrypted body session key
    ///   - atts: prepared attachments
    init(type: SendType, addr: PreAddress, session: Data, algo: String, atts : [PreAttachment]) {
        self.session = session
        self.algo = algo
        self.preAttachments = atts
        super.init(type: type, addr: addr)
    }
    
    override func build() -> Promise<AddressPackageBase> {
        return async {
            var attPackages = [AttachmentPackage]()
            for att in self.preAttachments {
                //TODO::here need hanlde the error
                let newKeyPack = try att.Session.getKeyPackage(dataKey: self.preAddress.pgpKey!, algo: att.Algo)?.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0)) ?? ""
                let attPacket = AttachmentPackage(attID: att.ID, attKey: newKeyPack)
                attPackages.append(attPacket)
            }
            
            //if plainText
            let newKeypacket = try self.session.getKeyPackage(dataKey: self.preAddress.pgpKey!, algo: self.algo)
            let newEncodedKey = newKeypacket?.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0)) ?? ""
            let addr = AddressPackage(email: self.preAddress.email, bodyKeyPacket: newEncodedKey, type: self.sendType, plainText: self.preAddress.plainText, attPackets: attPackages)
            return addr
        }
    }
}


/// Address Builder for building the packages
class MimeAddressBuilder : PackageBuilder {
    /// message body session key
    let session : Data
    let algo : String
    /// Initial
    ///
    /// - Parameters:
    ///   - type: SendType sending message type for address
    ///   - addr: message send to
    ///   - session: message encrypted body session key
    init(type: SendType, addr: PreAddress, session: Data, algo : String) {
        self.session = session
        self.algo = algo
        super.init(type: type, addr: addr)
    }
    
    override func build() -> Promise<AddressPackageBase> {
        return async {
            let newKeypacket = try self.session.getKeyPackage(dataKey: self.preAddress.pgpKey!, algo: self.algo)
            let newEncodedKey = newKeypacket?.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0)) ?? ""
            
            let addr = MimeAddressPackage(email: self.preAddress.email, bodyKeyPacket: newEncodedKey, type: self.sendType, plainText: self.preAddress.plainText)
            return addr
        }
    }
}


/// Address Builder for building the packages
class ClearMimeAddressBuilder : PackageBuilder {
    
    /// Initial
    ///
    /// - Parameters:
    ///   - type: SendType sending message type for address
    ///   - addr: message send to
    override init(type: SendType, addr: PreAddress) {
        super.init(type: type, addr: addr)
    }
    
    override func build() -> Promise<AddressPackageBase> {
        return async {
            let addr = AddressPackageBase(email: self.preAddress.email, type: self.sendType, sign : 1, plainText: self.preAddress.plainText)
            return addr
        }
    }
}

/// Address Builder for building the packages
class AddressBuilder : PackageBuilder {
    /// message body session key
    let session : Data
    let algo : String
    
    /// prepared attachment list
    let preAttachments : [PreAttachment]
    
    /// Initial
    ///
    /// - Parameters:
    ///   - type: SendType sending message type for address
    ///   - addr: message send to
    ///   - session: message encrypted body session key
    ///   - atts: prepared attachments
    init(type: SendType, addr: PreAddress, session: Data, algo: String, atts : [PreAttachment]) {
        self.session = session
        self.algo = algo
        self.preAttachments = atts
        super.init(type: type, addr: addr)
    }
    
    override func build() -> Promise<AddressPackageBase> {
        return async {
            var attPackages = [AttachmentPackage]()
            for att in self.preAttachments {
                //TODO::here need hanlde the error
                if let pubK = self.preAddress.pubKey {
                    let newKeyPack = try att.Session.getKeyPackage(strKey: pubK, algo: att.Algo)?.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0)) ?? ""
                    let attPacket = AttachmentPackage(attID: att.ID, attKey: newKeyPack)
                    attPackages.append(attPacket)
                }
            }
            
            //TODO::will remove from here debuging or merge this class with PGPAddressBuildr
            if let pk = self.preAddress.pgpKey {
                let newKeypacket = try self.session.getKeyPackage(dataKey: pk, algo: self.algo)
                let newEncodedKey = newKeypacket?.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0)) ?? ""
                let addr = AddressPackage(email: self.preAddress.email, bodyKeyPacket: newEncodedKey, type: self.sendType, plainText: self.preAddress.plainText, attPackets: attPackages)
                return addr
            } else {
                //TODO::here need hanlde the error
                let newKeypacket = try self.session.getKeyPackage(strKey: self.preAddress.pubKey ?? "", algo: self.algo)
                let newEncodedKey = newKeypacket?.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0)) ?? ""
                let addr = AddressPackage(email: self.preAddress.email, bodyKeyPacket: newEncodedKey, type: self.sendType, plainText: self.preAddress.plainText, attPackets: attPackages)
                return addr
            }
        }
    }
}

class ClearAddressBuilder : PackageBuilder {
    override func build() -> Promise<AddressPackageBase> {
        return async {
            let eo = AddressPackageBase(email: self.preAddress.email, type: self.sendType, sign: self.preAddress.sign ? 1 : 0, plainText: self.preAddress.plainText)
            return eo
        }
    }
}
