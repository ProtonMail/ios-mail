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
import Pm

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
    
    // MARK: - variables
    var allEmailAddresses: String {
        let lists: [String] = self.allEmails
        if lists.isEmpty {
            return ""
        }
        return lists.joined(separator: ",")
    }
    
    // MARK: - variables
    var allEmails: [String] {
        var lists: [String] = []
        
        if !recipientList.isEmpty {
            let to = MessageHelper.contactsToAddressesArray(recipientList)
            if !to.isEmpty  {
                lists.append(contentsOf: to)
            }
        }
        
        if !ccList.isEmpty {
            let cc = MessageHelper.contactsToAddressesArray(ccList)
            if !cc.isEmpty  {
                lists.append(contentsOf: cc)
            }
        }
        
        if !bccList.isEmpty {
            let bcc = MessageHelper.contactsToAddressesArray(bccList)
            if !bcc.isEmpty  {
                lists.append(contentsOf: bcc)
            }
        }
        
        return lists
    }
    
    
    var location: MessageLocation {
        get {
            return MessageLocation(rawValue: locationNumber.intValue) ?? .inbox
        }
        set {
            locationNumber = newValue.rawValue as NSNumber
        }
    }
    
    func getScore() -> MessageSpamScore {
        if let e = MessageSpamScore(rawValue: self.spamScore.intValue) {
            return e
        }
        return .others
    }
    
    func hasDraftLabel() -> Bool {
        let labels = self.labels
        for l in labels {
            if let label = l as? Label {
                if let l_id = Int(label.labelID) {
                    if let new_loc = MessageLocation(rawValue: l_id), new_loc == .draft {
                        return true
                    }
                }
                
            }
        }
        return false
    }
    
    func hasLocation(location : MessageLocation) -> Bool {
        for l in getLocationFromLabels() {
            if l == location {
                return true
            }
        }
        return false
    }
    
    func getLocationFromLabels() ->  [MessageLocation] {
        var locations = [MessageLocation]()
        let labels = self.labels
        for l in labels {
            if let label = l as? Label {
                if let l_id = Int(label.labelID) {
                    if let new_loc = MessageLocation(rawValue: l_id), new_loc != .starred && new_loc != .allmail {
                        locations.append(new_loc)
                    }
                }
                
            }
        }
        return locations
    }
    
    func getShowLocationNameFromLabels(ignored : String) -> String? {
        var lableOnly = false
        if ignored == MessageLocation.outbox.title {
            for l in getLocationFromLabels() {
                if l == .trash || l == .spam || l == .archive {
                    return l.title
                }
            }
            lableOnly = true
        }
    
        let labels = self.labels
        for l in labels {
            if let label = l as? Label {
                if label.exclusive == true && label.name != ignored {
                    return label.name
                } else if !lableOnly {
                    if let l_id = Int(label.labelID) {
                        PMLog.D(label.name)
                        if let new_loc = MessageLocation(rawValue: l_id), new_loc != .starred && new_loc != .allmail && new_loc.title != ignored {
                            return new_loc.title
                        }
                    }
                }
            }
        }
        return nil
    }
    
    func setLabelLocation(_ location : MessageLocation) {
        if let context = self.managedObjectContext {
            let toLableID = String(location.rawValue)
            let labelObjs = self.mutableSetValue(forKey: "labels")
            
            if let toLabel = Label.labelForLableID(toLableID, inManagedObjectContext: context) {
                var exsited = false
                for l in labelObjs {
                    if let label = l as? Label {
                        if label == toLabel {
                            exsited = true
                            break
                        }
                    }
                }
                if !exsited {
                    labelObjs.add(toLabel)
                }
            }
            self.setValue(labelObjs, forKey: "labels")
        }
    }
    
    func removeLocationFromLabels(currentlocation:MessageLocation, location : MessageLocation, keepSent: Bool) {
        if let context = self.managedObjectContext {
            context.performAndWait() {
                let labelObjs = self.mutableSetValue(forKey: "labels")
                if keepSent && currentlocation == .outbox {
                } else {
                    let fromLabelID = String(currentlocation.rawValue)
                    for l in labelObjs {
                        if let label = l as? Label {
                            if label.labelID == fromLabelID {
                                labelObjs.remove(label)
                                break
                            }
                        }
                    }
                }
                
                let toLableID = String(location.rawValue)
                if let toLabel = Label.labelForLableID(toLableID, inManagedObjectContext: context) {
                    var exsited = false
                    for l in labelObjs {
                        if let label = l as? Label {
                            if label == toLabel {
                                exsited = true
                                break
                            }
                        }
                    }
                    if !exsited {
                        labelObjs.add(toLabel)
                    }
                }
                
                self.setValue(labelObjs, forKey: "labels")
                if let error = context.saveUpstreamIfNeeded() {
                    PMLog.D("error: \(error)")
                }
            }
        }
    }
    
    func removeFromFolder(current: Label, location : MessageLocation, keepSent: Bool) {
        if let context = self.managedObjectContext {
            context.performAndWait() {
                let labelObjs = self.mutableSetValue(forKey: "labels")
                if keepSent && current.exclusive == false {
                    
                } else {
                    let fromLabelID = current.labelID
                    for l in labelObjs {
                        if let label = l as? Label {
                            if label.labelID == fromLabelID {
                                labelObjs.remove(label)
                                break
                            }
                        }
                    }
                }
                
                let toLableID = String(location.rawValue)
                if let toLabel = Label.labelForLableID(toLableID, inManagedObjectContext: context) {
                    var exsited = false
                    for l in labelObjs {
                        if let label = l as? Label {
                            if label == toLabel {
                                exsited = true
                                break
                            }
                        }
                    }
                    if !exsited {
                        labelObjs.add(toLabel)
                    }
                }
                
                self.setValue(labelObjs, forKey: "labels")
                if let error = context.saveUpstreamIfNeeded() {
                    PMLog.D("error: \(error)")
                }
            }
        }
    }
    
    var subject : String {
        return title
    }
    
    var displaySender : String {
        get {
            let sc = senderContactVO
            return sc!.name.isEmpty ?  sc!.email : sc!.name
        }
        
    }
    
    // MARK: - methods
    convenience init(context: NSManagedObjectContext) {
        self.init(entity: NSEntityDescription.entity(forEntityName: Attributes.entityName, in: context)!, insertInto: context)
    }
    
    /// Removes all messages from the store.
    class func deleteAll(inContext context: NSManagedObjectContext) {
        context.deleteAll(Attributes.entityName)
    }
    
    /**
     delete the message from local cache only use the message id
     
     :param: messageID String
     */
    class func deleteMessage(_ messageID : String) {
        if let context = sharedCoreDataService.mainManagedObjectContext {
            if let message = Message.messageForMessageID(messageID, inManagedObjectContext: context) {
                let labelObjs = message.mutableSetValue(forKey: "labels")
                labelObjs.removeAllObjects()
                message.setValue(labelObjs, forKey: "labels")
                context.delete(message)
            }
            if let error = context.saveUpstreamIfNeeded() {
                PMLog.D("error: \(error)")
            }
        }
    }
    
    class func deleteLocation(_ location : MessageLocation) -> Bool{
        if let mContext = sharedCoreDataService.mainManagedObjectContext {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: Message.Attributes.entityName)
            if location == .spam || location == .trash {
                fetchRequest.predicate = NSPredicate(format: "(ANY labels.labelID =[cd] %@)", "\(location.rawValue)")
                fetchRequest.sortDescriptors = [NSSortDescriptor(key: Message.Attributes.time, ascending: false)]
                do {
                    if let oldMessages = try mContext.fetch(fetchRequest) as? [Message] {
                        for message in oldMessages {
                            mContext.delete(message)
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
    
    class func messageForMessageID(_ messageID: String, inManagedObjectContext context: NSManagedObjectContext) -> Message? {
        return context.managedObjectWithEntityName(Attributes.entityName, forKey: Attributes.messageID, matchingValue: messageID) as? Message
    }
    
    class func messagesForObjectIDs(_ objectIDs: [NSManagedObjectID], inManagedObjectContext context: NSManagedObjectContext, error: NSErrorPointer) -> [Message]? {
        return context.managedObjectsWithEntityName(Attributes.entityName, forManagedObjectIDs: objectIDs, error: error) as? [Message]
    }
    
    override open func awakeFromInsert() {
        super.awakeFromInsert()
        replaceNilStringAttributesWithEmptyString()
    }
    
    func updateTag(_ tag: String) {
        self.tag = tag
        isStarred = tag.range(of: Constants.starredTag) != nil
    }
    
    // MARK: methods
    func decryptBody() throws -> String? {
        let keys = sharedUserDataService.addressPrivKeys
        return try body.decryptMessage(binKeys: keys, passphrase: passphrase)
    }
    
    func split() throws -> PmEncryptedSplit? {
        return try body.split()
    }
    
    func getSessionKey() throws -> PmSessionSplit? {
        return try split()?.keyPacket().getSessionFromPubKeyPackage(passphrase)
    }
    
    func bodyToHtml() -> String {
        if lockType == .plainTextLock {
            return "<div>" + body.ln2br() + "</div>"
        } else {
            let body_without_ln = body.rmln()
            return "<div><pre>" + body_without_ln.lr2lrln() + "</pre></div>"
        }
    }
    
    func decryptBodyIfNeeded() throws -> String? {
        if !checkIsEncrypted() {
            if isPlainText() {
                return body.ln2br() 
            }
            return body
        } else {
            if var body = try decryptBody() {
                PMLog.D(body)
                if isEncrypted == 8 || isEncrypted == 9 {
                    if let mimeMsg = MIMEMessage(string: body) {
                        if let html = mimeMsg.mainPart.part(ofType: "text/html")?.bodyString {
                            body = html
                            
                        } else if let text = mimeMsg.mainPart.part(ofType: "text/plain")?.plainString {
                            body = text.encodeHtml()
                            body = "<html><body>\(body.ln2br())</body></html>"
                        }
                        
                        if let cidPart = mimeMsg.mainPart.partCID(),
                            var cid = cidPart.cid,
                            let rawBody = cidPart.rawBodyString {
                            cid = cid.preg_replace("<", replaceto: "")
                            cid = cid.preg_replace(">", replaceto: "")
                            let attType = "image/jpg" //cidPart.headers[.contentType]?.body ?? "image/jpg;name=\"unknow.jpg\""
                            let encode = cidPart.headers[.contentTransferEncoding]?.body ?? "base64"
                            body = body.stringBySetupInlineImage("src=\"cid:\(cid)\"", to: "src=\"data:\(attType);\(encode),\(rawBody)\"")
                        }
                    } else { //backup plan
                        body = body.multipartGetHtmlContent ()
                    }
                } else if isEncrypted == 7 {
                    body = body.encodeHtml()
                    body = body.ln2br()
                    return body
                }
                if isPlainText() {
                    body = body.encodeHtml()
                    return body.ln2br() 
                }
                return body
            }
            return nil
        }
    }
    
    func encryptBody(_ body: String, mailbox_pwd: String, error: NSErrorPointer?) {
        let address_id = self.getAddressID;
        if address_id.isEmpty {
            return
        }
        self.body = try! body.encrypt(withAddr: address_id, mailbox_pwd: mailbox_pwd) ?? ""
    }
    
    func checkIsEncrypted() -> Bool! {
        PMLog.D(any: isEncrypted.intValue)
        let enc_type = EncryptTypes(rawValue: isEncrypted.intValue) ?? EncryptTypes.inner
        let checkIsEncrypted:Bool = enc_type.isEncrypted
        return checkIsEncrypted
    }
    
    func isPlainText() -> Bool {
        if let type = mimeType, type.lowercased() == "text/plain" {
            return true
        }
        return false
    }
    
    var encryptType : EncryptTypes! {
        let enc_type = EncryptTypes(rawValue: isEncrypted.intValue) ?? EncryptTypes.inner
        return enc_type
    }
    
    var lockType : LockTypes! {
        return self.encryptType.lockType
    }
    
    // MARK: Private variables
    fileprivate var passphrase: String {
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
    
    //this function need to factor
    var defaultAddress : Address? {
        get {
            if let addressID = addressID, !addressID.isEmpty {
                if let add = sharedUserDataService.userAddresses.indexOfAddress(addressID), add.send == 1 {
                    return add;
                } else {
                    if let add = sharedUserDataService.userAddresses.defaultSendAddress() {
                        return add;
                    }
                }
            } else {
                if let addr = sharedUserDataService.userAddresses.defaultSendAddress() {
                    return addr
                }
            }
            return nil
        }
    }
    
    var fromAddress : Address? {
        get {
            if let addressID = addressID, !addressID.isEmpty {
                if let add = sharedUserDataService.userAddresses.indexOfAddress(addressID) {
                    return add;
                }
            }
            return nil
        }
    }
    
    var senderContactVO : ContactVO! {
        var sender : ContactVO!
        sender = ContactVO(id: "", name: self.senderName, email: self.senderAddress)
        return sender
    }
    
    func copyMessage (_ copyAtts : Bool) -> Message {
        let message = self
        let newMessage = Message(context: sharedCoreDataService.mainManagedObjectContext!)
        newMessage.location = MessageLocation.draft
        newMessage.recipientList = message.recipientList
        newMessage.bccList = message.bccList
        newMessage.ccList = message.ccList
        newMessage.title = message.title
        newMessage.time = Date()
        newMessage.body = message.body
        newMessage.isEncrypted = message.isEncrypted
        newMessage.senderAddress = message.senderAddress
        newMessage.senderName = message.senderName
        newMessage.senderObject = message.senderObject
        newMessage.replyTo = message.replyTo
        newMessage.replyTos = message.replyTos
        
        newMessage.orginalTime = message.time
        newMessage.orginalMessageID = message.messageID
        newMessage.expirationOffset = 0
        
        newMessage.addressID = message.addressID
        newMessage.messageStatus = message.messageStatus
        newMessage.numAttachments = message.numAttachments
        newMessage.mimeType = message.mimeType

        if let error = newMessage.managedObjectContext?.saveUpstreamIfNeeded() {
            PMLog.D("error: \(error)")
        }
        
        for (index, attachment) in message.attachments.enumerated() {
            PMLog.D("index: \(index)")
            if let att = attachment as? Attachment {
                if att.inline() || copyAtts {
                    let attachment = Attachment(context: newMessage.managedObjectContext!)
                    attachment.attachmentID = att.attachmentID
                    attachment.message = newMessage
                    attachment.fileName = att.fileName
                    attachment.mimeType = "image/jpg"
                    attachment.fileData = att.fileData
                    attachment.fileSize = att.fileSize
                    attachment.headerInfo = att.headerInfo
                    attachment.localURL = att.localURL
                    attachment.keyPacket = att.keyPacket
                    attachment.isTemp = true
                    attachment.keyChanged = true
                    if let error = attachment.managedObjectContext?.saveUpstreamIfNeeded() {
                        PMLog.D("error: \(error)")
                    }
                }
                
            }
        }
        
        return newMessage
    }
    
    func fetchDetailIfNeeded(_ completion: @escaping MessageDataService.CompletionFetchDetail) {
        sharedMessageDataService.fetchMessageDetailForMessage(self, completion: completion)
    }
}



