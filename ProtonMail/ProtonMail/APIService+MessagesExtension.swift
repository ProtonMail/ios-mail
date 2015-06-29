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

//TODO :: all the request post put ... all could abstract a body layer, after change the request only need the url and request object.
/// Messages extension
extension APIService {
    
    private struct MessagePath {
        static let base = "/messages"
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
    
    struct MessageErrorCode {
        static let credentialExpired = 10
        static let credentialInvalid = 20
        static let invalidGrant = 30
        static let unableToParseToken = 40
    }
    
    //new way to do the new work calls
    func POST<T: ApiResponse> ( apiRequest : ApiRequest<T>!, completion: CompletionBlock?) {
        var parameterStrings = apiRequest.toDictionary()
        setApiVesion(apiRequest.getVersion(), appVersion: AppConstants.AppVersion)
        request(method: .POST, path: apiRequest.getRequestPath(), parameters: parameterStrings, completion: completion)
    }
    
    func PUT<T: ApiResponse>  ( apiRequest : ApiRequest<T>!, completion: CompletionBlock?) {
        var parameterStrings = apiRequest.toDictionary()
        setApiVesion(apiRequest.getVersion(), appVersion: AppConstants.AppVersion)
        request(method: .PUT, path: apiRequest.getRequestPath(), parameters: parameterStrings, completion: nil)
        completion!(task: nil, response: nil, error: nil)
    }

    func GET<T: ApiResponse>  ( apiRequest : ApiRequest<T>!, completion: CompletionBlock?) {
        var parameterStrings = apiRequest.toDictionary()
        setApiVesion(apiRequest.getVersion(), appVersion: AppConstants.AppVersion)
        request(method: .GET, path: apiRequest.getRequestPath(), parameters: parameterStrings, completion: completion)
    }
    
    func Delete<T: ApiResponse>  ( apiRequest : ApiRequest<T>!, completion: CompletionBlock?) {
        var parameterStrings = apiRequest.toDictionary()
        setApiVesion(apiRequest.getVersion(), appVersion: AppConstants.AppVersion)
        request(method: .DELETE, path: apiRequest.getRequestPath(), parameters: parameterStrings, completion: completion)
    }
    
    
    // MARK : Need change soon
    func fetchLatestMessageList(time: Int, completion: CompletionBlock) {
        let path = MessagePath.base + "/latest/\(time)"
        
        request(method: .GET, path: path, parameters: nil, completion: completion)
    }
    
    
    // func messageID(messageID: String, updateWithAction action: MessageAction, completion: CompletionBlock?) {
    
    
    
    
    //            let parameters = ["IDs" : [messageID]]
    //            request(method: .PUT, path: path, parameters: parameters, completion: nil)
    //            completion!(task: nil, response: nil, error: nil);//TODO:: need fix the response
    
    //        switch(action) {
    //        case .delete:
    //            let path = MessagePath.base.stringByAppendingPathComponent(messageID)
    //            request(method: .DELETE, path: path, parameters: nil, completion: completion)
    //        default:
    //            let path = MessagePath.base.stringByAppendingPathComponent(action.rawValue)
    //            //MessagePath.base.stringByAppendingPathComponent(messageID).stringByAppendingPathComponent(action.rawValue)
    //            let parameters = ["IDs" : [messageID]]
    //            request(method: .PUT, path: path, parameters: parameters, completion: nil)
    //            completion!(task: nil, response: nil, error: nil);//TODO:: need fix the response
    //        }
    //}

    
    
    
    
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
        isEncrypted: NSNumber,
        body: [String : String],
        attachments: [Attachment],
        completion: CompletionBlock?) {
            let path = "/messages"
            var parameterStrings: [String : String] = [
                "MessageID" : messageID,
                "RecipientList" : recipientList,
                "BCCList" : bccList,
                "CCList" : ccList,
                "MessageTitle" : title,
                "PasswordHint" : passwordHint]
            
            var parameters: [String : AnyObject] = filteredMessageStringParameters(parameterStrings)
            
            if expirationDate != nil {
                parameters["ExpirationTime"] = Double(expirationDate?.timeIntervalSince1970 ?? 0)
            }
            
            parameters["IsEncrypted"] =  isEncrypted.isEncrypted() ? 1 : 0
            parameters["MessageBody"] = body
            
            if !attachments.isEmpty {
//                var attachmentsArray: [[String : AnyObject]] = []
//                
//                for attachment in attachments {
//                    attachmentsArray.append(attachment.asJSON())
//                }
//                
//                parameters["Attachments"] = attachmentsArray
            }
            
            
            setApiVesion(2, appVersion: 1)
            request(method: .POST, path: path, parameters: parameters, completion: completion)
    }
    
    func messageDraft(
        recipientList: String = "",
        bccList: String = "",
        ccList: String = "",
        title: String = "",
        passwordHint: String = "",
        expirationDate: NSDate? = nil,
        isEncrypted: NSNumber,
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
//                var attachmentsJSON: Array<Dictionary<String,AnyObject>> = []
//                
//                for attachment in attachments {
//                    attachmentsJSON.append(attachment.asJSON())
//                }
//                
//                parameters["Attachments"] = attachmentsJSON
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
        isEncrypted: NSNumber,
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
//                var attachmentsJSON: Array<Dictionary<String,AnyObject>> = []
//                
//                for attachment in attachments {
//                    attachmentsJSON.append(attachment.asJSON())
//                }
//                
//                parameters["Attachments"] = attachmentsJSON
            }
            
            request(method: .POST, path: path, parameters: parameters, completion: completion)
    }
    
    
    func messageDetail(#messageID: String, completion: CompletionBlock) {
        let path = MessagePath.base.stringByAppendingPathComponent(messageID)
        
        NSLog("\(__FUNCTION__) path: \(path)")
        
        request(method: .GET, path: path, parameters: nil, completion: completion)
    }
    
    func messageList(location: Int, page: Int, sortedColumn: SortedColumn, order: Order, filter: Filter, completion: CompletionBlock) {
        let path = MessagePath.base
        
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
    
    
    // MARK: - Private methods
    private func filteredMessageStringParameters(parameters: [String : String]) -> [String : String] {
        var filteredParameters: [String : String] = [:]
        
        for (key, value) in parameters {
            if !value.isEmpty {
                filteredParameters[key] = value
            }
        }
        
        return filteredParameters
    }
}
