// Copyright (c) 2021 Proton Technologies AG
//
// This file is part of ProtonMail.
//
// ProtonMail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// ProtonMail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with ProtonMail. If not, see https://www.gnu.org/licenses/.

import AwaitKit
import PromiseKit
import ProtonCore_DataModel
import ProtonCore_SRP

/// A sending message request builder
///
/// You can create new builder like:
/// ````
///     let builder = MessageSendingRequestBuilder()
/// ````
///

// swiftlint:disable type_body_length
final class MessageSendingRequestBuilder {
    private(set) var bodyDataPacket: Data?
    private(set) var bodySession: Data?
    private(set) var bodySessionAlgo: String?

    private(set) var preAddresses = [PreAddress]()
    private(set) var preAttachments = [PreAttachment]()
    private(set) var password: String?
    private(set) var hint: String?

    var mimeSession: Data!
    var mimeSessionAlgo: String!
    var mimeDataPackage: String!

    private(set) var clearBody: String?

    var plainTextSession: Data!
    var plainTextSessionAlgo: String!
    var plainTextDataPackage: String!

    var clearPlainTextBody: String!
    let expirationOffset: Int32

    init(expirationOffset: Int32?) {
        self.expirationOffset = expirationOffset ?? 0
    }

    func update(bodyData data: Data, bodySession: Data, algo: String) {
        self.bodyDataPacket = data
        self.bodySession = bodySession
        self.bodySessionAlgo = algo
    }

    func set(password: String, hint: String?) {
        self.password = password
        self.hint = hint
    }

    func set(clearBody: String) {
        self.clearBody = clearBody
    }

    func add(address: PreAddress) {
        self.preAddresses.append(address)
    }

    func add(attachment: PreAttachment) {
        self.preAttachments.append(attachment)
    }

