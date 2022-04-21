// Copyright (c) 2022 Proton Technologies AG
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

import CoreData
import Foundation
import ProtonCore_Crypto
import ProtonCore_DataModel

protocol MessageDecrypterProtocol {
    func decrypt(message: Message) throws -> String
    func decrypt(message: MessageEntity) throws -> (String?, [MimeAttachment]?)
    func copy(message: Message,
              copyAttachments: Bool,
              context: NSManagedObjectContext) -> Message
    func verify(message: MessageEntity, verifier: [Data]) -> SignStatus
}

final class MessageDecrypter: MessageDecrypterProtocol {
    private weak var userDataSource: UserDataSource?

    init(userDataSource: UserDataSource) {
        self.userDataSource = userDataSource
    }

    func decrypt(message: Message) throws -> String {
        let addressKeys = self.getAddressKeys(for: message.addressID)
        if addressKeys.isEmpty {
            return message.body
        }
        guard let dataSource = self.userDataSource,
              case let passphrase = dataSource.mailboxPassword,
              var body = try self.decryptBody(message: message,
                                              addressKeys: addressKeys,
                                              privateKeys: dataSource.userPrivateKeys,
                                              passphrase: passphrase,
                                              newScheme: dataSource.newSchema) else {
                  throw MailCrypto.CryptoError.decryptionFailed
              }

        if message.isPgpMime || message.isSignedMime {
            let result = self.postProcessMIME(body: body)
            body = result.0
            message.tempAtts = result.1
            return body
        } else if message.isPgpInline {
            let result = self.postProcessPGPInline(
                isPlainText: message.isPlainText,
                isMultipartMixed: message.isMultipartMixed,
                body: body)
            body = result.0
            message.tempAtts = result.1
            return body
        }
        if message.isPlainText {
            if message.draft {
                return body
            } else {
                body = body.encodeHtml()
                return body.ln2br()
            }
        }
        return body
    }

    func decrypt(message: MessageEntity) throws -> (String?, [MimeAttachment]?) {
        let addressKeys = self.getAddressKeys(for: message.addressID.rawValue)
        if addressKeys.isEmpty {
            return (message.body, nil)
        }
        guard let dataSource = self.userDataSource,
              case let passphrase = dataSource.mailboxPassword,
              var body = try self.decryptBody(message: message,
                                              addressKeys: addressKeys,
                                              privateKeys: dataSource.userPrivateKeys,
                                              passphrase: passphrase,
                                              newScheme: dataSource.newSchema) else {
                  throw MailCrypto.CryptoError.decryptionFailed
              }

        if message.isPGPMime || message.isSignedMime {
            let result = self.postProcessMIME(body: body)
            body = result.0
            return (body, result.1)
        } else if message.isPGPInline {
            let result = self.postProcessPGPInline(
                isPlainText: message.isPlainText,
                isMultipartMixed: message.isMultipartMixed,
                body: body)
            body = result.0
            return (body, result.1)
        }
        if message.isPlainText {
            if message.isDraft {
                return (body, nil)
            } else {
                body = body.encodeHtml()
                return (body.ln2br(), nil)
            }
        }
        return (body, nil)
    }


    func copy(message: Message,
              copyAttachments: Bool,
              context: NSManagedObjectContext) -> Message {
        var newMessage: Message!

        context.performAndWait {
            newMessage = self.duplicate(message, context: context)

            if let conversation = Conversation.conversationForConversationID(message.conversationID, inManagedObjectContext: context) {
                let newCount = conversation.numMessages.intValue + 1
                conversation.numMessages = NSNumber(value: newCount)
            }

            let body = try? self.decrypt(message: newMessage)
            self.copy(attachments: message.attachments,
                      to: newMessage,
                      copyAttachment: copyAttachments,
                      decryptedBody: body)
            _ = context.saveUpstreamIfNeeded()
        }
        return newMessage
    }

    func verify(message: MessageEntity, verifier: [Data]) -> SignStatus {
        guard let keys = self.userDataSource?.addressKeys,
              let passphrase = self.userDataSource?.mailboxPassword else {
                  return .failed
              }

        do {
            let time = Int64(round(message.time?.timeIntervalSince1970 ?? 0))
            if let verify = self.userDataSource!.newSchema ?
                try message.body.verifyMessage(verifier: verifier,
                                       userKeys: self.userDataSource!.userPrivateKeys,
                                       keys: keys, passphrase: passphrase, time: time) :
                try message.body.verifyMessage(verifier: verifier,
                                               binKeys: keys.binPrivKeysArray,
                                               passphrase: passphrase,
                                               time: time) {
                guard let verification = verify.signatureVerificationError else {
                    return .ok
                }
                return SignStatus(rawValue: verification.status) ?? .notSigned
            }
        } catch {}
        return .failed
    }
}

