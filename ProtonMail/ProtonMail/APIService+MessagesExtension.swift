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
    
    enum SortedColumn: String {
        case date = "Date"
        case from = "From"
        case size = "Size"
        case subject = "Subject"
    }
    
    func messageList(location: Location, page: Int, sortedColumn: SortedColumn, order: Order, filter: Filter, failure: (NSError? -> Void)) {
        fetchAuthCredential(success: { credential in
            let messagesPath = "/messages"
            
            let parameters = [
                "Location" : location.rawValue,
                "Page" : page,
                "SortedColumn" : sortedColumn.rawValue,
                "Order" : order.rawValue,
                "FilterUnread" : filter.rawValue]
            
            self.sessionManager.GET(messagesPath, parameters: parameters, success: { (task, response) -> Void in
                NSLog("\(__FUNCTION__)\n request:\(task.currentRequest)\nresponse: \(response)")
                
                if let error = self.messagesForResponse(response) {
                    failure(error)
                }
            }, failure: { (task, error) -> Void in
                NSLog("\(__FUNCTION__)\n request:\(task.currentRequest)\nheaders: \(task.currentRequest.allHTTPHeaderFields)\nerror: \(error)\n\n")
                failure(error)
            })

        }, failure: failure)
    }
    
    func messagesForResponse(response: AnyObject?) -> NSError? {
        if let response = response as? NSDictionary {
            if let messagesArray = response["Messages"] as? [NSDictionary] {
                let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
                let managedObjectContext = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
                managedObjectContext.parentContext = appDelegate.managedObjectContext
                
                for messageDict in messagesArray {
                    managedObjectContext.performBlock() { () -> Void in
                        var (message, error) = self.messageWithMessageDict(messageDict, inManagedObjectContext: managedObjectContext)

                        if let message = message {
                            var error: NSError?
                            
                            if !managedObjectContext.saveAndSaveParents(&error) {
                                NSLog("\(__FUNCTION__) error: \(error)")
                            }
                        }
                    }
                }
                
                return nil
            }
        }
        
        return APIError.unableToParseResponse.asNSError()
    }
    
    private func messageWithMessageDict(messageDict: NSDictionary, inManagedObjectContext context: NSManagedObjectContext) -> (message: Message?, error: NSError?) {
        var error: NSError?
        var message: Message?
        
        if let messageID = messageDict["MessageID"] as? String {
            (message, error) = Message.fetchOrCreateMessageForMessageID(messageID, context: context)
            
            if let message = message {
                message.expirationTime = self.dateForKey("ExpirationTime", dictionary: messageDict)
                
                if let time = self.dateForKey("Time", dictionary: messageDict) {
                    message.time = time
                }
                
            }
        } else {
            error = APIError.unableToParseResponse.asNSError()
        }
        
        return (message: message, error: error)
    }
    
    private func dateForKey(key: String, dictionary: NSDictionary) -> NSDate? {
        if let time = dictionary.timeIntervalForKey(key) {
            if time != 0 {
                return time.asDate()
            }
        }
        
        return nil
    }
}
