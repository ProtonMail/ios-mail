//
//  Attachment+Info.swift
//  Proton Mail - Created on 1/3/19.
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
import PromiseKit

class AttachmentInfo: Hashable, Equatable {
    let fileName: String
    let size: Int
    let mimeType: String
    let localUrl: URL?

    let isDownloaded: Bool
    let id: AttachmentID
    let isInline: Bool
    let objectID: ObjectID?
    let contentID: String?

    var type: AttachmentType {
        AttachmentType(mimeType: mimeType)
    }

    init(fileName: String,
         size: Int,
         mimeType: String,
         localUrl: URL?,
         isDownloaded: Bool,
         id: AttachmentID,
         isInline: Bool,
         objectID: ObjectID?,
         contentID: String?) {
        self.fileName = fileName
        self.size = size
        self.mimeType = mimeType
        self.localUrl = localUrl
        self.isDownloaded = isDownloaded
        self.id = id
        self.isInline = isInline
        self.objectID = objectID
        self.contentID = contentID
    }

    static func == (lhs: AttachmentInfo, rhs: AttachmentInfo) -> Bool {
        // `localUrl`, `objectID` and `isDownloaded` are not suitable to be used in Equatable and Hashable
        // since the value could be changed after downloading the data
        return lhs.fileName == rhs.fileName &&
        lhs.size == rhs.size &&
        lhs.mimeType == rhs.mimeType &&
        lhs.id == rhs.id &&
        lhs.contentID == rhs.contentID
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(fileName)
        hasher.combine(size)
        hasher.combine(mimeType)
        hasher.combine(id)
        hasher.combine(contentID)
    }
}

final class MimeAttachment: AttachmentInfo {
    let disposition: String?

    init(filename: String, size: Int, mime: String, path: URL?, disposition: String?) {
        self.disposition = disposition
        super.init(fileName: filename,
                   size: size,
                   mimeType: mime,
                   localUrl: path,
                   isDownloaded: true,
                   id: AttachmentID(UUID().uuidString),
                   isInline: disposition?.contains(check: "inline") ?? false,
                   objectID: nil,
                   contentID: nil)
    }

    func toAttachment(message: Message?, stripMetadata: Bool) -> Promise<Attachment?> {
        if let msg = message, let url = localUrl, let data = try? Data(contentsOf: url) {
            let ext = url.mimeType()
            let fileData = ConcreteFileData<Data>(name: fileName, ext: ext, contents: data)
            return fileData.contents.toAttachment(
                msg,
                fileName: fileData.name,
                type: fileData.ext,
                stripMetadata: stripMetadata,
                isInline: false
            )
        }
        return Promise.value(nil)
    }
}

final class AttachmentNormal: AttachmentInfo {
    init(_ attachment: AttachmentEntity) {
        super.init(fileName: attachment.name,
                   size: attachment.fileSize.intValue,
                   mimeType: attachment.rawMimeType,
                   localUrl: attachment.localURL,
                   isDownloaded: attachment.downloaded,
                   id: attachment.id,
                   isInline: attachment.isInline,
                   objectID: attachment.objectID,
                   contentID: attachment.getContentID())
    }
}
