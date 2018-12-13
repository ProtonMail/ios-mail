//
//  APIService+ContactExtension.swift
//  ProtonMail
//
//
//  The MIT License
//
//  Copyright (c) 2018 Proton Technologies AG
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import Foundation

/// Contact extension
extension APIService {
    
    fileprivate struct ContactPath {
        static let base = Constants.App.API_PATH + "/contacts"
    }
    
    func contactDelete(contactID: String, completion: CompletionBlock?) {
        let path = ContactPath.base + "/delete"
        let parameters = ["IDs": [ contactID ] ]
        //setApiVesion(1, appVersion: 1)
        request(method: .put, path: path, parameters: parameters, headers: ["x-pm-apiversion": 3], completion: completion)
    }
    
    func contactList(_ completion: CompletionBlock?) {
        let path = ContactPath.base
        //setApiVesion(1, appVersion: 1)
        request(method: .get, path: path, parameters: nil, headers: ["x-pm-apiversion": 3], completion: completion)
    }
    
     func contactUpdate(contactID: String, name: String, email: String, completion: CompletionBlock?) {
         let path = ContactPath.base + "/\(contactID)"
         let parameters = parametersForName(name, email: email)
         //setApiVesion(1, appVersion: 1)
         request(method: .put, path: path, parameters: parameters, headers: ["x-pm-apiversion": 3], completion: completion)
    }
    
    // MARK: - Private methods
    fileprivate func parametersForName(_ name: String, email: String) -> NSDictionary {
        return [
            "Name" : name,
            "Email" :email]
    }
}
