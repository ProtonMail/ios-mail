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
        case header = 0, attachments, remoteContent, body
        static let totalNumber = 4 // TODO: update when new Swift will be available
    }
    
    internal let messageID: String
    @objc internal dynamic var body: String
    @objc internal dynamic var header: HeaderData
    @objc internal dynamic var attachments: [AttachmentInfo]
    
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
        if !self.attachments.isEmpty {
            self.divisions.append(.attachments)
        }
        if self.remoteContentModeObservable != WebContents.RemoteContentPolicy.allowed.rawValue {
            self.divisions.append(.remoteContent)
        }
        self.divisions.append(.body)
        
        // others
        self.messageID = message.messageID
        self.divisionsCount = self.divisions.count
        
        super.init()
    }
    
    internal func reload(from message: Message) {
        let temp = Standalone(message: message)

        self.header = temp.header
        self.body = temp.body
        self.attachments = temp.attachments
        self.remoteContentMode = temp.remoteContentMode
        self.divisions = temp.divisions
    }
}
