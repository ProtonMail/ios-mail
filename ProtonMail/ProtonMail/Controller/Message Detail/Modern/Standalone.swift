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
    
    init(message: Message) {
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
        
        self.showEmbedImage(message, body: self.body)
        
        if let expirationOffset = message.expirationTime?.timeIntervalSinceNow, expirationOffset > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(Int(expirationOffset))) { [weak self, message] in
                self?.reload(from: message)
            }
        }
    }
    
    internal func reload(from message: Message) {
        let temp = Standalone(message: message)

        self.header = temp.header
        self.attachments = temp.attachments
        self.remoteContentMode = temp.remoteContentMode
        self.divisions = temp.divisions
        
        self.showEmbedImage(message, body: temp.body)
    }

    // TODO: taken from old MessageViewController
    private var purifiedBodyLock: Int = 0
    private func showEmbedImage(_ message: Message, body: String) {
        var updatedBody = body
        
        guard let atts = message.attachments.allObjects as? [Attachment], !atts.isEmpty else {
            self.body = updatedBody
            return
        }
        
        var checkCount = atts.count
        for att in atts {
            if let content_id = att.contentID(), !content_id.isEmpty && att.inline() {
                att.base64AttachmentData({ (based64String) in
                    if !based64String.isEmpty {
                        objc_sync_enter(self.purifiedBodyLock)
                        updatedBody = updatedBody.stringBySetupInlineImage("src=\"cid:\(content_id)\"", to: "src=\"data:\(att.mimeType);base64,\(based64String)\"" )
                        objc_sync_exit(self.purifiedBodyLock)
                        checkCount = checkCount - 1
                        
                        if checkCount == 0 {
                            self.body = updatedBody
                        }

                    } else {
                        checkCount = checkCount - 1
                    }
                })
            } else {
                checkCount = checkCount - 1
            }
        }
    }
}
