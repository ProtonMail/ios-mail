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

final class MessageSendingRequestBuilder {
    enum BuilderError: Error {
        case MIMEDataNotPrepared
        case plainTextDataNotPrepared
        case encryptedPlainTextMsgFailedToCreate
        case packagesFailedToCreate
        case sessionKeyFailedToCreate
        case encryptedMIMEMsgFailedToCreate
    }

    private(set) var bodyDataPacket: Data?
    private(set) var bodySessionKey: Data?
    private(set) var bodySessionAlgo: String?

    private(set) var preAddresses = [PreAddress]()
    private(set) var preAttachments = [PreAttachment]()
    private(set) var password: String?
    private(set) var hint: String?

    private(set) var mimeSessionKey: Data?
    private(set) var mimeSessionAlgo: String?
    private(set) var mimeDataPackage: String?

    private(set) var clearBody: String?

    private(set) var plainTextSessionKey: Data?
    private(set) var plainTextSessionAlgo: String?
    private(set) var plainTextDataPackage: String?

    private(set) var clearPlainTextBody: String?

    // [AttachmentID: base64 attachment body]
    private var attachmentBodys: [String: String] = [:]

    let expirationOffset: Int32

    init(expirationOffset: Int32?) {
        self.expirationOffset = expirationOffset ?? 0
    }

