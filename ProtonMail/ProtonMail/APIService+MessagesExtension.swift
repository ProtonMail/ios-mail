//
//  APIService+MessagesExtension.swift
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

/// Messages extension
extension APIService {
    
    enum Filter: Int {
        case noFilter = -2
        case read = 0
        case unRead = 1
    }
    
    enum Location: Int, Printable {
        case draft = 1
        case inbox = 0
        case outbox = 2
        case spam = 4
        case starred = 5
        case trash = 3
        
        var description : String {
            get {
                switch(self) {
                case inbox:
                    return "Inbox"
                case draft:
                    return "Draft"
                case outbox:
                    return "Outbox"
                case spam:
                    return "Spam"
                case starred:
                    return "Starred"
                case trash:
                    return "Trash"
                }
            }
        }
    }
    
    enum Order: Int {
        case ascending = 0
        case descending = 1
    }
    
    enum MessageKey: String {
        case attachmentID = "AttachmentID"
        case attachments = "AttachmentIDList"
        case bccList = "BCCList"
        case bccNameList = "BCCNameList"
        case body = "MessageBody"
        case ccList = "CCList"
        case ccNameList = "CCNameList"
        case expirationTime = "ExpirationTime"
        case fileName = "FileName"
        case fileSize = "FileSize"
        case hasAttachment = "HasAttachment"
        case header = "Header"
        case isEncrypted = "IsEncrypted"
        case isForwarded = "IsForwarded"
        case isRead = "IsRead"
        case isReplied = "IsReplied"
        case isRepliedAll = "IsRepliedAll"
        case location = "Location"
        case messageID = "MessageID"
        case messages = "Messages"
        case mimeType = "MIMEType"
        case recipientList = "RecipientList"
        case recipientNameList = "RecipientNameList"
        case sender = "Sender"
        case senderName = "SenderName"
        case spamScore = "MessageSpamScore"
        case tag = "Tag"
        case time = "Time"
        case title = "MessageTitle"
        case totalSize = "TotalSize"
        
        var keyValue: String {
            return rawValue
        }
    }
    
    enum SortedColumn: String {
        case date = "Date"
        case from = "From"
        case size = "Size"
        case subject = "Subject"
    }
    
    
    // MARK: - Public methods
    
    func messageDetail(#message: Message, completion: (NSError? -> Void)) {
        let path = "/messages/\(message.messageID)"
        
        let successBlock: SuccessBlock = { response in
            let context = sharedCoreDataService.newManagedObjectContext()
            
            context.performBlock() {
                var (messageDetail, error) = self.messageDetailFromDictionary(response, inManagedObjectContext: context, messageObjectID: message.objectID)
                
                if let error = context.saveUpstreamIfNeeded() {
                    NSLog("\(__FUNCTION__) error: \(error)")
                }
            }
            
            completion(nil)
        }
        
        GET(path, parameters: nil, success: successBlock, failure: completion)
    }
    
    func messageList(location: Location, page: Int, sortedColumn: SortedColumn, order: Order, filter: Filter, completion: CompletionBlock) {
        let path = "/messages"
        
        let parameters = [
            "Location" : location.rawValue,
            "Page" : page,
            "SortedColumn" : sortedColumn.rawValue,
            "Order" : order.rawValue,
            "FilterUnread" : filter.rawValue]
        
        let successBlock: SuccessBlock = { response in
            var error: NSError?
            
            if let messagesArray = response[MessageKey.messages.keyValue] as? [NSDictionary] {
                let context = sharedCoreDataService.newManagedObjectContext()
                
                for messageDictionary in messagesArray {
                    context.performBlock() { () -> Void in
                        var (message, error) = self.messageFromDictionary(messageDictionary, inManagedObjectContext: context)
                        
                        if let message = message {
                            message.locationNumber = location.rawValue
                            
                            if let error = context.saveUpstreamIfNeeded() {
                                NSLog("\(__FUNCTION__) error: \(error)")
                            }
                        }
                    }
                }
            } else {
                error = APIError.unableToParseResponse.asNSError()
            }
            
            completion(error)
        }
        
        GET(path, parameters: parameters, success: successBlock, failure: completion)
    }
    
    func starMessage(message: Message, completion: (NSError? -> Void)) {
        fetchAuthCredential(success: { credential in
            let path = "/messages/\(message.messageID)/star"
            
            self.sessionManager.PUT(path, parameters: nil, success: { (task, result) -> Void in
                // TODO: update message details
                completion(nil)
            }, failure: { (task, error) -> Void in
                completion(error)
            })
            
        }, failure: completion)
    }
    
