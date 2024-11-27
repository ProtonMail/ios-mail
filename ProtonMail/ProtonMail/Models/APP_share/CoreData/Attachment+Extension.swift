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

import CoreData
import ProtonCoreCrypto
import ProtonCoreCryptoGoInterface
import ProtonCoreDataModel
import UIKit

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
        if let localURL = filePathByLocalURL() {
            do {
                try FileManager.default.removeItem(at: localURL as URL)
            } catch {
            }
        }
    }

    /// Application folder could be changed by system.
    /// When this happens, original localURL can no longer be used.
    /// Assemble new path with original localURL.
    func filePathByLocalURL() -> URL? {
        if ProcessInfo.isRunningUnitTests {
            // PrepareSendMetadataTests
            return localURL
        }
        #if APP_EXTENSION
        // Share extension doesn't have recovery situation
        // Also its path is different from main app
        return localURL
        #else
        guard let localURL = self.localURL else { return nil }

        let nameUUID = localURL.deletingPathExtension().lastPathComponent
        do {
            let writeURL = try FileManager.default.url(
                for: .cachesDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            ).appendingPathComponent(String(nameUUID))
            return writeURL
        } catch {
            return nil
        }
        #endif
    }

    var isUploaded: Bool {
        attachmentID != "0" && attachmentID != .empty
    }

    // Mark : functions
    func getSession(userKeys: [ArmoredKey], keys: [Key], mailboxPassword: Passphrase) throws -> SessionKey? {
        guard let keyPacket = self.keyPacket else {
            return nil
        }
        let passphrase = self.message.cachedPassphrase ?? mailboxPassword
        let data: Data = Data(base64Encoded: keyPacket, options: NSData.Base64DecodingOptions(rawValue: 0))!

        let sessionKey = try data.getSessionFromPubKeyPackage(userKeys: userKeys, passphrase: passphrase, keys: keys)
        return sessionKey
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
        guard let localURL = filePathByLocalURL() else { return }
        try? FileManager.default.removeItem(at: localURL)

        let cipherURL = localURL.appendingPathExtension("cipher")
        try? FileManager.default.removeItem(at: cipherURL)

        self.localURL = nil
    }
}

protocol AttachmentConvertible {
    var dataSize: Int { get }
    func toAttachment(
        _ context: NSManagedObjectContext,
        fileName: String,
        type: String,
        stripMetadata: Bool,
        cid: String?,
        isInline: Bool
    ) -> AttachmentEntity
}

// THIS IS CALLED FOR CAMERA
extension UIImage: AttachmentConvertible {
    var dataSize: Int {
        toData().count
    }
    private func toData() -> Data {
        jpegData(compressionQuality: 0)!
    }
    func toAttachment(
        _ context: NSManagedObjectContext,
        fileName: String,
        type: String,
        stripMetadata: Bool,
        cid: String?,
        isInline: Bool
    ) -> AttachmentEntity {
        let fileData = toData()

        return context.performAndWait {
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
                attachment.setupHeaderInfo(isInline: true, contentID: UUID().uuidString)
            }

            _ = context.saveUpstreamIfNeeded()
            return .init(attachment)
        }
    }
}

// THIS IS CALLED FOR INLINE AND PHOTO_LIBRARY AND DOCUMENT
extension Data: AttachmentConvertible {
    var dataSize: Int {
        return self.count
    }

    func toAttachment(
        _ context: NSManagedObjectContext,
        fileName: String,
        type: String,
        stripMetadata: Bool,
        cid: String? = nil,
        isInline: Bool = false
    ) -> AttachmentEntity {
        context.performAndWait {
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
            if isInline {
                attachment.setupHeaderInfo(isInline: true, contentID: cid ?? UUID().uuidString)
            }
            _ = context.saveUpstreamIfNeeded()
            return .init(attachment)
        }
    }
}

// THIS IS CALLED FROM SHARE EXTENSION
extension URL: AttachmentConvertible {
    func toAttachment(
        _ context: NSManagedObjectContext,
        fileName: String,
        type: String,
        stripMetadata: Bool,
        cid: String? = nil,
        isInline: Bool = false
    ) -> AttachmentEntity {
        context.performAndWait {
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

            if isInline {
                attachment.setupHeaderInfo(isInline: true, contentID: UUID().uuidString)
            }
            _ = context.saveUpstreamIfNeeded()
            return .init(attachment)
        }
    }

    var dataSize: Int {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: self.path),
            let size = attributes[.size] as? NSNumber else {
            return 0
        }
        return size.intValue
    }

    func toBase64() -> String? {
        guard let data = try? Data(contentsOf: self) else { return nil }
        return data.base64EncodedString()
    }
}
