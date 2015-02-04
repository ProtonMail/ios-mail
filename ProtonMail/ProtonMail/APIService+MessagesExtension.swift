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
    enum Location: Int {
        case draft = 1
        case inbox = 0
        case outbox = 2
        case spam = 4
        case starred = 5
        case trash = 3
    }
    
    enum Order: Int {
        case ascending = 0
        case descending = 1
    }
    
    enum MessageKey: String {
        case attachments = "AttachmentIDList"
        case bccList = "BCCList"
        case bccNameList = "BCCNameList"
        case body = "MessageBody"
        case ccList = "CCList"
        case ccNameList = "CCNameList"
        case expirationTime = "ExpirationTime"
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
        messageDetail(messageID: message.messageID, completion: completion)
    }
    
    func messageDetail(#messageID: String, completion: (NSError? -> Void)) {
        fetchAuthCredential(success: { credential in
            let path = "/messages/\(messageID)"
            
            self.sessionManager.GET(path, parameters: nil, success: { (task, response) -> Void in
                completion(self.messageForResponse(response))
            }, failure: { (task, error) -> Void in
                completion(error)
            })
        }, failure: completion)
    }
    
    func messageList(location: Location, page: Int, sortedColumn: SortedColumn, order: Order, filter: Filter, completion: (NSError? -> Void)) {
        fetchAuthCredential(success: { credential in
            let messagesPath = "/messages"
            
            let parameters = [
                "Location" : location.rawValue,
                "Page" : page,
                "SortedColumn" : sortedColumn.rawValue,
                "Order" : order.rawValue,
                "FilterUnread" : filter.rawValue]
            
            self.sessionManager.GET(messagesPath, parameters: parameters, success: { (task, response) -> Void in
                completion(self.messagesForResponse(response, location: location))
            }, failure: { (task, error) -> Void in
                completion(error)
            })

        }, failure: completion)
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
    
    private func handleMessageDict(messageDict: NSDictionary, inManagedObjectContext moc: NSManagedObjectContext, location: Location? = nil) {
        moc.performBlock() { () -> Void in
            var (message, error) = self.messageWithMessageDict(messageDict, inManagedObjectContext: moc, location: location)
            
            if let message = message {
                var error: NSError?
                
                if !moc.saveAndSaveParents(&error) {
                    NSLog("\(__FUNCTION__) error: \(error)")
                }
            }
        }
    }
    
    private func isStarred(#message: Message) -> Bool {
        return message.tag.rangeOfString("starred") != nil
    }
    
    private func locationInt(#messageDict: NSDictionary, location: Location?) -> Int32 {
        if let locationInt = location?.rawValue {
            return Int32(locationInt)
        }
        
        return messageDict.int32ForMessageKey(.location)
    }
    
    private func messageForResponse(response: AnyObject?) -> NSError? {
        if let response = response as? NSDictionary {
            handleMessageDict(response, inManagedObjectContext: newManagedObjectContext())
            
            return nil
        }
        
        return APIError.unableToParseResponse.asNSError()
    }
    
    private func messagesForResponse(response: AnyObject?, location: Location) -> NSError? {
        if let response = response as? NSDictionary {
            if let messagesArray = response[MessageKey.messages.keyValue] as? [NSDictionary] {
                let moc = newManagedObjectContext()
                for messageDict in messagesArray {
                    handleMessageDict(messageDict, inManagedObjectContext: moc, location: location)
                }
                
                return nil
            }
        }
        
        return APIError.unableToParseResponse.asNSError()
    }
    
    private func messageWithMessageDict(messageDict: NSDictionary, inManagedObjectContext context: NSManagedObjectContext, location: Location?) -> (message: Message?, error: NSError?) {
        var error: NSError?
        var message: Message?
        
        if let messageID = messageDict[MessageKey.messageID.keyValue] as? String {
            (message, error) = Message.fetchOrCreateMessageForMessageID(messageID, context: context)
            
            if let message = message {
                message.bccList = messageDict.stringForMessageKey(.bccList)
                message.bccNameList = messageDict.stringForMessageKey(.bccNameList)
                message.body = messageDict.stringForMessageKey(.body)
                message.ccList = messageDict.stringForMessageKey(.ccList)
                message.ccNameList = messageDict.stringForMessageKey(.ccNameList)
                message.expirationTime = messageDict.dateForMessageKey(.expirationTime)
                message.hasAttachment = messageDict.boolForMessageKey(.hasAttachment)
                message.header = messageDict.stringForMessageKey(.header)
                message.isEncrypted = messageDict.boolForMessageKey(.isEncrypted)
                message.isForwarded = messageDict.boolForMessageKey(.isForwarded)
                message.isRead = messageDict.boolForMessageKey(.isRead)
                message.isReplied = messageDict.boolForMessageKey(.isReplied)
                message.isRepliedAll = messageDict.boolForMessageKey(.isRepliedAll)
                message.locationInt = locationInt(messageDict: messageDict, location: location)
                message.recipientList = messageDict.stringForMessageKey(.recipientList)
                message.recipientNameList = messageDict.stringForMessageKey(.recipientNameList)
                message.sender = messageDict.stringForMessageKey(.sender)
                message.senderName = messageDict.stringForMessageKey(.senderName)
                message.spamScore = messageDict.int32ForMessageKey(.spamScore)
                message.tag = messageDict.stringForMessageKey(.tag)
                message.time = messageDict.dateForMessageKey(.time)
                message.title = messageDict.stringForMessageKey(.title)
                message.totalSize = messageDict.int32ForMessageKey(.totalSize)

                message.isStarred = isStarred(message: message)
                
                if let attachments = messageDict[MessageKey.attachments.keyValue] as? [NSDictionary] {
                    for attachmentDict in attachments {
                        
                    }
                }
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
    
    func int32ForMessageKey(key: APIService.MessageKey) -> Int32 {
        return (self[key.keyValue] as? NSString)?.intValue ?? 0
    }
    
    func stringForMessageKey(key: APIService.MessageKey) -> String {
        return self[key.keyValue] as? String ?? ""
    }
}
