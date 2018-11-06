//
//  Message+Helper.swift
//  ProtonMail
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
import CoreData

extension Message {
    static func messageWithLocation (_ location: MessageLocation,
                                     recipientList: String,
                                     bccList: String,
                                     ccList: String,
                                     title: String,
                                     encryptionPassword: String,
                                     passwordHint: String,
                                     expirationTimeInterval: TimeInterval,
                                     body: String,
                                     attachments: [Any]?,
                                     mailbox_pwd: String,
                                     inManagedObjectContext context: NSManagedObjectContext) -> Message {
        
        let message = Message(context: context)
        message.messageID = UUID().uuidString
        message.location = location
        message.recipientList = recipientList
        message.bccList = bccList
        message.ccList = ccList
        message.title = title
        message.passwordHint = passwordHint
        message.time = Date()
        message.isEncrypted = 1
        message.expirationOffset = Int32(expirationTimeInterval)
        message.messageStatus = 1
        
        if expirationTimeInterval > 0 {
            message.expirationTime = Date(timeIntervalSinceNow: expirationTimeInterval)
        }
        
        do {
            message.encryptBody(body, mailbox_pwd: mailbox_pwd, error: nil)
            if !encryptionPassword.isEmpty {
                if let encryptedBody = try body.encrypt(withPwd: encryptionPassword) {
                    message.isEncrypted = true
                    message.passwordEncryptedBody = encryptedBody
                }
            }
            if let attachments = attachments {
                for (index, attachment) in attachments.enumerated() {
                    if let image = attachment as? UIImage {
                        if let fileData = image.pngData() {
                            let attachment = Attachment(context: context)
                            attachment.attachmentID = "0"
                            attachment.message = message
                            attachment.fileName = "\(index).png"
                            attachment.mimeType = "image/png"
                            attachment.fileData = fileData
                            attachment.fileSize = fileData.count as NSNumber
                            continue
                        }
                    }
                }
            }
        } catch {
            PMLog.D("error: \(error)")
        }
        return message
    }
    
    static func updateMessage (_ message: Message ,
                               expirationTimeInterval: TimeInterval,
                               body: String,
                               attachments: [Any]?,
                               mailbox_pwd: String) {
        if expirationTimeInterval > 0 {
            message.expirationTime = Date(timeIntervalSinceNow: expirationTimeInterval)
        }
        message.encryptBody(body, mailbox_pwd: mailbox_pwd, error: nil)
    }
    
    
    static func contactsToAddresses (_ contacts : String!) -> String {
        var lists: [String] = []
        if let recipients : [[String : Any]] = contacts.parseJson() {
            for dict:[String : Any] in recipients {
                let to = dict.getAddress()
                if !to.isEmpty  {
                    lists.append(to)
                }
            }
        }
        return lists.joined(separator: ",")
    }
    
    static func contactsToAddressesArray (_ contacts : String!) -> [String] {
        var lists: [String] = []
        if let recipients : [[String : Any]] = contacts.parseJson() {
            for dict:[String : Any] in recipients {
                let to = dict.getAddress()
                if !to.isEmpty  {
                    lists.append(to)
                }
            }
        }
        return lists
    }
}
