//
//  Message+Helper.swift
//  ProtonMail
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
import CoreData

extension Message {
    static func messageWithLocation (recipientList: String,
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
        message.toList = recipientList
        message.bccList = bccList
        message.ccList = ccList
        message.title = title
        message.passwordHint = passwordHint
        message.time = Date()
        message.isEncrypted = 1
        message.expirationOffset = Int32(expirationTimeInterval)
        message.messageStatus = 1
        message.setAsDraft()
        
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
