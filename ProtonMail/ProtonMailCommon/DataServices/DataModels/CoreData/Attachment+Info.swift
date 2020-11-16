//
//  Attachment+Info.swift
//  ProtonMail - Created on 1/3/19.
//
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.
    

import Foundation
import PromiseKit

@objc protocol AttachmentInfo : AnyObject {
    var fileName: String { get }
    var size : Int { get }
    var mimeType: String { get }
    var localUrl : URL? { get }
    
    var isDownloaded: Bool { get }
    var att : Attachment? { get }
}


class AttachmentInline : AttachmentInfo {
    var isDownloaded: Bool {
        get {
            return true
        }
    }
    
    var att : Attachment? {
        get {
            return nil
        }
    }
    
    var fileName: String
    var size : Int
    var mimeType: String
    var localUrl : URL?
    
    init(fnam: String, size: Int, mime: String, path: URL?) {
        self.fileName = fnam
        self.size = size
        self.mimeType = mime
        self.localUrl = path
    }
    
    func toAttachment(message: Message?, stripMetadata: Bool) -> Promise<Attachment?> {
        if let msg = message, let url = localUrl, let data = try? Data(contentsOf: url) {
            let ext = url.mimeType()
            let fileData = ConcreteFileData<Data>(name: fileName, ext: ext, contents: data)
            return fileData.contents.toAttachment(msg, fileName: fileData.name, type: fileData.ext, stripMetadata: stripMetadata)
        }
        return Promise.value(nil)
    }
}


class AttachmentNormal : AttachmentInfo {
    var fileName: String {
        get {
            return attachment.fileName
        }
    }
    
    var att : Attachment? {
        get {
            return attachment
        }
    }
    
    var localUrl : URL? {
        get {
            return attachment.localURL
        }
    }
    
    var size : Int {
        get {
            return self.attachment.fileSize.intValue
        }
    }
    var mimeType: String {
        get {
            return attachment.mimeType
        }
    }
    var isDownloaded: Bool {
        get {
            return attachment.downloaded
        }
    }
    
    var attachment: Attachment
    
    init(att: Attachment) {
        self.attachment = att
    }
}
