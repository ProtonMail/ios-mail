//
//  MessageExtension.swift
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

extension Message {
    
    struct Attributes {
        static let entityName = "Message"
        static let locationNumber = "locationNumber"
        static let isDetailDownloaded = "isDetailDownloaded"
        static let isRead = "isRead"
        static let isStarred = "isStarred"
        static let messageID = "messageID"
        static let recipientList = "recipientList"
        static let senderName = "senderName"
        static let time = "time"
        static let title = "title"
        static let labels = "labels"
    }
    
    struct Constants {
        static let starredTag = "starred"
    }
    
    // MARK: - Public variables
    
    var allEmailAddresses: String {
        var lists: [String] = []
        
        if !recipientList.isEmpty {
            let to = MessageHelper.contactsToAddresses(recipientList)
            if !to.isEmpty  {
                lists.append(to)
            }
        }
        
        if !ccList.isEmpty {
            let cc = MessageHelper.contactsToAddresses(ccList)
            if !cc.isEmpty  {
                lists.append(cc)
            }
        }
        
        if !bccList.isEmpty {
            let bcc = MessageHelper.contactsToAddresses(bccList)
            if !bcc.isEmpty  {
                lists.append(bcc)
            }
        }
        
        if lists.isEmpty {
            return ""
        }
        
        return ",".join(lists)
    }
    
    var location: MessageLocation {
        get {
            return MessageLocation(rawValue: locationNumber.integerValue) ?? .inbox
        }
        set {
            locationNumber = newValue.rawValue
        }
    }
    
    var subject : String {
        return title //.decodeHtml()
    }
    
    var displaySender : String {
        get {
            return senderName.isEmpty ?  sender : senderName
        }
        
    }
    
    // MARK: - Public methods
    
    convenience init(context: NSManagedObjectContext) {
        self.init(entity: NSEntityDescription.entityForName(Attributes.entityName, inManagedObjectContext: context)!, insertIntoManagedObjectContext: context)
    }
        
    /// Removes all messages from the store.
    class func deleteAll(inContext context: NSManagedObjectContext) {
        context.deleteAll(Attributes.entityName)
    }
    
    class func messageForMessageID(messageID: String, inManagedObjectContext context: NSManagedObjectContext) -> Message? {
        return context.managedObjectWithEntityName(Attributes.entityName, forKey: Attributes.messageID, matchingValue: messageID) as? Message
    }
    
    class func messagesForObjectIDs(objectIDs: [NSManagedObjectID], inManagedObjectContext context: NSManagedObjectContext, error: NSErrorPointer) -> [Message]? {
        return context.managedObjectsWithEntityName(Attributes.entityName, forManagedObjectIDs: objectIDs, error: error) as? [Message]
    }
    
    override public func awakeFromInsert() {
        super.awakeFromInsert()
        replaceNilStringAttributesWithEmptyString()
    }
        
    func updateTag(tag: String) {
        self.tag = tag
        isStarred = tag.rangeOfString(Constants.starredTag) != nil
    }
    
    
    
    // MARK: Public methods
    
    func decryptBody(error: NSErrorPointer?) -> String? {
        return body.decryptWithPrivateKey(privateKey, passphrase: passphrase, publicKey: publicKey, error: error)
    }
    
    func decryptBodyIfNeeded(error: NSErrorPointer?) -> String? {
        
        //PMLog.D("\(body)")
        
        if !checkIsEncrypted() {
            return body
        } else {
            return decryptBody(error)
        }
    }
    
    func encryptBody(body: String, error: NSErrorPointer?) {
        self.body = body.encryptWithPublicKey(publicKey, error: error) ?? ""
    }
    
    func checkIsEncrypted() -> Bool!
    {
        let enc_type = EncryptTypes(rawValue: isEncrypted.integerValue) ?? EncryptTypes.Internal
        let checkIsEncrypted:Bool = enc_type.isEncrypted
        
        return checkIsEncrypted
    }

    
    
    // MARK: Private variables
    
    private var passphrase: String {
        return sharedUserDataService.mailboxPassword ?? ""
    }
    
    private var privateKey: String {
        return sharedUserDataService.userInfo?.privateKey ?? ""
    }
    
    private var publicKey: String {
        return sharedUserDataService.userInfo?.publicKey ?? ""
    }
    

    
    func copyMessage () -> Message {
        let message = self
        let newMessage = Message(context: sharedCoreDataService.mainManagedObjectContext!)
        
        newMessage.location = MessageLocation.draft
        newMessage.recipientList = message.recipientList
        newMessage.bccList = message.bccList
        newMessage.ccList = message.ccList
        newMessage.title = message.title
        newMessage.time = NSDate()
        newMessage.body = message.body
        newMessage.isEncrypted = message.isEncrypted
        newMessage.sender = message.sender
        newMessage.senderName = message.senderName
        
        newMessage.orginalTime = message.time
        newMessage.orginalMessageID = message.messageID
        //            if let attachments = message.attachments {
        //                for (index, attachment) in enumerate(attachments) {
        //                    if let image = attachment as? UIImage {
        //                        if let fileData = UIImagePNGRepresentation(image) {
        //                            let attachment = Attachment(context: context)
        //                            attachment.attachmentID = "0"
        //                            attachment.message = message
        //                            attachment.fileName = "\(index).png"
        //                            attachment.mimeType = "image/png"
        //                            attachment.fileData = fileData
        //                            attachment.fileSize = fileData.length
        //                            continue
        //                        }
        //                    }
        //
        //                    let description = attachment.description ?? "unknown"
        //                    NSLog("\(__FUNCTION__) unsupported attachment type \(description)")
        //                }
        //            }
        
        return newMessage
    }
}


