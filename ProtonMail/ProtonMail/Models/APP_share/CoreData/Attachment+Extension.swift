//
//  Attachment+Extension.swift
//  Proton Mail
//
//
//  Copyright (c) 2019 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import Foundation
import CoreData
import PromiseKit
import Crypto
import ProtonCore_Crypto
import ProtonCore_DataModel

// TODO::fixme import header
extension Attachment {

    struct Attributes {
        static let entityName   = "Attachment"
        static let attachmentID = "attachmentID"
        static let isSoftDelete = "isSoftDeleted"
        static let message = "message"
    }
    convenience init(context: NSManagedObjectContext) {
        self.init(entity: NSEntityDescription.entity(forEntityName: Attributes.entityName, in: context)!, insertInto: context)
    }

    override func prepareForDeletion() {
        super.prepareForDeletion()
        if let localURL = localURL {
            do {
                try FileManager.default.removeItem(at: localURL as URL)
            } catch {
            }
        }
    }

    var isUploaded: Bool {
        attachmentID != "0" && attachmentID != .empty
    }

    // Mark : functions
    func encrypt(byKey key: Key) throws -> (Data, URL)? {
        if let clearData = self.fileData, localURL == nil {
            try writeToLocalURL(data: clearData)
            self.fileData = nil
        }
        guard let localURL = self.localURL else {
            return nil
        }

        var error: NSError?
        let key = CryptoNewKeyFromArmored(key.publicKey, &error)
        if let err = error {
            throw err
        }

        let keyRing = CryptoNewKeyRing(key, &error)
        if let err = error {
            throw err
        }

        guard let aKeyRing = keyRing else {
            return nil
        }

        let cipherURL = localURL.appendingPathExtension("cipher")
        let keyPacket = try AttachmentStreamingEncryptor.encryptStream(localURL, cipherURL, aKeyRing, 2_000_000)

        return (keyPacket, cipherURL)
    }

    func sign(byKey key: Key, userKeys: [Data], passphrase: String) -> Data? {
        do {
            let addressKeyPassphrase = try MailCrypto.getAddressKeyPassphrase(
                userKeys: userKeys,
                passphrase: passphrase,
                key: key
            )
            let signature: String
            if let fileData = fileData {
                signature = try fileData.signAttachmentNonOptional(
                    byPrivKey: key.privateKey,
                    passphrase: addressKeyPassphrase
                )
            } else if let localURL = localURL {
                let fileData = try Data(contentsOf: localURL)
                signature = try Crypto.signDetachedNonOptional(
                    plainData: fileData,
                    privateKey: key.privateKey,
                    passphrase: addressKeyPassphrase
                )
            } else {
                return nil
            }
            var error: NSError?
            let data = ArmorUnarmor(signature, &error)
            if error != nil {
                return nil
            }

            return data
        } catch {
            return nil
        }
    }

    func getSession(keys: [Data], mailboxPassword: String) throws -> SymmetricKey? {
        guard let keyPacket = self.keyPacket else {
            return nil // TODO:: error throw
        }
        let passphrase = self.message.cachedPassphrase ?? mailboxPassword
        guard let data: Data = Data(base64Encoded: keyPacket, options: NSData.Base64DecodingOptions(rawValue: 0)) else {
            return nil // TODO:: error throw
        }

        let sessionKey = try data.getSessionFromPubKeyPackage(passphrase, privKeys: keys)
        return sessionKey
    }

    func getSession(userKey: [Data], keys: [Key], mailboxPassword: String) throws -> SymmetricKey? {
        guard let keyPacket = self.keyPacket else {
            return nil
        }
        let passphrase = self.message.cachedPassphrase ?? mailboxPassword
        let data: Data = Data(base64Encoded: keyPacket, options: NSData.Base64DecodingOptions(rawValue: 0))!

        let sessionKey = try data.getSessionFromPubKeyPackage(userKeys: userKey, passphrase: passphrase, keys: keys)
        return sessionKey
    }

