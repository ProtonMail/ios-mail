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

import ProtonCoreCrypto

class MessageDecrypter {
    typealias DecryptionOutput = (body: String, attachments: [MimeAttachment]?)

    typealias DecryptionAndVerificationOutput = (
        decryptionOutput: DecryptionOutput,
        signatureVerificationResult: SignatureVerificationResult
    )

    private let keyFactory: MessageDecrypterKeyFactory

    init(userDataSource: UserDataSource) {
        keyFactory = MessageDecrypterKeyFactory(userDataSource: userDataSource)
    }

    func decrypt(messageObject: Message) throws -> DecryptionOutput {
        let messageEntity = MessageEntity(messageObject)
        return try decrypt(message: messageEntity)
    }

    func decrypt(message: MessageEntity) throws -> DecryptionOutput {
        let output = try decryptAndVerify(message: message, verificationKeys: [])
        return output.decryptionOutput
    }

    func decryptAndVerify(
        message: MessageEntity,
        verificationKeys: [ArmoredKey]
    ) throws -> DecryptionAndVerificationOutput {
        let (decryptionKeyRing, keyRingWasCached) = try keyFactory.decryptionKeyRing(addressID: message.addressID)

        if message.isMultipartMixed {
            do {
                let messageData = try MailCrypto().decryptMIME(
                    encrypted: message.body,
                    publicKeys: verificationKeys,
                    decryptionKeyRing: decryptionKeyRing
                )
                let (body, attachments) = postProcessMIME(messageData: messageData)
                return ((body, attachments), messageData.signatureVerificationResult)
            } catch {
                SystemLogger.log(error: error, category: .encryption)
                // do not throw here, make a Hail Mary fallback to the non-MIME decryption method
            }
        }

        do {
            let (decryptedBody, signatureVerificationResult) = try MailCrypto().decryptNonMIME(
                encrypted: message.body,
                publicKeys: verificationKeys,
                decryptionKeyRing: decryptionKeyRing
            )
            let processedBody = postProcessNonMIME(decryptedBody: decryptedBody, isPlainText: message.isPlainText)
            return ((processedBody, nil), signatureVerificationResult)
        } catch {
            SystemLogger.log(error: error, category: .encryption)

            if keyRingWasCached {
                SystemLogger.log(
                    message: "Decryption failed while using a cached key ring, discarding...",
                    category: .encryption
                )
                keyFactory.removeKeyRingFromCache(addressID: message.addressID)
                return try decryptAndVerify(message: message, verificationKeys: verificationKeys)
            } else {
                throw error
            }
        }
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

    private func postProcessNonMIME(decryptedBody: String, isPlainText: Bool) -> String {
        if isPlainText {
            return decryptedBody.encodeHtml().ln2br()
        } else {
            return decryptedBody
        }
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

            guard let filename = attachment.getFilename()?.cleaningFilename() else {
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

    func setCaching(enabled: Bool) {
        keyFactory.setCaching(enabled: enabled)
    }
}
