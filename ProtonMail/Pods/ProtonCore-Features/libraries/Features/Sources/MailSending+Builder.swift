//
//  MessageDataService+Builder.swift
//  ProtonCore-Features - Created on 04.12.2018.
//
//  Copyright (c) 2022 Proton Technologies AG
//
//  This file is part of Proton Technologies AG and ProtonCore.
//
//  ProtonCore is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonCore is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore.  If not, see <https://www.gnu.org/licenses/>.

import Foundation
import ProtonCoreCrypto
import ProtonCoreCryptoGoInterface
import ProtonCoreDataModel
import ProtonCoreHash

extension Data {
    var html2AttributedString: NSAttributedString? {
        do {
            return try NSAttributedString(data: self, options: [.documentType: NSAttributedString.DocumentType.html, .characterEncoding: String.Encoding.utf8.rawValue], documentAttributes: nil)
        } catch {
            // PMLog.D("error:\(error)" )
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
public struct PreContact: Equatable {
    public let email: String
    public let firstPgpKey: Data?
    public let pgpKeys: [Data]
    public let isSigned: Bool
    public let isEncrypted: Bool
    public let hasMime: Bool
    public let isPlainText: Bool

    public init(
        email: String,
        pubKey: Data?,
        pubKeys: [Data],
        isSigned: Bool,
        isEncrypted: Bool,
        hasMime: Bool,
        isPlainText: Bool
    ) {
        self.email = email
        self.firstPgpKey = pubKey
        self.pgpKeys = pubKeys
        self.isSigned = isSigned
        self.isEncrypted = isEncrypted
        self.hasMime = hasMime
        self.isPlainText = isPlainText
    }
}

extension Array where Element == PreContact {

    func find(email: String) -> PreContact? {
        for c in self where c.email == email {
            return c
        }
        return nil
    }
}

final class PreAddress {
    let email: String!
    let recipintType: Int!
    let eo: Bool
    let pubKey: String?
    let pgpKey: Data?
    let hasMime: Bool
    let isSigned: Bool
    let isPgpEncrypted: Bool
    let isPlainText: Bool
    init(
        email: String,
        pubKey: String?,
        pgpKey: Data?,
        recipintType: Int,
        eo: Bool,
        hasMime: Bool,
        isSigned: Bool,
        isPgpEncrypted: Bool,
        isPlainText: Bool
    ) {
        self.email = email
        self.recipintType = recipintType
        self.eo = eo
        self.pubKey = pubKey
        self.pgpKey = pgpKey
        self.hasMime = hasMime
        self.isSigned = isSigned
        self.isPgpEncrypted = isPgpEncrypted
        self.isPlainText = isPlainText
    }
}

final class PreAttachment {
    /// attachment id
    let ID: String
    /// clear session key
    let Session: Data
    let Algo: String

    let att: AttachmentContent

    /// initial
    ///
    /// - Parameters:
    ///   - id: att id
    ///   - key: clear encrypted attachment session key
    public init(id: String, session: Data, algo: String, att: AttachmentContent) { // , att: Attachment
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
    var bodyDataPacket: Data!
    var bodySession: Data!
    var bodySessionAlgo: String!

    var preAddresses: [PreAddress] = [PreAddress]()
    var preAttachments: [PreAttachment] = [PreAttachment]()
    var password: String!
    var hit: String?

    var mimeSession: Data!
    var mimeSessionAlgo: String!
    var mimeDataPackage: String!

    var clearBody: String!

    var plainTextSession: Data!
    var plainTextSessionAlgo: String!
    var plainTextDataPackage: String!

    var clearPlainTextBody: String!

    init() { }

    func update(bodyData data: Data, bodySession: Data, algo: String) {
        self.bodyDataPacket = data
        self.bodySession = bodySession
        self.bodySessionAlgo = algo
    }

    func set(pwd password: String, hit: String?) {
        self.password = password
        self.hit = hit
    }

    func set(clear clearBody: String) {
        self.clearBody = clearBody
    }

    func add(addr address: PreAddress) {
        preAddresses.append(address)
    }

    func add(att attachment: PreAttachment) {
        self.preAttachments.append(attachment)
    }

    var clearBodyPackage: ClearBodyPackage? {
        if self.contains(type: .cinln) || self.contains(type: .cmime) {
            return ClearBodyPackage(key: self.encodedSession, algo: self.bodySessionAlgo)
        }
        return nil
    }

    var clearMimeBodyPackage: ClearBodyPackage? {
        if self.contains(type: .cmime) {
            return ClearBodyPackage(key: self.mimeSession.encodeBase64(), algo: self.mimeSessionAlgo)
        }
        return nil
    }

    var clearPlainBodyPackage: ClearBodyPackage? {
        if hasPlainText && (self.contains(type: .cinln) || self.contains(type: .cmime)) {
            return ClearBodyPackage(key: self.plainTextSession.encodeBase64(), algo: self.plainTextSessionAlgo)
        }
        return nil
    }

    var mimeBody: String {
        if self.hasMime {
           return mimeDataPackage
        }
        return ""
    }

    var plainBody: String {
        if self.hasPlainText {
            return plainTextDataPackage
        }
        return ""
    }

    var clearAtts: [ClearAttachmentPackage]? {
        if self.contains(type: .cinln) || self.contains(type: .cmime) {
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

    private func build(type rt: Int, eo: Bool, pgpkey: Bool, pgpencrypt: Bool, mime: Bool, sign: Bool) -> SendType {
        if rt == 1 {
            return .intl
        }

        // pgp mime
        if rt == 2 && mime && pgpkey && pgpencrypt {
            return .pgpmime
        }

        // sign only and set eo pwd
        if rt == 2 && !pgpencrypt && eo {
            return .eo
        }

        // pgp mime clear
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

    func buildMime(senderKey: Key, passphrase: String, userKeys: [Data], keys: [Key], newSchema: Bool) throws -> SendBuilder { // , userInfo: UserInfo
        /// decrypt attachments
        var messageBody = self.clearBody ?? ""
        messageBody = QuotedPrintable.encode(string: messageBody)
        var signbody = ""
        var boundaryMsg: String = "uF5XZWCLa1E8CXCUr2Kg8CSEyuEhhw9WU222" // default
        do {
            let random = try Crypto.random(byte: 20)
            if random.count > 0 {
                boundaryMsg = HMAC.hexStringFromData(random)
            }
        } catch {
            // ignore
        }

        let typeMessage = "Content-Type: multipart/related; boundary=\"\(boundaryMsg)\""
        signbody.append(contentsOf: typeMessage + "\r\n")
        signbody.append(contentsOf: "\r\n")
        signbody.append(contentsOf: "--\(boundaryMsg)" + "\r\n")
        signbody.append(contentsOf: "Content-Type: text/html; charset=utf-8" + "\r\n")
        signbody.append(contentsOf: "Content-Transfer-Encoding: quoted-printable" + "\r\n")
        signbody.append(contentsOf: "Content-Language: en-US" + "\r\n")
        signbody.append(contentsOf: "\r\n")
        signbody.append(contentsOf: messageBody + "\r\n")
        signbody.append(contentsOf: "\r\n")
        signbody.append(contentsOf: "\r\n")
        signbody.append(contentsOf: "\r\n")

        for attachment in self.preAttachments {
            let att = attachment.att
            signbody.append(contentsOf: "--\(boundaryMsg)" + "\r\n")
            let attName = QuotedPrintable.encode(string: att.fileName)
            signbody.append(contentsOf: "Content-Type: \(att.mimeType); name=\"\(attName)\"" + "\r\n")
            signbody.append(contentsOf: "Content-Transfer-Encoding: base64" + "\r\n")
            signbody.append(contentsOf: "Content-Disposition: attachment; filename=\"\(attName)\"" + "\r\n")
            var contentID: String = "1992861621357615" // default
            do {
                let random = try Crypto.random(byte: 16)
                if random.count > 0 {
                    contentID = HMAC.hexStringFromData(random)
                }
            } catch {
                // ignore
            }
            signbody.append(contentsOf: "Content-ID: <\(contentID)>\r\n")

            signbody.append(contentsOf: "\r\n")
            signbody.append(contentsOf: att.fileData + "\r\n")
        }
        signbody.append(contentsOf: "--\(boundaryMsg)--")
        let encrypted = try signbody.encrypt(withKey: senderKey,
                                             userKeys: userKeys,
                                             mailbox_pwd: passphrase)
        let spilted = try encrypted?.split()
        let session = newSchema ?
            try spilted?.keyPacket?.getSessionFromPubKeyPackageNonOptional(userKeys: userKeys, passphrase: passphrase, keys: keys) :
            try spilted?.keyPacket?.getSessionFromPubKeyPackageNonOptional(addrPrivKey: senderKey.privateKey, passphrase: passphrase)
        self.mimeSession = session?.key
        self.mimeSessionAlgo = session?.algo
        self.mimeDataPackage = spilted?.dataPacket?.base64EncodedString()

        return self
    }

    func buildPlainText(senderKey: Key, passphrase: String, userKeys: [Data], keys: [Key], newSchema: Bool) throws -> SendBuilder {
        // TODO:: fix all ?
        let messageBody = self.clearBody ?? ""
        let encrypted = try messageBody.encrypt(withKey: senderKey, userKeys: userKeys, mailbox_pwd: passphrase)
        let spilted = try encrypted?.split()
        let session = newSchema ?
            try spilted?.keyPacket?.getSessionFromPubKeyPackageNonOptional(userKeys: userKeys, passphrase: passphrase, keys: keys) :
            try spilted?.keyPacket?.getSessionFromPubKeyPackageNonOptional(addrPrivKey: senderKey.privateKey, passphrase: passphrase)

        self.plainTextSession = session?.key
        self.plainTextSessionAlgo = session?.algo
        self.plainTextDataPackage = spilted?.dataPacket?.base64EncodedString()

        self.clearPlainTextBody = messageBody

        return self
    }

    var builders: [PackageBuilder] {
        var out: [PackageBuilder] = [PackageBuilder]()
        for pre in preAddresses {

            var session = self.bodySession == nil ? Data() : self.bodySession!
            var algo = self.bodySessionAlgo == nil ? "aes256" : self.bodySessionAlgo!
            if pre.isPlainText {
                session = self.plainTextSession
                algo = self.plainTextSessionAlgo
            }
            switch self.build(type: pre.recipintType, eo: pre.eo, pgpkey: pre.pgpKey != nil, pgpencrypt: pre.isPgpEncrypted, mime: pre.hasMime, sign: pre.isSigned) {
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
            case .pgpmime: // pgp mime
                out.append(MimeAddressBuilder(type: .pgpmime, addr: pre,
                                              session: self.mimeSession,
                                              algo: self.mimeSessionAlgo))
            case .cmime: // clear text mime
                out.append(ClearMimeAddressBuilder(type: .cmime, addr: pre))
            default:
                break
            }
        }
        return out
    }

    var hasMime: Bool { self.contains(type: .pgpmime) || self.contains(type: .cmime) }

    var hasPlainText: Bool {
        for pre in preAddresses where pre.isPlainText {
            return true
        }
        return false
    }

    func contains(type: SendType) -> Bool {
        for pre in preAddresses {
            let buildType = self.build(type: pre.recipintType, eo: pre.eo,
                                       pgpkey: pre.pgpKey != nil, pgpencrypt: pre.isPgpEncrypted, mime: pre.hasMime, sign: pre.isSigned)
            if buildType.contains(type) {
                return true
            }
        }
        return false
    }

    func buildAddressPackages() -> [Result<AddressPackageBase, Error>] {

        assert(Thread.isMainThread == false, "This is a blocking call, should never be called from the main thread")

        let group = DispatchGroup()

        var results: [(UUID, Result<AddressPackageBase, Error>)] = []
        let requests = builders.map { (UUID(), $0) }
        let uuids = requests.map(\.0)
        requests.forEach { uuid, builder in
            group.enter()
            builder.build { (result: Result<AddressPackageBase, Error>) in
                results.append((uuid, result))
                group.leave()
            }
        }
        group.wait()

        return results.sorted { lhs, rhs in
            guard let lhIndex = uuids.firstIndex(of: lhs.0), let rhIndex = uuids.firstIndex(of: rhs.0) else {
                assertionFailure("Should never happen — the UUIDs associated with requests must not be changed")
                return true
            }
            return lhIndex < rhIndex
        }.map { $0.1 }
    }

    var encodedBody: String {
        bodyDataPacket.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
    }

    var encodedSession: String {
        bodySession.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
    }

    var outSideUser: Bool {
        for pre in preAddresses where pre.recipintType == 2 {
            return true
        }
        return false
    }
}

private let builderQueue = DispatchQueue(label: "ch.protonmail.ios.protoncore.features.builders", attributes: .concurrent)

protocol IPackageBuilder {
    func build(completion: @escaping (Result<AddressPackageBase, Error>) -> Void)
}

class PackageBuilder: IPackageBuilder {
    let preAddress: PreAddress
    func build(completion: @escaping (Result<AddressPackageBase, Error>) -> Void) {
        fatalError("This method must be overridden")
    }

    let sendType: SendType!

    init(type: SendType, addr: PreAddress) {
        self.sendType = type
        self.preAddress = addr
    }

}

/// Encrypt outside address builder
class EOAddressBuilder: PackageBuilder {
    let password: String
    let hit: String?
    let session: Data
    let algo: String

    /// prepared attachment list
    let preAttachments: [PreAttachment]

    init(type: SendType, addr: PreAddress, session: Data, algo: String, password: String, atts: [PreAttachment], hit: String?) {
        self.session = session
        self.algo = algo
        self.password = password
        self.preAttachments = atts
        self.hit = hit
        super.init(type: type, addr: addr)
    }

    override func build(completion: @escaping (Result<AddressPackageBase, Error>) -> Void) {
        fatalError("This method must be overridden")
    }
}

/// Address Builder for building the packages
class PGPAddressBuilder: PackageBuilder {
    /// message body session key
    let session: Data
    let algo: String

    /// prepared attachment list
    let preAttachments: [PreAttachment]

    /// Initial
    ///
    /// - Parameters:
    ///   - type: SendType sending message type for address
    ///   - addr: message send to
    ///   - session: message encrypted body session key
    ///   - atts: prepared attachments
    init(type: SendType, addr: PreAddress, session: Data, algo: String, atts: [PreAttachment]) {
        self.session = session
        self.algo = algo
        self.preAttachments = atts
        super.init(type: type, addr: addr)
    }

    override func build(completion: @escaping (Result<AddressPackageBase, Error>) -> Void) {
        builderQueue.async {
            do {
                var attPackages = [AttachmentPackage]()
                for att in self.preAttachments {
                    // TODO::here need hanlde the error
                    let newKeyPack = try att.Session.getKeyPackage(publicKey: self.preAddress.pgpKey!, algo: att.Algo)?.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0)) ?? ""
                    let attPacket = AttachmentPackage(attID: att.ID, attKey: newKeyPack)
                    attPackages.append(attPacket)
                }

                // if plainText
                let newKeypacket = try self.session.getKeyPackage(publicKey: self.preAddress.pgpKey!, algo: self.algo)
                let newEncodedKey = newKeypacket?.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0)) ?? ""
                let addr = AddressPackage(email: self.preAddress.email, bodyKeyPacket: newEncodedKey, type: self.sendType, plainText: self.preAddress.isPlainText, attPackets: attPackages)
                completion(.success(addr))
            } catch {
                completion(.failure(error))
            }
        }
    }
}

/// Address Builder for building the packages
class MimeAddressBuilder: PackageBuilder {
    /// message body session key
    let session: Data
    let algo: String
    /// Initial
    ///
    /// - Parameters:
    ///   - type: SendType sending message type for address
    ///   - addr: message send to
    ///   - session: message encrypted body session key
    init(type: SendType, addr: PreAddress, session: Data, algo: String) {
        self.session = session
        self.algo = algo
        super.init(type: type, addr: addr)
    }

    override func build(completion: @escaping (Result<AddressPackageBase, Error>) -> Void) {
        builderQueue.async {
            do {
                let newKeypacket = try self.session.getKeyPackage(publicKey: self.preAddress.pgpKey!, algo: self.algo)
                let newEncodedKey = newKeypacket?.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0)) ?? ""

                let addr = MimeAddressPackage(email: self.preAddress.email, bodyKeyPacket: newEncodedKey, type: self.sendType, plainText: self.preAddress.isPlainText)
                completion(.success(addr))
            } catch {
                completion(.failure(error))
            }
        }
    }
}

/// Address Builder for building the packages
class ClearMimeAddressBuilder: PackageBuilder {

