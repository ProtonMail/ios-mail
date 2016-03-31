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

import CoreData
import Foundation

extension Attachment {
    
    struct Attributes {
        static let entityName = "Attachment"
        static let attachmentID = "attachmentID"
    }
    
    var isDownloaded: Bool {
        return localURL != nil
    }
    
    convenience init(context: NSManagedObjectContext) {
        self.init(entity: NSEntityDescription.entityForName(Attributes.entityName, inManagedObjectContext: context)!, insertIntoManagedObjectContext: context)
    }
    
    override func prepareForDeletion() {
        super.prepareForDeletion()
        if let localURL = localURL {
            var error: NSError? = nil
            if !NSFileManager.defaultManager().removeItemAtURL(localURL, error: &error) {
                NSLog("\(__FUNCTION__) Could not delete \(localURL) with error: \(error)")
            }
        }
    }
    
    // MARK: - This is private functions
    
    private var passphrase: String {
        return sharedUserDataService.mailboxPassword ?? ""
    }
    
    // Mark : public functions
    
    func encryptAttachment(sender_address_id : String, error: NSErrorPointer?) -> PMNEncryptPackage? {
        let out = fileData?.encryptAttachment(sender_address_id, fileName: self.fileName, error: error)
        if out == nil {
            return nil
        }
        return out
    }
    
    func getSessionKey(error: NSErrorPointer?) -> NSData? {
        if self.keyPacket == nil {
            return nil
        }
        let data: NSData = NSData(base64EncodedString: self.keyPacket!, options: NSDataBase64DecodingOptions(rawValue: 0))!
        let sessionKey = data.getSessionKeyFromPubKeyPackage(passphrase, error: error) ?? nil
        return sessionKey
    }
    
    func fetchAttachment(downloadTask: ((NSURLSessionDownloadTask) -> Void)?, completion:((NSURLResponse?, NSURL?, NSError?) -> Void)?) {
        sharedMessageDataService.fetchAttachmentForAttachment(self, downloadTask: downloadTask, completion: completion)
    }
}

extension Attachment {
    class func attachmentDelete(attachmentObjectID: NSManagedObjectID, inManagedObjectContext context: NSManagedObjectContext) -> Void {
        var error: NSError? = nil
        if let att = context.existingObjectWithID(attachmentObjectID, error: &error) as? Attachment {
            context.delete(att);
            
            if let error = context.saveUpstreamIfNeeded() {
                PMLog.D("error: \(error)")
            }
            
        }
    }
    
}

extension UIImage {
    func toAttachment (message:Message, fileName : String, type:String) -> Attachment? {
        if let fileData = UIImageJPEGRepresentation(self, 0) {
            let attachment = Attachment(context: message.managedObjectContext!)
            attachment.attachmentID = "0"
            attachment.fileName = fileName
            attachment.mimeType = "image/jpg"
            attachment.fileData = fileData
            attachment.fileSize = fileData.length
            attachment.isTemp = false
            attachment.keyPacket = ""
            attachment.localURL = NSURL();
            
            attachment.message = message
            
            var error: NSError? = nil
            error = attachment.managedObjectContext?.saveUpstreamIfNeeded()
            if error != nil {
                NSLog("\(__FUNCTION__) toAttachment () with error: \(error)")
            }
            return attachment
        }
        
        return nil
    }
}

extension NSData {
    func toAttachment (message:Message, fileName : String, type:String) -> Attachment? {
        let attachment = Attachment(context: message.managedObjectContext!)
        attachment.attachmentID = "0"
        attachment.fileName = fileName
        attachment.mimeType = "image/jpg"
        attachment.fileData = self
        attachment.fileSize = self.length
        attachment.isTemp = false
        attachment.keyPacket = ""
        attachment.localURL = NSURL();
        
        attachment.message = message
        
        var error: NSError? = nil
        error = attachment.managedObjectContext?.saveUpstreamIfNeeded()
        if error != nil {
            NSLog("\(__FUNCTION__) toAttachment () with error: \(error)")
        }
        return attachment
        
    }
}