    func unstarMessage(message: Message, completion: (NSError? -> Void)) {
        fetchAuthCredential(success: { credential in
            let path = "/messages/\(message.messageID)/unstar"
            
            self.sessionManager.PUT(path, parameters: nil, success: { (task, result) -> Void in
                // TODO: update message details
                completion(nil)
                }, failure: { (task, error) -> Void in
                    completion(error)
            })
            
            }, failure: completion)
    }
    
    
    // MARK: - Private methods
    
    private func messageDetailFromDictionary(dictionary: NSDictionary, inManagedObjectContext context: NSManagedObjectContext, messageObjectID: NSManagedObjectID) -> (messageDetail: MessageDetail?, error: NSError?) {
        var error: NSError?
        var messageDetail: MessageDetail!
        
        if let message = context.existingObjectWithID(messageObjectID, error: &error) as? Message {
            messageDetail = message.detail
            
            if messageDetail == nil {
                messageDetail = MessageDetail(context: context)
                messageDetail.message = message
                messageDetail.bccList = dictionary.stringForMessageKey(.bccList)
                messageDetail.bccNameList = dictionary.stringForMessageKey(.bccNameList)
                messageDetail.body = dictionary.stringForMessageKey(.body)
                messageDetail.ccList = dictionary.stringForMessageKey(.ccList)
                messageDetail.ccNameList = dictionary.stringForMessageKey(.ccNameList)
                messageDetail.header = dictionary.stringForMessageKey(.header)
                messageDetail.spamScore = dictionary.numberForMessageKey(.spamScore)
                
                if let attachments = dictionary[MessageKey.attachments.keyValue] as? [NSDictionary] {
                    for dictionary in attachments {
                        let attachment = Attachment(context: context)
                        attachment.attachmentID = dictionary.stringForMessageKey(.attachmentID)
                        attachment.fileName = dictionary.stringForMessageKey(.fileName)
                        attachment.fileSize = dictionary.numberForMessageKey(.fileSize)
                        attachment.mimeType = dictionary.stringForMessageKey(.mimeType)
                        
                        messageDetail.attachments.addObject(attachment)
                    }
                }
                
                message.detail = messageDetail
            }
        }
        
        return (messageDetail, error)
    }

    private func messageFromDictionary(dictionary: NSDictionary, inManagedObjectContext context: NSManagedObjectContext) -> (message: Message?, error: NSError?) {
        var error: NSError?
        var message: Message?
        
        if let messageID = dictionary[MessageKey.messageID.keyValue] as? String {
            (message, error) = Message.fetchOrCreateMessageForMessageID(messageID, context: context)
            
            if let message = message {
                message.expirationTime = dictionary.dateForMessageKey(.expirationTime)
                message.hasAttachment = dictionary.boolForMessageKey(.hasAttachment)
                message.isEncrypted = dictionary.boolForMessageKey(.isEncrypted)
                message.isForwarded = dictionary.boolForMessageKey(.isForwarded)
                message.isRead = dictionary.boolForMessageKey(.isRead)
                message.isReplied = dictionary.boolForMessageKey(.isReplied)
                message.isRepliedAll = dictionary.boolForMessageKey(.isRepliedAll)
                message.recipientList = dictionary.stringForMessageKey(.recipientList)
                message.recipientNameList = dictionary.stringForMessageKey(.recipientNameList)
                message.sender = dictionary.stringForMessageKey(.sender)
                message.senderName = dictionary.stringForMessageKey(.senderName)
                message.updateTag(dictionary.stringForMessageKey(.tag))
                message.time = dictionary.dateForMessageKey(.time)
                message.title = dictionary.stringForMessageKey(.title)
                message.totalSize = dictionary.numberForMessageKey(.totalSize)
                
            }
        } else {
            error = APIError.unableToParseResponse.asNSError()
        }
        
        return (message: message, error: error)
    }
}


// MARK: - NSDictionary message extensions

extension NSDictionary {
    
    func boolForMessageKey(key: APIService.MessageKey) -> Bool {
        return self[key.keyValue] as? Bool ?? false
    }
    
    func dateForMessageKey(key: APIService.MessageKey) -> NSDate? {
        if let time = timeIntervalForKey(key.keyValue) {
            return time.asDate()
        }
        
        return nil
    }
    
    func numberForMessageKey(key: APIService.MessageKey) -> NSNumber {
        return (self[key.keyValue] as? String)?.toInt() ?? 0
    }
    
    func stringForMessageKey(key: APIService.MessageKey) -> String {
        return self[key.keyValue] as? String ?? ""
    }
}
