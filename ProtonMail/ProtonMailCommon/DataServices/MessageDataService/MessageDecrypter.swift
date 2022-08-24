// Copyright (c) 2022 Proton AG
//
// This file is part of Proton Mail.
//
// Proton Mail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Mail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Mail. If not, see https://www.gnu.org/licenses/.

import CoreData
import Foundation
import ProtonCore_Crypto
import ProtonCore_DataModel
import ProtonCore_Log

protocol MessageDecrypterProtocol {
    func decrypt(message: Message) throws -> String
    func decrypt(message: MessageEntity) throws -> (String, [MimeAttachment]?)
    func copy(message: Message,
              copyAttachments: Bool,
              context: NSManagedObjectContext) -> Message
    func verify(message: MessageEntity, verifier: [Data]) -> SignatureVerificationResult
}

final class MessageDecrypter: MessageDecrypterProtocol {
    private weak var userDataSource: UserDataSource?

    init(userDataSource: UserDataSource) {
        self.userDataSource = userDataSource
    }

    func decrypt(message: Message) throws -> String {
        let messageEntity = MessageEntity(message)
        let (body, attachments) = try decrypt(message: messageEntity)
        if let tempAtts = attachments {
            message.tempAtts = tempAtts
        }
        return body
    }

    func decrypt(message: MessageEntity) throws -> (String, [MimeAttachment]?) {
        let addressKeys = self.getAddressKeys(for: message.addressID.rawValue)
        if addressKeys.isEmpty {
            return (message.body, nil)
        }

        guard let dataSource = self.userDataSource else {
            throw MailCrypto.CryptoError.decryptionFailed
        }

        let keysWithPassphrases = MailCrypto.keysWithPassphrases(
            basedOn: addressKeys,
            mailboxPassword: dataSource.mailboxPassword,
            userKeys: dataSource.newSchema ? dataSource.userPrivateKeys : nil
        )

        if message.isMultipartMixed {
            let messageData = try MailCrypto().decryptMIME(encrypted: message.body, keys: keysWithPassphrases)
            return postProcessMIME(messageData: messageData)
        }

        // the code below is intentionally not inside an `else` block as a fallback attempt to handle MIME
        let decryptedBody = try MailCrypto().decrypt(encrypted: message.body, keys: keysWithPassphrases)
        let processedBody = postProcessNonMIME(decryptedBody, isPlainText: message.isPlainText)
        return (processedBody, nil)
    }

    func copy(message: Message,
              copyAttachments: Bool,
              context: NSManagedObjectContext) -> Message {
        var newMessage: Message!

        context.performAndWait {
            newMessage = self.duplicate(message, context: context)

            if let conversation = Conversation.conversationForConversationID(
                message.conversationID,
                inManagedObjectContext: context
            ) {
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

    func verify(message: MessageEntity, verifier: [Data]) -> SignatureVerificationResult {
        guard let userDataSource = self.userDataSource else {
            return .failed
        }

        let keys = userDataSource.addressKeys
        let passphrase = userDataSource.mailboxPassword

        let verify: ExplicitVerifyMessage?
        do {
            let time = Int64(round(message.time?.timeIntervalSince1970 ?? 0))
            if userDataSource.newSchema {
                verify = try message.body.verifyMessage(
                    verifier: verifier,
                    userKeys: userDataSource.userPrivateKeys,
                    keys: keys,
                    passphrase: passphrase,
                    time: time
                )
            } else {
                verify = try message.body.verifyMessage(
                    verifier: verifier,
                    binKeys: keys.binPrivKeysArray,
                    passphrase: passphrase,
                    time: time
                )
            }
        } catch {
            return .failed
        }

        guard let verify = verify else {
            return .failed
        }

        if let verification = verify.signatureVerificationError {
            return SignatureVerificationResult(rawValue: verification.status) ?? .notSigned
        } else {
            return .ok
        }
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

    private func postProcessMIME(messageData: MIMEMessageData) -> (String, [MimeAttachment]) {
        var body = messageData.body

        if messageData.mimeType == Message.MimeType.textPlain.rawValue {
            body = body.encodeHtml()
            body = "<html><body>\(body.ln2br())</body></html>"
        }

        let (mimeAttachments, mimeBody) = self.parse(attachments: messageData.attachments, body: body)
        return (mimeBody, mimeAttachments)
    }

    private func postProcessNonMIME(_ decryptedBody: String, isPlainText: Bool) -> String {
        let processedBody: String
        if isPlainText {
            processedBody = decryptedBody.encodeHtml().ln2br()
        } else {
            processedBody = decryptedBody
        }
        return processedBody
    }

    private func parse(attachments: [MIMEAttachmentData], body: String) -> ([MimeAttachment], String) {
        var body = body
        var infos = [MimeAttachment]()
        for attachment in attachments {
            // Replace inline data
            if var contentID = attachment.cid {
                contentID = contentID.preg_replace("<", replaceto: "")
                contentID = contentID.preg_replace(">", replaceto: "")
                let type = "image/jpg" // cidPart.headers[.contentType]?.body ?? "image/jpg;name=\"unknown.jpg\""
                let encode = attachment.headers[.contentTransferEncoding]?.body ?? "base64"
                let rawBody = attachment.encoded(with: encode)
                body = body.preg_replace_none_regex(
                    "src=\"cid:\(contentID)\"",
                    replaceto: "src=\"data:\(type);\(encode),\(rawBody)\""
                )
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
