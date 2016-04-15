//
//  MessageHelper.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 6/18/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation




public class MessageHelper {
    
    static func messageWithLocation (
        location: MessageLocation,
        recipientList: String,
        bccList: String,
        ccList: String,
        title: String,
        encryptionPassword: String,
        passwordHint: String,
        expirationTimeInterval: NSTimeInterval,
        body: String,
        attachments: [AnyObject]?,
        inManagedObjectContext context: NSManagedObjectContext) -> Message {
            let message = Message(context: context)
            message.messageID = NSUUID().UUIDString
            message.location = location
            message.recipientList = recipientList
            message.bccList = bccList
            message.ccList = ccList
            message.title = title
            message.passwordHint = passwordHint
            message.time = NSDate()
            message.isEncrypted = 1
            message.expirationOffset = Int32(expirationTimeInterval)
            message.messageStatus = 1
            
            if expirationTimeInterval > 0 {
                message.expirationTime = NSDate(timeIntervalSinceNow: expirationTimeInterval)
            }
            
            var error: NSError?
            message.encryptBody(body, error: &error)
            
            if error != nil {
                NSLog("\(__FUNCTION__) error: \(error)")
            }
            
            if !encryptionPassword.isEmpty {
                if let encryptedBody = body.encryptWithPassphrase(encryptionPassword, error: &error) {
                    message.isEncrypted = true
                    message.passwordEncryptedBody = encryptedBody
                } else {
                    NSLog("\(__FUNCTION__) encryption error: \(error)")
                }
            }
            
            if let attachments = attachments {
                for (index, attachment) in enumerate(attachments) {
                    if let image = attachment as? UIImage {
                        if let fileData = UIImagePNGRepresentation(image) {
                            let attachment = Attachment(context: context)
                            attachment.attachmentID = "0"
                            attachment.message = message
                            attachment.fileName = "\(index).png"
                            attachment.mimeType = "image/png"
                            attachment.fileData = fileData
                            attachment.fileSize = fileData.length
                            continue
                        }
                    }
                    
                    let description = attachment.description ?? "unknown"
                    NSLog("\(__FUNCTION__) unsupported attachment type \(description)")
                }
            }
            
            return message
    }
    
    static func updateMessage (message: Message ,
        expirationTimeInterval: NSTimeInterval,
        body: String,
        attachments: [AnyObject]?)
    {
        if expirationTimeInterval > 0 {
            message.expirationTime = NSDate(timeIntervalSinceNow: expirationTimeInterval)
        }
        
        var error: NSError?
        message.encryptBody(body, error: &error)
        
        if error != nil {
            NSLog("\(__FUNCTION__) error: \(error)")
        }
        
        //        if !encryptionPassword.isEmpty {
        //            if let encryptedBody = body.encryptWithPassphrase(encryptionPassword, error: &error) {
        //                message.isEncrypted = true
        //                message.passwordEncryptedBody = encryptedBody
        //            } else {
        //                NSLog("\(__FUNCTION__) encryption error: \(error)")
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
        //
        //                let description = attachment.description ?? "unknown"
        //                NSLog("\(__FUNCTION__) unsupported attachment type \(description)")
        //            }
        //        }
    }
    
    
    static func contactsToAddresses (contacts : String!) -> String
    {
        var lists: [String] = []
        let recipients : [[String : String]] = contacts.parseJson()!
        for dict:[String : String] in recipients {
            
            let to = dict.getAddress()
            if !to.isEmpty  {
                lists.append(to)
            }
        }
        return ",".join(lists)
    }
}