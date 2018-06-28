//
//  AttachmentExtension.swift
//  ProtonMail
//
//
// Copyright 2015 ArcTouch, Inc.
// All rights reserved.
//
// This file, its contents, concepts, methods, behavior, and operation
// (collectively the "Software") are protected by trade secret, patent,
// and copyright laws. The use of the Software is governed by a license
// agreement. Disclosure of the Software to third parties, in any form,
// in whole or in part, is expressly prohibited except as authorized by
// the license agreement.
//

import Foundation
import CoreData
import PromiseKit
import AwaitKit
import Pm

extension Attachment {
    
    struct Attributes {
        static let entityName   = "Attachment"
        static let attachmentID = "attachmentID"
    }
    convenience init(context: NSManagedObjectContext) {
        self.init(entity: NSEntityDescription.entity(forEntityName: Attributes.entityName, in: context)!, insertInto: context)
    }
    
    override func prepareForDeletion() {
        super.prepareForDeletion()
        if let localURL = localURL {
            do {
                try FileManager.default.removeItem(at: localURL as URL)
            } catch let ex as NSError {
                PMLog.D("Could not delete \(localURL) with error: \(ex)")
            }
        }
    }
    
    // MARK: - This is private functions
    
    var downloaded: Bool {
        return localURL != nil
    }
    
    fileprivate var passphrase: String {
        return sharedUserDataService.mailboxPassword ?? ""
    }
    
    
    // Mark : public functions
    func encrypt(byAddrID sender_address_id : String, mailbox_pwd: String) -> PmEncryptedSplit? {
        do {
            guard let out =  try fileData?.encryptAttachment(sender_address_id, fileName: self.fileName, mailbox_pwd: mailbox_pwd) else {
                return nil
            }
            return out
        } catch {
            return nil
        }
    }
    
    func getSession() throws -> Data? {
        if self.keyPacket == nil {
            return nil
        }
        let data: Data = Data(base64Encoded: self.keyPacket!, options: NSData.Base64DecodingOptions(rawValue: 0))!
        let sessionKey = try data.getSessionFromPubKeyPackage(passphrase)
        return sessionKey?.session()
    }
    
    func fetchAttachment(_ downloadTask: ((URLSessionDownloadTask) -> Void)?, completion:((URLResponse?, URL?, NSError?) -> Void)?) {
        sharedMessageDataService.fetchAttachmentForAttachment(self, downloadTask: downloadTask, completion: completion)
    }
    
    
    typealias base64AttachmentDataComplete = (_ based64String : String) -> Void
    
    func base64AttachmentData(_ complete : @escaping base64AttachmentDataComplete) {
        
        if let localURL = self.localURL, FileManager.default.fileExists(atPath: localURL.path, isDirectory: nil) {
            complete( self.base64DecryptAttachment() )
            return
        }
        
        if let data = self.fileData, data.count > 0 {
            complete( self.base64DecryptAttachment() )
            return
        }
        
        self.localURL = nil
        sharedMessageDataService.fetchAttachmentForAttachment(self, downloadTask: { (taskOne : URLSessionDownloadTask) -> Void in }, completion: { (_, url, error) -> Void in
            self.localURL = url;
            complete( self.base64DecryptAttachment() )
            if error != nil {
                PMLog.D("\(String(describing: error))")
            }
        })
    }
    
    func fetchAttachmentBody() -> Promise<String> {
        return Promise { seal in
            async {
                if let localURL = self.localURL, FileManager.default.fileExists(atPath: localURL.path, isDirectory: nil) {
                    seal.fulfill(self.base64DecryptAttachment())
                    return
                }
                
                if let data = self.fileData, data.count > 0 {
                    seal.fulfill(self.base64DecryptAttachment())
                    return
                }
                
                self.localURL = nil
                sharedMessageDataService.fetchAttachmentForAttachment(self, downloadTask: { (taskOne : URLSessionDownloadTask) -> Void in }, completion: { (_, url, error) -> Void in
                    self.localURL = url;
                    seal.fulfill(self.base64DecryptAttachment())
                    if error != nil {
                        PMLog.D("\(String(describing: error))")
                    }
                })
            }
            
        }
    }
    
