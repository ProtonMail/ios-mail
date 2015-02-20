//
//  APIService+ContactExtension.swift
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

/// Contact extension
extension APIService {
    
    private struct KeyPath {
        static let basePath = "/contacts"
        static let contactEmail = "ContactEmail"
        static let contactName = "ContactName"
    }
    
    func contactAdd(#name: String, email: String, completion: CompletionBlock?) {
        let path = KeyPath.basePath
        let parameters = [
            KeyPath.contactName : name,
            KeyPath.contactEmail : email]
        
        request(method: .POST, path: path, parameters: parameters, completion: completion)
    }
    
    func contactDelete(#contactID: String, completion: CompletionBlock?) {
        let path = "\(KeyPath.basePath)/\(contactID)"
        
        request(method: .DELETE, path: path, parameters: nil, completion: completion)
    }
    
    func contactList(completion: CompletionBlock?) {
        let path = KeyPath.basePath
        
        request(method: .GET, path: path, parameters: nil, completion: completion)
    }
    
    func contactUpdate(#contactID: String, name: String, email: String, completion: CompletionBlock?) {
        let path = "\(KeyPath.basePath)/\(contactID)"
        
        let parameters = [
            KeyPath.contactName : name,
            KeyPath.contactEmail : email]
        
        request(method: .PUT, path: path, parameters: parameters, completion: completion)
    }    
}