// MARK: decryption message
extension MessageDecrypter {
    func getAddressKeys(for addressID: String?) -> [Key] {
        guard let addressID = addressID,
              let keys = self.userDataSource?
                .getAllAddressKey(address_id: addressID) else {
            return self.userDataSource?.addressKeys ?? []
        }
        return keys
    }

    func decryptBody(message: Message,
                     addressKeys: [Key],
                     privateKeys: [Data],
                     passphrase: String,
                     newScheme: Bool) throws -> String? {

        var body: String?
        if newScheme {
            body = try message.decryptBody(keys: addressKeys,
                                           userKeys: privateKeys,
                                           passphrase: passphrase)
        } else {
            body = try message.decryptBody(keys: addressKeys,
                                           passphrase: passphrase)
        }
        return body
    }

    func decryptBody(message: MessageEntity,
                     addressKeys: [Key],
                     privateKeys: [Data],
                     passphrase: String,
                     newScheme: Bool) throws -> String? {

        var body: String?
        if newScheme {
            body = try self.decryptBody(message,
                             keys: addressKeys,
                             userKeys: privateKeys,
                             passphrase: passphrase)
        } else {
            body = try self.decryptBody(message,
                             keys: addressKeys,
                             passphrase: passphrase)
        }
        return body
    }

    private func decryptBody(_ message: MessageEntity,
                             keys: [Key],
                             userKeys: [Data],
                             passphrase: String) throws -> String? {
        var firstError : Error?
        var errorMessages: [String] = []
        for key in keys {
            do {
                let addressKeyPassphrase = try MailCrypto.getAddressKeyPassphrase(userKeys: userKeys,
                                                                              passphrase: passphrase,
                                                                              key: key)
                let decryptedBody = try message.body.decryptMessageWithSingleKeyNonOptional(key.privateKey,
                                                                           passphrase: addressKeyPassphrase)
                return decryptedBody
            } catch let error {
                if firstError == nil {
                    firstError = error
                    errorMessages.append(error.localizedDescription)
                }
            }
        }
        return nil
    }

    func decryptBody(_ message: MessageEntity,
                     keys: [Key],
                     passphrase: String) throws -> String? {
        var firstError : Error?
        var errorMessages: [String] = []
        for key in keys {
            do {
                let decryptedBody = try message.body.decryptMessageWithSingleKeyNonOptional(key.privateKey, passphrase: passphrase)
                return decryptedBody
            } catch let error {
                if firstError == nil {
                    firstError = error
                    errorMessages.append(error.localizedDescription)
                }
            }
        }

        if let error = firstError {
            throw error
        }
        return nil
    }

    func postProcessMIME(body: String) -> (String, [MimeAttachment])  {
        guard let mimeMessage = MIMEMessage(string: body) else {
            return (body.multipartGetHtmlContent(), [])
        }
        var body = body
        if let html = mimeMessage.mainPart.part(ofType: Message.MimeType.html)?.bodyString {
            body = html
        } else if let text = mimeMessage.mainPart.part(ofType: Message.MimeType.plainText)?.bodyString {
            body = text.encodeHtml()
            body = "<html><body>\(body.ln2br())</body></html>"
        }

        let (mimeAttachments, mimeBody) = self.parse(mimeMessage: mimeMessage, body: body)
        body = mimeBody
        return (body, mimeAttachments)
    }

    func parse(mimeMessage: MIMEMessage, body: String) -> ([MimeAttachment], String) {
        var body = body
        let mimeAttachments = mimeMessage.mainPart.findAtts()
        var infos = [MimeAttachment]()
        for attachment in mimeAttachments {
            // Replace inline data
            if var contentID = attachment.cid,
               let rawBody = attachment.rawBodyString {
                contentID = contentID.preg_replace("<", replaceto: "")
                contentID = contentID.preg_replace(">", replaceto: "")
                let type = "image/jpg" // cidPart.headers[.contentType]?.body ?? "image/jpg;name=\"unknown.jpg\""
                let encode = attachment.headers[.contentTransferEncoding]?.body ?? "base64"
                body = body.preg_replace_none_regex("src=\"cid:\(contentID)\"", replaceto: "src=\"data:\(type);\(encode),\(rawBody)\"")
            }

            guard let filename = attachment.getFilename()?.clear else {
                continue
            }
            let data = attachment.data
            let path = FileManager.default
                .attachmentDirectory.appendingPathComponent(filename)
            do {
                try data.write(to: path, options: [.atomic])
            } catch {
                continue
            }
            let disposition = attachment.contentDisposition?.raw ?? ""
            let mimeAttachment = MimeAttachment(filename: filename,
                                                size: data.count,
                                                mime: filename.mimeType(),
                                                path: path,
                                                disposition: disposition)
            infos.append(mimeAttachment)
        }
        return (infos, body)
    }