    func base64DecryptAttachment(userInfo: UserInfo, passphrase: String) -> String {
        let userPrivKeys = userInfo.userPrivateKeysArray
        let addrPrivKeys = userInfo.addressKeys

        if let localURL = self.localURL {
            if let data: Data = try? Data(contentsOf: localURL as URL) {
                do {
                    if let key_packet = self.keyPacket {
                        if let keydata: Data = Data(base64Encoded: key_packet, options: NSData.Base64DecodingOptions(rawValue: 0)) {
                            if let decryptData =
                                userInfo.isKeyV2 ?
                                    try data.decryptAttachment(keyPackage: keydata,
                                                               userKeys: userPrivKeys,
                                                               passphrase: passphrase,
                                                               keys: addrPrivKeys) :
                                    try data.decryptAttachmentNonOptional(keydata,
                                                                          passphrase: passphrase,
                                                                          privKeys: addrPrivKeys.binPrivKeysArray) {
                                let strBase64: String = decryptData.base64EncodedString(options: .lineLength64Characters)
                                return strBase64
                            }
                        }
                    }
                } catch {
                }
            } else if let data = self.fileData, data.count > 0 {
                do {
                    if let key_packet = self.keyPacket {
                        if let keydata: Data = Data(base64Encoded: key_packet, options: NSData.Base64DecodingOptions(rawValue: 0)) {
                            if let decryptData =
                                userInfo.isKeyV2 ?
                                    try data.decryptAttachment(keyPackage: keydata,
                                                               userKeys: userPrivKeys,
                                                               passphrase: passphrase,
                                                               keys: addrPrivKeys) :
                                    try data.decryptAttachmentNonOptional(keydata,
                                                                          passphrase: passphrase,
                                                                          privKeys: addrPrivKeys.binPrivKeysArray) {
                                let strBase64: String = decryptData.base64EncodedString(options: .lineLength64Characters)
                                return strBase64
                            }
                        }
                    }
                } catch {
                }
            }
        }

        if let data = self.fileData {
            let strBase64: String = data.base64EncodedString(options: .lineLength64Characters)
            return strBase64
        }
        return ""
    }

    func inline() -> Bool {
        guard let headerInfo = self.headerInfo else {
            return false
        }

        let headerObject = headerInfo.parseObject()
        guard let inlineCheckString = headerObject["content-disposition"] else {
            return false
        }

        if inlineCheckString.contains("inline") {
            return true
        }
        return false
    }

    func contentID() -> String? {
        guard let headerInfo = self.headerInfo else {
            return nil
        }

        let headerObject = headerInfo.parseObject()
        guard let inlineCheckString = headerObject["content-id"] else {
            return nil
        }

        let outString = inlineCheckString.preg_replace("[<>]", replaceto: "")

        return outString
    }

    func disposition() -> String {
        guard let headerInfo = self.headerInfo else {
            return "attachment"
        }

        let headerObject = headerInfo.parseObject()
        guard let inlineCheckString = headerObject["content-disposition"] else {
            return "attachment"
        }

        let outString = inlineCheckString.preg_replace("[<>]", replaceto: "")

        return outString
    }

    func setupHeaderInfo(isInline: Bool, contentID: String?) {
        let disposition = isInline ? "inline": "attachment"
        let id = contentID ?? UUID().uuidString
        self.headerInfo = "{ \"content-disposition\": \"\(disposition)\",  \"content-id\": \"\(id)\" }"
    }

    func writeToLocalURL(data: Data) throws {
        let writeURL = try FileManager.default.url(for: .cachesDirectory,
                                                   in: .userDomainMask,
                                                   appropriateFor: nil,
                                                   create: true)
            .appendingPathComponent(UUID().uuidString)
        try data.write(to: writeURL)
        self.localURL = writeURL
    }

    func cleanLocalURLs() {
        if let localURL = localURL {
            try? FileManager.default.removeItem(at: localURL)
            self.localURL = nil
        }
        let cipherURL = localURL?.appendingPathExtension("cipher")
        if let cipherURL = cipherURL {
            try? FileManager.default.removeItem(at: cipherURL)
        }
    }
}

protocol AttachmentConvertible {
    var dataSize: Int { get }
    func toAttachment (_ message: Message, fileName: String, type: String, stripMetadata: Bool, isInline: Bool) -> Guarantee<Attachment?>
}

