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

import Foundation

struct AttachmentEntity: Hashable, Equatable {

    // MARK: Properties
    private(set) var headerInfo: String?
    private(set) var id: AttachmentID
    private(set) var keyPacket: String?
    private(set) var rawMimeType: String
    private(set) var attachmentType: AttachmentType
    private(set) var name: String
    private(set) var userID: UserID
    private(set) var messageID: MessageID

    // MARK: Local properties
    /// Added in version 1.12.5 to handle the attachment deletion failed issue
    private(set) var isSoftDeleted: Bool
    private(set) var fileData: Data?
    private(set) var fileSize: NSNumber
    private(set) var localURL: URL?
    private(set) var isTemp: Bool
    private(set) var keyChanged: Bool
    let objectID: ObjectID
    let order: Int
    let contentId: String?
}

extension AttachmentEntity {
    init(_ attachment: Attachment) {
        self.headerInfo = attachment.headerInfo
        self.id = AttachmentID(attachment.attachmentID)
        self.keyPacket = attachment.keyPacket
        self.rawMimeType = attachment.mimeType
        self.attachmentType = AttachmentType(mimeType: attachment.mimeType)
        self.name = attachment.fileName
        self.userID = UserID(attachment.userID)
        self.messageID = MessageID(attachment.message.messageID)
        self.isSoftDeleted = attachment.isSoftDeleted
        self.fileData = attachment.fileData
        self.fileSize = attachment.fileSize
        self.localURL = attachment.localURL
        self.isTemp = attachment.isTemp
        self.keyChanged = attachment.keyChanged
        self.objectID = .init(rawValue: attachment.objectID)
        self.order = Int(attachment.order)
        self.contentId = attachment.contentID()
    }

    static func convert(from attachments: NSSet) -> [AttachmentEntity] {
        return attachments.allObjects.compactMap { item in
            guard let data = item as? Attachment else { return nil }
            return AttachmentEntity(data)
        }.sorted { $0.order < $1.order }
    }
}

extension AttachmentEntity {
    var downloaded: Bool {
        guard let url = localURL else { return false }
        return FileManager.default.fileExists(atPath: url.path)
    }

    func getContentID() -> String? {
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

    var isInline: Bool {
        guard let headerInfo = self.headerInfo else { return false }

        let headerObject = headerInfo.parseObject()
        guard let inlineCheckString = headerObject["content-disposition"] else {
            return false
        }

        if inlineCheckString.contains("inline") {
            return true
        }
        return false
    }
}