    var clearBodyPackage: ClearBodyPackage? {
        if self.contains(type: .cinln) || self.contains(type: .cmime) {
            if let algorithm = bodySessionAlgo,
               let encodedSession = self.encodedSession {
                return ClearBodyPackage(key: encodedSession,
                                        algo: algorithm)
            } else {
                return nil
            }
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
        if self.hasPlainText, self.contains(type: .cinln) || self.contains(type: .cmime) {
            return ClearBodyPackage(key: self.plainTextSession.encodeBase64(), algo: self.plainTextSessionAlgo)
        }
        return nil
    }

    var mimeBody: String {
        if self.hasMime {
            return self.mimeDataPackage
        }
        return ""
    }

    var plainBody: String {
        if self.hasPlainText {
            return self.plainTextDataPackage
        }
        return ""
    }

    var clearAtts: [ClearAttachmentPackage]? {
        if self.contains(type: .cinln) || self.contains(type: .cmime) {
            var attachments = [ClearAttachmentPackage]()
            for preAttachment in self.preAttachments {
                let encodedSession = preAttachment.session
                    .base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
                attachments.append(ClearAttachmentPackage(attID: preAttachment.attachmentId,
                                                          encodedSession: encodedSession,
                                                          algo: preAttachment.algo))
            }
            return attachments.isEmpty ? nil : attachments
        }
        return nil
    }

    func calculateSendType(recipientType type: Int,
                           isEO: Bool,
                           hasPGPKey: Bool,
                           hasPGPEncryption: Bool,
                           isMIME: Bool) -> SendType {
        if type == 1 {
            return .intl
        }

        // pgp mime
        if type == 2, isMIME, hasPGPKey, hasPGPEncryption {
            if isEO, self.expirationOffset > 0 {
                return .eo
            } else {
                return .pgpmime
            }
        }

        // encrypted outside
        if type == 2, isEO {
            return .eo
        }

        // mime clear
        if type == 2, isMIME {
            return .cmime
        }

        // pgp inline
        if type == 2, hasPGPKey, hasPGPEncryption {
            return .inlnpgp
        }

        // clear inline
        return .cinln
    }

    func fetchAttachmentBody(att: Attachment,
                             messageDataService: MessageDataService,
                             passphrase: String,
                             userInfo: UserInfo) -> Promise<String> {
        return Promise { seal in
            if let localURL = att.localURL, FileManager.default.fileExists(atPath: localURL.path, isDirectory: nil) {
                seal.fulfill(att.base64DecryptAttachment(userInfo: userInfo, passphrase: passphrase))
                return
            }

            if let data = att.fileData, !data.isEmpty {
                seal.fulfill(att.base64DecryptAttachment(userInfo: userInfo, passphrase: passphrase))
                return
            }

            att.localURL = nil
            messageDataService
                .fetchAttachmentForAttachment(att,
                                              customAuthCredential: att.message.cachedAuthCredential,
                                              downloadTask: { (_: URLSessionDownloadTask) -> Void in },
                                              completion: { _, _, error -> Void in
                    let decryptedAttachment = att.base64DecryptAttachment(userInfo: userInfo,
                                                                          passphrase: passphrase)
                    seal.fulfill(decryptedAttachment)
                    if error != nil {
                        PMLog.D("\(String(describing: error))")
                    }
                })
        }
    }

    // swiftlint:disable function_body_length
    func buildMime(senderKey: Key,
                   passphrase: String,
                   userKeys: [Data],
                   keys: [Key],
                   newSchema: Bool,
                   msgService: MessageDataService,
                   userInfo: UserInfo) -> Promise<MessageSendingRequestBuilder> {
        return Promise { seal in
            /// decrypt attachments
            var messageBody = self.clearBody ?? ""
            messageBody = QuotedPrintable.encode(string: messageBody)
            var signbody = ""
            var boundaryMsg: String = "uF5XZWCLa1E8CXCUr2Kg8CSEyuEhhw9WU222" // default
            do {
                let random = try Crypto.random(byte: 20)
                if !random.isEmpty {
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

            var fetchs = [Promise<String>]()
            for att in self.preAttachments {
                let promise = self.fetchAttachmentBody(att: att.att,
                                                       messageDataService: msgService,
                                                       passphrase: passphrase,
                                                       userInfo: userInfo)
                fetchs.append(promise)
            }
            // 1. fetch attachment first
            firstly {
                when(resolved: fetchs)
            }.done { bodys in
                for (index, body) in bodys.enumerated() {
                    switch body {
                    case .fulfilled(let value):
                        let att = self.preAttachments[index].att
                        signbody.append(contentsOf: "--\(boundaryMsg)" + "\r\n")
                        let attName = QuotedPrintable.encode(string: att.fileName)
                        signbody.append(contentsOf: "Content-Type: \(att.mimeType); name=\"\(attName)\"" + "\r\n")
                        signbody.append(contentsOf: "Content-Transfer-Encoding: base64" + "\r\n")
                        signbody.append(contentsOf: "Content-Disposition: attachment; filename=\"\(attName)\"" + "\r\n")
                        let contentID = att.contentID() ?? ""
                        signbody.append(contentsOf: "Content-ID: <\(contentID)>\r\n")

                        signbody.append(contentsOf: "\r\n")
                        signbody.append(contentsOf: value + "\r\n")
                    case .rejected(let error):
                        PMLog.D(error.localizedDescription)
                    }
                }
                signbody.append(contentsOf: "--\(boundaryMsg)--")
                let encrypted = try signbody.encrypt(withKey: senderKey,
                                                     userKeys: userKeys,
                                                     mailbox_pwd: passphrase)
                let spilted = try encrypted?.split()
                let session = newSchema ?
                    try spilted?.keyPacket?.getSessionFromPubKeyPackage(userKeys: userKeys,
                                                                        passphrase: passphrase,
                                                                        keys: keys) :
                    try spilted?.keyPacket?.getSessionFromPubKeyPackage(addrPrivKey: senderKey.privateKey,
                                                                        passphrase: passphrase)

                self.mimeSession = session?.key
                self.mimeSessionAlgo = session?.algo
                self.mimeDataPackage = spilted?.dataPacket?.base64EncodedString()

                seal.fulfill(self)
            }.catch(policy: .allErrors) { error in
                seal.reject(error)
            }
        }
    }

    func buildPlainText(senderKey: Key,
                        passphrase: String,
                        userKeys: [Data],
                        keys: [Key],
                        newSchema: Bool) -> Promise<MessageSendingRequestBuilder> {
        return Promise { seal in
            async {
                let messageBody = self.clearBody ?? ""
                // Need to improve replace part
                let plainText = messageBody.html2String.preg_replace("\n", replaceto: "\r\n")
                PMLog.D(plainText)
                let encrypted = try plainText.encrypt(withKey: senderKey,
                                                      userKeys: userKeys,
                                                      mailbox_pwd: passphrase)
                let spilted = try encrypted?.split()
                let session = newSchema ?
                    try spilted?.keyPacket?.getSessionFromPubKeyPackage(userKeys: userKeys,
                                                                        passphrase: passphrase,
                                                                        keys: keys) :
                    try spilted?.keyPacket?.getSessionFromPubKeyPackage(addrPrivKey: senderKey.privateKey,
                                                                        passphrase: passphrase)

                self.plainTextSession = session?.key
                self.plainTextSessionAlgo = session?.algo
                self.plainTextDataPackage = spilted?.dataPacket?.base64EncodedString()

                self.clearPlainTextBody = plainText

                seal.fulfill(self)
            }
        }
    }

    var builders: [PackageBuilder] {
        var out = [PackageBuilder]()
        for pre in self.preAddresses {
            var session = Data()
            var algo: String = "aes256"
            if let bodySession = self.bodySession {
                session = bodySession
            }
            if let bodySessionAlgo = self.bodySessionAlgo {
                algo = bodySessionAlgo
            }
            if pre.plainText {
                session = self.plainTextSession
                algo = self.plainTextSessionAlgo
            }
            switch self.calculateSendType(recipientType: pre.recipintType,
                                          isEO: pre.isEO,
                                          hasPGPKey: pre.pgpKey != nil,
                                          hasPGPEncryption: pre.pgpencrypt,
                                          isMIME: pre.mime) {
            case .intl:
                out.append(AddressBuilder(type: .intl,
                                          addr: pre,
                                          session: session,
                                          algo: algo,
                                          atts: self.preAttachments))
            case .eo where self.password != nil:
                out.append(EOAddressBuilder(type: .eo,
                                            addr: pre,
                                            session: session,
                                            algo: algo,
                                            password: self.password ?? "",
                                            atts: self.preAttachments,
                                            hit: self.hint))
            case .cinln:
                out.append(ClearAddressBuilder(type: .cinln, addr: pre))
            case .inlnpgp:
                out.append(PGPAddressBuilder(type: .inlnpgp,
                                             addr: pre,
                                             session: session,
                                             algo: algo,
                                             atts: self.preAttachments))
            case .pgpmime: // pgp mime
                out.append(MimeAddressBuilder(type: .pgpmime,
                                              addr: pre,
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

    var hasMime: Bool {
        return self.contains(type: .pgpmime) || self.contains(type: .cmime)
    }

    var hasPlainText: Bool {
        for preAddress in self.preAddresses where preAddress.plainText {
            return true
        }
        return false
    }

    func contains(type: SendType) -> Bool {
        for pre in self.preAddresses {
            let buildType = self.calculateSendType(recipientType: pre.recipintType,
                                                   isEO: pre.isEO,
                                                   hasPGPKey: pre.pgpKey != nil,
                                                   hasPGPEncryption: pre.pgpencrypt,
                                                   isMIME: pre.mime)
            if buildType.contains(type) {
                return true
            }
        }
        return false
    }

    var promises: [Promise<AddressPackageBase>] {
        var out = [Promise<AddressPackageBase>]()
        for buidler in self.builders {
            out.append(buidler.build())
        }
        return out
    }

    var encodedBody: String? {
        return self.bodyDataPacket?.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
    }

    var encodedSession: String? {
        return self.bodySession?.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
    }
}
