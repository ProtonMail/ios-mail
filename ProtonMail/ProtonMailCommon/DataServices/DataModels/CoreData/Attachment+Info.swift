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

protocol AttachmentInfo : AnyObject {
    var fileName: String { get }
    var size: Int { get }
    var mimeType: String { get }
    var localUrl: URL? { get }

    var isDownloaded: Bool { get }
    var id: AttachmentID? { get }
    var isInline: Bool { get }
    var objectID: ObjectID? { get }
    var contentID: String? { get }
}

class MimeAttachment: AttachmentInfo {
    var isDownloaded: Bool {
        get {
            return true
        }
    }

    var isInline: Bool {
        self.disposition?.contains(check: "inline") ?? false
    }

    let id: AttachmentID? = AttachmentID(UUID().uuidString)
    let objectID: ObjectID? = nil
    
    var fileName: String
    var size: Int
    var mimeType: String
    var localUrl: URL?
    let disposition: String?
    let contentID: String? = nil
    
    init(filename: String, size: Int, mime: String, path: URL?, disposition: String?) {
        self.fileName = filename
        self.size = size
        self.mimeType = mime
        self.localUrl = path
        self.disposition = disposition
    }

    func toAttachment(message: Message?, stripMetadata: Bool) -> Promise<Attachment?> {
        if let msg = message, let url = localUrl, let data = try? Data(contentsOf: url) {
            let ext = url.mimeType()
            let fileData = ConcreteFileData<Data>(name: fileName, ext: ext, contents: data)
            return fileData.contents.toAttachment(msg, fileName: fileData.name, type: fileData.ext, stripMetadata: stripMetadata, isInline: false)
        }
        return Promise.value(nil)
    }
}


class AttachmentNormal: AttachmentInfo {
    let fileName: String
    let id: AttachmentID?
    let objectID: ObjectID?
    let isInline: Bool
    let localUrl: URL?
    let size: Int
    let mimeType: String
    let isDownloaded: Bool
    let contentID: String?
    
    init(_ attachment: AttachmentEntity) {
        self.fileName = attachment.name
        self.id = attachment.id
        self.isInline = attachment.isInline
        self.localUrl = attachment.localURL
        self.size = attachment.fileSize.intValue
        self.mimeType = attachment.rawMimeType
        self.isDownloaded = attachment.downloaded
        self.objectID = attachment.objectID
        self.contentID = attachment.getContentID()
    }
}
