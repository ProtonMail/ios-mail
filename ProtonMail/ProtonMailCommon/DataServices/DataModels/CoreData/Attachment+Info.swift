//
//  Attachment+Info.swift
//  ProtonMail - Created on 1/3/19.
//
//
//  The MIT License
//
//  Copyright (c) 2018 Proton Technologies AG
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
    

import Foundation

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
    
    func toAttachment(message: Message?, stripMetadata: Bool) -> Attachment? {
        if let msg = message, let url = localUrl, let data = try? Data(contentsOf: url) {
            let ext = url.mimeType()
            let fileData = ConcreteFileData<Data>(name: fileName, ext: ext, contents: data)
            return fileData.contents.toAttachment(msg, fileName: fileData.name, type: fileData.ext, stripMetadata: stripMetadata)
        }
        return nil
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
