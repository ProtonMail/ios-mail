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
            do {
                try NSFileManager.defaultManager().removeItemAtURL(localURL)
            } catch let ex as NSError {
                PMLog.D("Could not delete \(localURL) with error: \(ex)")
            }
        }
    }
    
    // MARK: - This is private functions
    
    private var passphrase: String {
        return sharedUserDataService.mailboxPassword ?? ""
    }
    
    
    // Mark : public functions
    
    func encryptAttachment(sender_address_id : String) throws -> PMNEncryptPackage? {
        let out = try fileData?.encryptAttachment(sender_address_id, fileName: self.fileName)
        if out == nil {
            return nil
        }
        return out
    }
    
    func getSessionKey() throws -> NSData? {
        if self.keyPacket == nil {
            return nil
        }
        let data: NSData = NSData(base64EncodedString: self.keyPacket!, options: NSDataBase64DecodingOptions(rawValue: 0))!
        let sessionKey = try data.getSessionKeyFromPubKeyPackage(passphrase) ?? nil
        return sessionKey
    }
    
    func fetchAttachment(downloadTask: ((NSURLSessionDownloadTask) -> Void)?, completion:((NSURLResponse?, NSURL?, NSError?) -> Void)?) {
        sharedMessageDataService.fetchAttachmentForAttachment(self, downloadTask: downloadTask, completion: completion)
    }

}

extension Attachment {
    class func attachmentDelete(attachmentObjectID: NSManagedObjectID, inManagedObjectContext context: NSManagedObjectContext) -> Void {
        do {
            if let att = try context.existingObjectWithID(attachmentObjectID) as? Attachment {
                context.delete(att);
                if let error = context.saveUpstreamIfNeeded() {
                    PMLog.D("error: \(error)")
                }
            }
        } catch let ex as NSError {
            PMLog.D("error: \(ex)")
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
                PMLog.D("toAttachment () with error: \(error)")
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
            PMLog.D(" toAttachment () with error: \(error)")
        }
        return attachment
        
    }
}