    func postProcessPGPInline(isPlainText: Bool,
                              isMultipartMixed: Bool,
                              body: String) -> (String, [MimeAttachment]) {
        var body = body
        if isPlainText {
            let head = "<html><head></head><body>"
            // The plain text draft from android and web doesn't have
            // the head, so if the draft contains head
            // It means the draft already encoded
            if !body.hasPrefix(head) {
                body = body.encodeHtml()
                body = body.ln2br()
            }
            return (body, [])
        } else if isMultipartMixed {
            return self.postProcessMIME(body: body)
        }
        return (body, [])
    }
}

// MARK: copy message
extension MessageDecrypter {
    func getFirstAddressKey(for addressID: String?) -> Key? {
        guard let addressID = addressID,
        let userInfo = self.userDataSource?.userInfo,
        let keys = userInfo.getAllAddressKey(address_id: addressID) else {
            return nil
        }
        return keys.first
    }

    func updateKeyPacketIfNeeded(attachment: Attachment, addressID: String?) {
        guard let key = self.getFirstAddressKey(for: addressID),
              let userData = self.userDataSource else {
                  return
              }

        do {
            let symmetricKey: SymmetricKey?
            if userData.newSchema {
                symmetricKey = try attachment
                    .getSession(userKey: userData.userPrivateKeys,
                                keys: userData.addressKeys,
                                mailboxPassword: userData.mailboxPassword)
            } else {
                symmetricKey = try attachment
                    .getSession(keys: userData.addressPrivateKeys,
                                mailboxPassword: userData.mailboxPassword)
            }

            guard let sessionPack = symmetricKey,
                  let session = sessionPack.key,
                  let newkp = try session
                    .getKeyPackage(publicKey: key.publicKey,
                                   algo: sessionPack.algo) else {
                        return
                    }
            let encodedkp = newkp.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
            attachment.keyPacket = encodedkp
            attachment.keyChanged = true
        } catch {
            return
        }
    }

    func duplicate(_ message: Message, context: NSManagedObjectContext) -> Message {
        let newMessage = Message(context: context)
        newMessage.toList = message.toList
        newMessage.bccList = message.bccList
        newMessage.ccList = message.ccList
        newMessage.title = message.title
        newMessage.time = Date()
        newMessage.body = message.body

        // newMessage.flag = message.flag
        newMessage.sender = message.sender
        newMessage.replyTos = message.replyTos

        newMessage.orginalTime = message.time
        newMessage.orginalMessageID = message.messageID
        newMessage.expirationOffset = 0

        newMessage.addressID = message.addressID
        newMessage.messageStatus = message.messageStatus
        newMessage.mimeType = message.mimeType
        newMessage.conversationID = message.conversationID
        newMessage.setAsDraft()

        newMessage.userID = self.userDataSource?.userID.rawValue ?? ""
        return newMessage
    }

    func copy(attachments: NSSet,
              to newMessage: Message,
              copyAttachment: Bool,
              decryptedBody: String?) {
        var newAttachmentCount: Int = 0
        let oldAttachments = attachments
            .allObjects
            .compactMap({ $0 as? Attachment })
        for attachment in oldAttachments {
            guard attachment.inline() || copyAttachment,
                  let context = newMessage.managedObjectContext else {
                continue
            }
            if let body = decryptedBody, !copyAttachment {
                if attachment.inline() == false {
                    // Normal attachment & shouldn't copy attachment
                    continue
                }
                // Inline attachment but the body doesn't contain the contentID
                if let contentID = attachment.contentID(),
                   !body.contains(check: contentID) {
                    continue
                }
            }
            let newAttachment = self.duplicate(oldAttachment: attachment,
                                               newMessage: newMessage,
                                               context: context)
            if newAttachment.managedObjectContext?.saveUpstreamIfNeeded() == nil {
                newAttachmentCount += 1
            }
        }
        newMessage.numAttachments = NSNumber(value: newAttachmentCount)
    }

    func duplicate(oldAttachment: Attachment,
                   newMessage: Message,
                   context: NSManagedObjectContext) -> Attachment {
        let attachment = Attachment(context: context)
        attachment.attachmentID = oldAttachment.attachmentID
        attachment.message = newMessage
        attachment.fileName = oldAttachment.fileName
        attachment.mimeType = oldAttachment.mimeType
        attachment.fileData = oldAttachment.fileData
        attachment.fileSize = oldAttachment.fileSize
        attachment.headerInfo = oldAttachment.headerInfo
        attachment.localURL = oldAttachment.localURL
        attachment.keyPacket = oldAttachment.keyPacket
        attachment.isTemp = true
        attachment.userID = self.userDataSource?.userID.rawValue ?? ""

        self.updateKeyPacketIfNeeded(attachment: attachment,
                                     addressID: newMessage.addressID)
        return attachment
    }
}