    func base64DecryptAttachment() -> String {
        if let localURL = self.localURL {
            if let data : Data = try? Data(contentsOf: localURL as URL) {
                do {
                    if let key_packet = self.keyPacket {
                        if let keydata: Data = Data(base64Encoded:key_packet, options: NSData.Base64DecodingOptions(rawValue: 0)) {
                            if let decryptData = try data.decryptAttachment(keydata, passphrase: sharedUserDataService.mailboxPassword!) {
                                let strBase64:String = decryptData.base64EncodedString(options: .lineLength64Characters)
                                return strBase64
                            }
                        }
                    }
                } catch let ex as NSError{
                    PMLog.D("\(ex)")
                }
            } else if let data = self.fileData, data.count > 0 {
                do {
                    if let key_packet = self.keyPacket {
                        if let keydata: Data = Data(base64Encoded:key_packet, options: NSData.Base64DecodingOptions(rawValue: 0)) {
                            if let decryptData = try data.decryptAttachment(keydata, passphrase: sharedUserDataService.mailboxPassword!) {
                                let strBase64:String = decryptData.base64EncodedString(options: .lineLength64Characters)
                                return strBase64
                            }
                        }
                    }
                } catch let ex as NSError{
                    PMLog.D("\(ex)")
                }
            }
        }
        
        
        if let data = self.fileData {
            let strBase64:String = data.base64EncodedString(options: .lineLength64Characters)
            return strBase64
        }
        return ""
    }
    
    func inline() -> Bool {
        guard let headerInfo = self.headerInfo else {
            return false
        }
        
        let headerObject = headerInfo.parseObject()
        guard let inlineCheckString = headerObject["content-disposition"] else {
            return false
        }
        
        if inlineCheckString.contains("inline") {
            return true
        }
        return false
    }
    
    func contentID() -> String? {
        guard let headerInfo = self.headerInfo else {
            return nil
        }
        
        let headerObject = headerInfo.parseObject()
        guard let inlineCheckString = headerObject["content-id"] else {
            return nil
        }
        
        let outString = inlineCheckString.preg_replace("[<>]", replaceto: "")
        
        return outString
    }
}

protocol AttachmentConvertible {
    func toAttachment (_ message:Message, fileName : String, type:String) -> Attachment?
}

extension UIImage: AttachmentConvertible {
    func toAttachment (_ message:Message, fileName : String, type:String) -> Attachment? {
        if let fileData = UIImageJPEGRepresentation(self, 0) {
            if let context = message.managedObjectContext {
                let attachment = Attachment(context: context)
                attachment.attachmentID = "0"
                attachment.fileName = fileName
                attachment.mimeType = "image/jpg"
                attachment.fileData = fileData
                attachment.fileSize = fileData.count as NSNumber
                attachment.isTemp = false
                attachment.keyPacket = ""
                attachment.localURL = nil
            
                attachment.message = message
                
                let number = message.numAttachments.int32Value
                let newNum = number > 0 ? number + 1 : 1
                message.numAttachments = NSNumber(value: newNum)
                
                var error: NSError? = nil
                error = context.saveUpstreamIfNeeded()
                if error != nil {
                    PMLog.D("toAttachment () with error: \(String(describing: error))")
                }
                return attachment
            }
        }
        
        return nil
    }
}

extension Data: AttachmentConvertible {
    func toAttachment (_ message:Message, fileName : String) -> Attachment? {
        return self.toAttachment(message, fileName: fileName, type: "image/jpg")
    }
    
    func toAttachment (_ message:Message, fileName : String, type:String) -> Attachment? {
        let attachment = Attachment(context: message.managedObjectContext!)//TODO:: need check context nil or not instead of !
        attachment.attachmentID = "0"
        attachment.fileName = fileName
        attachment.mimeType = type
        attachment.fileData = self
        attachment.fileSize = self.count as NSNumber
        attachment.isTemp = false
        attachment.keyPacket = ""
        attachment.localURL = nil
        
        attachment.message = message
        
        let number = message.numAttachments.int32Value
        let newNum = number > 0 ? number + 1 : 1
        message.numAttachments = NSNumber(value: newNum)
        
        var error: NSError? = nil
        error = attachment.managedObjectContext?.saveUpstreamIfNeeded()
        if error != nil {
            PMLog.D(" toAttachment () with error: \(String(describing: error))")
        }
        return attachment
        
    }
}
