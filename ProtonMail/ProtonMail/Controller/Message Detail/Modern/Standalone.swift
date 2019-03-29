//
//  Standalone.swift
//  ProtonMail - Created on 14/03/2019.
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

/// ViewModel object representing one Message in a thread
class Standalone: NSObject {
    
    internal enum Divisions: Int { // TODO: refactor with OptionSet
        // each division is perpresented by a single row in tableView
        case header = 0, attachments, remoteContent, body, expiration
    }
    
    internal let messageID: String
    @objc internal dynamic var body: String
    @objc internal dynamic var header: HeaderData
    @objc internal dynamic var attachments: [AttachmentInfo]
    internal let expiration: Date?
    
    @objc internal dynamic var heightOfHeader: CGFloat = 0.0
    @objc internal dynamic var heightOfBody: CGFloat = 0.0
    @objc internal dynamic var heightOfAttachments: CGFloat = 0.0
    
    @objc internal dynamic var divisionsCount: Int
    private(set) var divisions: [Divisions] {
        didSet { self.divisionsCount = divisions.count }
    }
    
    @objc private(set) dynamic var remoteContentModeObservable: WebContents.RemoteContentPolicy.RawValue
    internal var remoteContentMode: WebContents.RemoteContentPolicy {
        get { return WebContents.RemoteContentPolicy(rawValue: self.remoteContentModeObservable)! }
        set {
            self.remoteContentModeObservable = newValue.rawValue
            if newValue == .allowed {
                self.divisions = self.divisions.filter { $0 != .remoteContent}
            }
        }
    }
    
    convenience init(message: Message) {
        self.init(message: message, embeddingImages: true)
    }
    
    init(message: Message, embeddingImages: Bool) {
        // 0. expiration
        self.expiration = message.expirationTime
        let expired = (self.expiration ?? .distantFuture).compare(Date()) == .orderedAscending
        
        // 1. header
        self.header = HeaderData(message: message)
        
        // 2. body
        var body = ""
        do {
            body = try message.decryptBodyIfNeeded() ?? LocalString._unable_to_decrypt_message
        } catch let ex as NSError {
            PMLog.D("purifyEmailBody error : \(ex)")
            body = message.bodyToHtml()
        }
        if expired {
            body = LocalString._message_expired
        }
        if !message.isDetailDownloaded {
            body = LocalString._loading_
        }
        self.body = body
        
        // 3. attachments
        var atts: [AttachmentInfo] = (message.attachments.allObjects as? [Attachment])?.map(AttachmentNormal.init) ?? [] // normal
        atts.append(contentsOf: message.tempAtts ?? []) // inline
        self.attachments = atts
        
        // 4. remote content policy
        // should not show Allow button if there is no remote content, even when global settings require
        self.remoteContentModeObservable = (sharedUserDataService.autoLoadRemoteImages || !body.hasImage())
                                    ? WebContents.RemoteContentPolicy.allowed.rawValue
                                    : WebContents.RemoteContentPolicy.disallowed.rawValue
        
        // 5. divisions
        self.divisions = []
        self.divisions.append(.header)
        if self.expiration != nil {
            self.divisions.append(.expiration)
        }
        if !self.attachments.isEmpty, !expired  {
            self.divisions.append(.attachments)
        }
        if self.remoteContentModeObservable != WebContents.RemoteContentPolicy.allowed.rawValue, !expired {
            self.divisions.append(.remoteContent)
        }
        self.divisions.append(.body)
        
        // others
        self.messageID = message.messageID
        self.divisionsCount = self.divisions.count
        
        super.init()
        
        if embeddingImages {
            self.showEmbedImage(message, body: self.body)
        }
        
        if let expirationOffset = message.expirationTime?.timeIntervalSinceNow, expirationOffset > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(Int(expirationOffset))) { [weak self, message] in
                self?.reload(from: message)
            }
        }
    }
    
    internal func reload(from message: Message) {
        let temp = Standalone(message: message, embeddingImages: false)

        self.header = temp.header
        self.attachments = temp.attachments
        self.remoteContentMode = temp.remoteContentMode
        self.body = temp.body
        self.divisions = temp.divisions
        
        self.showEmbedImage(message, body: temp.body)
    }

    private func showEmbedImage(_ message: Message, body: String) {
        var updatedBody = body
        
        guard message.isDetailDownloaded,
            let allAttachments = message.attachments.allObjects as? [Attachment],
            case let atts = allAttachments.filter({ $0.inline() && $0.contentID()?.isEmpty == false }), !atts.isEmpty else
        {
            return
        }
        
        var checkCount = atts.count
        let queue: DispatchQueue = .global(qos: .userInteractive)

        DispatchQueue.global(qos: .userInitiated).async {
            for att in atts {
                att.base64AttachmentData { [weak self] based64String in
                    let work = DispatchWorkItem {
                        if !based64String.isEmpty {
                            updatedBody = updatedBody.stringBySetupInlineImage("src=\"cid:\(att.contentID()!)\"", to: "src=\"data:\(att.mimeType);base64,\(based64String)\"" )
                        }
                        checkCount -= 1
                        if checkCount == 0 {
                            self?.body = updatedBody
                        }
                    }

                    queue.async(execute: work)
                }
            }
        }
    }
}
