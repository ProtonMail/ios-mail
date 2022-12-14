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
import GoLibs
import ProtonCore_Crypto
import ProtonCore_DataModel
import ProtonCore_Log

protocol MessageDecrypterProtocol {
    typealias Output = (
        body: String,
        attachments: [MimeAttachment]?,
        signatureVerificationResult: SignatureVerificationResult
    )

    func decrypt(message: Message) throws -> String
    func decrypt(message: MessageEntity, verificationKeys: [ArmoredKey]) throws -> Output
    func copy(message: Message,
              copyAttachments: Bool,
              context: NSManagedObjectContext) -> Message
}

extension MessageDecrypterProtocol {
    func decrypt(message: MessageEntity) throws -> Output {
        try decrypt(message: message, verificationKeys: [])
    }
}

class MessageDecrypter: MessageDecrypterProtocol {
    private weak var userDataSource: UserDataSource?

    init(userDataSource: UserDataSource) {
        self.userDataSource = userDataSource
    }

    func decrypt(message: Message) throws -> String {
        let messageEntity = MessageEntity(message)
        let output = try decrypt(message: messageEntity, verificationKeys: [])
        if let tempAtts = output.attachments {
            message.tempAtts = tempAtts
        }
        return output.body
    }

    func decrypt(message: MessageEntity, verificationKeys: [ArmoredKey]) throws -> Output {
        let addressKeys = self.getAddressKeys(for: message.addressID.rawValue)
        if addressKeys.isEmpty {
            return (message.body, nil, .failure)
        }

        guard let dataSource = self.userDataSource else {
            throw MailCrypto.CryptoError.decryptionFailed
        }

        let decryptionKeys = MailCrypto.decryptionKeys(
            basedOn: addressKeys,
            mailboxPassword: dataSource.mailboxPassword,
            userKeys: dataSource.userPrivateKeys
        )

        if message.isMultipartMixed {
            do {
                let messageData = try MailCrypto().decryptMIME(
                    encrypted: message.body,
                    publicKeys: verificationKeys,
                    decryptionKeys: decryptionKeys
                )
                let (body, attachments) = postProcessMIME(messageData: messageData)
                return (body, attachments, messageData.signatureVerificationResult)
            } catch {
                // NOTE, decryption function will be called multiple times
                // Reports on the Sentry could be triple than real situation
                Analytics.shared.sendError(
                    .decryptMIMEFailed(error: "\(error)",
                                       messageID: message.messageID.rawValue)

                )
                assertionFailure("\(error)")
                // do not throw here, make a Hail Mary fallback to the non-MIME decryption method
            }
        }

        let decrypted = try Crypto().decryptVerify(
            encrypted: message.body,
            publicKeys: verificationKeys.compactMap { try? $0.unArmor().value },
            privateKeys: decryptionKeys.map { ($0.privateKey.value, $0.passphrase.value) },
            verifyTime: CryptoGetUnixTime()
        )
        let (processedBody, verificationResult) = try postProcessNonMIME(
            decrypted: decrypted,
            isPlainText: message.isPlainText,
            hasVerificationKeys: !verificationKeys.isEmpty
        )
        return (processedBody, nil, verificationResult)
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

    private func postProcessNonMIME(
        decrypted: ExplicitVerifyMessage,
        isPlainText: Bool,
        hasVerificationKeys: Bool
    ) throws -> (String, SignatureVerificationResult) {
        guard let decryptedBody = decrypted.message?.getString() else {
            throw MailCrypto.CryptoError.decryptionFailed
        }

        let processedBody: String
        if isPlainText {
            processedBody = decryptedBody.encodeHtml().ln2br()
        } else {
            processedBody = decryptedBody
        }

        let signatureVerificationResult: SignatureVerificationResult

        if hasVerificationKeys {
            if let gopenpgpError = decrypted.signatureVerificationError {
                signatureVerificationResult = SignatureVerificationResult(gopenpgpOutput: gopenpgpError.status)
            } else {
                signatureVerificationResult = .success
            }
        } else {
            signatureVerificationResult = .signatureVerificationSkipped
        }

        return (processedBody, signatureVerificationResult)
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
            let symmetricKey = try attachment.getSession(
                userKeys: userData.userPrivateKeys,
                keys: userData.addressKeys,
                mailboxPassword: userData.mailboxPassword
            )

            guard let sessionPack = symmetricKey,
                  let newkp = try sessionPack.sessionKey
                    .getKeyPackage(publicKey: key.publicKey,
                                   algo: sessionPack.algo.value) else {
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
        attachment.order = oldAttachment.order
        attachment.userID = self.userDataSource?.userID.rawValue ?? ""

        self.updateKeyPacketIfNeeded(attachment: attachment,
                                     addressID: newMessage.addressID)
        return attachment
    }
}
