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
    
    struct Attachment {
        let fileName: String
        let mimeType: String
        let fileData: Dictionary<String,String>
        let fileSize: Int
        
        init(fileName: String, mimeType: String, fileData: Dictionary<String,String>, fileSize: Int) {
            self.fileName = fileName
            self.mimeType = mimeType
            self.fileData = fileData
            self.fileSize = fileSize
        }
        
        func asJSON() -> Dictionary<String,AnyObject> {
            return [
                "FileName" : fileName,
                "MIMEType" : mimeType,
                "FileData" : fileData,
                "FileSize" : String(fileSize)]
        }
    }
    
    enum Filter: Int {
        case noFilter = -2
        case read = 0
        case unRead = 1
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
    
    func messageCheck(#timestamp: NSTimeInterval, completion: CompletionBlock?) {
        let path = "/messages/check"
        let parameters = ["t" : timestamp]
        
        request(method: .GET, path: path, parameters: parameters, completion: completion)
    }
    
    func messageCountForLocation(location: Int, completion: CompletionBlock?) {
        let path = "/messages"
        let parameters = ["Location" : location]
        let completionWrapper = completionWrapperParseCompletion(completion, forKey: "MessageCount")
        
        request(method: .GET, path: path, parameters: parameters, completion: completionWrapper)
    }
    
    func messageCreate(
        messageID: String = "0",
        recipientList: String = "",
        bccList: String = "",
        ccList: String = "",
        title: String = "",
        passwordHint: String = "",
        expirationDate: NSDate? = nil,
        isEncrypted: Bool,
        body: Dictionary<String,String>,
        attachments: Array<Attachment>?,
        completion: CompletionBlock?) {
            let path = "/messages"
            var parameters: Dictionary<String,AnyObject> = [
                "MessageID" : messageID,
                "RecipientList" : recipientList,
                "BCCList" : bccList,
                "CCList" : ccList,
                "MessageTitle" : title,
                "PasswordHint" : passwordHint,
                "ExpirationTime" : expirationDate?.timeIntervalSince1970 ?? 0,
                "IsEncrypted" : isEncrypted,
                "MessageBody" : body]
            
            if let attachments = attachments {
                var attachmentsJSON: Array<Dictionary<String,AnyObject>> = []
                
                for attachment in attachments {
                    attachmentsJSON.append(attachment.asJSON())
                }
                
                parameters["Attachments"] = attachmentsJSON
            }
            
            request(method: .POST, path: path, parameters: parameters, completion: completion)
    }
    
    func messageDraft(
        recipientList: String = "",
        bccList: String = "",
        ccList: String = "",
        title: String = "",
        passwordHint: String = "",
        expirationDate: NSDate? = nil,
        isEncrypted: Bool,
        body: Dictionary<String,String>,
        attachments: Array<Attachment>?,
        completion: CompletionBlock?) {
            let path = "/messages/draft"
            var parameters: Dictionary<String,AnyObject> = [
                "RecipientList" : recipientList,
                "BCCList" : bccList,
                "CCList" : ccList,
                "MessageTitle" : title,
                "PasswordHint" : passwordHint,
                "ExpirationTime" : expirationDate?.timeIntervalSince1970 ?? 0,
                "IsEncrypted" : isEncrypted,
                "MessageBody" : body]
            
            if let attachments = attachments {
                var attachmentsJSON: Array<Dictionary<String,AnyObject>> = []
                
                for attachment in attachments {
                    attachmentsJSON.append(attachment.asJSON())
                }
                
                parameters["Attachments"] = attachmentsJSON
            }
            
            request(method: .POST, path: path, parameters: parameters, completion: completion)
    }
    
    func messageDraftUpdate(
        #messageID: String,
        recipientList: String = "",
        bccList: String = "",
        ccList: String = "",
        title: String = "",
        passwordHint: String = "",
        expirationDate: NSDate? = nil,
        isEncrypted: Bool,
        body: Dictionary<String,String>,
        attachments: Array<Attachment>?,
        completion: CompletionBlock?) {
            let path = "/messages/\(messageID)/draft"
            var parameters: Dictionary<String,AnyObject> = [
                "MessageID" : messageID,
                "RecipientList" : recipientList,
                "BCCList" : bccList,
                "CCList" : ccList,
                "MessageTitle" : title,
                "PasswordHint" : passwordHint,
                "ExpirationTime" : expirationDate?.timeIntervalSince1970 ?? 0,
                "IsEncrypted" : isEncrypted,
                "MessageBody" : body]
            
            if let attachments = attachments {
                var attachmentsJSON: Array<Dictionary<String,AnyObject>> = []
                
                for attachment in attachments {
                    attachmentsJSON.append(attachment.asJSON())
                }
                
                parameters["Attachments"] = attachmentsJSON
            }
            
            request(method: .POST, path: path, parameters: parameters, completion: completion)
    }

    
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
    
    func messageList(location: Int, page: Int, sortedColumn: SortedColumn, order: Order, filter: Filter, completion: CompletionBlock) {
        let path = "/messages"
        
        let parameters = [
            "Location" : location,
            "Page" : page,
            "SortedColumn" : sortedColumn.rawValue,
            "Order" : order.rawValue,
            "FilterUnread" : filter.rawValue]
        
        request(method: .GET, path: path, parameters: parameters, completion: completion)
    }
    
    func messageSearch(query: String, page: Int, completion: CompletionBlock?) {
        let path = "/messages/search"
        let parameters = [
            "query" : query,
            "page" : page]
        
        request(method: .GET, path: path, parameters: parameters, completion: completion)
    }
}
