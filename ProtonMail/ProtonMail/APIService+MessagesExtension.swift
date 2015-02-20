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
        
        var moveAction: MessageDataService.MessageAction? {
            switch(self) {
            case .inbox:
                return .inbox
            case .spam:
                return .spam
            case .trash:
                return .trash
            default:
                return nil
            }
        }
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
    
    // MARK: - Public methods
    
    // FIXME: Pass in MessageDataService.MessageAction, instead of a String.  Xcode 6.1.1 generates a segmentation fault 11, try it again when a newer version is released.
    func messageID(messageID: String, updateWithAction action: String, completion: CompletionBlock) {

        // FIXME: Remove this wrapper when action can be passed in directly
        if let action = MessageDataService.MessageAction(rawValue: action) {
            let path = "/messages/\(messageID)/\(action.rawValue)"

            switch(action) {
            case .delete:
                request(method: .DELETE, path: path, parameters: nil, completion: completion)
            default:
                request(method: .PUT, path: path, parameters: nil, completion: completion)
            }
        }
    }
    
    func messageDetail(#messageID: String, completion: CompletionBlock) {
        let path = "/messages/\(messageID)"
        
        request(method: .GET, path: path, parameters: nil, completion: completion)
    }
    
    func messageList(location: Location, page: Int, sortedColumn: SortedColumn, order: Order, filter: Filter, completion: CompletionBlock) {
        let path = "/messages"
        
        let parameters = [
            "Location" : location.rawValue,
            "Page" : page,
            "SortedColumn" : sortedColumn.rawValue,
            "Order" : order.rawValue,
            "FilterUnread" : filter.rawValue]
        
        request(method: .GET, path: path, parameters: parameters, completion: completion)
    }
}


// MARK: - Message APIService extension

extension Message {
    
    // MARK: - Public variables
    
    var location: APIService.Location {
        return APIService.Location(rawValue: locationNumber.integerValue) ?? APIService.Location.inbox
    }
}
