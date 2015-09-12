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

import Foundation
import CoreData

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
        static let senderObject = "senderObject"
        static let time = "time"
        static let title = "title"
        static let labels = "labels"
        
        static let messageType = "messageType"
        static let messageStatus = "messageStatus"
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
        
        PMLog.D("allEmailAddresses  ---  \(lists)" )
        return lists.joinWithSeparator(",")
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
        return title
    }
    
    var displaySender : String {
        get {
            let sc = senderContactVO
            return sc.name.isEmpty ?  sc.email : sc.name
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
    
    /**
    delete the message from local cache only use the message id
    
    :param: messageID String
    */
    class func deleteMessage(messageID : String) {
        if let context = sharedCoreDataService.mainManagedObjectContext {
            if let message = Message.messageForMessageID(messageID, inManagedObjectContext: context) {
                let labelObjs = message.mutableSetValueForKey("labels")
                labelObjs.removeAllObjects()
                message.setValue(labelObjs, forKey: "labels")
                context.deleteObject(message)
            }
            if let error = context.saveUpstreamIfNeeded() {
                PMLog.D("error: \(error)")
            }
        }
    }
    
    class func deleteLocation(location : MessageLocation) -> Bool{
        if let mContext = sharedCoreDataService.mainManagedObjectContext {
            let fetchRequest = NSFetchRequest(entityName: Message.Attributes.entityName)
            if location == .spam || location == .trash {
                fetchRequest.predicate = NSPredicate(format: "%K == %i", Message.Attributes.locationNumber, location.rawValue)
                fetchRequest.sortDescriptors = [NSSortDescriptor(key: Message.Attributes.time, ascending: false)]
                do {
                    if let oldMessages = try mContext.executeFetchRequest(fetchRequest) as? [Message] {
                        for message in oldMessages {
                            mContext.deleteObject(message)
                        }
                        if let error = mContext.saveUpstreamIfNeeded() {
                            PMLog.D(" error: \(error)")
                        } else {
                            return true
                        }
                    }
                } catch {
                     PMLog.D(" error: \(error)")
                }
            }
        }
        return false
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
    func decryptBody() throws -> String? {
        return try body.decryptMessage(passphrase)
    }
    
    func decryptBodyIfNeeded() throws -> String? {
        //PMLog.D("\(body)")
        if !checkIsEncrypted() {
            return body
        } else {
            var body = try decryptBody()
            if body == nil {
                return body
            }
            if isEncrypted == 8 {
                body = body?.multipartGetHtmlContent () ?? ""
            } else if isEncrypted == 7 {
                body = body?.ln2br() ?? ""
            }
            return body
        }
    }
    
    func encryptBody(body: String, error: NSErrorPointer?) {
        let address_id = self.getAddressID;
        if address_id.isEmpty {
            return
        }
        self.body = try! body.encryptMessage(address_id) ?? ""
    }
    
    func checkIsEncrypted() -> Bool! {
        let enc_type = EncryptTypes(rawValue: isEncrypted.integerValue) ?? EncryptTypes.Internal
        let checkIsEncrypted:Bool = enc_type.isEncrypted
        return checkIsEncrypted
    }
    
    var encryptType : EncryptTypes! {
        let enc_type = EncryptTypes(rawValue: isEncrypted.integerValue) ?? EncryptTypes.Internal
        return enc_type
    }
    
    var lockType : LockTypes! {
        return self.encryptType.lockType
    }
    
    // MARK: Private variables
    private var passphrase: String {
        return sharedUserDataService.mailboxPassword ?? ""
    }
    
    var getAddressID: String {
        get {
            if let addr = defaultAddress {
                return addr.address_id
            }
            return ""
        }
    }
    
    var defaultAddress : Address? {
        get {
            if let addressID = addressID {
                if !addressID.isEmpty {
                    if let add = sharedUserDataService.userAddresses.indexOfAddress(addressID) {
                        return add;
                    } else {
                        if let add = sharedUserDataService.userAddresses.getDefaultAddress() {
                            return add;
                        }
                    }
                }
            } else {
                if let addr = sharedUserDataService.userAddresses.getDefaultAddress() {
                    return addr
                }
            }
            return nil
        }
    }
    
    var senderContactVO : ContactVO! {
        var sender : ContactVO!
//        if let beforeParsed = self.newSender, paserdNewSender = beforeParsed.toContact() {
//            sender = paserdNewSender
//        } else {
            sender = ContactVO(id: "", name: self.senderName, email: self.senderAddress)
//        }
        return sender
    }
    
    func copyMessage (copyAtts : Bool) -> Message {
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
        newMessage.senderAddress = message.senderAddress
        newMessage.senderName = message.senderName
        newMessage.senderObject = message.senderObject
        newMessage.replyTo = message.replyTo
        
        newMessage.orginalTime = message.time
        newMessage.orginalMessageID = message.messageID
        newMessage.expirationOffset = 0
        
        newMessage.addressID = message.getAddressID
        newMessage.messageStatus = message.messageStatus
        
        if let error = newMessage.managedObjectContext?.saveUpstreamIfNeeded() {
            PMLog.D("error: \(error)")
        }
        if copyAtts {
            for (index, attachment) in message.attachments.enumerate() {
                PMLog.D("index: \(index)")
                if let att = attachment as? Attachment {
                    let attachment = Attachment(context: newMessage.managedObjectContext!)
                    attachment.attachmentID = "0"
                    attachment.message = newMessage
                    attachment.fileName = att.fileName
                    attachment.mimeType = "image/jpg"
                    attachment.fileData = att.fileData
                    attachment.fileSize = att.fileSize
                    attachment.isTemp = true
                    if let error = attachment.managedObjectContext?.saveUpstreamIfNeeded() {
                        PMLog.D("error: \(error)")
                    }
                }
            }
        }
        return newMessage
    }
    
    func fetchDetailIfNeeded(completion: MessageDataService.CompletionFetchDetail) {
        sharedMessageDataService.fetchMessageDetailForMessage(self, completion: completion)
    }
}

extension String {
    
    public func multipartGetHtmlContent() -> String {
        //PMLog.D(self)
        let textplainType = "text/plain".dataUsingEncoding(NSUTF8StringEncoding)!
        let htmlType = "text/html".dataUsingEncoding(NSUTF8StringEncoding)!
        
        var data = self.dataUsingEncoding(NSUTF8StringEncoding)!
        var len = data.length as Int;
        
        //get boundary=
        let boundarLine = "boundary=".dataUsingEncoding(NSASCIIStringEncoding)!
        let boundaryRange = data.rangeOfData(boundarLine, options: NSDataSearchOptions.init(rawValue: 0), range: NSMakeRange(0, len))
        if boundaryRange.location == NSNotFound {
            return "";
        }
        
        //new len
        len = len - (boundaryRange.location + boundaryRange.length);
        data = data.subdataWithRange(NSMakeRange(boundaryRange.location + boundaryRange.length, len))
        let lineEnd = "\n".dataUsingEncoding(NSASCIIStringEncoding)!;
        let nextLine = data.rangeOfData(lineEnd, options: NSDataSearchOptions.init(rawValue: 0), range: NSMakeRange(0, len))
        if nextLine.location == NSNotFound {
            return "";
        }
        let boundary = data.subdataWithRange(NSMakeRange(0, nextLine.location))
        var boundaryString = NSString(data: boundary, encoding: NSUTF8StringEncoding) as! String
        boundaryString = boundaryString.stringByReplacingOccurrencesOfString("\"", withString: "")
        boundaryString = boundaryString.stringByReplacingOccurrencesOfString("\r", withString: "")
        boundaryString = "--" + boundaryString;
        
        len = len - (nextLine.location + nextLine.length);
        data = data.subdataWithRange(NSMakeRange(nextLine.location + nextLine.length, len))
        
        var html : String = "";
        var plaintext : String = "";
        
        var count = 0;
        let nextBoundaryLine = boundaryString.dataUsingEncoding(NSASCIIStringEncoding)!
        var firstboundaryRange = data.rangeOfData(nextBoundaryLine, options: NSDataSearchOptions(rawValue: 0), range: NSMakeRange(0, len))
        
        if firstboundaryRange.location == NSNotFound {
            return "";
        }
        
        while true {
            if count >= 10 {
                break;
            }
            count += 1;
            len = len - (firstboundaryRange.location + firstboundaryRange.length) - 1;
            data = data.subdataWithRange(NSMakeRange(1 + firstboundaryRange.location + firstboundaryRange.length, len))
            
            if data.subdataWithRange(NSMakeRange(0 , 1)).isEqualToData("-".dataUsingEncoding(NSASCIIStringEncoding)!) {
                break;
            }
            
            var bodyString = NSString(data: data, encoding: NSUTF8StringEncoding) as! String
            
            let ContentEnd = data.rangeOfData(lineEnd, options: NSDataSearchOptions(rawValue: 0), range: NSMakeRange(2, len - 2))
            if ContentEnd.location == NSNotFound {
                break
            }
            let ContentType = data.subdataWithRange(NSMakeRange(0, ContentEnd.location))
            len = len - (ContentEnd.location + ContentEnd.length);
            data = data.subdataWithRange(NSMakeRange(ContentEnd.location + ContentEnd.length, len))
            
            bodyString = NSString(data: ContentType, encoding: NSUTF8StringEncoding) as! String
            
            let EncodingEnd = data.rangeOfData(lineEnd, options: NSDataSearchOptions(rawValue: 0), range: NSMakeRange(2, len - 2))
            if EncodingEnd.location == NSNotFound {
                break
            }
            let EncodingType = data.subdataWithRange(NSMakeRange(0, EncodingEnd.location))
            len = len - (EncodingEnd.location + EncodingEnd.length);
            data = data.subdataWithRange(NSMakeRange(EncodingEnd.location + EncodingEnd.length, len))
            
            bodyString = NSString(data: EncodingType, encoding: NSUTF8StringEncoding) as! String
            
            let secondboundaryRange = data.rangeOfData(nextBoundaryLine, options: NSDataSearchOptions(rawValue: 0), range: NSMakeRange(0, len))
            if secondboundaryRange.location == NSNotFound {
                break
            }
            //get data
            
            let text = data.subdataWithRange(NSMakeRange(1, secondboundaryRange.location - 1))
            let plainFound = ContentType.rangeOfData(textplainType, options: NSDataSearchOptions(rawValue: 0), range: NSMakeRange(0, ContentType.length))
            if plainFound.location != NSNotFound {
                plaintext = NSString(data: text, encoding: NSUTF8StringEncoding) as! String;
            }
            
            let htmlFound = ContentType.rangeOfData(htmlType, options: NSDataSearchOptions(rawValue: 0), range: NSMakeRange(0, ContentType.length))
            if htmlFound.location != NSNotFound {
                html = NSString(data: text, encoding: NSUTF8StringEncoding) as! String;
            }
            
            // check html or plain text
            bodyString = NSString(data: text, encoding: NSUTF8StringEncoding) as! String
            
            firstboundaryRange = secondboundaryRange
            
            PMLog.D(bodyString)
        }
        
        return html.isEmpty ? plaintext.ln2br() : html;
    }
    
}


