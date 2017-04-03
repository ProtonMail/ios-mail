//
//  MessageHelper.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 6/18/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation
import CoreData


open class MessageHelper {
    
    static func messageWithLocation (
        _ location: MessageLocation,
        recipientList: String,
        bccList: String,
        ccList: String,
        title: String,
        encryptionPassword: String,
        passwordHint: String,
        expirationTimeInterval: TimeInterval,
        body: String,
        attachments: [Any]?,
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
                message.encryptBody(body, error: nil)
                if !encryptionPassword.isEmpty {
                    if let encryptedBody = try body.encryptWithPassphrase(encryptionPassword) {
                        message.isEncrypted = true
                        message.passwordEncryptedBody = encryptedBody
                    }
                }
                if let attachments = attachments {
                    for (index, attachment) in attachments.enumerated() {
                        if let image = attachment as? UIImage {
                            if let fileData = UIImagePNGRepresentation(image) {
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
        attachments: [Any]?)
    {
        if expirationTimeInterval > 0 {
            message.expirationTime = Date(timeIntervalSinceNow: expirationTimeInterval)
        }

            message.encryptBody(body, error: nil)
 
            //PMLog.D(" error: \(error)")
        
        
        //        if !encryptionPassword.isEmpty {
        //            if let encryptedBody = body.encryptWithPassphrase(encryptionPassword, error: &error) {
        //                message.isEncrypted = true
        //                message.passwordEncryptedBody = encryptedBody
        //            } else {
        //                PMLog.D(" encryption error: \(error)")
        //            }
        //        }
        //
        //        if let attachments = attachments {
        //            for (index, attachment) in enumerate(attachments) {
        //                if let image = attachment as? UIImage {
        //                    if let fileData = UIImagePNGRepresentation(image) {
        //                        let attachment = Attachment(context: context)
        //                        attachment.attachmentID = "0"
        //                        attachment.message = message
        //                        attachment.fileName = "\(index).png"
        //                        attachment.mimeType = "image/png"
        //                        attachment.fileData = fileData
        //                        attachment.fileSize = fileData.length
        //                        continue
        //                    }
        //                }
        //                let description = attachment.description ?? "unknown"
        //                PMLog.D(" unsupported attachment type \(description)")
        //            }
        //        }
    }

    
    static func contactsToAddresses (_ contacts : String!) -> String
    {
        var lists: [String] = []
        let recipients : [[String : String]] = contacts.parseJson()!
        for dict:[String : String] in recipients {
            
            let to = dict.getAddress()
            if !to.isEmpty  {
                lists.append(to)
            }
        }
        return lists.joined(separator: ",")
    }
}
