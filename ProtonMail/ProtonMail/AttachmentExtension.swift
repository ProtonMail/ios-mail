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
    
    private var privateKey: String {
        return sharedUserDataService.userInfo?.privateKey ?? ""
    }
    
    private var publicKey: String {
        return sharedUserDataService.userInfo?.publicKey ?? ""
    }
    
    // Mark : public functions
    
    func encryptAttachment(error: NSErrorPointer?) -> NSMutableDictionary? {
        let out = fileData?.encryptWithPublicKeys(["self" : publicKey], fileName: self.fileName, error: error)
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
        
        let sessionKey = data.getSessionKeyFromPubKeyPackage(privateKey, passphrase: passphrase, publicKey:publicKey, error: error) ?? nil
        
        return sessionKey
    }
    
    //    func getNewSessionKeyPackage(publicKey: String!, error: NSErrorPointer?) -> NSData? {
    //        let key = self.getSessionKey(nil)
    //
    //        key?.getSessionKeyPackage(publicKey, error: nil)
    //
    //    }
    
    //    func decryptAttachment(keyPackage:NSData!, error: NSErrorPointer?) -> NSData? {
    //
    //        self.keyPacket
    //
    //        return nil
    //    }
    
}


extension Attachment {
    //    func toImage -> UIImage {
    //        return UIImage();
    //    }
    
    
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
            attachment.message = message
            attachment.fileName = fileName
            attachment.mimeType = "image/jpg"
            attachment.fileData = fileData
            attachment.fileSize = fileData.length
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
