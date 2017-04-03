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
    
    fileprivate struct ContactPath {
        static let base = AppConstants.API_PATH + "/contacts"
    }
    
    func contactAdd(name: String, email: String, completion: CompletionBlock?) {
        let path = ContactPath.base
        let contact = [ "Name": name, "Email" : email];
        let parameters = ["Contacts": [contact] ];
        //setApiVesion(1, appVersion: 1)
        request(method: .post, path: path, parameters: parameters, headers: ["x-pm-apiversion": 1], completion: completion)
    }
    
    func contactDelete(contactID: String, completion: CompletionBlock?) {
        let path = ContactPath.base + "/delete"
        let parameters = ["IDs": [ contactID ] ]
        //setApiVesion(1, appVersion: 1)
        request(method: .put, path: path, parameters: parameters, headers: ["x-pm-apiversion": 1], completion: completion)
    }
    
    func contactList(_ completion: CompletionBlock?) {
        let path = ContactPath.base
        //setApiVesion(1, appVersion: 1)
        request(method: .get, path: path, parameters: nil, headers: ["x-pm-apiversion": 1], completion: completion)
    }
    
    func contactUpdate(contactID: String, name: String, email: String, completion: CompletionBlock?) {
        let path = ContactPath.base + "/\(contactID)"
        let parameters = parametersForName(name, email: email)
        //setApiVesion(1, appVersion: 1)
        request(method: .put, path: path, parameters: parameters, headers: ["x-pm-apiversion": 1], completion: completion)
    }
    
    // MARK: - Private methods
    fileprivate func parametersForName(_ name: String, email: String) -> NSDictionary {
        return [
            "Name" : name,
            "Email" :email]
    }
}
