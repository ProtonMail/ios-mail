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
        
        var moveAction: MessageAction? {
            var action: APIService.MessageAction?
            
            switch(self) {
            case .inbox:
                action = .inbox
            case .spam:
                action = .spam
            case .trash:
                action = .trash
            default:
                action = nil
            }
            
            return action
        }
    }
    
    enum MessageAction: String {
        
        // Read/unread
        case read = "read"
        case unread = "unread"
        
        // Star/unstar
        case star = "star"
        case unstar = "unstar"
        
        // Move mailbox
        case delete = "delete"
        case inbox = "inbox"
        case spam = "spam"
        case trash = "trash"
        
        var method: HTTPMethod {
            switch(self) {
            case .delete:
                return .DELETE
            case .read, .unread, .star, .unstar, .inbox, .spam, .trash:
                return .PUT
            default:
                return .GET
            }
        }
        
        var pathSuffix: String {
            return rawValue
        }
        
        func pathForMessage(message: Message) -> String {
            let path = "/messages/\(message.messageID)/\(pathSuffix)"
            
            return path
        }
    }
    
    enum Order: Int {
        case ascending = 0
        case descending = 1
    }
    
    struct KeyPath {
        static let messages = "Messages"
    }
        
    enum SortedColumn: String {
        case date = "Date"
        case from = "From"
        case size = "Size"
        case subject = "Subject"
    }
    
    // MARK: - Public methods
    
    func message(message: Message, action: MessageAction) {
        writeRequest(action.method, path: action.pathForMessage(message), parameters: nil)
    }
    
    func messageDetail(#message: Message, completion: (NSError? -> Void)) {
        let path = "/messages/\(message.messageID)"
        
        let successBlock: SuccessBlock = { response in
            let context = sharedCoreDataService.newManagedObjectContext()
            
            context.performBlock() {
                var error: NSError?
                let message = GRTJSONSerialization.mergeObjectForEntityName(Message.Attributes.entityName, fromJSONDictionary: response, inManagedObjectContext: context, error: &error) as Message
                
                if error == nil {
                    message.isDetailDownloaded = true
                    
                    error = context.saveUpstreamIfNeeded()
                }
                
                if error != nil  {
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
            
            if let messagesArray = response[KeyPath.messages] as? [NSDictionary] {
                let context = sharedCoreDataService.newManagedObjectContext()
                
                context.performBlock() {
                    var messages = GRTJSONSerialization.mergeObjectsForEntityName(Message.Attributes.entityName, fromJSONArray: messagesArray, inManagedObjectContext: context, error: &error)
                    
                    if error == nil {
                        for message in messages as [Message] {
                            message.locationNumber = location.rawValue
                        }

                        error = context.saveUpstreamIfNeeded()
                    }
                    
                    if error != nil  {
                        NSLog("\(__FUNCTION__) error: \(error)")
                    }
                }
            } else {
                error = APIError.unableToParseResponse.asNSError()
            }
            
            completion(error)
        }
        
        GET(path, parameters: parameters, success: successBlock, failure: completion)
    }
}


/// Message APIService extension
extension Message {
    
    // MARK: - Public variables
    
    var location: APIService.Location {
        return APIService.Location(rawValue: locationNumber.integerValue) ?? APIService.Location.inbox
    }
}