// THIS IS CALLED FOR CAMERA
extension UIImage: AttachmentConvertible {
    var dataSize: Int {
        return self.toData().count
    }
    private func toData() -> Data! {
        return self.jpegData(compressionQuality: 0)
    }
    func toAttachment (_ message: Message, fileName: String, type: String, stripMetadata: Bool, isInline: Bool) -> Guarantee<Attachment?> {
        return Guarantee { fulfill in
            guard let context = message.managedObjectContext else {
                assert(false, "Context improperly destroyed")
                fulfill(nil)
                return
            }
            if let fileData = self.toData() {
                context.perform {
                    let attachment = Attachment(context: context)
                    attachment.attachmentID = "0"
                    attachment.fileName = fileName
                    attachment.mimeType = "image/jpg"
                    attachment.fileData = nil
                    attachment.fileSize = fileData.count as NSNumber
                    attachment.isTemp = false
                    attachment.keyPacket = ""
                    let dataToWrite: Data
                    if self.containsExifMetadata(mimeType: attachment.mimeType) && stripMetadata {
                        dataToWrite = fileData.strippingExif()
                    } else {
                        dataToWrite = fileData
                    }
                    try? attachment.writeToLocalURL(data: dataToWrite)
                    if isInline {
                        attachment.setupHeaderInfo(isInline: true, contentID: fileName)
                    }

                    attachment.message = message

                    if userCachedStatus.realAttachments {
                        let attachments = message.attachments
                            .compactMap({ $0 as? Attachment })
                            .filter { !$0.inline() }
                        message.numAttachments = NSNumber(value: attachments.count)
                    } else {
                        let number = message.numAttachments.int32Value
                        let newNum = number > 0 ? number + 1 : 1
                        message.numAttachments = NSNumber(value: max(newNum, Int32(message.attachments.count)))
                    }
                    attachment.order = Int32(message.attachments.count)
                    _ = context.saveUpstreamIfNeeded()
                    fulfill(attachment)
                }
            }
        }
    }
}

// THIS IS CALLED FOR INLINE AND PHOTO_LIBRARY AND DOCUMENT
extension Data: AttachmentConvertible {
    var dataSize: Int {
        return self.count
    }

    func toAttachment (_ message: Message, fileName: String, type: String, stripMetadata: Bool, isInline: Bool = false) -> Guarantee<Attachment?> {
        return Guarantee { fulfill in
            guard let context = message.managedObjectContext else {
                assert(false, "Context improperly destroyed")
                fulfill(nil)
                return
            }
            context.perform {
                let attachment = Attachment(context: context)
                attachment.attachmentID = "0"
                attachment.fileName = fileName
                attachment.mimeType = type
                attachment.fileData = nil
                attachment.fileSize = self.count as NSNumber
                attachment.isTemp = false
                attachment.keyPacket = ""
                let dataToWrite: Data
                if containsExifMetadata(mimeType: attachment.mimeType) && stripMetadata {
                    dataToWrite = self.strippingExif()
                } else {
                    dataToWrite = self
                }
                try? attachment.writeToLocalURL(data: dataToWrite)
                attachment.message = message
                if isInline {
                    attachment.setupHeaderInfo(isInline: true, contentID: fileName)
                }
                attachment.message = message

                if userCachedStatus.realAttachments {
                    let attachments = message.attachments
                        .compactMap({ $0 as? Attachment })
                        .filter { !$0.inline() }
                    message.numAttachments = NSNumber(value: attachments.count)
                } else {
                    let number = message.numAttachments.int32Value
                    let newNum = number > 0 ? number + 1 : 1
                    message.numAttachments = NSNumber(value: Swift.max(newNum, Int32(message.attachments.count)))
                }
                _ = context.saveUpstreamIfNeeded()
                fulfill(attachment)
            }
        }
    }
}

// THIS IS CALLED FROM SHARE EXTENSION
extension URL: AttachmentConvertible {
    func toAttachment(_ message: Message, fileName: String, type: String, stripMetadata: Bool, isInline: Bool = false) -> Guarantee<Attachment?> {
        return Guarantee { fulfill in
            guard let context = message.managedObjectContext else {
                assert(false, "Context improperly destroyed")
                fulfill(nil)
                return
            }
            context.perform {
                let attachment = Attachment(context: context)
                attachment.attachmentID = "0"
                attachment.fileName = fileName
                attachment.mimeType = type
                attachment.fileData = nil
                attachment.fileSize = NSNumber(value: self.dataSize)
                attachment.isTemp = false
                attachment.keyPacket = ""
                if containsExifMetadata(mimeType: attachment.mimeType) && stripMetadata {
                    attachment.localURL = self.strippingExif()
                } else {
                    attachment.localURL = self
                }
                attachment.message = message
                if isInline {
                    attachment.setupHeaderInfo(isInline: true, contentID: fileName)
                }
                attachment.message = message

                if userCachedStatus.realAttachments {
                    let attachments = message.attachments
                        .compactMap({ $0 as? Attachment })
                        .filter { !$0.inline() }
                    message.numAttachments = NSNumber(value: attachments.count)
                } else {
                    let number = message.numAttachments.int32Value
                    let newNum = number > 0 ? number + 1 : 1
                    message.numAttachments = NSNumber(value: max(newNum, Int32(message.attachments.count)))
                }
                _ = context.saveUpstreamIfNeeded()
                fulfill(attachment)
            }
        }
    }

    var dataSize: Int {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: self.path),
            let size = attributes[.size] as? NSNumber else {
            return 0
        }
        return size.intValue
    }
}