    /// Initial
    ///
    /// - Parameters:
    ///   - type: SendType sending message type for address
    ///   - addr: message send to
    override init(type: SendType, addr: PreAddress) {
        super.init(type: type, addr: addr)
    }

    override func build(completion: @escaping (Result<AddressPackageBase, Error>) -> Void) {
        builderQueue.async {
            let addr = AddressPackageBase(email: self.preAddress.email, type: self.sendType, sign: self.preAddress.isSigned ? 1 : 0, plainText: self.preAddress.isPlainText)
            completion(.success(addr))
        }
    }
}

/// Address Builder for building the packages
class AddressBuilder: PackageBuilder {
    /// message body session key
    let session: Data
    let algo: String

    /// prepared attachment list
    let preAttachments: [PreAttachment]

    /// Initial
    ///
    /// - Parameters:
    ///   - type: SendType sending message type for address
    ///   - addr: message send to
    ///   - session: message encrypted body session key
    ///   - atts: prepared attachments
    init(type: SendType, addr: PreAddress, session: Data, algo: String, atts: [PreAttachment]) {
        self.session = session
        self.algo = algo
        self.preAttachments = atts
        super.init(type: type, addr: addr)
    }

    override func build(completion: @escaping (Result<AddressPackageBase, Error>) -> Void) {
        builderQueue.async {
            do {
                var attPackages = [AttachmentPackage]()
                for att in self.preAttachments {
                    // TODO::here need hanlde the error
                    if let pubK = self.preAddress.pubKey {
                        let newKeyPack = try att.Session.getKeyPackage(publicKey: pubK, algo: att.Algo)?.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0)) ?? ""
                        let attPacket = AttachmentPackage(attID: att.ID, attKey: newKeyPack)
                        attPackages.append(attPacket)
                    }
                }

                // TODO::will remove from here debuging or merge this class with PGPAddressBuildr
                if let pk = self.preAddress.pgpKey {
                    let newKeypacket = try self.session.getKeyPackage(publicKey: pk, algo: self.algo)
                    let newEncodedKey = newKeypacket?.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0)) ?? ""
                    let addr = AddressPackage(email: self.preAddress.email, bodyKeyPacket: newEncodedKey, type: self.sendType, plainText: self.preAddress.isPlainText, attPackets: attPackages)
                    completion(.success(addr))
                } else {
                    // TODO::here need hanlde the error
                    let newKeypacket = try self.session.getKeyPackage(publicKey: self.preAddress.pubKey ?? "", algo: self.algo)
                    let newEncodedKey = newKeypacket?.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0)) ?? ""
                    let addr = AddressPackage(email: self.preAddress.email, bodyKeyPacket: newEncodedKey, type: self.sendType, plainText: self.preAddress.isPlainText, attPackets: attPackages)
                    completion(.success(addr))
                }
            } catch {
                completion(.failure(error))
            }
        }
    }
}

class ClearAddressBuilder: PackageBuilder {
    override func build(completion: @escaping (Result<AddressPackageBase, Error>) -> Void) {
        builderQueue.async {
            let eo = AddressPackageBase(email: self.preAddress.email, type: self.sendType, sign: self.preAddress.isSigned ? 1 : 0, plainText: self.preAddress.isPlainText)
            completion(.success(eo))
        }
    }
}
