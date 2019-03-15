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
    internal enum Divisions: Int {  // each division is perpresented by a single row in tableView
        case header = 0, attachments, body
        static let totalNumber = 3 // TODO: update when new Swift will be available
    }
    
    @objc internal dynamic var heightOfHeader: CGFloat = 0.0
    @objc internal dynamic var heightOfBody: CGFloat = 0.0
    @objc internal dynamic var heightOfAttachments: CGFloat = 0.0
    
    internal let divisionsCount: Int = Divisions.totalNumber
    internal let messageID: String
    @objc internal dynamic var body: String
    @objc internal dynamic var header: HeaderData
    @objc internal dynamic var attachments: [AttachmentInfo]
    
    init(message: Message) {
        // 1. header
        self.header = HeaderData(message: message, showShowImages: true) // FIXME show images does not belong here
        
        // 2. body
        do {
            self.body = try message.decryptBodyIfNeeded() ?? LocalString._unable_to_decrypt_message
        } catch let ex as NSError {
            PMLog.D("purifyEmailBody error : \(ex)")
            self.body = message.bodyToHtml()
        }
        
        // 3. attachments
        var atts: [AttachmentInfo] = (message.attachments.allObjects as? [Attachment])?.map(AttachmentNormal.init) ?? [] // normal
        atts.append(contentsOf: message.tempAtts ?? []) // inline
        self.attachments = atts
        
        // others
        self.messageID = message.messageID
    }
    
    internal func reload(from message: Message) {
        let temp = Standalone(message: message)
        
        self.header = temp.header
        self.body = temp.body
        self.attachments = temp.attachments
    }
}