    func update(bodyData data: Data, bodySession: Data, algo: String) {
        self.bodyDataPacket = data
        self.bodySessionKey = bodySession
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
               let encodedSessionKey = self.encodedSessionKey {
                return ClearBodyPackage(key: encodedSessionKey,
                                        algo: algorithm)
            }
        }
        return nil
    }

    var clearMimeBodyPackage: ClearBodyPackage? {
        if self.contains(type: .cmime),
           let base64MIMESessionKey = mimeSessionKey?.encodeBase64(),
           let algorithm = mimeSessionAlgo {
            return ClearBodyPackage(key: base64MIMESessionKey,
                                    algo: algorithm)
        }
        return nil
    }

    var clearPlainBodyPackage: ClearBodyPackage? {
        if hasPlainText, contains(type: .cinln) || contains(type: .cmime) {
            guard let base64SessionKey = plainTextSessionKey?.encodeBase64(),
                  let algorithm = plainTextSessionAlgo else {
                      return nil
                  }
            return ClearBodyPackage(key: base64SessionKey,
                                    algo: algorithm)
        }
        return nil
    }

    var mimeBody: String {
        if hasMime, let dataPackage = mimeDataPackage {
            return dataPackage
        }
        return ""
    }

    var plainBody: String {
        if hasPlainText, let dataPackage = plainTextDataPackage {
            return dataPackage
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

    var encodedBody: String? {
        return self.bodyDataPacket?.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
    }

    var encodedSessionKey: String? {
        return self.bodySessionKey?.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
    }
}

// MARK: - Build Message Body
extension MessageSendingRequestBuilder {
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

    func fetchAttachmentBodyForMime(passphrase: String,
                                    msgService: MessageDataService,
                                    userInfo: UserInfo) -> Promise<MessageSendingRequestBuilder> {
        var fetches = [Promise<String>]()
        for att in preAttachments {
            let promise = fetchAttachmentBody(att: att.att,
                                              messageDataService: msgService,
                                              passphrase: passphrase,
                                              userInfo: userInfo)
            fetches.append(promise)
        }

        return when(resolved: fetches).then { attachmentBodys -> Promise<MessageSendingRequestBuilder> in
            for (index, result) in attachmentBodys.enumerated() {
                switch result {
                case .fulfilled(let body):
                    let preAttachment = self.preAttachments[index].att
                    self.attachmentBodys[preAttachment.attachmentID] = body
                case .rejected(let error):
                    PMLog.D(error.localizedDescription)
                }
            }
            return .value(self)
        }
    }

    // swiftlint:disable function_body_length
    func buildMime(senderKey: Key,
                   passphrase: String,
                   userKeys: [Data],
                   keys: [Key],
                   newSchema: Bool) -> Promise<MessageSendingRequestBuilder> {
        return Promise { seal in
            var messageBody = self.clearBody ?? ""
            messageBody = QuotedPrintable.encode(string: messageBody)

            let boundaryMsg = generateMessageBoundaryString()
            var signbody = buildFirstPartOfBody(boundaryMsg: boundaryMsg, messageBody: messageBody)

            for preAttachment in self.preAttachments {
                guard let attachmentBody = attachmentBodys[preAttachment.attachmentId] else {
                    continue
                }
                let attachment = preAttachment.att
                let attName = QuotedPrintable.encode(string: attachment.fileName)
                let contentID = attachment.contentID() ?? ""

                let bodyToAdd = self.buildAttachmentBody(boundaryMsg: boundaryMsg,
                                                         base64AttachmentContent: attachmentBody,
                                                         attachmentName: attName,
                                                         contentID: contentID,
                                                         attachmentMIMEType: attachment.mimeType)
                signbody.append(contentsOf: bodyToAdd)
            }

            signbody.append(contentsOf: "--\(boundaryMsg)--")

            guard let encrypted = try signbody.encrypt(withKey: senderKey,
                                                       userKeys: userKeys,
                                                       mailbox_pwd: passphrase) else {
                throw BuilderError.encryptedMIMEMsgFailedToCreate
            }

            let (keyPacket, dataPacket) = try self.preparePackages(encrypted: encrypted)

            guard let sessionKey = try self.getSessionKey(from: keyPacket,
                                                          isNewSchema: newSchema,
                                                          userKeys: userKeys,
                                                          senderKey: senderKey,
                                                          addressKeys: keys,
                                                          passphrase: passphrase) else {
                throw BuilderError.sessionKeyFailedToCreate
            }
            self.mimeSessionKey = sessionKey.key
            self.mimeSessionAlgo = sessionKey.algo
            self.mimeDataPackage = dataPacket.base64EncodedString()

            seal.fulfill(self)
        }
    }

    func buildPlainText(senderKey: Key,
                        passphrase: String,
                        userKeys: [Data],
                        keys: [Key],
                        newSchema: Bool) -> Promise<MessageSendingRequestBuilder> {
        return Promise { seal in
            async {
                let plainText = self.generatePlainTextBody()

                guard let encrypted = try plainText.encrypt(withKey: senderKey,
                                                            userKeys: userKeys,
                                                            mailbox_pwd: passphrase) else {
                    throw BuilderError.encryptedPlainTextMsgFailedToCreate
                }

                let (keyPacket, dataPacket) = try self.preparePackages(encrypted: encrypted)

                guard let sessionKey = try self.getSessionKey(from: keyPacket,
                                                              isNewSchema: newSchema,
                                                              userKeys: userKeys,
                                                              senderKey: senderKey,
                                                              addressKeys: keys,
                                                              passphrase: passphrase) else {
                    throw BuilderError.sessionKeyFailedToCreate
                }

                self.plainTextSessionKey = sessionKey.key
                self.plainTextSessionAlgo = sessionKey.algo
                self.plainTextDataPackage = dataPacket.base64EncodedString()

                self.clearPlainTextBody = plainText

                seal.fulfill(self)
            }
        }
    }

    func buildAttachmentBody(boundaryMsg: String,
                             base64AttachmentContent: String,
                             attachmentName: String,
                             contentID: String,
                             attachmentMIMEType: String) -> String {
        var body = ""
        body.append(contentsOf: "--\(boundaryMsg)" + "\r\n")
        body.append(contentsOf: "Content-Type: \(attachmentMIMEType); name=\"\(attachmentName)\"" + "\r\n")
        body.append(contentsOf: "Content-Transfer-Encoding: base64" + "\r\n")
        body.append(contentsOf: "Content-Disposition: attachment; filename=\"\(attachmentName)\"" + "\r\n")
        body.append(contentsOf: "Content-ID: <\(contentID)>\r\n")

        body.append(contentsOf: "\r\n")
        body.append(contentsOf: base64AttachmentContent + "\r\n")
        return body
    }

    func buildFirstPartOfBody(boundaryMsg: String, messageBody: String) -> String {
        let typeMessage = "Content-Type: multipart/related; boundary=\"\(boundaryMsg)\""
        var signbody = ""
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
        return signbody
    }

    func preparePackages(encrypted: String) throws -> (Data, Data) {
        guard let spilted = try encrypted.split(),
              let keyPacket = spilted.keyPacket,
              let dataPacket = spilted.dataPacket else {
                  throw BuilderError.packagesFailedToCreate
              }
        return (keyPacket, dataPacket)
    }

    func getSessionKey(from keyPacket: Data,
                       isNewSchema: Bool,
                       userKeys: [Data],
                       senderKey: Key,
                       addressKeys: [Key],
                       passphrase: String) throws -> SymmetricKey? {
        if isNewSchema {
            return try keyPacket.getSessionFromPubKeyPackage(userKeys: userKeys,
                                                             passphrase: passphrase,
                                                             keys: addressKeys)
        } else {
            return try keyPacket.getSessionFromPubKeyPackage(addrPrivKey: senderKey.privateKey,
                                                             passphrase: passphrase)
        }
    }

    func generatePlainTextBody() -> String {
        let body = self.clearBody ?? ""
        // TODO: need improve replace part
        return body.html2String.preg_replace("\n", replaceto: "\r\n")
    }

    func generateMessageBoundaryString() -> String {
        var boundaryMsg = "uF5XZWCLa1E8CXCUr2Kg8CSEyuEhhw9WU222" // default
        if let random = try? Crypto.random(byte: 20), !random.isEmpty {
            boundaryMsg = HMAC.hexStringFromData(random)
        }
        return boundaryMsg
    }
}

// MARK: - Create builders for each type of message
extension MessageSendingRequestBuilder {
    func generatePackageBuilder() throws -> [PackageBuilder] {
        var out = [PackageBuilder]()
        for pre in self.preAddresses {
            var session = Data()
            var algo: String = "aes256"
            if let bodySession = self.bodySessionKey {
                session = bodySession
            }
            if let bodySessionAlgo = self.bodySessionAlgo {
                algo = bodySessionAlgo
            }
            if pre.plainText {
                if let sessionKey = plainTextSessionKey,
                   let algorithm = plainTextSessionAlgo {
                    session = sessionKey
                    algo = algorithm
                } else {
                    throw BuilderError.plainTextDataNotPrepared
                }
            }
            switch self.calculateSendType(recipientType: pre.recipintType,
                                          isEO: pre.isEO,
                                          hasPGPKey: pre.pgpKey != nil,
                                          hasPGPEncryption: pre.pgpencrypt,
                                          isMIME: pre.mime) {
            case .intl:
                out.append(InternalAddressBuilder(type: .intl,
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
                guard let sessionData = mimeSessionKey,
                      let algorithm = mimeSessionAlgo else {
                          throw BuilderError.MIMEDataNotPrepared
                      }
                out.append(PGPMimeAddressBuilder(type: .pgpmime,
                                                 addr: pre,
                                                 session: sessionData,
                                                 algo: algorithm))
            case .cmime: // clear text mime
                out.append(ClearMimeAddressBuilder(type: .cmime, addr: pre))
            default:
                break
            }
        }
        return out
    }

    func getBuilderPromises() throws -> [Promise<AddressPackageBase>] {
        var result = [Promise<AddressPackageBase>]()
        let builders = try generatePackageBuilder()
        for builder in builders {
            result.append(builder.build())
        }
        return result
    }
}
